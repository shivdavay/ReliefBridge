// ReliefBridge/Views/ReliefBridge/ReliefGlobeView.swift
// ReliefBridge — the interactive crisis globe.
//
// Tap a glowing hotspot (a live crisis from USGS / GDACS) → a Need card slides
// up → "Bridge it" pledges support → a geodesic arc animates from you to the
// need and its progress ring fills. Every hotspot is real, live data.

import SwiftUI
import MapKit

@available(iOS 17.0, macOS 14.0, *)
struct ReliefGlobeView: View {

    @EnvironmentObject private var relief: ReliefService

    @State private var selectedNeed: Need? = nil
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 20.0, longitude: 10.0),
            span: MKCoordinateSpan(latitudeDelta: 110, longitudeDelta: 140)
        )
    )

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                globe
                    .ignoresSafeArea(edges: .top)

                bottomDeck
            }
            .overlay(alignment: .top) { header.padding(.horizontal, 16).padding(.top, 56) }
            .overlay(alignment: .topTrailing) {
                SeverityLegend(relief: relief)
                    .padding(.horizontal, 16)
                    .padding(.top, 150)
            }
            .overlay { loadingOrEmptyOverlay }
            .navigationTitle("ReliefBridge")
            #if os(iOS)
            .toolbarBackground(Theme.Colors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button { relief.kindFilter = nil } label: {
                            Label("All hazards", systemImage: relief.kindFilter == nil ? "checkmark" : "globe")
                        }
                        ForEach(HazardKind.allCases) { kind in
                            Button { relief.kindFilter = kind } label: {
                                Label(kind.label, systemImage: relief.kindFilter == kind ? "checkmark" : kind.symbolName)
                            }
                        }
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                            .foregroundColor(relief.kindFilter == nil ? .white : Theme.Colors.efficiencyGreen)
                    }
                }
            }
            .sheet(item: $selectedNeed) { need in
                NeedDetailSheet(needID: need.id)
                    .environmentObject(relief)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .task {
                if relief.needs.isEmpty { await relief.refresh() }
            }
        }
        .background(Theme.Colors.background.ignoresSafeArea())
    }

    // MARK: - Globe

    private var globe: some View {
        Map(position: $cameraPosition) {
            // Bridge arcs — geodesic great-circle lines from you to each bridged need.
            if let origin = relief.resolvedOrigin {
                ForEach(relief.bridgedNeeds) { need in
                    MapPolyline(MKGeodesicPolyline(
                        coordinates: [origin, need.coordinate],
                        count: 2
                    ))
                    .stroke(
                        LinearGradient(
                            colors: [Theme.Colors.aqua, severityColor(need.severity)],
                            startPoint: .leading, endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 2.4, lineCap: .round, dash: need.state == .fulfilled ? [] : [2, 6])
                    )
                }
            }

            // Crisis hotspots.
            ForEach(relief.visibleNeeds) { need in
                Annotation(need.title, coordinate: need.coordinate) {
                    NeedHotspot(need: need, color: severityColor(need.severity))
                        .onTapGesture { selectedNeed = need }
                }
            }
        }
        .mapStyle(.imagery(elevation: .realistic))
        .colorScheme(.dark)
    }

    // MARK: - Bottom deck (KPI carousel)

    private var bottomDeck: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(kpiCards) { card in KPICardView(card: card) }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(
                LinearGradient(
                    colors: [Theme.Colors.background.opacity(0), Theme.Colors.background],
                    startPoint: .top, endPoint: .bottom
                )
            )
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    LivePulseDot()
                    Text("LIVE CRISIS FEED")
                        .font(Theme.Fonts.sansSerif(size: 10, weight: .semibold))
                        .foregroundColor(Theme.Colors.secondaryText)
                        .tracking(1.0)
                }
                Text("\(relief.visibleNeeds.count) active needs")
                    .font(Theme.Fonts.monospacedDigit(size: 17, weight: .bold))
                    .foregroundColor(Theme.Colors.primaryText)
                Text(updatedLabel)
                    .font(Theme.Fonts.sansSerif(size: 11))
                    .foregroundColor(Theme.Colors.secondaryText)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .glassPanel(accent: Theme.Colors.aqua, cornerRadius: 22)

            Button {
                Task { await relief.refresh() }
            } label: {
                VStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 18, weight: .semibold))
                        .rotationEffect(.degrees(relief.isLoading ? 360 : 0))
                        .animation(relief.isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: relief.isLoading)
                    Text("Refresh")
                        .font(Theme.Fonts.sansSerif(size: 10, weight: .semibold))
                }
                .foregroundColor(Theme.Colors.primaryText)
                .frame(width: 64, height: 78)
                .glassPanel(accent: Theme.Colors.electricBlue, cornerRadius: 22)
            }
            .buttonStyle(.plain)
            .disabled(relief.isLoading)
        }
    }

    @ViewBuilder
    private var loadingOrEmptyOverlay: some View {
        if relief.needs.isEmpty {
            VStack(spacing: 14) {
                if relief.isLoading {
                    ProgressView().tint(Theme.Colors.aqua).scaleEffect(1.4)
                    Text("Pulling live crises from USGS + GDACS…")
                        .font(Theme.Fonts.sansSerif(size: 13))
                        .foregroundColor(Theme.Colors.secondaryText)
                } else if let err = relief.lastError {
                    Image(systemName: "antenna.radiowaves.left.and.right.slash")
                        .font(.system(size: 34))
                        .foregroundColor(Theme.Colors.alertOrange)
                    Text(err)
                        .font(Theme.Fonts.sansSerif(size: 12))
                        .foregroundColor(Theme.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Button("Retry") { Task { await relief.refresh() } }
                        .foregroundColor(Theme.Colors.aqua)
                }
            }
            .padding(26)
            .glassPanel(accent: Theme.Colors.aqua, cornerRadius: 26)
            .padding(.horizontal, 40)
        }
    }

    // MARK: - Helpers

    private var updatedLabel: String {
        guard let updated = relief.lastUpdated else { return "Updating…" }
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return "Updated \(f.localizedString(for: updated, relativeTo: Date()))"
    }

    private var kpiCards: [KPICard] {
        [
            KPICard(id: UUID(), title: "Active Crises", value: "\(relief.activeCrisisCount)", unit: "live worldwide", isHealthy: false),
            KPICard(id: UUID(), title: "Severe Alerts", value: "\(relief.severeCrisisCount)", unit: "red-level", isHealthy: relief.severeCrisisCount == 0),
            KPICard(id: UUID(), title: "Orgs to Contact", value: "\(relief.contactableOrgCount)", unit: "verified relief", isHealthy: relief.contactableOrgCount > 0),
            KPICard(id: UUID(), title: "Needs You Bridged", value: "\(relief.bridgedNeeds.count)", unit: "connections", isHealthy: !relief.bridgedNeeds.isEmpty),
            KPICard(id: UUID(), title: "You've Pledged", value: relief.totalPledgedUSD.compactUSD, unit: "to relief", isHealthy: relief.totalPledgedUSD > 0)
        ]
    }

    private func severityColor(_ s: Severity) -> Color {
        switch s {
        case .red:    return Color(red: 1.0, green: 0.30, blue: 0.33)
        case .orange: return Theme.Colors.alertOrange
        case .green:  return Theme.Colors.efficiencyGreen
        }
    }
}

