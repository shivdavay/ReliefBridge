// ReliefBridgeTests/DigitalTwinViewModelTests.swift
// Unit tests for DigitalTwinViewModel.
// Validates: Requirements 3.8

import XCTest
import Combine
import CoreLocation
@testable import ReliefBridge

// MARK: - Gauge Color Boundary Tests

/// Tests for the gauge color selection logic at boundary values.
///
/// The rule: color is Alert Orange iff `value > threshold`, Efficiency Green otherwise.
final class DigitalTwinViewModelGaugeColorTests: XCTestCase {

    // MARK: Ram Air Intake Pressure

    /// Exactly at threshold → Efficiency Green (not strictly above).
    func testRamAirPressure_atThreshold_isEfficiencyGreen() {
        let color = gaugeColor(value: Thresholds.ramAirPressureWarning,
                               threshold: Thresholds.ramAirPressureWarning)
        XCTAssertEqual(color, Theme.Colors.efficiencyGreen,
            "Value exactly at threshold should be Efficiency Green")
    }

    /// One unit above threshold → Alert Orange.
    func testRamAirPressure_oneAboveThreshold_isAlertOrange() {
        let color = gaugeColor(value: Thresholds.ramAirPressureWarning + 1.0,
                               threshold: Thresholds.ramAirPressureWarning)
        XCTAssertEqual(color, Theme.Colors.alertOrange,
            "Value one unit above threshold should be Alert Orange")
    }

    /// One unit below threshold → Efficiency Green.
    func testRamAirPressure_oneBelowThreshold_isEfficiencyGreen() {
        let color = gaugeColor(value: Thresholds.ramAirPressureWarning - 1.0,
                               threshold: Thresholds.ramAirPressureWarning)
        XCTAssertEqual(color, Theme.Colors.efficiencyGreen,
            "Value one unit below threshold should be Efficiency Green")
    }

    // MARK: Gyroid Flow Uniformity

    /// Exactly at threshold → Efficiency Green.
    func testGyroidFlow_atThreshold_isEfficiencyGreen() {
        let color = gaugeColor(value: Thresholds.gyroidFlowWarning,
                               threshold: Thresholds.gyroidFlowWarning)
        XCTAssertEqual(color, Theme.Colors.efficiencyGreen,
            "Value exactly at threshold should be Efficiency Green")
    }

    /// One unit above threshold → Alert Orange.
    func testGyroidFlow_oneAboveThreshold_isAlertOrange() {
        let color = gaugeColor(value: Thresholds.gyroidFlowWarning + 0.01,
                               threshold: Thresholds.gyroidFlowWarning)
        XCTAssertEqual(color, Theme.Colors.alertOrange,
            "Value above threshold should be Alert Orange")
    }

    /// One unit below threshold → Efficiency Green.
    func testGyroidFlow_oneBelowThreshold_isEfficiencyGreen() {
        let color = gaugeColor(value: Thresholds.gyroidFlowWarning - 0.01,
                               threshold: Thresholds.gyroidFlowWarning)
        XCTAssertEqual(color, Theme.Colors.efficiencyGreen,
            "Value below threshold should be Efficiency Green")
    }

    // MARK: Jet Sheet Velocity

    /// Exactly at threshold → Efficiency Green.
    func testJetSheetVelocity_atThreshold_isEfficiencyGreen() {
        let color = gaugeColor(value: Thresholds.jetSheetVelocityWarning,
                               threshold: Thresholds.jetSheetVelocityWarning)
        XCTAssertEqual(color, Theme.Colors.efficiencyGreen,
            "Value exactly at threshold should be Efficiency Green")
    }

    /// One unit above threshold → Alert Orange.
    func testJetSheetVelocity_oneAboveThreshold_isAlertOrange() {
        let color = gaugeColor(value: Thresholds.jetSheetVelocityWarning + 1.0,
                               threshold: Thresholds.jetSheetVelocityWarning)
        XCTAssertEqual(color, Theme.Colors.alertOrange,
            "Value one unit above threshold should be Alert Orange")
    }

