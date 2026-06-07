// ReliefBridge/ViewModels/MaintenanceViewModel.swift

import Foundation
import Combine

struct MaintenanceOverviewItem: Identifiable {
    let id = UUID()
    let title: String
    let summary: String
    let score: Double
}

final class MaintenanceViewModel: ObservableObject {

    @Published private(set) var selectedCarrier: CargoCarrier = .fedex
    @Published private(set) var overviewItems: [MaintenanceOverviewItem] = []
    @Published private(set) var problemFlights: [Aircraft] = []
    @Published private(set) var fleetSummary: String = ""
    @Published private(set) var alertsByFlight: [String: [MaintenanceAlert]] = [:]

    private let dataService: SimulatedDataService
    private var cancellables = Set<AnyCancellable>()

    init(dataService: SimulatedDataService) {
        self.dataService = dataService
        bindToDataService()
    }

    func alerts(for tailNumber: String?) -> [MaintenanceAlert] {
        guard let tailNumber else { return [] }
        return alertsByFlight[tailNumber] ?? []
    }

    private func bindToDataService() {
        Publishers.CombineLatest4(
            dataService.$maintenanceAlerts,
            dataService.$aircraft,
            dataService.$telemetry,
            dataService.$selectedCarrier
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] alerts, aircraft, telemetry, carrier in
            guard let self else { return }

            let carrierAircraft = aircraft.filter { $0.carrier == carrier }
            let carrierAlerts = alerts
                .filter { $0.carrier == carrier }
                .sorted { lhs, rhs in
                    if lhs.severity == rhs.severity {
                        return lhs.generatedAt > rhs.generatedAt
                    }
                    return lhs.severity > rhs.severity
                }

            let groupedAlerts = Dictionary(grouping: carrierAlerts, by: \.tailNumber)
            let flightsWithIssues = carrierAircraft
                .filter { groupedAlerts[$0.tailNumber] != nil }
                .sorted { lhs, rhs in
                    let lhsSeverity = groupedAlerts[lhs.tailNumber]?.first?.severity.rawValue ?? 0
                    let rhsSeverity = groupedAlerts[rhs.tailNumber]?.first?.severity.rawValue ?? 0
                    if lhsSeverity == rhsSeverity {
                        return lhs.flightIdentifier < rhs.flightIdentifier
                    }
                    return lhsSeverity > rhsSeverity
                }

            self.selectedCarrier = carrier
            self.alertsByFlight = groupedAlerts
            self.problemFlights = flightsWithIssues
            self.overviewItems = Self.buildOverviewItems(
                aircraft: carrierAircraft,
                telemetry: telemetry,
                alerts: carrierAlerts
            )
            self.fleetSummary = Self.buildFleetSummary(
                carrier: carrier,
                aircraft: carrierAircraft,
                alerts: carrierAlerts
            )
        }
        .store(in: &cancellables)
    }

    private static func buildOverviewItems(
        aircraft: [Aircraft],
        telemetry: [String: TelemetrySnapshot],
        alerts: [MaintenanceAlert]
    ) -> [MaintenanceOverviewItem] {
        let liveSnapshots = aircraft.compactMap { telemetry[$0.tailNumber] }
        let coverageScore = aircraft.isEmpty ? 0.0 : Double(liveSnapshots.count) / Double(aircraft.count)
        let averagePressureSpread = liveSnapshots.isEmpty
            ? 12.0
            : liveSnapshots.reduce(0.0) { $0 + abs($1.ramAirIntakePressure - 1_008.0) } / Double(liveSnapshots.count)
        let pressureScore = clamp(1.0 - (averagePressureSpread / 70.0), min: 0.62, max: 0.98)

        let averageUniformity = liveSnapshots.isEmpty
            ? 0.84
            : liveSnapshots.reduce(0.0) { $0 + $1.gyroidFlowUniformity } / Double(liveSnapshots.count)
        let uniformityScore = clamp(averageUniformity, min: 0.60, max: 0.98)

        let averageRetention = liveSnapshots.isEmpty
            ? 0.84
            : liveSnapshots.reduce(0.0) { $0 + $1.boundaryLayerRetention } / Double(liveSnapshots.count)
        let retentionScore = clamp(averageRetention, min: 0.60, max: 0.98)

        let criticalPenalty = Double(alerts.filter { $0.severity == .critical }.count) * 0.05
        let controllerScore = clamp(0.91 - criticalPenalty, min: 0.58, max: 0.96)

        return [
            MaintenanceOverviewItem(
                title: "Sensor coverage",
                summary: "\(liveSnapshots.count) of \(aircraft.count) flights are publishing live retrofit sensor data across the selected fleet.",
                score: coverageScore
            ),
            MaintenanceOverviewItem(
                title: "Pressure stability",
                summary: pressureScore >= 0.82
                    ? "Pressure arrays are staying inside the normal operating band for most flights."
                    : "A small number of flights are showing wider intake pressure spread than the fleet baseline.",
                score: pressureScore
            ),
            MaintenanceOverviewItem(
                title: "Flow uniformity",
                summary: uniformityScore >= 0.82
                    ? "Surface flow remains evenly distributed across the active retrofit panels."
                    : "Flow balance is softening on a few aircraft and should be checked against the next route cycle.",
                score: uniformityScore
            ),
            MaintenanceOverviewItem(
                title: "Boundary-layer retention",
                summary: retentionScore >= 0.84
                    ? "Attached airflow is holding steadily through the current fleet-wide route mix."
                    : "Retention is dropping on a handful of flights, which can indicate panel contamination or sensor drift.",
                score: retentionScore
            ),
            MaintenanceOverviewItem(
                title: "Controller confidence",
                summary: controllerScore >= 0.80
                    ? "Control electronics look stable across the selected fleet and no software event is blocking operations."
                    : "Open alerts suggest the next engineering review should focus on one or two flights before the next long-haul cycle.",
                score: controllerScore
            )
        ]
    }

    private static func buildFleetSummary(
        carrier: CargoCarrier,
        aircraft: [Aircraft],
        alerts: [MaintenanceAlert]
    ) -> String {
        let criticalCount = alerts.filter { $0.severity == .critical }.count
        let warningCount = alerts.filter { $0.severity == .warning }.count
        let activeFlights = aircraft.filter(\.isAirborne).count

        return "\(carrier.rawValue) has \(activeFlights) live flights in scope, \(criticalCount) immediate engineering checks, and \(warningCount) route-specific items to clear before the next full cycle."
    }

    private static func clamp(_ value: Double, min minValue: Double, max maxValue: Double) -> Double {
        Swift.max(minValue, Swift.min(maxValue, value))
    }
}
