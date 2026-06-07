// ReliefBridge/Views/ReliefBridge/RespondView.swift
// ReliefBridge — Respond / triage feed.
//
// Every active crisis (USGS + GDACS), ranked by a real urgency index computed
// from severity, recency, magnitude and reach. Filter, search, and bridge any
// need directly. All data is live.

import SwiftUI

@available(iOS 17.0, macOS 14.0, *)
struct RespondView: View {

    @EnvironmentObject private var relief: ReliefService

    @State private var search = ""
    @State private var severityFilter: Severity? = nil
    @State private var kindFilter: HazardKind? = nil
    @State private var selectedNeed: Need? = nil

    private var results: [Need] {
        relief.needsByUrgency.filter { need in
            if let severityFilter, need.severity != severityFilter { return false }
            if let kindFilter, need.kind != kindFilter { return false }
            if !search.isEmpty {
                let hay = ([need.title, need.locationLabel, need.source] + need.affectedCountries).joined(separator: " ")
                if !hay.localizedCaseInsensitiveContains(search) { return false }
            }
            return true
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 10, pinnedViews: []) {
                    severityBar
                    ForEach(results) { need in
                        Button { selectedNeed = need } label: { needRow(need) }
                            .buttonStyle(.plain)
                    }
                    if results.isEmpty {
                        Text(relief.needs.isEmpty ? "Loading live crises…" : "No crises match your filters")
                            .font(Theme.Fonts.sansSerif(size: 14))
                            .foregroundColor(Theme.Colors.secondaryText)
                            .padding(.top, 40)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 30)
                .padding(.top, 8)
            }
            .background(Theme.AppBackdrop().ignoresSafeArea())
            .navigationTitle("Respond")
            #if os(iOS)
            .toolbarBackground(Theme.Colors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            #endif
            .searchable(text: $search, prompt: "Search crisis, country, source…")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button { kindFilter = nil } label: {
                            Label("All hazards", systemImage: kindFilter == nil ? "checkmark" : "globe")
                        }
                        ForEach(HazardKind.allCases) { kind in
                            Button { kindFilter = kind } label: {
                                Label(kind.label, systemImage: kindFilter == kind ? "checkmark" : kind.symbolName)
                            }
                        }
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                            .foregroundColor(kindFilter == nil ? .white : Theme.Colors.efficiencyGreen)
                    }
                }
            }
            .sheet(item: $selectedNeed) { need in
                NeedDetailSheet(needID: need.id)
                    .environmentObject(relief)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .refreshable { await relief.refresh() }
        }
    }

    // MARK: - Severity filter bar

    private var severityBar: some View {
        HStack(spacing: 8) {
            sevChip(nil, "All \(relief.needs.count)", Theme.Colors.aqua)
            sevChip(.red, "Severe \(relief.globalCount(of: .red))", Color(red: 1.0, green: 0.30, blue: 0.33))
            sevChip(.orange, "Sig. \(relief.globalCount(of: .orange))", Theme.Colors.alertOrange)
            sevChip(.green, "Ltd. \(relief.globalCount(of: .green))", Theme.Colors.efficiencyGreen)
        }
    }

    private func sevChip(_ sev: Severity?, _ label: String, _ color: Color) -> some View {
        let selected = severityFilter == sev
        return Button {
            severityFilter = selected ? nil : sev
        } label: {
            Text(label)
                .font(Theme.Fonts.sansSerif(size: 12, weight: .semibold))
                .foregroundColor(selected ? Theme.Colors.background : color)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Capsule().fill(selected ? color : color.opacity(0.14)))
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Row

    private func needRow(_ need: Need) -> some View {
        HStack(spacing: 12) {
            // Urgency dial
            ZStack {
                Circle().stroke(Color.white.opacity(0.08), lineWidth: 4).frame(width: 46, height: 46)
                Circle()
                    .trim(from: 0, to: Double(need.urgencyScore) / 100)
                    .stroke(severityColor(need.severity), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 46, height: 46)
                    .rotationEffect(.degrees(-90))
                Image(systemName: need.kind.symbolName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(severityColor(need.severity))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(need.title)
                    .font(Theme.Fonts.sansSerif(size: 14, weight: .semibold))
                    .foregroundColor(Theme.Colors.primaryText)
                    .lineLimit(2)
                HStack(spacing: 8) {
                    Text(need.urgencyLabel)
                        .font(Theme.Fonts.sansSerif(size: 11, weight: .bold))
                        .foregroundColor(severityColor(need.severity))
                    Text("·")
                        .foregroundColor(Theme.Colors.secondaryText)
                    Text(need.locationLabel)
                        .font(Theme.Fonts.sansSerif(size: 11))
                        .foregroundColor(Theme.Colors.secondaryText)
                        .lineLimit(1)
                    if !need.timeAgo.isEmpty {
                        Text("· \(need.timeAgo)")
                            .font(Theme.Fonts.sansSerif(size: 11))
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }
                // Verified relief orgs available to contact for this crisis.
                if let orgs = relief.matchedOrgs[need.id], !orgs.isEmpty {
                    Label("\(orgs.count) relief orgs to contact", systemImage: "building.2.crop.circle.fill")
                        .font(Theme.Fonts.sansSerif(size: 10, weight: .semibold))
                        .foregroundColor(Theme.Colors.aqua)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Theme.Colors.aqua.opacity(0.14)))
                }
            }
            Spacer(minLength: 4)
            if need.isBridged {
                Image(systemName: "point.topleft.down.to.point.bottomright.curvepath.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.aqua)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.Colors.surface)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(severityColor(need.severity).opacity(0.18), lineWidth: 1))
        )
    }

    private func severityColor(_ s: Severity) -> Color {
        switch s {
        case .red:    return Color(red: 1.0, green: 0.30, blue: 0.33)
        case .orange: return Theme.Colors.alertOrange
        case .green:  return Theme.Colors.efficiencyGreen
        }
    }
}
