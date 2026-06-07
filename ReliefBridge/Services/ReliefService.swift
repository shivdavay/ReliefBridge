// ReliefBridge/Services/ReliefService.swift
// Live crisis data engine for ReliefBridge.
//
// Pulls REAL humanitarian data from two free, keyless feeds:
//   • USGS  — earthquakes, always-live GeoJSON, updated ~every minute.
//   • GDACS — multi-hazard (floods, cyclones, droughts, volcanoes, wildfires),
//             color-coded alert severity. Credit: Global Disaster Alert and
//             Coordination System (GDACS).
//
// No mock data: every Need originates from one of these feeds. The user's
// pledges (Contributions) are persisted to disk via UserDefaults.

import Foundation
import CoreLocation
import Combine

// MARK: - ReliefService

@MainActor
final class ReliefService: ObservableObject {

    @Published private(set) var needs: [Need] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var lastUpdated: Date? = nil
    @Published var lastError: String? = nil

    /// The user's location — the near endpoint of every bridge arc.
    @Published private(set) var userOrigin: CLLocationCoordinate2D? = nil

    /// Hazard filter; nil = show everything.
    @Published var kindFilter: HazardKind? = nil

    /// What the user has registered they can give (Surplus Radar).
    @Published private(set) var surplusOffers: [SurplusOffer] = []
    
    /// Matched relief organizations for each need (needID -> orgs).
    @Published private(set) var matchedOrgs: [String: [ReliefOrg]] = [:]

    private let location = LocationProvider()
    private var cancellables = Set<AnyCancellable>()
    
    private let everyOrgAPIKey = "pk_live_cbdbe270a64e06830568e1cae0f27950"

    /// Repeating live-refresh timer. Crisis feeds update continuously, so we
    /// re-pull every few minutes to keep the globe and triage current.
    private var refreshTimer: Timer?
    private let autoRefreshInterval: TimeInterval = 120

    /// Persisted user pledges keyed by Need id.
    private var contributionStore: [String: [Contribution]] = [:]
    private let defaultsKey = "reliefbridge.contributions.v1"
    private let surplusKey = "reliefbridge.surplus.v1"

    private let usgsURL = URL(string: "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/4.5_week.geojson")!
    private let gdacsURL = URL(string: "https://www.gdacs.org/gdacsapi/api/events/geteventlist/SEARCH")!

    init() {
        loadContributions()
        loadSurplus()
        location.$coordinate
            .receive(on: DispatchQueue.main)
            .sink { [weak self] coord in self?.userOrigin = coord }
            .store(in: &cancellables)
        location.requestLocation()
        // Kick off the first live fetch immediately so every tab has data,
        // regardless of which tab the user opens first.
        Task { await refresh() }
        startAutoRefresh()
    }

    deinit { refreshTimer?.invalidate() }

