// ReliefBridge/Services/SimulatedDataService.swift
// Central simulated data engine — single source of truth for all modules.

import Foundation
import CoreLocation
import Combine

final class SimulatedDataService: ObservableObject {

    // MARK: - Published Properties

    @Published var aircraft: [Aircraft] = []
    @Published var telemetry: [String: TelemetrySnapshot] = [:]
    @Published var ledgerBlocks: [LedgerBlock] = []
    @Published var financialMonths: [FinancialMonth] = []
    @Published var maintenanceAlerts: [MaintenanceAlert] = []
    @Published var latticeZones: [LatticeZone] = []
    @Published var selectedCarrier: CargoCarrier = .fedex {
        didSet {
            ensureSelectedAircraftBelongsToCarrier()
        }
    }
    @Published var selectedAircraftTailNumber: String? = nil {
        didSet {
            syncCarrierToSelectedAircraft()
        }
    }
    @Published var isInitialized: Bool = false
    @Published var initializationError: String? = nil

    // MARK: - Private State

    private var timer: Timer?
    private var tickCount: Int = 0
    private let carrierProfiles: [CargoCarrier: CarrierProfile] = [
        .fedex: CarrierProfile(
            carrier: .fedex,
            retrofittedAircraftCount: 96,
            annualFuelSavedPerKitKg: Double.random(in: 8_333...9_375),
            annualCarbonSavedPerKitTons: 27.7,
            annualSavingsPerKitUSD: 11_025,
            quarterlyCarbonTargetTons: 132,
            annualCarbonGoalTons: 528,
            dailyFlightsInScope: 152,
            networkHeadline: "Representative ReliefBridge deployment across Memphis, Paris, Cologne, Anchorage, and Asia gateways."
        ),
        .ups: CarrierProfile(
            carrier: .ups,
            retrofittedAircraftCount: 78,
            annualFuelSavedPerKitKg: Double.random(in: 10_256...11_538),
            annualCarbonSavedPerKitTons: 34.4,
            annualSavingsPerKitUSD: 13_735,
            quarterlyCarbonTargetTons: 118,
            annualCarbonGoalTons: 472,
            dailyFlightsInScope: 116,
            networkHeadline: "Representative Louisville-led cargo network spanning Cologne, Anchorage, Honolulu, and Sydney."
        ),
        .dhl: CarrierProfile(
            carrier: .dhl,
            retrofittedAircraftCount: 52,
            annualFuelSavedPerKitKg: Double.random(in: 15_385...17_308),
            annualCarbonSavedPerKitTons: 51.7,
            annualSavingsPerKitUSD: 20_600,
            quarterlyCarbonTargetTons: 84,
            annualCarbonGoalTons: 336,
            dailyFlightsInScope: 89,
            networkHeadline: "Representative superhub coverage across Leipzig, Cincinnati, Hong Kong, New York, and Bahrain."
        )
    ]

    // MARK: - Init

