// ReliefBridgeTests/FleetCommandViewModelTests.swift
// Unit tests for FleetCommandViewModel.
// Validates: Requirements 2.4, 2.5, 2.6, 2.9, 2.11

import XCTest
import Combine
import CoreLocation
@testable import ReliefBridge

// MARK: - Helpers

private func makeAircraft(
    tailNumber: String = "TEST-1",
    aircraftType: String = "Airbus A320neo",
    region: String = "Europe",
    healthScore: Double = 90.0,
    isAirborne: Bool = true,
    fuelSavedKg: Double = 1000.0,
    co2AvoidedTons: Double = 3.0
) -> Aircraft {
    Aircraft(
        id: UUID(),
        tailNumber: tailNumber,
        aircraftType: aircraftType,
        region: region,
        coordinate: CLLocationCoordinate2D(latitude: 51.0, longitude: 0.0),
        isAirborne: isAirborne,
        healthScore: healthScore,
        isReliefBridgeEngaged: isAirborne,
        fuelSavedKg: fuelSavedKg,
        co2AvoidedTons: co2AvoidedTons
    )
}

// MARK: - KPI Aggregation Tests

final class FleetCommandViewModelKPITests: XCTestCase {

    private var cancellables = Set<AnyCancellable>()

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    // MARK: Total Fuel Saved