    /// Begin periodic live refreshes. Safe on the main runloop since the class
    /// is @MainActor; each tick spawns a Task that hops back onto the actor.
    private func startAutoRefresh() {
        refreshTimer?.invalidate()
        let timer = Timer.scheduledTimer(withTimeInterval: autoRefreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, !self.isLoading else { return }
                await self.refresh()
            }
        }
        timer.tolerance = 15
        refreshTimer = timer
    }

    // MARK: - Derived view data

    var visibleNeeds: [Need] {
        guard let kindFilter else { return needs }
        return needs.filter { $0.kind == kindFilter }
    }

    var bridgedNeeds: [Need] { needs.filter(\.isBridged) }

    var activeCrisisCount: Int { needs.count }

    var severeCrisisCount: Int { needs.filter { $0.severity == .red }.count }

    var totalPledgedUSD: Double { needs.reduce(0) { $0 + $1.pledgedUSD } }

    var fulfilledCount: Int { needs.filter { $0.state == .fulfilled }.count }

    /// The arc origin, falling back to the centroid of active needs if the
    /// device location is not yet available.
    var resolvedOrigin: CLLocationCoordinate2D? {
        if let userOrigin { return userOrigin }
        guard !needs.isEmpty else { return nil }
        let lat = needs.map(\.coordinate.latitude).reduce(0, +) / Double(needs.count)
        let lon = needs.map(\.coordinate.longitude).reduce(0, +) / Double(needs.count)
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    // MARK: - Impact (computed from the user's real pledges + real needs)

    /// All of the user's contributions, newest first.
    var allContributions: [Contribution] {
        needs.flatMap(\.contributions).sorted { $0.createdAt > $1.createdAt }
    }

    /// Distinct affected countries across every need the user has bridged.
    var regionsReached: [String] {
        Array(Set(bridgedNeeds.flatMap(\.affectedCountries))).sorted()
    }

    /// How many of each hazard kind the user has bridged.
    var bridgedByKind: [(kind: HazardKind, count: Int)] {
        Dictionary(grouping: bridgedNeeds, by: \.kind)
            .map { ($0.key, $0.value.count) }
            .sorted { $0.count > $1.count }
    }

    /// Live global breakdown of active crises by hazard kind.
    var globalByKind: [(kind: HazardKind, count: Int)] {
        Dictionary(grouping: needs, by: \.kind)
            .map { ($0.key, $0.value.count) }
            .sorted { $0.count > $1.count }
    }

    /// Live global breakdown by severity.
    func globalCount(of severity: Severity) -> Int {
        needs.filter { $0.severity == severity }.count
    }

    // MARK: - Triage (urgency-ranked)

    var needsByUrgency: [Need] {
        needs.sorted { $0.urgencyScore > $1.urgencyScore }
    }

    // MARK: - Surplus Radar

    func addSurplus(kind: ContributionKind, title: String, detail: String = "") {
        let offer = SurplusOffer(kind: kind, title: title, detail: detail)
        surplusOffers.insert(offer, at: 0)
        saveSurplus()
    }

    func removeSurplus(_ offer: SurplusOffer) {
        surplusOffers.removeAll { $0.id == offer.id }
        saveSurplus()
    }

    /// Needs ranked by how well they match the user's surplus + how close/urgent
    /// they are. If no origin is known, distance is treated as neutral.
    func matchedNeeds(limit: Int = 25) -> [(need: Need, distanceKm: Double?)] {
        let origin = resolvedOrigin
        let relevantKinds = Set(surplusOffers.map(\.kind))

        return needs
            .map { need -> (need: Need, distanceKm: Double?, score: Double) in
                let dist = origin.map { need.distanceKm(from: $0) }
                var score = Double(need.urgencyScore)
                // Closer needs score higher (full bonus within 500 km, fading to 0 at 8000 km).
                if let d = dist {
                    score += max(0, 40 * (1 - min(d, 8000) / 8000))
                }
                // Hazard relevance bonus for kinds the user can actually supply.
                if relevantKinds.contains(.blood) && (need.kind == .earthquake || need.kind == .flood || need.kind == .cyclone) {
                    score += 15
                }
                if relevantKinds.contains(.supplies) { score += 8 }
                return (need, dist, score)
            }
            .sorted { $0.score > $1.score }
            .prefix(limit)
            .map { ($0.need, $0.distanceKm) }
    }

    func distanceLabel(to need: Need) -> String? {
        guard let origin = resolvedOrigin else { return nil }
        let km = need.distanceKm(from: origin)
        if km < 1000 { return String(format: "%.0f km away", km) }
        return String(format: "%.0fk km away", km / 1000)
    }

    // MARK: - Refresh

    func refresh() async {
        isLoading = true
        lastError = nil
        defer { isLoading = false }

        async let usgs = fetchUSGS()
        async let gdacs = fetchGDACS()

        let usgsResult = await usgs
        let gdacsResult = await gdacs

        var merged: [Need] = []
        var errors: [String] = []

        merged.append(contentsOf: gdacsResult.needs)
        if let e = gdacsResult.error { errors.append("GDACS: \(e)") }
        merged.append(contentsOf: usgsResult.needs)
        if let e = usgsResult.error { errors.append("USGS: \(e)") }

        // De-duplicate by id (GDACS earthquakes can overlap USGS); keep first.
        var seen = Set<String>()
        var deduped: [Need] = []
        for var need in merged where !seen.contains(need.id) {
            seen.insert(need.id)
            need.contributions = contributionStore[need.id] ?? []
            deduped.append(need)
        }

        // Most severe first, then most recent.
        deduped.sort { lhs, rhs in
            if lhs.severity != rhs.severity { return lhs.severity > rhs.severity }
            return (lhs.eventDate ?? .distantPast) > (rhs.eventDate ?? .distantPast)
        }

        if deduped.isEmpty {
            lastError = errors.isEmpty ? "No active crises returned by the feeds." : errors.joined(separator: "  •  ")
        } else {
            needs = deduped
            lastUpdated = Date()
            if !errors.isEmpty { lastError = errors.joined(separator: "  •  ") }
            // Warm the verified-org cache so contact info + counts show up
            // across the globe and triage list without waiting for a tap.
            Task { await prefetchOrgs() }
        }
    }

    // MARK: - Bridge a need (the core action)

    @discardableResult
    func bridge(needID: String, amountUSD: Double, kind: ContributionKind = .money) -> Bool {
        guard let index = needs.firstIndex(where: { $0.id == needID }) else { return false }
        let contribution = Contribution(needID: needID, kind: kind, amountUSD: amountUSD)
        needs[index].contributions.append(contribution)
        contributionStore[needID, default: []].append(contribution)
        saveContributions()
        return true
    }

    func need(withID id: String) -> Need? {
        needs.first { $0.id == id }
    }

    // MARK: - Persistence

    private func loadContributions() {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey) else { return }
        if let decoded = try? JSONDecoder().decode([Contribution].self, from: data) {
            contributionStore = Dictionary(grouping: decoded, by: \.needID)
        }
    }

    private func saveContributions() {
        let all = contributionStore.values.flatMap { $0 }
        if let data = try? JSONEncoder().encode(all) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }

    private func loadSurplus() {
        guard let data = UserDefaults.standard.data(forKey: surplusKey) else { return }
        if let decoded = try? JSONDecoder().decode([SurplusOffer].self, from: data) {
            surplusOffers = decoded
        }
    }

    private func saveSurplus() {
        if let data = try? JSONEncoder().encode(surplusOffers) {
            UserDefaults.standard.set(data, forKey: surplusKey)
        }
    }
    
    // MARK: - Relief Organizations (Every.org)

    /// Verified nonprofits cached per search term. Orgs are the same for every
    /// need of a given hazard kind, so we fetch once per term and reuse it for
    /// all matching needs — that keeps us to ≈8 calls instead of one per need.
    private var orgCacheByTerm: [String: [ReliefOrg]] = [:]

    /// Total distinct verified orgs the user can contact across active crises.
    var contactableOrgCount: Int {
        Set(matchedOrgs.values.flatMap { $0 }.map(\.slug)).count
    }

    /// Maps a hazard kind to the Every.org search query for matching relief orgs.
    private func searchTerm(for kind: HazardKind) -> String {
        switch kind {
        case .earthquake: return "earthquake relief"
        case .flood:      return "flood relief"
        case .cyclone:    return "hurricane relief"
        case .volcano:    return "disaster relief"
        case .drought:    return "water relief"
        case .wildfire:   return "wildfire relief"
        case .tsunami:    return "tsunami relief"
        case .other:      return "disaster relief"
        }
    }

    /// Fetch (or reuse cached) verified nonprofits for a need and publish them
    /// keyed by need id so the detail sheet and list rows can show them.
    func fetchOrgsForNeed(_ need: Need) async {
        if matchedOrgs[need.id] != nil { return }
        let term = searchTerm(for: need.kind)
        if let cached = orgCacheByTerm[term] {
            matchedOrgs[need.id] = cached
            return
        }
        if let orgs = await fetchOrgs(term: term) {
            cacheOrgs(orgs, term: term)
        }
    }

    /// Prefetch orgs for every hazard kind currently on the globe so contact
    /// info and counts appear instantly — without the user tapping anything.
    func prefetchOrgs() async {
        for kind in Set(needs.map(\.kind)) {
            let term = searchTerm(for: kind)
            if orgCacheByTerm[term] != nil { continue }
            if let orgs = await fetchOrgs(term: term) {
                cacheOrgs(orgs, term: term)
            }
        }
    }

    /// Store orgs for a term and publish them to every loaded need of that kind.
    private func cacheOrgs(_ orgs: [ReliefOrg], term: String) {
        orgCacheByTerm[term] = orgs
        for need in needs where searchTerm(for: need.kind) == term {
            matchedOrgs[need.id] = orgs
        }
    }

    /// Returns up to 5 verified nonprofits for a search term, or nil on failure.
    private func fetchOrgs(term: String) async -> [ReliefOrg]? {
        let encoded = term.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? term
        guard var components = URLComponents(string: "https://partners.every.org/v0.2/search/\(encoded)") else { return nil }
        components.queryItems = [
            URLQueryItem(name: "apiKey", value: everyOrgAPIKey),
            URLQueryItem(name: "take", value: "5")
        ]
        guard let url = components.url else { return nil }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { return nil }
            let decoded = try JSONDecoder().decode(EveryOrgSearchResponse.self, from: data)
            return Array(decoded.nonprofits.prefix(5))
        } catch {
            print("⚠️ Every.org fetch failed: \(error)")
            return nil
        }
    }

    // MARK: - USGS fetch

    private func fetchUSGS() async -> (needs: [Need], error: String?) {
        do {
            let (data, response) = try await URLSession.shared.data(from: usgsURL)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                return ([], "bad response")
            }
            let collection = try JSONDecoder().decode(USGSFeatureCollection.self, from: data)
            return (collection.features.compactMap { $0.toNeed() }, nil)
        } catch {
            return ([], error.localizedDescription)
        }
    }

    // MARK: - GDACS fetch

    private func fetchGDACS() async -> (needs: [Need], error: String?) {
        do {
            var request = URLRequest(url: gdacsURL)
            request.timeoutInterval = 20
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                return ([], "bad response")
            }
            let collection = try JSONDecoder().decode(GDACSFeatureCollection.self, from: data)
            return (collection.features.compactMap { $0.toNeed() }, nil)
        } catch {
            return ([], error.localizedDescription)
        }
    }
}

