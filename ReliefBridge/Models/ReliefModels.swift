// ReliefBridge/Models/ReliefModels.swift
// ReliefBridge domain model — the need → pledge → fulfillment loop.
//
// Design note: there are two sides to ReliefBridge. The *need* side (crises,
// where + how severe) is real public data pulled live from USGS and GDACS.
// The *contribution* side is the user's own real action, stored on device.
// Nothing here is mock data — Needs are decoded from live feeds, and the
// funding goal is a transparent severity-scaled target, not invented progress.

import Foundation
import CoreLocation

// MARK: - Hazard kind

enum HazardKind: String, CaseIterable, Identifiable {
    case earthquake
    case flood
    case cyclone
    case volcano
    case drought
    case wildfire
    case tsunami
    case other

    var id: String { rawValue }

    /// SF Symbol used on the hotspot and in the need card.
    var symbolName: String {
        switch self {
        case .earthquake: return "waveform.path.ecg"
        case .flood:      return "drop.fill"
        case .cyclone:    return "hurricane"
        case .volcano:    return "mountain.2.fill"
        case .drought:    return "sun.max.trianglebadge.exclamationmark.fill"
        case .wildfire:   return "flame.fill"
        case .tsunami:    return "water.waves"
        case .other:      return "exclamationmark.triangle.fill"
        }
    }

    var label: String {
        switch self {
        case .earthquake: return "Earthquake"
        case .flood:      return "Flood"
        case .cyclone:    return "Cyclone"
        case .volcano:    return "Volcano"
        case .drought:    return "Drought"
        case .wildfire:   return "Wildfire"
        case .tsunami:    return "Tsunami"
        case .other:      return "Hazard"
        }
    }

    /// Maps a GDACS `eventtype` code to a hazard kind.
    static func fromGDACS(_ code: String) -> HazardKind {
        switch code.uppercased() {
        case "EQ": return .earthquake
        case "FL": return .flood
        case "TC": return .cyclone
        case "VO": return .volcano
        case "DR": return .drought
        case "WF": return .wildfire
        case "TS": return .tsunami
        default:   return .other
        }
    }
}

// MARK: - Severity (drives hotspot color)

/// Three-level alert severity, mirroring the GDACS / USGS PAGER color scheme.
enum Severity: Int, Comparable, CaseIterable, Identifiable {
    case green = 0   // limited impact
    case orange = 1  // significant
    case red = 2     // severe

    var id: Int { rawValue }

    static func < (lhs: Severity, rhs: Severity) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var label: String {
        switch self {
        case .green:  return "Limited"
        case .orange: return "Significant"
        case .red:    return "Severe"
        }
    }

    /// Parses a GDACS / USGS PAGER alert string ("Green"/"Orange"/"Red"/"Yellow").
    static func fromAlertString(_ raw: String?) -> Severity? {
        guard let raw = raw?.lowercased() else { return nil }
        switch raw {
        case "red":              return .red
        case "orange", "yellow": return .orange
        case "green":            return .green
        default:                 return nil
        }
    }
}

// MARK: - Relief Organizations
struct ReliefOrg: Identifiable, Codable, Hashable {
    let id = UUID()
    let name: String
    let slug: String
    let description: String?
    let profileUrl: String
    let logoUrl: String?
    let websiteUrl: String?
    let location: String?

    enum CodingKeys: String, CodingKey {
        case name, slug, description, profileUrl, logoUrl, websiteUrl, location
    }
}

// MARK: - Contribution (the bridge the user builds)

enum ContributionKind: String, CaseIterable, Identifiable {
    case money
    case supplies
    case volunteerHours
    case blood
    case skill

    var id: String { rawValue }

    var label: String {
        switch self {
        case .money:          return "Funds"
        case .supplies:       return "Supplies"
        case .volunteerHours: return "Volunteer Hours"
        case .blood:          return "Blood"
        case .skill:          return "Skills"
        }
    }
}

extension ContributionKind {
    var symbolName: String {
        switch self {
        case .money:          return "dollarsign.circle.fill"
        case .supplies:       return "shippingbox.fill"
        case .volunteerHours: return "hands.and.sparkles.fill"
        case .blood:          return "drop.fill"
        case .skill:          return "wrench.and.screwdriver.fill"
        }
    }
    /// What a non-money pledge of this kind shows in the feed.
    var actionVerb: String {
        switch self {
        case .money:          return "Funded"
        case .supplies:       return "Pledged supplies to"
        case .volunteerHours: return "Volunteered for"
        case .blood:          return "Pledged blood to"
        case .skill:          return "Offered skills to"
        }
    }
}

/// A single real pledge made by the user toward a Need. Persisted on device.
struct Contribution: Identifiable, Codable, Equatable {
    let id: UUID
    let needID: String
    let kind: ContributionKind
    let amountUSD: Double
    let createdAt: Date