// MARK: - Hotspot annotation

@available(iOS 17.0, macOS 14.0, *)
struct NeedHotspot: View {
    let need: Need
    let color: Color
    @State private var pulse = false

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.30))
                .frame(width: pulse ? 34 : 16, height: pulse ? 34 : 16)
                .opacity(pulse ? 0.0 : 0.7)
                .animation(.easeOut(duration: 1.4).repeatForever(autoreverses: false), value: pulse)

            if need.isBridged {
                // A fulfilled / bridging need wears its progress ring.
                Circle()
                    .trim(from: 0, to: need.progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .frame(width: 22, height: 22)
                    .rotationEffect(.degrees(-90))
            }

            Image(systemName: need.kind.symbolName)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(Theme.Colors.background)
                .frame(width: 16, height: 16)
                .background(Circle().fill(color))
                .overlay(Circle().stroke(Theme.Colors.background, lineWidth: 1.5))
        }
        .onAppear { pulse = true }
    }
}

// MARK: - Live pulse dot

/// A small green dot that softly breathes — the "we're streaming live" signal.
struct LivePulseDot: View {
    @State private var on = false
    var body: some View {
        Circle()
            .fill(Theme.Colors.efficiencyGreen)
            .frame(width: 7, height: 7)
            .overlay(
                Circle()
                    .stroke(Theme.Colors.efficiencyGreen, lineWidth: 1.5)
                    .scaleEffect(on ? 2.4 : 1.0)
                    .opacity(on ? 0.0 : 0.8)
            )
            .shadow(color: Theme.Colors.efficiencyGreen.opacity(0.7), radius: on ? 4 : 1)
            .animation(.easeOut(duration: 1.6).repeatForever(autoreverses: false), value: on)
            .onAppear { on = true }
    }
}