// MARK: - USGS GeoJSON decoding

private struct USGSFeatureCollection: Decodable {
    let features: [USGSFeature]
}

private struct USGSFeature: Decodable {
    let id: String
    let properties: Properties
    let geometry: PointGeometry

    struct Properties: Decodable {
        let mag: Double?
        let place: String?
        let title: String?
        let time: Double?
        let url: String?
        let alert: String?
        let tsunami: Int?
    }

    func toNeed() -> Need? {
        guard let coord = geometry.coordinate else { return nil }
        let severity: Severity = Severity.fromAlertString(properties.alert) ?? {
            guard let mag = properties.mag else { return .green }
            if mag >= 6.5 { return .red }
            if mag >= 5.5 { return .orange }
            return .green
        }()
        let kind: HazardKind = (properties.tsunami ?? 0) == 1 ? .tsunami : .earthquake
        let date = properties.time.map { Date(timeIntervalSince1970: $0 / 1000.0) }
        let place = properties.place ?? "Unknown location"
        let magText = properties.mag.map { String(format: "M%.1f", $0) } ?? "Earthquake"
        return Need(
            id: "usgs:\(id)",
            source: "USGS",
            kind: kind,
            title: properties.title ?? "\(magText) — \(place)",
            summary: "\(magText) earthquake near \(place). Communities may need search-and-rescue, shelter, water, and medical support.",
            coordinate: coord,
            severity: severity,
            magnitude: properties.mag,
            affectedCountries: USGSFeature.country(from: place),
            eventDate: date,
            sourceURL: properties.url.flatMap(URL.init(string:))
        )
    }