    /// Verify Total Fuel Saved KPI equals the sum of fuelSavedKg across all aircraft.
    func testTotalFuelSaved_equalsSumOfFuelSavedKg() {
        let sut = SimulatedDataService()
        let vm = FleetCommandViewModel(dataService: sut)

        let aircraft = [
            makeAircraft(tailNumber: "A1", fuelSavedKg: 500.0),
            makeAircraft(tailNumber: "A2", fuelSavedKg: 750.0),
            makeAircraft(tailNumber: "A3", fuelSavedKg: 250.0),
        ]

        let expectation = XCTestExpectation(description: "KPI cards updated")
        // Subscribe first, then mutate — filter for the emission that matches our test data
        vm.$kpiCards
            .filter { cards in
                // Wait for the emission that reflects our 3-aircraft set
                guard let fuelCard = cards.first(where: { $0.title == "Total Fuel Saved" }) else { return false }
                return fuelCard.value == "1500"
            }
            .first()
            .sink { cards in
                let fuelCard = cards.first { $0.title == "Total Fuel Saved" }
                XCTAssertNotNil(fuelCard)
                XCTAssertEqual(fuelCard?.value, "1500", "Expected sum 1500 kg")
                XCTAssertEqual(fuelCard?.unit, "kg")
                XCTAssertTrue(fuelCard?.isHealthy == true)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        sut.aircraft = aircraft
        wait(for: [expectation], timeout: 2.0)
    }

    // MARK: Net CO2 Avoided

    /// Verify Net CO2 Avoided KPI equals the sum of co2AvoidedTons across all aircraft.
    func testNetCO2Avoided_equalsSumOfCO2AvoidedTons() {
        let sut = SimulatedDataService()
        let vm = FleetCommandViewModel(dataService: sut)

        let aircraft = [
            makeAircraft(tailNumber: "A1", co2AvoidedTons: 2.5),
            makeAircraft(tailNumber: "A2", co2AvoidedTons: 1.75),
        ]

        let expectation = XCTestExpectation(description: "KPI cards updated")
        vm.$kpiCards
            .filter { cards in
                guard let co2Card = cards.first(where: { $0.title == "Net CO2 Avoided" }) else { return false }
                return co2Card.value == "4.25"
            }
            .first()
            .sink { cards in
                let co2Card = cards.first { $0.title == "Net CO2 Avoided" }
                XCTAssertNotNil(co2Card)
                XCTAssertEqual(co2Card?.value, "4.25", "Expected sum 4.25 t")
                XCTAssertEqual(co2Card?.unit, "t")
                XCTAssertTrue(co2Card?.isHealthy == true)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        sut.aircraft = aircraft
        wait(for: [expectation], timeout: 2.0)
    }

    // MARK: Active Fleet Health Score

    /// Verify Active Fleet Health Score KPI equals the average healthScore.
    func testFleetHealthScore_equalsAverageHealthScore() {
        let sut = SimulatedDataService()
        let vm = FleetCommandViewModel(dataService: sut)

        let aircraft = [
            makeAircraft(tailNumber: "A1", healthScore: 80.0),
            makeAircraft(tailNumber: "A2", healthScore: 90.0),
            makeAircraft(tailNumber: "A3", healthScore: 70.0),
        ]

        let expectation = XCTestExpectation(description: "KPI cards updated")
        vm.$kpiCards
            .filter { cards in
                guard let h = cards.first(where: { $0.title == "Active Fleet Health Score" }) else { return false }
                return h.value == "80.0"
            }
            .first()
            .sink { cards in
                let healthCard = cards.first { $0.title == "Active Fleet Health Score" }
                XCTAssertNotNil(healthCard)
                XCTAssertEqual(healthCard?.value, "80.0", "Expected average 80.0%")
                XCTAssertEqual(healthCard?.unit, "%")
                XCTAssertTrue(healthCard?.isHealthy == true, "Score 80.0 >= 70.0 should be healthy")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        sut.aircraft = aircraft
        wait(for: [expectation], timeout: 2.0)
    }

    /// Verify health score KPI is NOT healthy when average is below 70.
    func testFleetHealthScore_notHealthyWhenAverageBelow70() {
        let sut = SimulatedDataService()
        let vm = FleetCommandViewModel(dataService: sut)

        let aircraft = [
            makeAircraft(tailNumber: "A1", healthScore: 60.0),
            makeAircraft(tailNumber: "A2", healthScore: 65.0),
        ]

        let expectation = XCTestExpectation(description: "KPI cards updated")
        vm.$kpiCards
            .filter { cards in
                guard let h = cards.first(where: { $0.title == "Active Fleet Health Score" }) else { return false }
                return h.value == "62.5"
            }
            .first()
            .sink { cards in
                let healthCard = cards.first { $0.title == "Active Fleet Health Score" }
                XCTAssertNotNil(healthCard)
                XCTAssertFalse(healthCard?.isHealthy == true, "Score 62.5 < 70.0 should not be healthy")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        sut.aircraft = aircraft
        wait(for: [expectation], timeout: 2.0)
    }

    /// Verify health score KPI is healthy at exactly 70.0 (boundary).
    func testFleetHealthScore_healthyAtExactly70() {
        let sut = SimulatedDataService()
        let vm = FleetCommandViewModel(dataService: sut)

        let aircraft = [makeAircraft(tailNumber: "A1", healthScore: 70.0)]

        let expectation = XCTestExpectation(description: "KPI cards updated")
        vm.$kpiCards
            .filter { cards in
                guard let h = cards.first(where: { $0.title == "Active Fleet Health Score" }) else { return false }
                return h.value == "70.0"
            }
            .first()
            .sink { cards in
                let healthCard = cards.first { $0.title == "Active Fleet Health Score" }
                XCTAssertTrue(healthCard?.isHealthy == true, "Score exactly 70.0 should be healthy")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        sut.aircraft = aircraft
        wait(for: [expectation], timeout: 2.0)
    }
}

// MARK: - Empty Fleet Edge Case Tests

final class FleetCommandViewModelEmptyFleetTests: XCTestCase {

    private var cancellables = Set<AnyCancellable>()

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    /// When filteredAircraft is empty, all KPI cards should show "—" as value.
    func testEmptyFleet_kpiCardsShowDashPlaceholder() {
        let sut = SimulatedDataService()
        let vm = FleetCommandViewModel(dataService: sut)

        let expectation = XCTestExpectation(description: "KPI cards updated to empty state")
        vm.$kpiCards
            .filter { cards in
                // Wait for the emission where all 3 cards show "—"
                cards.count == 3 && cards.allSatisfy { $0.value == "—" }
            }
            .first()
            .sink { cards in
                XCTAssertEqual(cards.count, 3, "Should always have 3 KPI cards")
                for card in cards {
                    XCTAssertEqual(card.value, "—",
                        "Card '\(card.title)' should show '—' when fleet is empty, got '\(card.value)'")
                    XCTAssertFalse(card.isHealthy,
                        "Card '\(card.title)' should not be healthy when fleet is empty")
                }
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Clear all aircraft after subscribing
        sut.aircraft = []
        wait(for: [expectation], timeout: 2.0)
    }

    /// When search text matches no aircraft, KPI cards should show "—".
    func testSearchWithNoMatches_kpiCardsShowDashPlaceholder() {
        let sut = SimulatedDataService()
        let vm = FleetCommandViewModel(dataService: sut)

        sut.aircraft = [makeAircraft(tailNumber: "G-AERO1")]

        let expectation = XCTestExpectation(description: "KPI cards updated to empty state")
        vm.$kpiCards
            .filter { cards in
                cards.allSatisfy { $0.value == "—" }
            }
            .first()
            .sink { cards in
                for card in cards {
                    XCTAssertEqual(card.value, "—",
                        "Card '\(card.title)' should show '—' when no aircraft match search")
                }
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Set search text that matches nothing
        vm.searchText = "ZZZNOMATCH"
        wait(for: [expectation], timeout: 2.0)
    }
}

// MARK: - Filter Logic Tests

final class FleetCommandViewModelFilterTests: XCTestCase {

    private var cancellables = Set<AnyCancellable>()

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    // MARK: Search Text Filter

    /// Verify search text filters by tail number (case-insensitive).
    func testSearchText_filtersByTailNumber() {
        let sut = SimulatedDataService()
        let vm = FleetCommandViewModel(dataService: sut)

        sut.aircraft = [
            makeAircraft(tailNumber: "G-AERO1"),
            makeAircraft(tailNumber: "N-AERO3"),
            makeAircraft(tailNumber: "A-AERO5"),
        ]

        let expectation = XCTestExpectation(description: "Filtered aircraft updated")
        vm.$filteredAircraft
            .filter { $0.count == 1 && $0.first?.tailNumber == "G-AERO1" }
            .first()
            .sink { filtered in
                XCTAssertEqual(filtered.count, 1)
                XCTAssertEqual(filtered.first?.tailNumber, "G-AERO1")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        vm.searchText = "G-AERO"
        wait(for: [expectation], timeout: 2.0)
    }

    /// Verify search text is case-insensitive.
    func testSearchText_isCaseInsensitive() {
        let sut = SimulatedDataService()
        let vm = FleetCommandViewModel(dataService: sut)

        sut.aircraft = [makeAircraft(tailNumber: "G-AERO1")]

        let expectation = XCTestExpectation(description: "Filtered aircraft updated")
        vm.$filteredAircraft
            .filter { $0.count == 1 && $0.first?.tailNumber == "G-AERO1" }
            .first()
            .sink { filtered in
                XCTAssertEqual(filtered.count, 1, "Case-insensitive search should match")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        vm.searchText = "g-aero1"
        wait(for: [expectation], timeout: 2.0)
    }

    // MARK: Aircraft Type Filter

    /// Verify filter by aircraft type returns only matching aircraft.
    func testFilterByAircraftType_returnsOnlyMatchingAircraft() {
        let sut = SimulatedDataService()
        let vm = FleetCommandViewModel(dataService: sut)

        sut.aircraft = [
            makeAircraft(tailNumber: "A1", aircraftType: "Airbus A320neo"),
            makeAircraft(tailNumber: "A2", aircraftType: "Boeing 737 MAX"),
            makeAircraft(tailNumber: "A3", aircraftType: "Airbus A321neo"),
        ]

        let expectation = XCTestExpectation(description: "Filtered aircraft updated")
        vm.$filteredAircraft
            .filter { filtered in
                filtered.count == 2 && filtered.allSatisfy { $0.aircraftType.contains("Airbus") }
            }
            .first()
            .sink { filtered in
                XCTAssertEqual(filtered.count, 2, "Expected 2 Airbus aircraft")
                XCTAssertTrue(filtered.allSatisfy { $0.aircraftType.contains("Airbus") })
                expectation.fulfill()
            }
            .store(in: &cancellables)

        vm.filterCriteria.aircraftType = "Airbus"
        wait(for: [expectation], timeout: 2.0)
    }

    // MARK: Region Filter

    /// Verify filter by region returns only aircraft in that region.
    func testFilterByRegion_returnsOnlyMatchingAircraft() {
        let sut = SimulatedDataService()
        let vm = FleetCommandViewModel(dataService: sut)

        sut.aircraft = [
            makeAircraft(tailNumber: "A1", region: "Europe"),
            makeAircraft(tailNumber: "A2", region: "Asia Pacific"),
            makeAircraft(tailNumber: "A3", region: "Europe"),
        ]

        let expectation = XCTestExpectation(description: "Filtered aircraft updated")
        vm.$filteredAircraft
            .filter { filtered in
                filtered.count == 2 && filtered.allSatisfy { $0.region == "Europe" }
            }
            .first()
            .sink { filtered in
                XCTAssertEqual(filtered.count, 2, "Expected 2 European aircraft")
                XCTAssertTrue(filtered.allSatisfy { $0.region == "Europe" })
                expectation.fulfill()
            }
            .store(in: &cancellables)

        vm.filterCriteria.region = "Europe"
        wait(for: [expectation], timeout: 2.0)
    }

    // MARK: Health Status Filter

    /// Verify filter by .healthy returns only aircraft with healthScore >= 70.
    func testFilterByHealthStatus_healthy_returnsOnlyHealthyAircraft() {
        let sut = SimulatedDataService()
        let vm = FleetCommandViewModel(dataService: sut)

        sut.aircraft = [
            makeAircraft(tailNumber: "A1", healthScore: 80.0),
            makeAircraft(tailNumber: "A2", healthScore: 65.0),
            makeAircraft(tailNumber: "A3", healthScore: 70.0), // boundary — healthy
        ]

        let expectation = XCTestExpectation(description: "Filtered aircraft updated")
        vm.$filteredAircraft
            .filter { filtered in
                filtered.count == 2 && filtered.allSatisfy { $0.healthScore >= 70.0 }
            }
            .first()
            .sink { filtered in
                XCTAssertEqual(filtered.count, 2, "Expected 2 healthy aircraft (80.0 and 70.0)")
                XCTAssertTrue(filtered.allSatisfy { $0.healthScore >= 70.0 })
                expectation.fulfill()
            }
            .store(in: &cancellables)

        vm.filterCriteria.healthStatus = .healthy
        wait(for: [expectation], timeout: 2.0)
    }

    /// Verify filter by .degraded returns only aircraft with healthScore < 70.
    func testFilterByHealthStatus_degraded_returnsOnlyDegradedAircraft() {
        let sut = SimulatedDataService()
        let vm = FleetCommandViewModel(dataService: sut)

        sut.aircraft = [
            makeAircraft(tailNumber: "A1", healthScore: 80.0),
            makeAircraft(tailNumber: "A2", healthScore: 65.0),
            makeAircraft(tailNumber: "A3", healthScore: 69.9),
        ]

        let expectation = XCTestExpectation(description: "Filtered aircraft updated")
        vm.$filteredAircraft
            .filter { filtered in
                filtered.count == 2 && filtered.allSatisfy { $0.healthScore < 70.0 }
            }
            .first()
            .sink { filtered in
                XCTAssertEqual(filtered.count, 2, "Expected 2 degraded aircraft (65.0 and 69.9)")
                XCTAssertTrue(filtered.allSatisfy { $0.healthScore < 70.0 })
                expectation.fulfill()
            }
            .store(in: &cancellables)

        vm.filterCriteria.healthStatus = .degraded
        wait(for: [expectation], timeout: 2.0)
    }

    // MARK: Combined Filters

    /// Verify multiple filter criteria are applied conjunctively (AND logic).
    func testCombinedFilters_appliedConjunctively() {
        let sut = SimulatedDataService()
        let vm = FleetCommandViewModel(dataService: sut)

        sut.aircraft = [
            makeAircraft(tailNumber: "A1", aircraftType: "Airbus A320neo", region: "Europe",       healthScore: 90.0),
            makeAircraft(tailNumber: "A2", aircraftType: "Airbus A320neo", region: "Asia Pacific",  healthScore: 90.0),
            makeAircraft(tailNumber: "A3", aircraftType: "Boeing 737 MAX", region: "Europe",        healthScore: 90.0),
            makeAircraft(tailNumber: "A4", aircraftType: "Airbus A320neo", region: "Europe",        healthScore: 60.0),
        ]

        let expectation = XCTestExpectation(description: "Filtered aircraft updated")
        vm.$filteredAircraft
            .filter { filtered in
                // Only A1 matches: Airbus + Europe + healthy
                filtered.count == 1 && filtered.first?.tailNumber == "A1"
            }
            .first()
            .sink { filtered in
                XCTAssertEqual(filtered.count, 1)
                XCTAssertEqual(filtered.first?.tailNumber, "A1")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        vm.filterCriteria = FilterCriteria(
            aircraftType: "Airbus",
            region: "Europe",
            healthStatus: .healthy
        )
        wait(for: [expectation], timeout: 2.0)
    }

    // MARK: No Filter

    /// Verify that with no search text and no filter criteria, all aircraft are returned.
    func testNoFilter_returnsAllAircraft() {
        let sut = SimulatedDataService()
        let vm = FleetCommandViewModel(dataService: sut)

        let aircraft = [
            makeAircraft(tailNumber: "A1"),
            makeAircraft(tailNumber: "A2"),
            makeAircraft(tailNumber: "A3"),
        ]

        let expectation = XCTestExpectation(description: "Filtered aircraft updated")
        vm.$filteredAircraft
            .filter { $0.count == 3 }
            .first()
            .sink { filtered in
                XCTAssertEqual(filtered.count, 3, "All aircraft should be returned with no filter")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        sut.aircraft = aircraft
        wait(for: [expectation], timeout: 2.0)
    }
}