// MARK: - Severity legend

/// Compact, glassy legend mapping hotspot colors to alert levels + live counts.
@available(iOS 17.0, macOS 14.0, *)
struct SeverityLegend: View {
    @ObservedObject var relief: ReliefService

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            row(Color(red: 1.0, green: 0.30, blue: 0.33), "Severe", relief.globalCount(of: .red))
            row(Theme.Colors.alertOrange, "Significant", relief.globalCount(of: .orange))
            row(Theme.Colors.efficiencyGreen, "Limited", relief.globalCount(of: .green))
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Theme.Colors.background.opacity(0.55))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.Colors.glassStroke.opacity(0.25), lineWidth: 1))
        )
    }

    private func row(_ color: Color, _ label: String, _ count: Int) -> some View {
        HStack(spacing: 7) {
            Circle().fill(color).frame(width: 8, height: 8)
                .shadow(color: color.opacity(0.6), radius: 2)
            Text(label)
                .font(Theme.Fonts.sansSerif(size: 10, weight: .medium))
                .foregroundColor(Theme.Colors.secondaryText)
            Spacer(minLength: 8)
            Text("\(count)")
                .font(Theme.Fonts.monospacedDigit(size: 10, weight: .bold))
                .foregroundColor(color)
        }
    }
}

// MARK: - Need detail sheet (the bridge action lives here)

@available(iOS 17.0, macOS 14.0, *)
struct NeedDetailSheet: View {
    let needID: String
    @EnvironmentObject private var relief: ReliefService
    @Environment(\.dismiss) private var dismiss
    @State private var justBridged = false

    private let pledgeOptions: [Double] = [25, 100, 500]

    var body: some View {
        if let need = relief.need(withID: needID) {
            content(for: need)
        } else {
            Color.clear.onAppear { dismiss() }
        }
    }

    @ViewBuilder
    private func content(for need: Need) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Header
                HStack(spacing: 12) {
                    Image(systemName: need.kind.symbolName)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Theme.Colors.background)
                        .frame(width: 46, height: 46)
                        .background(Circle().fill(severityColor(need.severity)))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(need.kind.label.uppercased())
                            .font(Theme.Fonts.sansSerif(size: 11, weight: .semibold))
                            .foregroundColor(Theme.Colors.secondaryText)
                            .tracking(1.2)
                        Text(need.title)
                            .font(Theme.Fonts.sansSerif(size: 18, weight: .bold))
                            .foregroundColor(Theme.Colors.primaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }

                // Severity + urgency + location pills
                HStack(spacing: 8) {
                    pill(severityColor(need.severity), "\(need.severity.label) alert", "exclamationmark.shield.fill")
                    pill(urgencyColor(need.urgencyScore), "\(need.urgencyLabel) · \(need.urgencyScore)", "gauge.with.dots.needle.67percent")
                    pill(Theme.Colors.secondaryText, need.source, "dot.radiowaves.left.and.right")
                }
                HStack(spacing: 8) {
                    pill(Theme.Colors.electricBlue, need.locationLabel, "mappin.circle.fill")
                    if !need.timeAgo.isEmpty {
                        pill(Theme.Colors.secondaryText, need.timeAgo, "clock.fill")
                    }
                }