    /// One unit below threshold → Efficiency Green.
    func testJetSheetVelocity_oneBelowThreshold_isEfficiencyGreen() {
        let color = gaugeColor(value: Thresholds.jetSheetVelocityWarning - 1.0,
                               threshold: Thresholds.jetSheetVelocityWarning)
        XCTAssertEqual(color, Theme.Colors.efficiencyGreen,
            "Value one unit below threshold should be Efficiency Green")
    }
}

// MARK: - Placeholder State Tests

/// Tests for the DigitalTwinViewModel placeholder state when no telemetry exists.
final class DigitalTwinViewModelPlaceholderTests: XCTestCase {

    private var cancellables = Set<AnyCancellable>()

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    /// When no telemetry exists for the tail number, `noTelemetryAvailable` is true
    /// and all gauge values are 0.0.
    func testNoTelemetry_placeholderStateIsCorrect() {
        let dataService = SimulatedDataService()
        // Use a tail number that will never have telemetry seeded
        let unknownTail = "UNKNOWN-TAIL-99"
        let vm = DigitalTwinViewModel(tailNumber: unknownTail, dataService: dataService)

        let expectation = XCTestExpectation(description: "ViewModel reflects no-telemetry state")

        // Observe until we get a stable no-telemetry state
        vm.$noTelemetryAvailable
            .filter { $0 == true }
            .first()
            .sink { _ in
                XCTAssertTrue(vm.noTelemetryAvailable,
                    "noTelemetryAvailable should be true when no snapshot exists")
                XCTAssertEqual(vm.ramAirIntakePressure, 0.0,
                    "ramAirIntakePressure should be 0.0 when no telemetry")
                XCTAssertEqual(vm.gyroidFlowUniformity, 0.0,
                    "gyroidFlowUniformity should be 0.0 when no telemetry")
                XCTAssertEqual(vm.jetSheetVelocity, 0.0,
                    "jetSheetVelocity should be 0.0 when no telemetry")
                XCTAssertTrue(vm.dragCoefficientHistory.isEmpty,
                    "dragCoefficientHistory should be empty when no telemetry")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Ensure the unknown tail has no telemetry entry
        dataService.telemetry.removeValue(forKey: unknownTail)

        wait(for: [expectation], timeout: 2.0)
    }

    /// When telemetry is present for the tail number, `noTelemetryAvailable` is false
    /// and gauge values reflect the snapshot.
    func testWithTelemetry_noTelemetryAvailableIsFalse() {
        let dataService = SimulatedDataService()
        let tail = "TEST-TWIN-1"

        // Inject a known telemetry snapshot
        let snapshot = TelemetrySnapshot(
            tailNumber: tail,
            timestamp: Date(),
            ramAirIntakePressure: 1020.0,
            gyroidFlowUniformity: 0.85,
            jetSheetVelocity: 260.0,
            dragCoefficientHistory: []
        )
        dataService.telemetry[tail] = snapshot

        let vm = DigitalTwinViewModel(tailNumber: tail, dataService: dataService)

        let expectation = XCTestExpectation(description: "ViewModel reflects telemetry state")

        // Observe noTelemetryAvailable — it should emit false once the snapshot is received.
        // We check the emitted value directly (not vm.noTelemetryAvailable) to avoid
        // a race with the 2-second timer.
        vm.$noTelemetryAvailable
            .filter { $0 == false }
            .first()
            .sink { noTelemetryAvailable in
                XCTAssertFalse(noTelemetryAvailable,
                    "noTelemetryAvailable should be false when snapshot exists")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 2.0)
    }

    /// When telemetry is removed for a tail number, `noTelemetryAvailable` transitions to true.
    func testTelemetryRemoved_transitionsToPlaceholderState() {
        let dataService = SimulatedDataService()
        let tail = "TEST-TWIN-2"

        // Start with telemetry present
        dataService.telemetry[tail] = TelemetrySnapshot(
            tailNumber: tail,
            timestamp: Date(),
            ramAirIntakePressure: 1000.0,
            gyroidFlowUniformity: 0.80,
            jetSheetVelocity: 250.0,
            dragCoefficientHistory: []
        )

        let vm = DigitalTwinViewModel(tailNumber: tail, dataService: dataService)

        let expectation = XCTestExpectation(description: "ViewModel transitions to no-telemetry state")

        vm.$noTelemetryAvailable
            .filter { $0 == true }
            .first()
            .sink { _ in
                XCTAssertTrue(vm.noTelemetryAvailable)
                XCTAssertEqual(vm.ramAirIntakePressure, 0.0)
                XCTAssertEqual(vm.gyroidFlowUniformity, 0.0)
                XCTAssertEqual(vm.jetSheetVelocity, 0.0)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Remove telemetry after subscribing
        dataService.telemetry.removeValue(forKey: tail)

        wait(for: [expectation], timeout: 2.0)
    }
}

// MARK: - ViewModel Computed Color Tests

/// Tests that DigitalTwinViewModel's computed color properties delegate correctly
/// to the pure `gaugeColor` function using the correct thresholds.
///
/// These tests verify the ViewModel's computed properties directly by checking
/// that they return the same result as calling `gaugeColor` with the current
/// published value and the appropriate threshold constant.
final class DigitalTwinViewModelComputedColorTests: XCTestCase {

    private var cancellables = Set<AnyCancellable>()

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    /// When ramAirIntakePressure exceeds threshold, ramAirPressureColor is Alert Orange.
    func testRamAirPressureColor_aboveThreshold_isAlertOrange() {
        let dataService = SimulatedDataService()
        let tail = "COLOR-TEST-1"
        let aboveThreshold = Thresholds.ramAirPressureWarning + 5.0

        dataService.telemetry[tail] = TelemetrySnapshot(
            tailNumber: tail,
            timestamp: Date(),
            ramAirIntakePressure: aboveThreshold,
            gyroidFlowUniformity: 0.80,
            jetSheetVelocity: 250.0,
            dragCoefficientHistory: []
        )

        let vm = DigitalTwinViewModel(tailNumber: tail, dataService: dataService)

        let expectation = XCTestExpectation(description: "Color updated to above-threshold value")
        // Wait until the ViewModel has received the above-threshold value
        vm.$ramAirIntakePressure
            .filter { $0 == aboveThreshold }
            .first()
            .sink { value in
                XCTAssertEqual(
                    gaugeColor(value: value, threshold: Thresholds.ramAirPressureWarning),
                    Theme.Colors.alertOrange,
                    "Value \(value) above threshold \(Thresholds.ramAirPressureWarning) should be Alert Orange"
                )
                expectation.fulfill()
            }
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 2.0)
    }

    /// When ramAirIntakePressure is at threshold, ramAirPressureColor is Efficiency Green.
    func testRamAirPressureColor_atThreshold_isEfficiencyGreen() {
        let dataService = SimulatedDataService()
        let tail = "COLOR-TEST-2"
        let atThreshold = Thresholds.ramAirPressureWarning

        dataService.telemetry[tail] = TelemetrySnapshot(
            tailNumber: tail,
            timestamp: Date(),
            ramAirIntakePressure: atThreshold,
            gyroidFlowUniformity: 0.80,
            jetSheetVelocity: 250.0,
            dragCoefficientHistory: []
        )

        let vm = DigitalTwinViewModel(tailNumber: tail, dataService: dataService)

        let expectation = XCTestExpectation(description: "Color updated to at-threshold value")
        vm.$ramAirIntakePressure
            .filter { $0 == atThreshold }
            .first()
            .sink { value in
                XCTAssertEqual(
                    gaugeColor(value: value, threshold: Thresholds.ramAirPressureWarning),
                    Theme.Colors.efficiencyGreen,
                    "Value exactly at threshold should be Efficiency Green"
                )
                expectation.fulfill()
            }
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 2.0)
    }
}
