// ReliefBridge/ViewModels/FleetCommandViewModel.swift

import Foundation
import Combine

struct FilterCriteria {
    var aircraftType: String? = nil
    var region: String? = nil
}

final class FleetCommandViewModel: ObservableObject {

    @Published var searchText: String = ""
    @Published var filterCriteria: FilterCriteria = FilterCriteria()

    @Published private(set) var filteredAircraft: [Aircraft] = []
    @Published private(set) var kpiCards: [KPICard] = []
    @Published private(set) var selectedCarrier: CargoCarrier = .fedex

    private let dataService: SimulatedDataService
    private var cancellables = Set<AnyCancellable>()

    init(dataService: SimulatedDataService) {
        self.dataService = dataService
        bindToDataService()
    }

    private func bindToDataService() {
        Publishers.CombineLatest4(
            dataService.$aircraft,
            dataService.$selectedCarrier,
            $searchText,
            $filterCriteria
        )
        .map { [weak self] aircraft, carrier, searchText, criteria -> (CargoCarrier, [Aircraft], [KPICard]) in
            guard let self else {
                return (carrier, [], Self.emptyKPICards())
            }

            let carrierAircraft = aircraft.filter { $0.carrier == carrier }
            let filtered = self.applyFilters(to: carrierAircraft, searchText: searchText, criteria: criteria)
            return (carrier, filtered, Self.buildKPICards(from: filtered))
        }
        .receive(on: DispatchQueue.main)
        .sink { [weak self] carrier, filtered, cards in
            self?.selectedCarrier = carrier
            self?.filteredAircraft = filtered
            self?.kpiCards = cards
        }
        .store(in: &cancellables)
    }

    private func applyFilters(
        to aircraft: [Aircraft],
        searchText: String,
        criteria: FilterCriteria
    ) -> [Aircraft] {
        aircraft.filter { aircraft in
            if !searchText.isEmpty {
                let searchableFields = [
                    aircraft.flightIdentifier,
                    aircraft.tailNumber,
                    aircraft.aircraftType,
                    aircraft.originCode,
                    aircraft.destinationCode,
                    aircraft.originCity,
                    aircraft.destinationCity
                ]

                guard searchableFields.contains(where: { $0.localizedCaseInsensitiveContains(searchText) }) else {
                    return false
                }
            }

            if let aircraftType = criteria.aircraftType, !aircraftType.isEmpty {
                guard aircraft.aircraftType.localizedCaseInsensitiveContains(aircraftType) else {
                    return false
                }
            }

            if let region = criteria.region, !region.isEmpty {
                guard aircraft.region.localizedCaseInsensitiveContains(region) else {
                    return false
                }
            }

            return true
        }
        .sorted { lhs, rhs in
            if lhs.isAirborne != rhs.isAirborne {
                return lhs.isAirborne && !rhs.isAirborne
            }
            return lhs.flightIdentifier < rhs.flightIdentifier
        }
    }

    private static func buildKPICards(from aircraft: [Aircraft]) -> [KPICard] {
        guard !aircraft.isEmpty else {
            return emptyKPICards()
        }

        // Fleet-wide annual totals (random in range) divided by number of displayed flights
        let fleetFuelSavedTotal = Double.random(in: 800_000...900_000)
        let fleetCO2AvoidedTotal = fleetFuelSavedTotal * 3.16 / 1000 // Convert kg to tons with CO2 factor
        
        let avgFuelSaved = fleetFuelSavedTotal / Double(aircraft.count)
        let avgCO2Avoided = fleetCO2AvoidedTotal / Double(aircraft.count)
        let reportingFlights = aircraft.filter(\.isAirborne).count

        return [
            KPICard(
                id: UUID(),
                title: "Avg Fuel Saved Per Aircraft",
                value: String(format: "%.0f", avgFuelSaved),
                unit: "kg/yr",
                isHealthy: avgFuelSaved > 0
            ),
            KPICard(
                id: UUID(),
                title: "Avg Carbon Saved Per Aircraft",
                value: String(format: "%.0f", avgCO2Avoided),
                unit: "t/yr",
                isHealthy: avgCO2Avoided > 0
            ),
            KPICard(
                id: UUID(),
                title: "Flights Reporting",
                value: "\(reportingFlights)",
                unit: "live",
                isHealthy: reportingFlights > 0
            )
        ]
    }

    private static func emptyKPICards() -> [KPICard] {
        [
            KPICard(id: UUID(), title: "Avg Fuel Saved Per Aircraft", value: "—", unit: "kg/yr", isHealthy: false),
            KPICard(id: UUID(), title: "Avg Carbon Saved Per Aircraft", value: "—", unit: "t/yr", isHealthy: false),
            KPICard(id: UUID(), title: "Flights Reporting", value: "—", unit: "live", isHealthy: false)
        ]
    }
}