                Text(need.summary)
                    .font(Theme.Fonts.sansSerif(size: 14))
                    .foregroundColor(Theme.Colors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                // Verified relief orgs you can contact — surfaced up top.
                orgsContactSection(for: need)

                // Progress ring + numbers
                HStack(spacing: 18) {
                    ZStack {
                        Circle().stroke(Color.white.opacity(0.08), lineWidth: 9).frame(width: 92, height: 92)
                        Circle()
                            .trim(from: 0, to: need.progress)
                            .stroke(severityColor(need.severity), style: StrokeStyle(lineWidth: 9, lineCap: .round))
                            .frame(width: 92, height: 92)
                            .rotationEffect(.degrees(-90))
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: need.progress)
                        Text("\(Int(need.progress * 100))%")
                            .font(Theme.Fonts.monospacedDigit(size: 20, weight: .bold))
                            .foregroundColor(Theme.Colors.primaryText)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text(stateLabel(need.state))
                            .font(Theme.Fonts.sansSerif(size: 13, weight: .semibold))
                            .foregroundColor(severityColor(need.severity))
                        Text("\(need.pledgedUSD.compactUSD) bridged")
                            .font(Theme.Fonts.monospacedDigit(size: 16, weight: .bold))
                            .foregroundColor(Theme.Colors.primaryText)
                        Text("of \(need.goalUSD.compactUSD) goal")
                            .font(Theme.Fonts.sansSerif(size: 12))
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                    Spacer(minLength: 0)
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 16).fill(Theme.Colors.surface))

