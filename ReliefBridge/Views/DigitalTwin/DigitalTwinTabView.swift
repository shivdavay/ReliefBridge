import SwiftUI

struct DigitalTwinTabView: View {
    let dataService: SimulatedDataService

    @EnvironmentObject private var sharedDataService: SimulatedDataService

    init(dataService: SimulatedDataService) {
        self.dataService = dataService
    }

    private var selectedCarrier: CargoCarrier {
        sharedDataService.selectedCarrier
    }

    private var trackableAircraft: [Aircraft] {
        sharedDataService.aircraft(for: selectedCarrier)
    }

    private var selectedAircraft: Aircraft? {
        sharedDataService.selectedAircraft()
    }

    private var liveSensorFeedCount: Int {
        trackableAircraft.filter(\.isAirborne).count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.AppBackdrop()
                    .ignoresSafeArea()

                if let selectedAircraft {
                    VStack(spacing: 14) {
                        heroCard(for: selectedAircraft)
                        flightDropdown

                        DigitalTwinView(
                            aircraft: selectedAircraft,
                            dataService: dataService
                        )
                        .environmentObject(sharedDataService)
                        .id(selectedAircraft.tailNumber)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 6)
                    .animation(.spring(response: 0.5, dampingFraction: 0.86), value: selectedAircraft.tailNumber)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "waveform.badge.exclamationmark")
                            .font(.system(size: 42))
                            .foregroundStyle(Theme.Gradients.accentGlow)
                        Text("No live sensor feed available")
                            .font(Theme.Fonts.serifHero(size: 26, weight: .semibold))
                            .foregroundStyle(Theme.Gradients.heroText)
                        Text("Select a carrier in Fleet Command to load a flight into the digital twin.")
                            .font(Theme.Fonts.sansSerif(size: 14))
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                    .padding(24)
                    .glassPanel(accent: Theme.Colors.aqua)
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.Colors.backgroundElevated.opacity(0.96), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                ensureSelectedAircraft()
            }
            .onChange(of: selectedCarrier) { _, _ in
                ensureSelectedAircraft()
            }
        }
    }

    private func heroCard(for aircraft: Aircraft) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    GlowText(
                        text: "Digital Twin",
                        font: Theme.Fonts.serifHero(size: 34, weight: .bold),
                        glowColor: Theme.Colors.aqua
                    )

                    Text("\(selectedCarrier.rawValue) flight selection is synced from Fleet Command. Pick any live route below to inspect how the passive retrofit is changing airflow on that aircraft.")
                        .font(Theme.Fonts.sansSerif(size: 13))
                        .foregroundColor(Theme.Colors.secondaryText)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    Text(aircraft.flightIdentifier)
                        .font(Theme.Fonts.monospacedDigit(size: 16, weight: .bold))
                        .foregroundColor(Theme.Colors.primaryText)

                    Text(aircraft.isAirborne ? "LIVE" : "GROUND")
                        .font(Theme.Fonts.sansSerif(size: 10, weight: .bold))
                        .foregroundColor(aircraft.isAirborne ? Theme.Colors.aqua : Theme.Colors.gold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(aircraft.isAirborne ? Theme.Colors.aqua.opacity(0.14) : Theme.Colors.gold.opacity(0.12))
                        )
                }
            }

            HStack(spacing: 12) {
                InfoStatCard(
                    title: "Selected Route",
                    value: aircraft.routeLabel,
                    detail: "\(aircraft.aircraftType) • \(aircraft.routeSummary)",
                    icon: "airplane.departure",
                    accent: Theme.Colors.electricBlue,
                    usesMonospacedValue: false
                )

                InfoStatCard(
                    title: "Sensor Feed",
                    value: aircraft.isAirborne ? "Live" : "Standby",
                    detail: "\(liveSensorFeedCount) \(selectedCarrier.rawValue) flights streaming right now",
                    icon: "waveform.path.ecg",
                    accent: Theme.Colors.aqua,
                    usesMonospacedValue: false
                )
            }
        }
        .padding(18)
        .glassPanel(accent: Theme.Colors.electricBlue, cornerRadius: 28)
    }

    private var flightDropdown: some View {
        Menu {
            Picker("Flight", selection: Binding(
                get: { sharedDataService.selectedAircraftTailNumber ?? trackableAircraft.first?.tailNumber ?? "" },
                set: { newTailNumber in
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                        sharedDataService.selectAircraft(tailNumber: newTailNumber)
                    }
                }
            )) {
                ForEach(trackableAircraft) { aircraft in
                    Text("\(aircraft.flightIdentifier) • \(aircraft.routeLabel)").tag(aircraft.tailNumber)
                }
            }
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Flight Selector")
                        .font(Theme.Fonts.sansSerif(size: 10, weight: .semibold))
                        .foregroundColor(Theme.Colors.secondaryText)
                        .tracking(1.0)

                    Text(selectedAircraft?.flightIdentifier ?? "No flight selected")
                        .font(Theme.Fonts.sansSerif(size: 18, weight: .semibold))
                        .foregroundColor(Theme.Colors.primaryText)

                    Text(selectedAircraft?.routeSummary ?? "Choose a flight from the selected carrier")
                        .font(Theme.Fonts.sansSerif(size: 12))
                        .foregroundColor(Theme.Colors.secondaryText)
                }

                Spacer()

                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            .padding(16)
            .glassPanel(accent: Theme.Colors.aqua, cornerRadius: 24)
        }
        .buttonStyle(.plain)
    }

    private func ensureSelectedAircraft() {
        if let currentTail = sharedDataService.selectedAircraftTailNumber,
           trackableAircraft.contains(where: { $0.tailNumber == currentTail }) {
            return
        }

        if let firstTail = trackableAircraft.first?.tailNumber {
            sharedDataService.selectAircraft(tailNumber: firstTail)
        }
    }
}
