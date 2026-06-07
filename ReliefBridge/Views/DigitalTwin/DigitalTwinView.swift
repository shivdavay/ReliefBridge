// ReliefBridge/Views/DigitalTwin/DigitalTwinView.swift

import SwiftUI

struct DigitalTwinView: View {

    let aircraft: Aircraft

    @EnvironmentObject private var dataService: SimulatedDataService
    @StateObject private var viewModel: DigitalTwinViewModel

    init(aircraft: Aircraft, dataService: SimulatedDataService) {
        self.aircraft = aircraft
        _viewModel = StateObject(
            wrappedValue: DigitalTwinViewModel(tailNumber: aircraft.tailNumber, dataService: dataService)
        )
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    scenePanel(height: geometry.size.height * 0.4)
                    engagementBadge
                    gaugeRow
                    impactSummary
                    sensorGuide
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 8)
            }
        }
        .navigationTitle(aircraft.flightIdentifier)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.Colors.backgroundElevated.opacity(0.96), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        #endif
        .background(Color.clear)
    }

    private func scenePanel(height: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            AircraftSceneView(aircraft: aircraft, isReliefBridgeEngaged: viewModel.isReliefBridgeEngaged)
                .frame(height: height)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

            LinearGradient(
                colors: [
                    Theme.Colors.background.opacity(0.84),
                    Theme.Colors.background.opacity(0.16),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text("Passive Retrofit Airflow View")
                    .font(Theme.Fonts.sansSerif(size: 12, weight: .semibold))
                    .foregroundColor(Theme.Colors.secondaryText)

                GlowText(
                    text: aircraft.flightIdentifier,
                    font: Theme.Fonts.serifHero(size: 24, weight: .semibold),
                    glowColor: Theme.Colors.aqua
                )

                Text("\(aircraft.aircraftType) • \(aircraft.routeSummary)")
                    .font(Theme.Fonts.sansSerif(size: 12))
                    .foregroundColor(Theme.Colors.primaryText)

                Text(viewModel.noTelemetryAvailable ? "Awaiting sensor feed for this aircraft" : "Live airflow signature compared with the aircraft baseline for the current route")
                    .font(Theme.Fonts.sansSerif(size: 12))
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            .padding(18)
        }
        .glassPanel(accent: Theme.Colors.electricBlue, cornerRadius: 28)
    }

    private var engagementBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(viewModel.isReliefBridgeEngaged ? Theme.Colors.efficiencyGreen : Theme.Colors.secondaryText)
                .frame(width: 8, height: 8)

            Text(viewModel.isReliefBridgeEngaged ? "ReliefBridge passive retrofit engaged" : "Retrofit disengaged")
                .font(Theme.Fonts.sansSerif(size: 12, weight: .medium))
                .foregroundColor(viewModel.isReliefBridgeEngaged ? Theme.Colors.efficiencyGreen : Theme.Colors.secondaryText)

            Spacer(minLength: 12)

            Text(viewModel.noTelemetryAvailable ? "offline" : aircraft.routeLabel)
                .font(Theme.Fonts.monospacedDigit(size: 11, weight: .semibold))
                .foregroundColor(viewModel.noTelemetryAvailable ? Theme.Colors.gold : Theme.Colors.aqua)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .glassPanel(accent: viewModel.noTelemetryAvailable ? Theme.Colors.gold : Theme.Colors.aqua, cornerRadius: 999)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var gaugeRow: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 145), spacing: 12)], spacing: 12) {
            TelemetryGaugeView(
                title: "Intake Pressure",
                value: viewModel.ramAirIntakePressure,
                unit: "hPa",
                minValue: 950,
                maxValue: 1_060,
                gaugeColor: viewModel.ramAirPressureColor
            )

            TelemetryGaugeView(
                title: "Flow Uniformity",
                value: viewModel.gyroidFlowUniformity * 100.0,
                unit: "%",
                minValue: 0.0,
                maxValue: 100.0,
                gaugeColor: viewModel.gyroidFlowColor
            )

            TelemetryGaugeView(
                title: "Flow Exit Velocity",
                value: viewModel.jetSheetVelocity,
                unit: "m/s",
                minValue: 200,
                maxValue: 320,
                gaugeColor: viewModel.jetSheetVelocityColor
            )
        }
    }

    private var impactSummary: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
            InfoStatCard(
                title: "Boundary Layer",
                value: String(format: "%.1f%%", viewModel.boundaryLayerRetention * 100.0),
                detail: "Retained surface airflow with the passive retrofit active on this route.",
                icon: "wind",
                accent: Theme.Colors.aqua
            )

            InfoStatCard(
                title: "Drag Reduction",
                value: String(format: "%.1f%%", viewModel.dragReductionPercent * 100.0),
                detail: "Current reduction versus the aircraft’s untreated baseline for this lane.",
                icon: "arrow.down.forward.and.arrow.up.backward",
                accent: Theme.Colors.electricBlue
            )

            InfoStatCard(
                title: "Fuel Saved In 1 Year",
                value: String(format: "%.0f kg", viewModel.projectedAnnualFuelGainKg),
                detail: "Projected annual fuel saved for this specific retrofit kit if the current route profile holds.",
                icon: "drop.fill",
                accent: Theme.Colors.efficiencyGreen,
                usesMonospacedValue: false
            )
        }
    }

    private var sensorGuide: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("How ReliefBridge is changing the airflow")
                .font(Theme.Fonts.sansSerif(size: 13, weight: .semibold))
                .foregroundColor(Theme.Colors.secondaryText)

            sensorGuideRow(
                title: "Intake Pressure",
                detail: "Tracks how cleanly the aircraft is feeding air into the passive surface channels as flight conditions change."
            )
            sensorGuideRow(
                title: "Flow Uniformity",
                detail: "Shows whether the retrofit is keeping airflow evenly distributed across the treated surface."
            )
            sensorGuideRow(
                title: "Boundary Layer",
                detail: "Higher retention means attached airflow is staying on the surface longer, which supports lower drag on this route."
            )
        }
        .padding(18)
        .glassPanel(accent: Theme.Colors.aqua, cornerRadius: 24)
    }

    @ViewBuilder
    private func sensorGuideRow(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(Theme.Fonts.sansSerif(size: 12, weight: .semibold))
                .foregroundColor(Theme.Colors.primaryText)

            Text(detail)
                .font(Theme.Fonts.sansSerif(size: 12))
                .foregroundColor(Theme.Colors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Theme.Colors.surface.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Theme.Colors.glassStroke.opacity(0.18), lineWidth: 1)
                )
        )
    }
}

#if DEBUG
#Preview {
    let service = SimulatedDataService()
    NavigationStack {
        if let aircraft = service.aircraft.first {
            DigitalTwinView(aircraft: aircraft, dataService: service)
                .environmentObject(service)
        }
    }
    .aviationDarkMode()
}
#endif
