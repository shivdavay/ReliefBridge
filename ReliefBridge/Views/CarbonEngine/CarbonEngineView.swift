// ReliefBridge/Views/CarbonEngine/CarbonEngineView.swift

import SwiftUI

struct CarbonEngineView: View {

    @EnvironmentObject private var dataService: SimulatedDataService
    @StateObject private var viewModel: CarbonEngineViewModel
    @State private var showAuditReportSheet: Bool = false

    init(dataService: SimulatedDataService) {
        _viewModel = StateObject(
            wrappedValue: CarbonEngineViewModel(dataService: dataService)
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.AppBackdrop()
                    .ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 18) {
                        heroCard

                        QuotaProgressRingView(
                            progressFraction: viewModel.progressFraction,
                            ringColor: viewModel.ringColor,
                            headline: viewModel.totalCarbonSavedString,
                            supportingText: viewModel.quotaRemainingString
                        )
                        .frame(height: 260)

                        HStack(spacing: 12) {
                            InfoStatCard(
                                title: "Quarter Goal",
                                value: String(format: "%.0f t", viewModel.quarterlyTarget),
                                detail: viewModel.annualGoalString,
                                icon: "scope",
                                accent: Theme.Colors.gold,
                                usesMonospacedValue: false
                            )

                            InfoStatCard(
                                title: "Verified Flights",
                                value: "\(viewModel.verifiedFlightCount)",
                                detail: String(format: "%.1f t average carbon saved per verified flight", viewModel.averageCarbonPerFlight),
                                icon: "checkmark.seal.fill",
                                accent: Theme.Colors.efficiencyGreen,
                                usesMonospacedValue: false
                            )
                        }

                        roiSection

                        Button {
                            viewModel.generateAuditReport()
                            showAuditReportSheet = true
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: viewModel.auditReportState == .compiling ? "hourglass" : "chart.xyaxis.line")
                                    .font(.system(size: 16, weight: .semibold))
                                Text(viewModel.auditReportState == .compiling ? "Preparing Audit Report" : "Generate Audit Report")
                                    .font(Theme.Fonts.sansSerif(size: 16, weight: .semibold))
                            }
                            .foregroundColor(Theme.Colors.background)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(Theme.Gradients.accentGlow)
                            )
                            .shadow(color: Theme.Colors.aqua.opacity(0.25), radius: 16, x: 0, y: 8)
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.auditReportState == .compiling)
                        .opacity(viewModel.auditReportState == .compiling ? 0.78 : 1.0)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Carbon Ledger")
                                .font(Theme.Fonts.sansSerif(size: 13, weight: .semibold))
                                .foregroundColor(Theme.Colors.secondaryText)

                            if viewModel.ledgerBlocks.isEmpty {
                                emptyStateView
                            } else {
                                ForEach(viewModel.ledgerBlocks) { block in
                                    LedgerBlockRow(block: block)
                                }
                            }
                        }
                        .padding(18)
                        .glassPanel(accent: Theme.Colors.efficiencyGreen, cornerRadius: 28)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 16)
                }
            }
            .navigationTitle("Carbon Compliance")
            #if os(iOS)
            .toolbarBackground(Theme.Colors.backgroundElevated.opacity(0.96), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            #endif
            .sheet(isPresented: $showAuditReportSheet, onDismiss: {
                viewModel.resetAuditReport()
            }) {
                AuditReportSheet(
                    auditReportState: $viewModel.auditReportState,
                    carrier: viewModel.selectedCarrier,
                    reportPoints: viewModel.auditReportPoints,
                    totalCarbonSavedString: viewModel.totalCarbonSavedString,
                    quarterlyTarget: viewModel.quarterlyTarget,
                    annualFleetSavingsString: viewModel.annualFleetSavingsString,
                    verifiedFlightCount: viewModel.verifiedFlightCount
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            GlowText(
                text: "Carbon Compliance",
                font: Theme.Fonts.serifHero(size: 34, weight: .bold),
                glowColor: Theme.Colors.efficiencyGreen
            )

            Text("\(viewModel.selectedCarrier.rawValue) carbon saved is shown as a 1-year ReliefBridge projection, tracked against the current quarter’s filing target.")
                .font(Theme.Fonts.sansSerif(size: 13))
                .foregroundColor(Theme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .glassPanel(accent: Theme.Colors.efficiencyGreen, cornerRadius: 28)
    }

    private var roiSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("1-Year ROI")
                .font(Theme.Fonts.sansSerif(size: 13, weight: .semibold))
                .foregroundColor(Theme.Colors.secondaryText)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                InfoStatCard(
                    title: "Per Retrofit Kit",
                    value: viewModel.annualSavingsPerKitString,
                    detail: String(format: "%.0f t carbon saved and projected over 1 year per installed kit", viewModel.annualCarbonSavedPerKitTons),
                    icon: "dollarsign.circle.fill",
                    accent: Theme.Colors.gold,
                    usesMonospacedValue: false
                )

                InfoStatCard(
                    title: "Fleet-Wide In 1 Year",
                    value: viewModel.annualFleetSavingsString,
                    detail: "\(viewModel.retrofittedAircraftCount) ReliefBridge-equipped aircraft currently in the selected company deployment.",
                    icon: "building.2.crop.circle.fill",
                    accent: Theme.Colors.aqua,
                    usesMonospacedValue: false
                )

                InfoStatCard(
                    title: "Fuel Saved In 1 Year",
                    value: viewModel.annualFuelSavedFleetString,
                    detail: "Projected 1-year fuel saved across every aircraft in the selected ReliefBridge fleet scope.",
                    icon: "drop.triangle.fill",
                    accent: Theme.Colors.efficiencyGreen,
                    usesMonospacedValue: false
                )
            }
        }
        .padding(18)
        .glassPanel(accent: Theme.Colors.aqua, cornerRadius: 28)
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(Theme.Colors.secondaryText)
            Text("No ledger blocks available")
                .font(Theme.Fonts.sansSerif(size: 14))
                .foregroundColor(Theme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

#if DEBUG
#Preview {
    let service = SimulatedDataService()
    CarbonEngineView(dataService: service)
        .environmentObject(service)
        .aviationDarkMode()
}
#endif