                // Bridge actions
                if need.state == .fulfilled {
                    Label("Need fully bridged — thank you", systemImage: "checkmark.seal.fill")
                        .font(Theme.Fonts.sansSerif(size: 14, weight: .semibold))
                        .foregroundColor(Theme.Colors.efficiencyGreen)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.Colors.efficiencyGreen.opacity(0.12)))
                } else {
                    Text("Bridge this need")
                        .font(Theme.Fonts.sansSerif(size: 13, weight: .semibold))
                        .foregroundColor(Theme.Colors.secondaryText)
                    HStack(spacing: 10) {
                        ForEach(pledgeOptions, id: \.self) { amount in
                            Button {
                                bridge(need: need, amount: amount, kind: .money)
                            } label: {
                                Text(amount.compactUSD)
                                    .font(Theme.Fonts.sansSerif(size: 15, weight: .bold))
                                    .foregroundColor(Theme.Colors.background)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(RoundedRectangle(cornerRadius: 14).fill(severityColor(need.severity)))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Text("Or bridge in kind")
                        .font(Theme.Fonts.sansSerif(size: 13, weight: .semibold))
                        .foregroundColor(Theme.Colors.secondaryText)
                        .padding(.top, 4)
                    HStack(spacing: 10) {
                        ForEach([ContributionKind.supplies, .volunteerHours, .skill, .blood]) { kind in
                            Button {
                                bridge(need: need, amount: 0, kind: kind)
                            } label: {
                                VStack(spacing: 6) {
                                    Image(systemName: kind.symbolName)
                                        .font(.system(size: 16, weight: .semibold))
                                    Text(kind.label)
                                        .font(Theme.Fonts.sansSerif(size: 9, weight: .semibold))
                                        .lineLimit(1).minimumScaleFactor(0.7)
                                }
                                .foregroundColor(Theme.Colors.primaryText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Theme.Colors.surface)
                                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.Colors.glassStroke.opacity(0.3), lineWidth: 1))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if !need.contributions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your bridges to this need")
                            .font(Theme.Fonts.sansSerif(size: 12, weight: .semibold))
                            .foregroundColor(Theme.Colors.secondaryText)
                        ForEach(need.contributions.reversed()) { c in
                            HStack(spacing: 8) {
                                Image(systemName: c.kind.symbolName)
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.Colors.aqua)
                                Text(c.kind == .money ? "\(c.amountUSD.compactUSD) funded" : "\(c.kind.label) pledged")
                                    .font(Theme.Fonts.sansSerif(size: 13))
                                    .foregroundColor(Theme.Colors.primaryText)
                                Spacer()
                            }
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Theme.Colors.surface.opacity(0.6)))
                }

                if let url = need.sourceURL {
                    Link(destination: url) {
                        Label("View official \(need.source) report", systemImage: "arrow.up.right.square")
                            .font(Theme.Fonts.sansSerif(size: 13, weight: .medium))
                            .foregroundColor(Theme.Colors.aqua)
                    }
                }
            }
            .padding(20)
        }
        .background(Theme.AppBackdrop().ignoresSafeArea())
        .task {
            await relief.fetchOrgsForNeed(need)
        }
    }

    private func bridge(need: Need, amount: Double, kind: ContributionKind) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            relief.bridge(needID: need.id, amountUSD: amount, kind: kind)
            justBridged = true
        }
        #if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }

    // MARK: - Verified relief orgs you can contact

    @ViewBuilder
    private func orgsContactSection(for need: Need) -> some View {
        let orgs = relief.matchedOrgs[need.id] ?? []
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "building.2.crop.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.aqua)
                Text("Relief orgs you can contact")
                    .font(Theme.Fonts.sansSerif(size: 13, weight: .bold))
                    .foregroundColor(Theme.Colors.primaryText)
                Spacer()
                if !orgs.isEmpty {
                    Text("\(orgs.count) verified")
                        .font(Theme.Fonts.monospacedDigit(size: 11, weight: .bold))
                        .foregroundColor(Theme.Colors.aqua)
                }
            }

            if orgs.isEmpty {
                HStack(spacing: 8) {
                    ProgressView().scaleEffect(0.7).tint(Theme.Colors.aqua)
                    Text("Finding verified \(need.kind.label.lowercased()) relief orgs…")
                        .font(Theme.Fonts.sansSerif(size: 12))
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                .padding(.vertical, 4)
            } else {
                ForEach(orgs.prefix(4)) { org in orgRow(org) }
                Text("Verified by Every.org · tap to view, contact or donate")
                    .font(Theme.Fonts.sansSerif(size: 10))
                    .foregroundColor(Theme.Colors.secondaryText.opacity(0.7))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.Colors.aqua.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.Colors.aqua.opacity(0.22), lineWidth: 1))
        )
    }

    @ViewBuilder
    private func orgRow(_ org: ReliefOrg) -> some View {
        let profile = URL(string: org.profileUrl)
        HStack(spacing: 12) {
            // Logo or monogram fallback.
            Group {
                if let logo = org.logoUrl, let url = URL(string: logo) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image.resizable().aspectRatio(contentMode: .fill)
                        } else {
                            monogram(org.name)
                        }
                    }
                } else {
                    monogram(org.name)
                }
            }
            .frame(width: 42, height: 42)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 3) {
                Text(org.name)
                    .font(Theme.Fonts.sansSerif(size: 14, weight: .semibold))
                    .foregroundColor(Theme.Colors.primaryText)
                    .lineLimit(1)
                if let location = org.location, !location.isEmpty {
                    Label(location, systemImage: "mappin.and.ellipse")
                        .font(Theme.Fonts.sansSerif(size: 11))
                        .foregroundColor(Theme.Colors.secondaryText)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 6)

            // Contact / open profile.
            if let profile {
                Link(destination: profile) {
                    Text("Contact")
                        .font(Theme.Fonts.sansSerif(size: 12, weight: .bold))
                        .foregroundColor(Theme.Colors.background)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(Theme.Colors.aqua))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.Colors.surface))
    }

    private func monogram(_ name: String) -> some View {
        Text(String(name.prefix(1)).uppercased())
            .font(Theme.Fonts.serifHero(size: 20, weight: .bold))
            .foregroundColor(Theme.Colors.background)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.Colors.aqua.opacity(0.85))
    }

    private func urgencyColor(_ score: Int) -> Color {
        switch score {
        case 70...:   return Color(red: 1.0, green: 0.30, blue: 0.33)
        case 45..<70: return Theme.Colors.alertOrange
        default:      return Theme.Colors.gold
        }
    }

    private func stateLabel(_ s: NeedState) -> String {
        switch s {
        case .open:      return "OPEN — be the first to bridge"
        case .bridging:  return "BRIDGING — progress underway"
        case .fulfilled: return "FULFILLED"
        }
    }

    private func pill(_ color: Color, _ text: String, _ icon: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 10, weight: .semibold))
            Text(text).font(Theme.Fonts.sansSerif(size: 11, weight: .semibold)).lineLimit(1)
        }
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(color.opacity(0.14)))
    }

    private func severityColor(_ s: Severity) -> Color {
        switch s {
        case .red:    return Color(red: 1.0, green: 0.30, blue: 0.33)
        case .orange: return Theme.Colors.alertOrange
        case .green:  return Theme.Colors.efficiencyGreen
        }
    }
}

// MARK: - Formatting

extension Double {
    /// Compact USD: 25 → "$25", 1500 → "$1.5K", 50000 → "$50K".
    var compactUSD: String {
        let n = self
        if n >= 1_000_000 { return String(format: "$%.1fM", n / 1_000_000) }
        if n >= 1_000 {
            let k = n / 1_000
            return k == k.rounded() ? String(format: "$%.0fK", k) : String(format: "$%.1fK", k)
        }
        return String(format: "$%.0f", n)
    }
}