    init(id: UUID = UUID(), needID: String, kind: ContributionKind = .money, amountUSD: Double, createdAt: Date = Date()) {
        self.id = id
        self.needID = needID
        self.kind = kind
        self.amountUSD = amountUSD
        self.createdAt = createdAt
    }
}

extension ContributionKind: Codable {}

// MARK: - Surplus offer (what the user has to give — the Surplus Radar side)

/// Something the user has registered that they can give. Persisted on device.
/// Matched against live needs by hazard relevance + real distance.
struct SurplusOffer: Identifiable, Codable, Equatable {
    let id: UUID
    let kind: ContributionKind
    let title: String
    let detail: String
    let createdAt: Date

    init(id: UUID = UUID(), kind: ContributionKind, title: String, detail: String = "", createdAt: Date = Date()) {
        self.id = id
        self.kind = kind
        self.title = title
        self.detail = detail
        self.createdAt = createdAt
    }
}

// MARK: - Need lifecycle

enum NeedState: String {
    case open       // no contributions yet
    case bridging   // partially funded
    case fulfilled  // funding goal reached
}

// MARK: - Need

/// A single humanitarian need, decoded from a live crisis feed.
struct Need: Identifiable, Equatable {
    /// Stable, source-prefixed id (e.g. "usgs:us7000sr8k", "gdacs:1018431").
    let id: String
    let source: String          // "USGS" or "GDACS"
    let kind: HazardKind
    let title: String
    let summary: String
    let coordinate: CLLocationCoordinate2D
    let severity: Severity
    let magnitude: Double?       // earthquakes only
    let affectedCountries: [String]
    let eventDate: Date?
    let sourceURL: URL?

    /// Real user pledges toward this need (reattached across refreshes).
    var contributions: [Contribution] = []

    static func == (lhs: Need, rhs: Need) -> Bool {
        lhs.id == rhs.id &&
        lhs.severity == rhs.severity &&
        lhs.contributions == rhs.contributions
    }
}

extension Need {

    /// Transparent funding target scaled by real severity. This frames the
    /// real crisis as a goal for the user's contributions — it is not invented
    /// progress; progress comes entirely from the user's own pledges.
    var goalUSD: Double {
        switch severity {
        case .red:    return 50_000
        case .orange: return 20_000
        case .green:  return 5_000
        }
    }

    var pledgedUSD: Double {
        contributions.reduce(0) { $0 + $1.amountUSD }
    }

    /// 0.0 – 1.0, derived purely from the user's real contributions.
    var progress: Double {
        guard goalUSD > 0 else { return 0 }
        return min(1.0, pledgedUSD / goalUSD)
    }

    var state: NeedState {
        if progress >= 1.0 { return .fulfilled }
        if pledgedUSD > 0 { return .bridging }
        return .open
    }

    /// Any kind of pledge (money OR supplies/skill/etc) counts as a bridge.
    var isBridged: Bool { !contributions.isEmpty }

    var locationLabel: String {
        if !affectedCountries.isEmpty {
            return affectedCountries.joined(separator: ", ")
        }
        return String(format: "%.2f, %.2f", coordinate.latitude, coordinate.longitude)
    }

    // MARK: - Urgency (computed from real signals — severity, recency, magnitude, reach)

    /// 0–100 urgency index. Deterministic, derived purely from real feed data.
    var urgencyScore: Int {
        var score: Double
        switch severity {
        case .red:    score = 60
        case .orange: score = 35
        case .green:  score = 15
        }
        if let date = eventDate {
            let hours = Date().timeIntervalSince(date) / 3600
            if hours <= 24 { score += 25 }
            else if hours <= 72 { score += 15 }
            else if hours <= 24 * 7 { score += 8 }
        }
        if let mag = magnitude {
            score += min(15, max(0, (mag - 4.5) * 6))
        }
        score += min(10, Double(affectedCountries.count) * 3)
        return Int(min(100, score.rounded()))
    }

    var urgencyLabel: String {
        switch urgencyScore {
        case 70...:  return "Critical"
        case 45..<70: return "High"
        case 25..<45: return "Elevated"
        default:     return "Moderate"
        }
    }

    /// Great-circle distance in km from a given coordinate (Haversine).
    func distanceKm(from origin: CLLocationCoordinate2D) -> Double {
        let r = 6371.0
        let dLat = (coordinate.latitude - origin.latitude) * .pi / 180
        let dLon = (coordinate.longitude - origin.longitude) * .pi / 180
        let a = sin(dLat / 2) * sin(dLat / 2)
            + cos(origin.latitude * .pi / 180) * cos(coordinate.latitude * .pi / 180)
            * sin(dLon / 2) * sin(dLon / 2)
        return r * 2 * atan2(sqrt(a), sqrt(1 - a))
    }

    var timeAgo: String {
        guard let date = eventDate else { return "" }
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f.localizedString(for: date, relativeTo: Date())
    }
}