    /// Best-effort country extraction from a USGS place string ("... , Argentina").
    static func country(from place: String) -> [String] {
        let parts = place.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        if let last = parts.last, !last.isEmpty, parts.count > 1 { return [String(last)] }
        return []
    }
}

// MARK: - GDACS GeoJSON decoding

private struct GDACSFeatureCollection: Decodable {
    let features: [GDACSFeature]
}

private struct GDACSFeature: Decodable {
    let properties: Properties
    let geometry: PointGeometry

    struct Properties: Decodable {
        let eventtype: String
        let eventid: Int
        let name: String?
        let description: String?
        let htmldescription: String?
        let alertlevel: String?
        let country: String?
        let fromdate: String?
        let affectedcountries: [AffectedCountry]?
        let severitydata: SeverityData?
        let url: URLBlock?

        struct AffectedCountry: Decodable { let countryname: String? }
        struct SeverityData: Decodable { let severitytext: String? }
        struct URLBlock: Decodable { let report: String? }
    }

    func toNeed() -> Need? {
        guard let coord = geometry.coordinate else { return nil }
        let severity = Severity.fromAlertString(properties.alertlevel) ?? .green
        let kind = HazardKind.fromGDACS(properties.eventtype)
        let title = properties.name ?? properties.description ?? "\(kind.label) event"
        var summaryParts: [String] = []
        if let s = properties.severitydata?.severitytext, !s.isEmpty { summaryParts.append(s) }
        if let d = properties.description, !d.isEmpty, d != title { summaryParts.append(d) }
        let summary = summaryParts.isEmpty
            ? "\(severity.label) \(kind.label.lowercased()) event reported by GDACS."
            : summaryParts.joined(separator: " — ")
        let countries = properties.affectedcountries?.compactMap(\.countryname).filter { !$0.isEmpty }
            ?? properties.country.map { [$0] } ?? []
        let date = GDACSFeature.parseDate(properties.fromdate)
        return Need(
            id: "gdacs:\(properties.eventid)",
            source: "GDACS",
            kind: kind,
            title: title,
            summary: summary,
            coordinate: coord,
            severity: severity,
            magnitude: nil,
            affectedCountries: countries,
            eventDate: date,
            sourceURL: properties.url?.report.flatMap(URL.init(string:))
        )
    }

