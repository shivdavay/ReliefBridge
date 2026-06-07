// ReliefBridge/Views/Maintenance/MaintenanceView.swift

import SwiftUI

struct MaintenanceView: View {

    @EnvironmentObject private var dataService: SimulatedDataService
    @StateObject private var viewModel: MaintenanceViewModel
    @State private var selectedProblemTailNumber: String? = nil

    init(dataService: SimulatedDataService) {
        _viewModel = StateObject(
            wrappedValue: MaintenanceViewModel(dataService: dataService)
        )
    }

    private var selectedProblemFlight: Aircraft? {
        if let selectedProblemTailNumber {
            return viewModel.problemFlights.first(where: { $0.tailNumber == selectedProblemTailNumber })
        }
        return viewModel.problemFlights.first
    }

    private var selectedFlightAlerts: [MaintenanceAlert] {
        viewModel.alerts(for: selectedProblemFlight?.tailNumber)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.AppBackdrop()
                    .ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 18) {
                        heroCard

                        VStack(alignment: .leading, spacing: 12) {
                            Text("System Overview")
                                .font(Theme.Fonts.sansSerif(size: 13, weight: .semibold))
                                .foregroundColor(Theme.Colors.secondaryText)

                            ForEach(viewModel.overviewItems) { item in
                                SubsystemStatusRow(item: item)
                            }
                        }
                        .padding(18)
                        .glassPanel(accent: Theme.Colors.aqua, cornerRadius: 28)

                        VStack(alignment: .leading, spacing: 14) {
                            Text("Engineering Watchlist")
                                .font(Theme.Fonts.sansSerif(size: 13, weight: .semibold))
                                .foregroundColor(Theme.Colors.secondaryText)

                            if viewModel.problemFlights.isEmpty {
                                emptyStateView
                            } else {
                                watchlistSelector

                                if let selectedProblemFlight {
                                    InfoStatCard(
                                        title: "Selected Flight",
                                        value: selectedProblemFlight.flightIdentifier,
                                        detail: "\(selectedProblemFlight.aircraftType) • \(selectedProblemFlight.routeSummary)",
                                        icon: "airplane",
                                        accent: Theme.Colors.alertOrange,
                                        usesMonospacedValue: false
                                    )

                                    ForEach(selectedFlightAlerts) { alert in
                                        MaintenanceAlertRow(alert: alert)
                                    }
                                }
                            }
                        }
                        .padding(18)
                        .glassPanel(accent: Theme.Colors.alertOrange, cornerRadius: 28)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 16)
                }
            }
            .navigationTitle("Maintenance Readiness")
            #if os(iOS)
            .toolbarBackground(Theme.Colors.backgroundElevated.opacity(0.96), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            #endif
            .onAppear {
                ensureSelectedProblemFlight()
            }
            .onChange(of: viewModel.problemFlights.map(\.tailNumber)) { _, _ in
                ensureSelectedProblemFlight()
            }
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            GlowText(
                text: "Maintenance Readiness",
                font: Theme.Fonts.serifHero(size: 34, weight: .bold),
                glowColor: Theme.Colors.aqua
            )

            Text("\(viewModel.selectedCarrier.rawValue) fleet sensor health at a glance. All fuel and carbon savings shown throughout the app are projected over 1 year.")
                .font(Theme.Fonts.sansSerif(size: 13))
                .foregroundColor(Theme.Colors.secondaryText)

            Text(viewModel.fleetSummary)
                .font(Theme.Fonts.sansSerif(size: 13, weight: .medium))
                .foregroundColor(Theme.Colors.primaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .glassPanel(accent: Theme.Colors.aqua, cornerRadius: 28)
    }

    private var watchlistSelector: some View {
        Menu {
            Picker("Problem Flight", selection: Binding(
                get: { selectedProblemTailNumber ?? viewModel.problemFlights.first?.tailNumber ?? "" },
                set: { selectedProblemTailNumber = $0 }
            )) {
                ForEach(viewModel.problemFlights) { flight in
                    Text("\(flight.flightIdentifier) • \(flight.routeLabel)").tag(flight.tailNumber)
                }
            }
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Problem Flight")
                        .font(Theme.Fonts.sansSerif(size: 10, weight: .semibold))
                        .foregroundColor(Theme.Colors.secondaryText)
                        .tracking(1.0)

                    Text(selectedProblemFlight?.flightIdentifier ?? "Select a flight")
                        .font(Theme.Fonts.sansSerif(size: 18, weight: .semibold))
                        .foregroundColor(Theme.Colors.primaryText)

                    Text(selectedProblemFlight?.routeSummary ?? "Choose a flight to inspect its engineering notes")
                        .font(Theme.Fonts.sansSerif(size: 12))
                        .foregroundColor(Theme.Colors.secondaryText)
                }

                Spacer()

                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            .padding(16)
            .glassPanel(accent: Theme.Colors.gold, cornerRadius: 22)
        }
        .buttonStyle(.plain)
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 40))
                .foregroundColor(Theme.Colors.efficiencyGreen)
            Text("No engineering watch items are open for \(viewModel.selectedCarrier.rawValue) right now")
                .font(Theme.Fonts.sansSerif(size: 14))
                .foregroundColor(Theme.Colors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func ensureSelectedProblemFlight() {
        if let selectedProblemTailNumber,
           viewModel.problemFlights.contains(where: { $0.tailNumber == selectedProblemTailNumber }) {
            return
        }

        selectedProblemTailNumber = viewModel.problemFlights.first?.tailNumber
    }
}

#if DEBUG
#Preview {
    let service = SimulatedDataService()
    MaintenanceView(dataService: service)
        .environmentObject(service)
        .aviationDarkMode()
}
#endif
