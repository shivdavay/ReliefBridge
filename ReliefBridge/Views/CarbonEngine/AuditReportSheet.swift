// ReliefBridge/Views/CarbonEngine/AuditReportSheet.swift

import SwiftUI
import Charts

struct AuditReportSheet: View {

    @Binding var auditReportState: AuditReportState
    let carrier: CargoCarrier
    let reportPoints: [AuditReportPoint]
    let totalCarbonSavedString: String
    let quarterlyTarget: Double
    let annualFleetSavingsString: String
    let verifiedFlightCount: Int

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                switch auditReportState {
                case .idle:
                    idleView
                case .compiling:
                    compilingView
                case .complete:
                    completeView
                }

                Spacer(minLength: 0)
            }
            .padding(.top, 24)
            .padding(.horizontal, 20)
            .background(Theme.AppBackdrop().ignoresSafeArea())
            .navigationTitle("Audit Report")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.Colors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.efficiencyGreen)
                }
            }
        }
    }

    private var idleView: some View {
        VStack(spacing: 14) {
            Image(systemName: "doc.text")
                .font(.system(size: 46))
                .foregroundColor(Theme.Colors.secondaryText)
            Text("Ready to generate report")
                .font(Theme.Fonts.sansSerif(size: 16, weight: .medium))
                .foregroundColor(Theme.Colors.secondaryText)
        }
    }

    private var compilingView: some View {
        VStack(spacing: 18) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(Theme.Colors.efficiencyGreen)
                .scaleEffect(1.4)

            Text("Compiling \(carrier.rawValue) audit report…")
                .font(Theme.Fonts.sansSerif(size: 17, weight: .semibold))
                .foregroundColor(.white)

            Text("Summarizing carbon ledger history into an in-app quarterly filing view.")
                .font(Theme.Fonts.sansSerif(size: 13))
                .foregroundColor(Theme.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private var completeView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(carrier.rawValue) quarterly audit view")
                        .font(Theme.Fonts.sansSerif(size: 12, weight: .semibold))
                        .foregroundColor(Theme.Colors.secondaryText)

                    GlowText(
                        text: totalCarbonSavedString,
                        font: Theme.Fonts.serifHero(size: 32, weight: .bold),
                        glowColor: Theme.Colors.efficiencyGreen
                    )

                    Text("Cumulative carbon saved over time from the verified ledger, presented as an in-app report instead of an export.")
                        .font(Theme.Fonts.sansSerif(size: 13))
                        .foregroundColor(Theme.Colors.secondaryText)
                }

                chartCard

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 145), spacing: 12)], spacing: 12) {
                    metricCard(
                        title: "Quarter Goal",
                        value: String(format: "%.0f t", quarterlyTarget),
                        detail: "Current quarter filing target for the selected carrier.",
                        accent: Theme.Colors.gold
                    )

                    metricCard(
                        title: "Ledger Entries",
                        value: "\(verifiedFlightCount)",
                        detail: "Verified flight-level entries included in this report.",
                        accent: Theme.Colors.aqua
                    )

                    metricCard(
                        title: "1-Year ROI",
                        value: annualFleetSavingsString,
                        detail: "Projected 1-year savings across the current ReliefBridge deployment.",
                        accent: Theme.Colors.efficiencyGreen
                    )
                }
            }
            .padding(.bottom, 20)
        }
    }

    @ViewBuilder
    private var chartCard: some View {
        let upperBound = max(max(reportPoints.last?.cumulativeCarbonSaved ?? 0, quarterlyTarget), 1)

        VStack(alignment: .leading, spacing: 12) {
            Text("Verified carbon saved over time")
                .font(Theme.Fonts.sansSerif(size: 13, weight: .semibold))
                .foregroundColor(Theme.Colors.secondaryText)

            Chart(reportPoints) { point in
                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("Carbon Saved", point.cumulativeCarbonSaved)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Theme.Colors.efficiencyGreen.opacity(0.45),
                            Theme.Colors.aqua.opacity(0.12)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Carbon Saved", point.cumulativeCarbonSaved)
                )
                .foregroundStyle(Theme.Colors.efficiencyGreen)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.catmullRom)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .weekOfYear)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.white.opacity(0.08))
                    AxisValueLabel(format: .dateTime.month(.defaultDigits).day())
                        .foregroundStyle(Theme.Colors.secondaryText)
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.white.opacity(0.08))
                    AxisValueLabel()
                        .foregroundStyle(Theme.Colors.secondaryText)
                }
            }
            .chartYScale(domain: 0...(upperBound * 1.08))
            .frame(height: 250)
        }
        .padding(18)
        .glassPanel(accent: Theme.Colors.efficiencyGreen, cornerRadius: 26)
    }

    private func metricCard(title: String, value: String, detail: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(Theme.Fonts.sansSerif(size: 10, weight: .semibold))
                .foregroundColor(Theme.Colors.secondaryText)
                .tracking(1.0)

            Text(value)
                .font(Theme.Fonts.sansSerif(size: 22, weight: .bold))
                .foregroundColor(Theme.Colors.primaryText)

            Text(detail)
                .font(Theme.Fonts.sansSerif(size: 12))
                .foregroundColor(Theme.Colors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 118, alignment: .leading)
        .padding(16)
        .glassPanel(accent: accent, cornerRadius: 22)
    }
}

#if DEBUG
#Preview("Compiling State") {
    AuditReportSheet(
        auditReportState: .constant(.compiling),
        carrier: .fedex,
        reportPoints: [],
        totalCarbonSavedString: "101.2 t",
        quarterlyTarget: 132,
        annualFleetSavingsString: "$17,664,000",
        verifiedFlightCount: 12
    )
    .aviationDarkMode()
}

#Preview("Complete State") {
    let points = [
        AuditReportPoint(date: .now.addingTimeInterval(-40 * 86_400), cumulativeCarbonSaved: 18),
        AuditReportPoint(date: .now.addingTimeInterval(-32 * 86_400), cumulativeCarbonSaved: 35),
        AuditReportPoint(date: .now.addingTimeInterval(-24 * 86_400), cumulativeCarbonSaved: 54),
        AuditReportPoint(date: .now.addingTimeInterval(-16 * 86_400), cumulativeCarbonSaved: 73),
        AuditReportPoint(date: .now.addingTimeInterval(-8 * 86_400), cumulativeCarbonSaved: 89),
        AuditReportPoint(date: .now, cumulativeCarbonSaved: 103)
    ]

    AuditReportSheet(
        auditReportState: .constant(.complete),
        carrier: .ups,
        reportPoints: points,
        totalCarbonSavedString: "103.0 t",
        quarterlyTarget: 118,
        annualFleetSavingsString: "$13,182,000",
        verifiedFlightCount: 12
    )
    .aviationDarkMode()
}
#endif