    init() {
        do {
            try seedData()
            isInitialized = true
        } catch {
            isInitialized = false
            initializationError = "Initialization failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Public Helpers

    func aircraft(for carrier: CargoCarrier) -> [Aircraft] {
        aircraft
            .filter { $0.carrier == carrier }
            .sorted { lhs, rhs in
                if lhs.isAirborne != rhs.isAirborne {
                    return lhs.isAirborne && !rhs.isAirborne
                }
                return lhs.flightIdentifier < rhs.flightIdentifier
            }
    }

    func aircraft(forTailNumber tailNumber: String) -> Aircraft? {
        aircraft.first(where: { $0.tailNumber == tailNumber })
    }

    func ledgerBlocks(for carrier: CargoCarrier) -> [LedgerBlock] {
        ledgerBlocks
            .filter { $0.carrier == carrier }
            .sorted { $0.timestamp > $1.timestamp }
    }

    func maintenanceAlerts(for carrier: CargoCarrier) -> [MaintenanceAlert] {
        maintenanceAlerts
            .filter { $0.carrier == carrier }
            .sorted { lhs, rhs in
                if lhs.severity == rhs.severity {
                    return lhs.generatedAt > rhs.generatedAt
                }
                return lhs.severity > rhs.severity
            }
    }

    func profile(for carrier: CargoCarrier) -> CarrierProfile {
        carrierProfiles[carrier] ?? CarrierProfile(
            carrier: carrier,
            retrofittedAircraftCount: 0,
            annualFuelSavedPerKitKg: 0,
            annualCarbonSavedPerKitTons: 0,
            annualSavingsPerKitUSD: 0,
            quarterlyCarbonTargetTons: 0,
            annualCarbonGoalTons: 0,
            dailyFlightsInScope: 0,
            networkHeadline: ""
        )
    }

    func selectedAircraft(in carrier: CargoCarrier? = nil) -> Aircraft? {
        let activeCarrier = carrier ?? selectedCarrier
        let carrierAircraft = aircraft(for: activeCarrier)

        if let selectedAircraftTailNumber,
           let selected = carrierAircraft.first(where: { $0.tailNumber == selectedAircraftTailNumber }) {
            return selected
        }

        return carrierAircraft.first
    }

    func selectCarrier(_ carrier: CargoCarrier) {
        guard selectedCarrier != carrier else {
            ensureSelectedAircraftBelongsToCarrier()
            return
        }
        selectedCarrier = carrier
    }

    func selectAircraft(tailNumber: String) {
        guard aircraft.contains(where: { $0.tailNumber == tailNumber }) else { return }
        selectedAircraftTailNumber = tailNumber
    }

    // MARK: - Seeding

    private func seedData() throws {
        seedAircraft()
        seedTelemetry()
        seedLedgerBlocks()
        seedFinancialMonths()
        seedMaintenanceAlerts()
        seedLatticeZones()
        ensureSelectedAircraftBelongsToCarrier()
        startTimer()
    }

    private func seedAircraft() {
        let records: [FlightSeed] = [
            FlightSeed(
                carrier: .fedex,
                flightIdentifier: "FX4",
                tailNumber: "N885FD",
                aircraftType: "Boeing 777F",
                region: "North Atlantic",
                originCode: "MEM",
                originCity: "Memphis",
                originCoordinate: .init(latitude: 35.0425, longitude: -89.9767),
                destinationCode: "CGN",
                destinationCity: "Cologne",
                destinationCoordinate: .init(latitude: 50.8659, longitude: 7.1427),
                scheduledDurationHours: 8.4,
                routeDistanceKm: 7_180,
                routeProgress: 0.62,
                healthScore: 95.1,
                annualFuelSavedKg: 145_000,
                annualCarbonSavedTons: 458.0
            ),
            FlightSeed(
                carrier: .fedex,
                flightIdentifier: "FX38",
                tailNumber: "N852FD",
                aircraftType: "Boeing 777F",
                region: "North Atlantic",
                originCode: "MEM",
                originCity: "Memphis",
                originCoordinate: .init(latitude: 35.0425, longitude: -89.9767),
                destinationCode: "CDG",
                destinationCity: "Paris",
                destinationCoordinate: .init(latitude: 49.0097, longitude: 2.5479),
                scheduledDurationHours: 8.2,
                routeDistanceKm: 7_326,
                routeProgress: 0.38,
                healthScore: 93.8,
                annualFuelSavedKg: 138_000,
                annualCarbonSavedTons: 436.0
            ),
            FlightSeed(
                carrier: .fedex,
                flightIdentifier: "FX40",
                tailNumber: "N124FE",
                aircraftType: "Boeing 767-300F",
                region: "Latin America",
                originCode: "MEM",
                originCity: "Memphis",
                originCoordinate: .init(latitude: 35.0425, longitude: -89.9767),
                destinationCode: "VCP",
                destinationCity: "Campinas",
                destinationCoordinate: .init(latitude: -23.0074, longitude: -47.1345),
                scheduledDurationHours: 9.1,
                routeDistanceKm: 7_740,
                routeProgress: 0.74,
                healthScore: 91.7,
                annualFuelSavedKg: 132_000,
                annualCarbonSavedTons: 417.0
            ),
            FlightSeed(
                carrier: .fedex,
                flightIdentifier: "FX23",
                tailNumber: "N873FD",
                aircraftType: "Boeing 777F",
                region: "Transpacific",
                originCode: "ANC",
                originCity: "Anchorage",
                originCoordinate: .init(latitude: 61.1743, longitude: -149.9962),
                destinationCode: "HKG",
                destinationCity: "Hong Kong",
                destinationCoordinate: .init(latitude: 22.3080, longitude: 113.9185),
                scheduledDurationHours: 8.9,
                routeDistanceKm: 7_200,
                routeProgress: 0.55,
                healthScore: 94.2,
                annualFuelSavedKg: 148_000,
                annualCarbonSavedTons: 468.0
            ),
            FlightSeed(
                carrier: .fedex,
                flightIdentifier: "FX169",
                tailNumber: "N846FD",
                aircraftType: "Boeing 777F",
                region: "Asia Pacific",
                originCode: "ANC",
                originCity: "Anchorage",
                originCoordinate: .init(latitude: 61.1743, longitude: -149.9962),
                destinationCode: "SIN",
                destinationCity: "Singapore",
                destinationCoordinate: .init(latitude: 1.3644, longitude: 103.9915),
                scheduledDurationHours: 9.8,
                routeDistanceKm: 9_700,
                routeProgress: 0.42,
                healthScore: 92.9,
                annualFuelSavedKg: 152_000,
                annualCarbonSavedTons: 480.0
            ),
            FlightSeed(
                carrier: .fedex,
                flightIdentifier: "FX944",
                tailNumber: "N884FD",
                aircraftType: "Boeing 767-300F",
                region: "North America",
                originCode: "MEM",
                originCity: "Memphis",
                originCoordinate: .init(latitude: 35.0425, longitude: -89.9767),
                destinationCode: "ONT",
                destinationCity: "Ontario",
                destinationCoordinate: .init(latitude: 34.0560, longitude: -117.6012),
                scheduledDurationHours: 3.6,
                routeDistanceKm: 2_570,
                routeProgress: 0.66,
                healthScore: 90.8,
                annualFuelSavedKg: 135_000,
                annualCarbonSavedTons: 427.0
            ),
            FlightSeed(
                carrier: .ups,
                flightIdentifier: "5X223",
                tailNumber: "N570UP",
                aircraftType: "Boeing 747-8F",
                region: "North Atlantic",
                originCode: "SDF",
                originCity: "Louisville",
                originCoordinate: .init(latitude: 38.1744, longitude: -85.7360),
                destinationCode: "CGN",
                destinationCity: "Cologne",
                destinationCoordinate: .init(latitude: 50.8659, longitude: 7.1427),
                scheduledDurationHours: 7.8,
                routeDistanceKm: 7_009,
                routeProgress: 0.61,
                healthScore: 94.4,
                annualFuelSavedKg: 142_000,
                annualCarbonSavedTons: 449.0
            ),
            FlightSeed(
                carrier: .ups,
                flightIdentifier: "5X60",
                tailNumber: "N582UP",
                aircraftType: "Boeing 747-8F",
                region: "Transpacific",
                originCode: "ANC",
                originCity: "Anchorage",
                originCoordinate: .init(latitude: 61.1743, longitude: -149.9962),
                destinationCode: "HKG",
                destinationCity: "Hong Kong",
                destinationCoordinate: .init(latitude: 22.3080, longitude: 113.9185),
                scheduledDurationHours: 9.8,
                routeDistanceKm: 7_200,
                routeProgress: 0.48,
                healthScore: 92.3,
                annualFuelSavedKg: 136_000,
                annualCarbonSavedTons: 430.0
            ),
            FlightSeed(
                carrier: .ups,
                flightIdentifier: "5X69",
                tailNumber: "N632UP",
                aircraftType: "Boeing 747-8F",
                region: "Transpacific",
                originCode: "HKG",
                originCity: "Hong Kong",
                originCoordinate: .init(latitude: 22.3080, longitude: 113.9185),
                destinationCode: "ANC",
                destinationCity: "Anchorage",
                destinationCoordinate: .init(latitude: 61.1743, longitude: -149.9962),
                scheduledDurationHours: 8.7,
                routeDistanceKm: 7_200,
                routeProgress: 0.63,
                healthScore: 93.7,
                annualFuelSavedKg: 134_000,
                annualCarbonSavedTons: 424.0
            ),
            FlightSeed(
                carrier: .ups,
                flightIdentifier: "5X51",
                tailNumber: "N633UP",
                aircraftType: "Boeing 747-8F",
                region: "North America",
                originCode: "ONT",
                originCity: "Ontario",
                originCoordinate: .init(latitude: 34.0560, longitude: -117.6012),
                destinationCode: "SDF",
                destinationCity: "Louisville",
                destinationCoordinate: .init(latitude: 38.1744, longitude: -85.7360),
                scheduledDurationHours: 3.2,
                routeDistanceKm: 2_900,
                routeProgress: 0.58,
                healthScore: 91.8,
                annualFuelSavedKg: 131_000,
                annualCarbonSavedTons: 414.0
            ),
            FlightSeed(
                carrier: .ups,
                flightIdentifier: "5X32",
                tailNumber: "N626UP",
                aircraftType: "Boeing 747-8F",
                region: "Pacific",
                originCode: "SDF",
                originCity: "Louisville",
                originCoordinate: .init(latitude: 38.1744, longitude: -85.7360),
                destinationCode: "HNL",
                destinationCity: "Honolulu",
                destinationCoordinate: .init(latitude: 21.3187, longitude: -157.9225),
                scheduledDurationHours: 9.0,
                routeDistanceKm: 7_100,
                routeProgress: 0.45,
                healthScore: 90.9,
                annualFuelSavedKg: 140_000,
                annualCarbonSavedTons: 442.0
            ),
            FlightSeed(
                carrier: .ups,
                flightIdentifier: "5X34",
                tailNumber: "N634UP",
                aircraftType: "Boeing 747-8F",
                region: "Pacific",
                originCode: "HNL",
                originCity: "Honolulu",
                originCoordinate: .init(latitude: 21.3187, longitude: -157.9225),
                destinationCode: "SYD",
                destinationCity: "Sydney",
                destinationCoordinate: .init(latitude: -33.9399, longitude: 151.1753),
                scheduledDurationHours: 10.1,
                routeDistanceKm: 8_160,
                routeProgress: 0.37,
                healthScore: 89.6,
                annualFuelSavedKg: 147_000,
                annualCarbonSavedTons: 465.0
            ),
            FlightSeed(
                carrier: .dhl,
                flightIdentifier: "D0314",
                tailNumber: "G-DHLW",
                aircraftType: "Boeing 777F",
                region: "North Atlantic",
                originCode: "LEJ",
                originCity: "Leipzig",
                originCoordinate: .init(latitude: 51.4239, longitude: 12.2364),
                destinationCode: "CVG",
                destinationCity: "Cincinnati",
                destinationCoordinate: .init(latitude: 39.0488, longitude: -84.6678),
                scheduledDurationHours: 9.0,
                routeDistanceKm: 7_153,
                routeProgress: 0.57,
                healthScore: 93.2,
                annualFuelSavedKg: 139_000,
                annualCarbonSavedTons: 439.0
            ),
            FlightSeed(
                carrier: .dhl,
                flightIdentifier: "D0376",
                tailNumber: "G-DHLJ",
                aircraftType: "Boeing 767-300F",
                region: "North Atlantic",
                originCode: "LEJ",
                originCity: "Leipzig",
                originCoordinate: .init(latitude: 51.4239, longitude: 12.2364),
                destinationCode: "CVG",
                destinationCity: "Cincinnati",
                destinationCoordinate: .init(latitude: 39.0488, longitude: -84.6678),
                scheduledDurationHours: 9.4,
                routeDistanceKm: 7_153,
                routeProgress: 0.23,
                healthScore: 90.7,
                annualFuelSavedKg: 133_000,
                annualCarbonSavedTons: 420.0
            ),
            FlightSeed(
                carrier: .dhl,
                flightIdentifier: "D0814",
                tailNumber: "G-DHLX",
                aircraftType: "Boeing 777F",
                region: "Asia Pacific",
                originCode: "LEJ",
                originCity: "Leipzig",
                originCoordinate: .init(latitude: 51.4239, longitude: 12.2364),
                destinationCode: "HKG",
                destinationCity: "Hong Kong",
                destinationCoordinate: .init(latitude: 22.3080, longitude: 113.9185),
                scheduledDurationHours: 11.2,
                routeDistanceKm: 8_820,
                routeProgress: 0.71,
                healthScore: 94.1,
                annualFuelSavedKg: 146_000,
                annualCarbonSavedTons: 461.0
            ),
            FlightSeed(
                carrier: .dhl,
                flightIdentifier: "QY364",
                tailNumber: "D-AJFK",
                aircraftType: "Airbus A330-300P2F",
                region: "North Atlantic",
                originCode: "LEJ",
                originCity: "Leipzig",
                originCoordinate: .init(latitude: 51.4239, longitude: 12.2364),
                destinationCode: "JFK",
                destinationCity: "New York",
                destinationCoordinate: .init(latitude: 40.6413, longitude: -73.7781),
                scheduledDurationHours: 8.6,
                routeDistanceKm: 6_330,
                routeProgress: 0.44,
                healthScore: 92.6,
                annualFuelSavedKg: 137_000,
                annualCarbonSavedTons: 433.0
            ),
            FlightSeed(
                carrier: .dhl,
                flightIdentifier: "QY549",
                tailNumber: "D-ALMD",
                aircraftType: "Airbus A330-243F",
                region: "Asia Pacific",
                originCode: "HKG",
                originCity: "Hong Kong",
                originCoordinate: .init(latitude: 22.3080, longitude: 113.9185),
                destinationCode: "LEJ",
                destinationCity: "Leipzig",
                destinationCoordinate: .init(latitude: 51.4239, longitude: 12.2364),
                scheduledDurationHours: 11.0,
                routeDistanceKm: 8_820,
                routeProgress: 0.34,
                healthScore: 91.4,
                annualFuelSavedKg: 141_000,
                annualCarbonSavedTons: 446.0
            ),
            FlightSeed(
                carrier: .dhl,
                flightIdentifier: "QY758",
                tailNumber: "D-ALEJ",
                aircraftType: "Airbus A330-243F",
                region: "Middle East",
                originCode: "LEJ",
                originCity: "Leipzig",
                originCoordinate: .init(latitude: 51.4239, longitude: 12.2364),
                destinationCode: "BAH",
                destinationCity: "Bahrain",
                destinationCoordinate: .init(latitude: 26.2708, longitude: 50.6336),
                scheduledDurationHours: 5.3,
                routeDistanceKm: 4_180,
                routeProgress: 0.52,
                healthScore: 89.8,
                annualFuelSavedKg: 134_000,
                annualCarbonSavedTons: 424.0
            )
        ]

        aircraft = records.map { record in
            Aircraft(
                id: UUID(),
                carrier: record.carrier,
                flightIdentifier: record.flightIdentifier,
                tailNumber: record.tailNumber,
                aircraftType: record.aircraftType,
                region: record.region,
                originCode: record.originCode,
                originCity: record.originCity,
                originCoordinate: record.originCoordinate,
                destinationCode: record.destinationCode,
                destinationCity: record.destinationCity,
                destinationCoordinate: record.destinationCoordinate,
                scheduledDurationHours: record.scheduledDurationHours,
                routeDistanceKm: record.routeDistanceKm,
                coordinate: coordinateAlongRoute(
                    from: record.originCoordinate,
                    to: record.destinationCoordinate,
                    progress: record.routeProgress
                ),
                routeProgress: record.routeProgress,
                isAirborne: true,
                healthScore: record.healthScore,
                isReliefBridgeEngaged: true,
                fuelSavedKg: record.annualFuelSavedKg,
                co2AvoidedTons: record.annualCarbonSavedTons
            )
        }
    }

    private func seedTelemetry() {
        telemetry = Dictionary(
            uniqueKeysWithValues: aircraft.map { aircraft in
                (aircraft.tailNumber, makeTelemetrySnapshot(for: aircraft, timestamp: Date()))
            }
        )
    }

    private func seedLedgerBlocks() {
        let calendar = Calendar.current
        let now = Date()
        let carrierSeries: [CargoCarrier: [Double]] = [
            .fedex: [7.8, 8.2, 7.4, 8.9, 9.1, 8.0, 9.3, 7.7, 8.8, 9.5, 8.6, 9.0],
            .ups: [6.9, 7.1, 7.5, 8.1, 8.0, 7.8, 8.4, 7.6, 8.2, 8.7, 8.0, 8.3],
            .dhl: [5.4, 5.8, 6.1, 6.4, 6.6, 6.2, 6.9, 6.1, 6.8, 7.0, 6.5, 6.9]
        ]

        var blocks: [LedgerBlock] = []
        var blockIndex = 0

        for carrier in CargoCarrier.allCases {
            let identifiers = aircraft(for: carrier).map(\.flightIdentifier)
            let savings = carrierSeries[carrier] ?? []

            for (offset, carbonSavedMetricTons) in savings.enumerated() {
                let timestamp = calendar.date(
                    byAdding: .day,
                    value: -((savings.count - offset) * 7) + Int.random(in: -1...1),
                    to: now
                ) ?? now

                let flightIdentifier = identifiers[offset % max(identifiers.count, 1)]
                let standard: RegulatoryStandard = offset.isMultiple(of: 2) ? .corsia : .euEts

                blocks.append(
                    LedgerBlock(
                        id: UUID(),
                        carrier: carrier,
                        timestamp: timestamp,
                        flightIdentifier: flightIdentifier,
                        carbonSavedMetricTons: carbonSavedMetricTons,
                        regulatoryStandard: standard,
                        blockHash: simulatedBlockHash(index: blockIndex)
                    )
                )
                blockIndex += 1
            }
        }

        ledgerBlocks = blocks
    }

    private func seedFinancialMonths() {
        let calendar = Calendar.current
        let now = Date()
        let fleetSavingsSeries: [Double] = [2_120_000, 2_180_000, 2_250_000, 2_310_000, 2_365_000, 2_430_000, 2_488_000, 2_552_000, 2_610_000, 2_680_000, 2_742_000, 2_810_000]
        let carbonCreditSeries: [Double] = [382_000, 394_000, 406_000, 421_000, 432_000, 446_000, 458_000, 471_000, 482_000, 495_000, 509_000, 524_000]
        let avoidedGroundDelaySeries: [Double] = [118_000, 121_000, 125_000, 129_000, 132_000, 136_000, 141_000, 145_000, 149_000, 153_000, 157_000, 162_000]

        financialMonths = (0..<12).map { index in
            let monthDate = calendar.date(byAdding: .month, value: -(11 - index), to: now) ?? now
            return FinancialMonth(
                id: UUID(),
                month: monthDate,
                fuelSavingsUSD: fleetSavingsSeries[index],
                monetizedCarbonCreditsUSD: carbonCreditSeries[index],
                avoidedNoiseFinesUSD: avoidedGroundDelaySeries[index]
            )
        }
    }

    private func seedMaintenanceAlerts() {
        maintenanceAlerts = [
            MaintenanceAlert(
                id: UUID(),
                carrier: .fedex,
                tailNumber: "N852FD",
                flightIdentifier: "FX38",
                affectedComponent: "Leading-edge retrofit panel",
                description: "Pressure taps on the Paris lane are reading a wider spread than the Memphis baseline during descent.",
                recommendedAction: "Inspect the port-side surface panel and re-run the pressure calibration before the next CDG departure.",
                severity: .critical,
                generatedAt: Date().addingTimeInterval(-2_100)
            ),
            MaintenanceAlert(
                id: UUID(),
                carrier: .fedex,
                tailNumber: "N884FD",
                flightIdentifier: "FX944",
                affectedComponent: "Starboard sensor harness",
                description: "One sensor channel on the Ontario rotation is reporting values outside the expected configuration range.",
                recommendedAction: "Recalibrate the sensor configuration during the next westbound gate stop to restore baseline readings.",
                severity: .warning,
                generatedAt: Date().addingTimeInterval(-7_900)
            ),
            MaintenanceAlert(
                id: UUID(),
                carrier: .ups,
                tailNumber: "N570UP",
                flightIdentifier: "5X223",
                affectedComponent: "Upper wing pressure manifold",
                description: "Cologne-bound cruise data shows one manifold climbing faster than the rest of the retrofit surface.",
                recommendedAction: "Inspect the upper wing manifold at the next CGN handling window and compare against Louisville baseline data.",
                severity: .critical,
                generatedAt: Date().addingTimeInterval(-1_400)
            ),
            MaintenanceAlert(
                id: UUID(),
                carrier: .ups,
                tailNumber: "N626UP",
                flightIdentifier: "5X32",
                affectedComponent: "Surface temperature probe cluster",
                description: "The Honolulu lane is running hotter than forecast near the inboard panel set during climb.",
                recommendedAction: "Validate probe alignment during the next SDF departure prep and inspect thermal shielding.",
                severity: .warning,
                generatedAt: Date().addingTimeInterval(-4_200)
            ),
            MaintenanceAlert(
                id: UUID(),
                carrier: .ups,
                tailNumber: "N634UP",
                flightIdentifier: "5X34",
                affectedComponent: "Retrofit seal line",
                description: "Sydney-bound data suggests a minor seal-line gap on the right trailing segment after a long Pacific leg.",
                recommendedAction: "Re-seat the seal line at the next major stop and confirm drag delta recovery on departure.",
                severity: .warning,
                generatedAt: Date().addingTimeInterval(-8_700)
            ),
            MaintenanceAlert(
                id: UUID(),
                carrier: .dhl,
                tailNumber: "G-DHLW",
                flightIdentifier: "D0314",
                affectedComponent: "Forward intake pressure array",
                description: "The Cincinnati lane is carrying a persistent pressure imbalance across the forward ReliefBridge array.",
                recommendedAction: "Run a targeted intake inspection in Leipzig before the next transatlantic departure.",
                severity: .critical,
                generatedAt: Date().addingTimeInterval(-1_900)
            ),
            MaintenanceAlert(
                id: UUID(),
                carrier: .dhl,
                tailNumber: "D-AJFK",
                flightIdentifier: "QY364",
                affectedComponent: "Boundary-layer sensor pair",
                description: "Two New York-bound sensors are drifting apart enough to reduce confidence in the airflow comparison trace.",
                recommendedAction: "Recalibrate the pair at the next LEJ turnaround and recheck the airflow retention trend.",
                severity: .warning,
                generatedAt: Date().addingTimeInterval(-5_900)
            ),
            MaintenanceAlert(
                id: UUID(),
                carrier: .dhl,
                tailNumber: "D-ALEJ",
                flightIdentifier: "QY758",
                affectedComponent: "Controller cooling loop",
                description: "Cooling margin on the Bahrain sector is running tighter than the rest of the DHL widebody sample.",
                recommendedAction: "Inspect the controller cooling loop and confirm fan response before the next Gulf departure.",
                severity: .warning,
                generatedAt: Date().addingTimeInterval(-9_400)
            )
        ]
    }

    private func seedLatticeZones() {
        let labels = [
            "A1", "A2", "A3", "A4", "A5",
            "B1", "B2", "B3", "B4", "B5",
            "C1", "C2", "C3", "C4", "C5"
        ]
        let risks: [Double] = [
            0.18, 0.27, 0.44, 0.62, 0.39,
            0.24, 0.53, 0.71, 0.58, 0.33,
            0.29, 0.81, 0.67, 0.49, 0.21
        ]

        latticeZones = zip(labels, risks).map { label, risk in
            LatticeZone(id: UUID(), zoneLabel: label, microPoreBlockageRisk: risk)
        }
    }

    // MARK: - Timer

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.tick()
        }

        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func tick() {
        tickCount += 1
        mutateAircraft()
        mutateTelemetry()
    }

    private func mutateAircraft() {
        for index in aircraft.indices {
            guard aircraft[index].isAirborne else { continue }

            let speedFactor = clamp(aircraft[index].routeDistanceKm / 10_000.0, min: 0.35, max: 1.0)
            let increment = 0.010 + (0.006 * speedFactor)
            var nextProgress = aircraft[index].routeProgress + increment
            if nextProgress >= 1.0 {
                nextProgress -= 1.0
            }

            aircraft[index].routeProgress = nextProgress
            aircraft[index].coordinate = coordinateAlongRoute(
                from: aircraft[index].originCoordinate,
                to: aircraft[index].destinationCoordinate,
                progress: nextProgress
            )
            aircraft[index].healthScore = clamp(
                aircraft[index].healthScore + Double.random(in: -0.12...0.10),
                min: 86,
                max: 98
            )
            aircraft[index].fuelSavedKg = clamp(
                aircraft[index].fuelSavedKg + Double.random(in: -800...1200),
                min: 130_000,
                max: 155_000
            )
            aircraft[index].co2AvoidedTons = clamp(
                aircraft[index].co2AvoidedTons + Double.random(in: -2.5...3.8),
                min: 410,
                max: 490
            )
            aircraft[index].isReliefBridgeEngaged = true
        }
    }

    private func mutateTelemetry() {
        let now = Date()

        for aircraft in aircraft where aircraft.isAirborne {
            guard var snapshot = telemetry[aircraft.tailNumber] else {
                telemetry[aircraft.tailNumber] = makeTelemetrySnapshot(for: aircraft, timestamp: now)
                continue
            }

            snapshot = TelemetrySnapshot(
                tailNumber: aircraft.tailNumber,
                timestamp: now,
                ramAirIntakePressure: clamp(
                    snapshot.ramAirIntakePressure + Double.random(in: -6...6),
                    min: 972,
                    max: 1_040
                ),
                gyroidFlowUniformity: clamp(
                    snapshot.gyroidFlowUniformity + Double.random(in: -0.012...0.014),
                    min: 0.78,
                    max: 0.98
                ),
                jetSheetVelocity: clamp(
                    snapshot.jetSheetVelocity + Double.random(in: -3.5...4.0),
                    min: 236,
                    max: 298
                ),
                boundaryLayerRetention: clamp(
                    snapshot.boundaryLayerRetention + Double.random(in: -0.010...0.012),
                    min: 0.79,
                    max: 0.97
                ),
                dragReductionPercent: clamp(
                    snapshot.dragReductionPercent + Double.random(in: -0.01...0.01),
                    min: 0.14,
                    max: 0.18
                ),
                projectedAnnualFuelGainKg: aircraft.fuelSavedKg,
                dragCoefficientHistory: appendDragPoint(to: snapshot.dragCoefficientHistory)
            )

            telemetry[aircraft.tailNumber] = snapshot
        }
    }

    // MARK: - Helpers

    private func ensureSelectedAircraftBelongsToCarrier() {
        let carrierAircraft = aircraft(for: selectedCarrier)

        guard !carrierAircraft.isEmpty else {
            selectedAircraftTailNumber = nil
            return
        }

        if let selectedAircraftTailNumber,
           carrierAircraft.contains(where: { $0.tailNumber == selectedAircraftTailNumber }) {
            return
        }

        selectedAircraftTailNumber = carrierAircraft.first?.tailNumber
    }

    private func syncCarrierToSelectedAircraft() {
        guard let selectedAircraftTailNumber,
              let aircraft = aircraft(forTailNumber: selectedAircraftTailNumber),
              aircraft.carrier != selectedCarrier else {
            return
        }

        selectedCarrier = aircraft.carrier
    }

    private func appendDragPoint(to history: [DragDataPoint]) -> [DragDataPoint] {
        let lastElapsed = history.last?.timeElapsed ?? 0.0
        let baseline = history.last?.dragCoefficient ?? 0.0285
        let nextValue = clamp(
            baseline + Double.random(in: -0.00035...0.00020),
            min: 0.0215,
            max: 0.0305
        )

        var updated = history
        updated.append(
            DragDataPoint(
                id: UUID(),
                timeElapsed: lastElapsed + 2.0,
                dragCoefficient: nextValue
            )
        )

        if updated.count > 120 {
            updated.removeFirst(updated.count - 120)
        }

        return updated
    }

    private func coordinateAlongRoute(
        from origin: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D,
        progress: Double
    ) -> CLLocationCoordinate2D {
        let clampedProgress = clamp(progress, min: 0, max: 1)
        let latitude = origin.latitude + ((destination.latitude - origin.latitude) * clampedProgress)
        let longitude = interpolatedLongitude(
            from: origin.longitude,
            to: destination.longitude,
            progress: clampedProgress
        )

        let arcHeight = sin(clampedProgress * .pi) * max(abs(destination.latitude - origin.latitude), 12) * 0.09
        return CLLocationCoordinate2D(latitude: latitude + arcHeight, longitude: longitude)
    }

    private func interpolatedLongitude(from start: Double, to end: Double, progress: Double) -> Double {
        var delta = end - start
        if abs(delta) > 180 {
            delta = delta > 0 ? delta - 360 : delta + 360
        }

        var interpolated = start + (delta * progress)
        if interpolated > 180 {
            interpolated -= 360
        } else if interpolated < -180 {
            interpolated += 360
        }
        return interpolated
    }

    private func clamp(_ value: Double, min minValue: Double, max maxValue: Double) -> Double {
        Swift.max(minValue, Swift.min(maxValue, value))
    }

    private func makeTelemetrySnapshot(for aircraft: Aircraft, timestamp: Date) -> TelemetrySnapshot {
        let longHaulBias = clamp(aircraft.routeDistanceKm / 10_000.0, min: 0.18, max: 0.95)
        let airframeBias = aircraft.aircraftType.contains("747") || aircraft.aircraftType.contains("777") ? 1.0 : 0.0
        let healthBias = aircraft.healthScore / 100.0

        let basePressure = 994 + (longHaulBias * 18) + (airframeBias * 6)
        let baseUniformity = 0.82 + (healthBias * 0.10)
        let baseJetVelocity = 248 + (longHaulBias * 26) + (airframeBias * 10)
        let baseRetention = 0.81 + (healthBias * 0.12)
        let baseDragReduction = 0.15 + (longHaulBias * 0.018) + (healthBias * 0.010)

        let dragHistory = (0..<14).map { index in
            let elapsed = Double(index) * 180.0
            let drift = Double(index) * 0.00014
            let oscillation = sin(Double(index) * 0.44) * 0.00008
            return DragDataPoint(
                id: UUID(),
                timeElapsed: elapsed,
                dragCoefficient: clamp(0.0288 - drift + oscillation, min: 0.0215, max: 0.0300)
            )
        }

        return TelemetrySnapshot(
            tailNumber: aircraft.tailNumber,
            timestamp: timestamp,
            ramAirIntakePressure: clamp(basePressure + Double.random(in: -7...7), min: 972, max: 1_040),
            gyroidFlowUniformity: clamp(baseUniformity + Double.random(in: -0.012...0.012), min: 0.79, max: 0.98),
            jetSheetVelocity: clamp(baseJetVelocity + Double.random(in: -4...4), min: 236, max: 298),
            boundaryLayerRetention: clamp(baseRetention + Double.random(in: -0.010...0.010), min: 0.80, max: 0.97),
            dragReductionPercent: clamp(baseDragReduction + Double.random(in: -0.01...0.01), min: 0.14, max: 0.18),
            projectedAnnualFuelGainKg: aircraft.fuelSavedKg,
            dragCoefficientHistory: dragHistory
        )
    }

    private func simulatedBlockHash(index: Int) -> String {
        let seed = "reliefbridge-block-\(index)"
        var hash = ""
        for char in seed.unicodeScalars {
            hash += String(format: "%02x", char.value)
        }
        while hash.count < 64 {
            hash += "0"
        }
        return String(hash.prefix(64))
    }

    // MARK: - Deinit

    deinit {
        timer?.invalidate()
    }
}

// MARK: - Seed Support

private struct FlightSeed {
    let carrier: CargoCarrier
    let flightIdentifier: String
    let tailNumber: String
    let aircraftType: String
    let region: String
    let originCode: String
    let originCity: String
    let originCoordinate: CLLocationCoordinate2D
    let destinationCode: String
    let destinationCity: String
    let destinationCoordinate: CLLocationCoordinate2D
    let scheduledDurationHours: Double
    let routeDistanceKm: Double
    let routeProgress: Double
    let healthScore: Double
    let annualFuelSavedKg: Double
    let annualCarbonSavedTons: Double
}
