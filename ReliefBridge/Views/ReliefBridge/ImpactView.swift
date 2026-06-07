// ReliefBridge/Views/ReliefBridge/ImpactView.swift
// ReliefBridge — Impact dashboard.
//
// Everything here is real: your own pledges (stored on device) measured against
// live crises pulled from USGS + GDACS. No invented numbers.

import SwiftUI
import Charts

@available(iOS 17.0, macOS 14.0, *)
struct ImpactView: View {

    @EnvironmentObject private var relief: ReliefService

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    statGrid
                    yourBridgesChart
                    globalPulse
                    activityFeed
                }
                .padding(20)
                .padding(.bottom, 30)
            }
            .background(Theme.AppBackdrop().ignoresSafeArea())
            .navigationTitle("Your Impact")
            #if os(iOS)
            .toolbarBackground(Theme.Colors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            #endif
        }
    }

    // MARK: - Stat grid

    private var statGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            statTile("Bridges Built", "\(relief.bridgedNeeds.count)", "point.topleft.down.to.point.bottomright.curvepath.fill", Theme.Colors.aqua)
            statTile("Funds Pledged", relief.totalPledgedUSD.compactUSD, "dollarsign.circle.fill", Theme.Colors.efficiencyGreen)
            statTile("Needs Fulfilled", "\(relief.fulfilledCount)", "checkmark.seal.fill", Theme.Colors.gold)
            statTile("Regions Reached", "\(relief.regionsReached.count)", "globe.americas.fill", Theme.Colors.electricBlue)
        }
    }

    private func statTile(_ title: String, _ value: String, _ icon: String, _ accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(accent)
                Spacer()
            }
            Text(value)
                .font(Theme.Fonts.monospacedDigit(size: 30, weight: .bold))
                .foregroundColor(Theme.Colors.primaryText)
                .minimumScaleFactor(0.6).lineLimit(1)
            Text(title)
                .font(Theme.Fonts.sansSerif(size: 12, weight: .medium))
                .foregroundColor(Theme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassPanel(accent: accent, cornerRadius: 20)
    }

    // MARK: - Your bridges chart

    @ViewBuilder
    private var yourBridgesChart: some View {
        if relief.bridgedNeeds.isEmpty {
            VStack(spacing: 10) {
                Image(systemName: "hand.point.up.left.fill")
                    .font(.system(size: 30))
                    .foregroundColor(Theme.Colors.aqua)
                Text("You haven't bridged a need yet")
                    .font(Theme.Fonts.sansSerif(size: 15, weight: .semibold))
                    .foregroundColor(Theme.Colors.primaryText)
                Text("Open the Bridge globe and tap a glowing crisis to build your first bridge. Your impact will appear here.")
                    .font(Theme.Fonts.sansSerif(size: 13))
                    .foregroundColor(Theme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(22)
            .glassPanel(accent: Theme.Colors.aqua, cornerRadius: 20)
        } else {
            sectionCard("Your bridges by hazard", icon: "chart.bar.fill") {
                Chart(relief.bridgedByKind, id: \.kind.id) { item in
                    BarMark(
                        x: .value("Count", item.count),
                        y: .value("Hazard", item.kind.label)
                    )
                    .foregroundStyle(Theme.Colors.aqua.gradient)
                    .annotation(position: .trailing) {
                        Text("\(item.count)")
                            .font(Theme.Fonts.monospacedDigit(size: 11, weight: .bold))
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }
                .chartXAxis { AxisMarks(values: .automatic(desiredCount: 3)) }
                .frame(height: max(80, CGFloat(relief.bridgedByKind.count) * 36))
            }
        }
    }

    // MARK: - Global live pulse

    private var globalPulse: some View {
        sectionCard("Live global pulse", icon: "dot.radiowaves.left.and.right") {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    severityChip("Severe", relief.globalCount(of: .red), Color(red: 1.0, green: 0.30, blue: 0.33))
                    severityChip("Significant", relief.globalCount(of: .orange), Theme.Colors.alertOrange)
                    severityChip("Limited", relief.globalCount(of: .green), Theme.Colors.efficiencyGreen)
                }
                if !relief.globalByKind.isEmpty {
                    Chart(relief.globalByKind, id: \.kind.id) { item in
                        BarMark(
                            x: .value("Hazard", item.kind.label),
                            y: .value("Active", item.count)
                        )
                        .foregroundStyle(Theme.Colors.electricBlue.gradient)
                    }
                    .chartYAxis { AxisMarks(values: .automatic(desiredCount: 3)) }
                    .frame(height: 150)
                }
                Text("\(relief.activeCrisisCount) active crises tracked live via USGS + GDACS")
                    .font(Theme.Fonts.sansSerif(size: 11))
                    .foregroundColor(Theme.Colors.secondaryText)
            }
        }
    }

    private func severityChip(_ label: String, _ count: Int, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(Theme.Fonts.monospacedDigit(size: 22, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(Theme.Fonts.sansSerif(size: 10, weight: .medium))
                .foregroundColor(Theme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 14).fill(color.opacity(0.12)))
    }

    // MARK: - Activity feed

    @ViewBuilder
    private var activityFeed: some View {
        if !relief.allContributions.isEmpty {
            sectionCard("Your bridge activity", icon: "list.bullet.rectangle.fill") {
                VStack(spacing: 0) {
                    ForEach(relief.allContributions) { c in
                        let need = relief.need(withID: c.needID)
                        HStack(spacing: 12) {
                            Image(systemName: c.kind.symbolName)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Theme.Colors.aqua)
                                .frame(width: 30, height: 30)
                                .background(Circle().fill(Theme.Colors.aqua.opacity(0.14)))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(c.kind == .money ? "Funded \(c.amountUSD.compactUSD)" : "\(c.kind.actionVerb) a need")
                                    .font(Theme.Fonts.sansSerif(size: 14, weight: .semibold))
                                    .foregroundColor(Theme.Colors.primaryText)
                                Text(need?.title ?? "Crisis")
                                    .font(Theme.Fonts.sansSerif(size: 12))
                                    .foregroundColor(Theme.Colors.secondaryText)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Text(relativeTime(c.createdAt))
                                .font(Theme.Fonts.sansSerif(size: 11))
                                .foregroundColor(Theme.Colors.secondaryText)
                        }
                        .padding(.vertical, 10)
                        if c.id != relief.allContributions.last?.id {
                            Divider().overlay(Color.white.opacity(0.06))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func sectionCard<Content: View>(_ title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.Colors.aqua)
                Text(title)
                    .font(Theme.Fonts.sansSerif(size: 15, weight: .bold))
                    .foregroundColor(Theme.Colors.primaryText)
            }
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .glassPanel(accent: Theme.Colors.electricBlue, cornerRadius: 20)
    }

    private func relativeTime(_ date: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f.localizedString(for: date, relativeTo: Date())
    }
}