    private static let dateFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    static func parseDate(_ raw: String?) -> Date? {
        guard let raw else { return nil }
        if let d = dateFormatter.date(from: raw) { return d }
        // GDACS uses "2025-11-21T00:00:00" (no zone / no fractional seconds).
        let fallback = DateFormatter()
        fallback.locale = Locale(identifier: "en_US_POSIX")
        fallback.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return fallback.date(from: raw)
    }
}

// MARK: - Shared GeoJSON point geometry

private struct PointGeometry: Decodable {
    let coordinates: [Double]

    /// GeoJSON stores [longitude, latitude, (depth)].
    var coordinate: CLLocationCoordinate2D? {
        guard coordinates.count >= 2 else { return nil }
        let lon = coordinates[0]
        let lat = coordinates[1]
        guard lat >= -90, lat <= 90, lon >= -180, lon <= 180 else { return nil }
        guard !(lat == 0 && lon == 0) else { return nil } // null-island guard
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}

// MARK: - Location

/// Thin CoreLocation wrapper publishing the user's coordinate (the bridge origin).
final class LocationProvider: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var coordinate: CLLocationCoordinate2D? = nil
    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestLocation() {
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        DispatchQueue.main.async { self.coordinate = loc.coordinate }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Silent: the globe falls back to the centroid of active needs.
    }
}

// MARK: - Every.org API decoder

private struct EveryOrgSearchResponse: Decodable {
    let nonprofits: [ReliefOrg]
}
