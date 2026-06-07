// ReliefBridgeTests/DigitalTwinViewIntegrationTests.swift
// Integration tests for DigitalTwinView gauge color updates.
// Validates: Requirements 3.8

import XCTest
import Combine
import SwiftUI
@testable import ReliefBridge

/// Integration tests for DigitalTwinView gauge color updates.
///
/// These tests verify that when telemetry values cross warning thresholds,
/// the DigitalTwinViewModel's computed color properties update correctly,
/// and the view reflects those color changes.
///
/// The tests pre-seed the SimulatedDataService with specific telemetry values
/// that are above, at, or below thresholds, then verify the ViewModel's
/// computed color properties return the correct colors.
final class DigitalTwinViewIntegrationTests: XCTestCase {

    private var cancellables = Set<AnyCancellable>()

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    // MARK: - Ram Air Intake Pressure

    /// When ramAirIntakePressure is seeded above threshold, ramAirPressureColor is Alert Orange.
    func testRamAirPressure_aboveThreshold_gaugeColorIsAlertOrange() {
        let dataService = SimulatedDataService()
        let tail = "INTEGRATION-TEST-1"
        let aboveThreshold = Thresholds.ramAirPressureWarning + 10.0

        let viewModel = DigitalTwinViewModel(tailNumber: tail, dataService: dataService)

        let expectation = XCTestExpectation(description: "ViewModel receives above-threshold value")

        // Wait for the ViewModel to receive the telemetry update with the expected value
        viewModel.$ramAirIntakePressure
            .filter { $0 == aboveThreshold }
            .first()
            .sink { value in
                // Defer the check to ensure the ViewModel has finished processing
                DispatchQueue.main.async {
                    // Verify the computed color property returns Alert Orange
                    XCTAssertEqual(
                        viewModel.ramAirPressureColor,
                        Theme.Colors.alertOrange,
                        "ramAirPressureColor should be Alert Orange when value (\(value)) exceeds threshold (\(Thresholds.ramAirPressureWarning))"
                    )
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // Pre-seed telemetry with value above threshold AFTER subscribing
        // Force the publisher to emit by reassigning the entire dictionary
        var updatedTelemetry = dataService.telemetry
        updatedTelemetry[tail] = TelemetrySnapshot(
            tailNumber: tail,
            timestamp: Date(),
            ramAirIntakePressure: aboveThreshold,
            gyroidFlowUniformity: 0.80,
            jetSheetVelocity: 250.0,
            dragCoefficientHistory: []
        )
        dataService.telemetry = updatedTelemetry

        wait(for: [expectation], timeout: 2.0)
    }

    /// When ramAirIntakePressure is seeded below threshold, ramAirPressureColor is Efficiency Green.
    func testRamAirPressure_belowThreshold_gaugeColorIsEfficiencyGreen() {
        let dataService = SimulatedDataService()
        let tail = "INTEGRATION-TEST-2"
        let belowThreshold = Thresholds.ramAirPressureWarning - 10.0

        let viewModel = DigitalTwinViewModel(tailNumber: tail, dataService: dataService)

        let expectation = XCTestExpectation(description: "ViewModel receives below-threshold value")

        viewModel.$ramAirIntakePressure
            .filter { $0 == belowThreshold }
            .first()
            .sink { value in
                XCTAssertEqual(
                    viewModel.ramAirPressureColor,
                    Theme.Colors.efficiencyGreen,
                    "ramAirPressureColor should be Efficiency Green when value (\(value)) is below threshold (\(Thresholds.ramAirPressureWarning))"
                )
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Pre-seed telemetry with value below threshold AFTER subscribing
        var updatedTelemetry = dataService.telemetry
        updatedTelemetry[tail] = TelemetrySnapshot(
            tailNumber: tail,
            timestamp: Date(),
            ramAirIntakePressure: belowThreshold,
            gyroidFlowUniformity: 0.80,
            jetSheetVelocity: 250.0,
            dragCoefficientHistory: []
        )
        dataService.telemetry = updatedTelemetry

        wait(for: [expectation], timeout: 2.0)
    }

    /// When ramAirIntakePressure crosses from below to above threshold, color transitions to Alert Orange.
    func testRamAirPressure_crossingThreshold_colorTransitionsToAlertOrange() {
        let dataService = SimulatedDataService()
        let tail = "INTEGRATION-TEST-3"
        let belowThreshold = Thresholds.ramAirPressureWarning - 5.0
        let aboveThreshold = Thresholds.ramAirPressureWarning + 5.0

        let viewModel = DigitalTwinViewModel(tailNumber: tail, dataService: dataService)

        let expectation = XCTestExpectation(description: "Color transitions when crossing threshold")

        // First, verify initial color is Efficiency Green
        viewModel.$ramAirIntakePressure
            .filter { $0 == belowThreshold }
            .first()
            .sink { value in
                XCTAssertEqual(
                    viewModel.ramAirPressureColor,
                    Theme.Colors.efficiencyGreen,
                    "Initial color should be Efficiency Green"
                )

                // Now update telemetry to cross threshold
                var updatedTelemetry = dataService.telemetry
                updatedTelemetry[tail] = TelemetrySnapshot(
                    tailNumber: tail,
                    timestamp: Date(),
                    ramAirIntakePressure: aboveThreshold,
                    gyroidFlowUniformity: 0.80,
                    jetSheetVelocity: 250.0,
                    dragCoefficientHistory: []
                )
                dataService.telemetry = updatedTelemetry
            }
            .store(in: &cancellables)

        // Then verify color transitions to Alert Orange
        viewModel.$ramAirIntakePressure
            .filter { $0 == aboveThreshold }
            .first()
            .sink { value in
                DispatchQueue.main.async {
                    XCTAssertEqual(
                        viewModel.ramAirPressureColor,
                        Theme.Colors.alertOrange,
                        "Color should transition to Alert Orange after crossing threshold (value: \(value))"
                    )
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // Start with value below threshold
        var initialTelemetry = dataService.telemetry
        initialTelemetry[tail] = TelemetrySnapshot(
            tailNumber: tail,
            timestamp: Date(),
            ramAirIntakePressure: belowThreshold,
            gyroidFlowUniformity: 0.80,
            jetSheetVelocity: 250.0,
            dragCoefficientHistory: []
        )
        dataService.telemetry = initialTelemetry

        wait(for: [expectation], timeout: 3.0)
    }

    // MARK: - Gyroid Flow Uniformity

    /// When gyroidFlowUniformity is seeded above threshold, gyroidFlowColor is Alert Orange.
    func testGyroidFlow_aboveThreshold_gaugeColorIsAlertOrange() {
        let dataService = SimulatedDataService()
        let tail = "INTEGRATION-TEST-4"
        let aboveThreshold = Thresholds.gyroidFlowWarning + 0.05

        let viewModel = DigitalTwinViewModel(tailNumber: tail, dataService: dataService)

        let expectation = XCTestExpectation(description: "ViewModel receives above-threshold gyroid flow")

        viewModel.$gyroidFlowUniformity
            .filter { $0 == aboveThreshold }
            .first()
            .sink { value in
                DispatchQueue.main.async {
                    XCTAssertEqual(
                        viewModel.gyroidFlowColor,
                        Theme.Colors.alertOrange,
                        "gyroidFlowColor should be Alert Orange when value (\(value)) exceeds threshold (\(Thresholds.gyroidFlowWarning))"
                    )
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        var updatedTelemetry = dataService.telemetry
        updatedTelemetry[tail] = TelemetrySnapshot(
            tailNumber: tail,
            timestamp: Date(),
            ramAirIntakePressure: 1000.0,
            gyroidFlowUniformity: aboveThreshold,
            jetSheetVelocity: 250.0,
            dragCoefficientHistory: []
        )
        dataService.telemetry = updatedTelemetry

        wait(for: [expectation], timeout: 2.0)
    }

    /// When gyroidFlowUniformity is seeded below threshold, gyroidFlowColor is Efficiency Green.
    func testGyroidFlow_belowThreshold_gaugeColorIsEfficiencyGreen() {
        let dataService = SimulatedDataService()
        let tail = "INTEGRATION-TEST-5"
        let belowThreshold = Thresholds.gyroidFlowWarning - 0.05

        let viewModel = DigitalTwinViewModel(tailNumber: tail, dataService: dataService)

        let expectation = XCTestExpectation(description: "ViewModel receives below-threshold gyroid flow")

        viewModel.$gyroidFlowUniformity
            .filter { $0 == belowThreshold }
            .first()
            .sink { value in
                XCTAssertEqual(
                    viewModel.gyroidFlowColor,
                    Theme.Colors.efficiencyGreen,
                    "gyroidFlowColor should be Efficiency Green when value (\(value)) is below threshold (\(Thresholds.gyroidFlowWarning))"
                )
                expectation.fulfill()
            }
            .store(in: &cancellables)

        var updatedTelemetry = dataService.telemetry
        updatedTelemetry[tail] = TelemetrySnapshot(
            tailNumber: tail,
            timestamp: Date(),
            ramAirIntakePressure: 1000.0,
            gyroidFlowUniformity: belowThreshold,
            jetSheetVelocity: 250.0,
            dragCoefficientHistory: []
        )
        dataService.telemetry = updatedTelemetry

        wait(for: [expectation], timeout: 2.0)
    }

    // MARK: - Jet Sheet Velocity

    /// When jetSheetVelocity is seeded above threshold, jetSheetVelocityColor is Alert Orange.
    func testJetSheetVelocity_aboveThreshold_gaugeColorIsAlertOrange() {
        let dataService = SimulatedDataService()
        let tail = "INTEGRATION-TEST-6"
        let aboveThreshold = Thresholds.jetSheetVelocityWarning + 10.0

        let viewModel = DigitalTwinViewModel(tailNumber: tail, dataService: dataService)

        let expectation = XCTestExpectation(description: "ViewModel receives above-threshold jet sheet velocity")

        viewModel.$jetSheetVelocity
            .filter { $0 == aboveThreshold }
            .first()
            .sink { value in
                DispatchQueue.main.async {
                    XCTAssertEqual(
                        viewModel.jetSheetVelocityColor,
                        Theme.Colors.alertOrange,
                        "jetSheetVelocityColor should be Alert Orange when value (\(value)) exceeds threshold (\(Thresholds.jetSheetVelocityWarning))"
                    )
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        var updatedTelemetry = dataService.telemetry
        updatedTelemetry[tail] = TelemetrySnapshot(
            tailNumber: tail,
            timestamp: Date(),
            ramAirIntakePressure: 1000.0,
            gyroidFlowUniformity: 0.80,
            jetSheetVelocity: aboveThreshold,
            dragCoefficientHistory: []
        )
        dataService.telemetry = updatedTelemetry

        wait(for: [expectation], timeout: 2.0)
    }

    /// When jetSheetVelocity is seeded below threshold, jetSheetVelocityColor is Efficiency Green.
    func testJetSheetVelocity_belowThreshold_gaugeColorIsEfficiencyGreen() {
        let dataService = SimulatedDataService()
        let tail = "INTEGRATION-TEST-7"
        let belowThreshold = Thresholds.jetSheetVelocityWarning - 10.0

        let viewModel = DigitalTwinViewModel(tailNumber: tail, dataService: dataService)

        let expectation = XCTestExpectation(description: "ViewModel receives below-threshold jet sheet velocity")

        viewModel.$jetSheetVelocity
            .filter { $0 == belowThreshold }
            .first()
            .sink { value in
                XCTAssertEqual(
                    viewModel.jetSheetVelocityColor,
                    Theme.Colors.efficiencyGreen,
                    "jetSheetVelocityColor should be Efficiency Green when value (\(value)) is below threshold (\(Thresholds.jetSheetVelocityWarning))"
                )
                expectation.fulfill()
            }
            .store(in: &cancellables)

        var updatedTelemetry = dataService.telemetry
        updatedTelemetry[tail] = TelemetrySnapshot(
            tailNumber: tail,
            timestamp: Date(),
            ramAirIntakePressure: 1000.0,
            gyroidFlowUniformity: 0.80,
            jetSheetVelocity: belowThreshold,
            dragCoefficientHistory: []
        )
        dataService.telemetry = updatedTelemetry

        wait(for: [expectation], timeout: 2.0)
    }

    // MARK: - Multiple Gauges Crossing Thresholds

    /// When multiple telemetry values cross thresholds simultaneously, all gauge colors update correctly.
    func testMultipleGauges_crossingThresholds_allColorsUpdateCorrectly() {
        let dataService = SimulatedDataService()
        let tail = "INTEGRATION-TEST-8"

        let viewModel = DigitalTwinViewModel(tailNumber: tail, dataService: dataService)

        let expectation = XCTestExpectation(description: "All gauge colors update when crossing thresholds")

        // Wait for initial values to be received
        viewModel.$noTelemetryAvailable
            .filter { $0 == false }
            .first()
            .sink { _ in
                // Verify all colors are initially Efficiency Green
                XCTAssertEqual(viewModel.ramAirPressureColor, Theme.Colors.efficiencyGreen,
                    "Initial ramAirPressureColor should be Efficiency Green")
                XCTAssertEqual(viewModel.gyroidFlowColor, Theme.Colors.efficiencyGreen,
                    "Initial gyroidFlowColor should be Efficiency Green")
                XCTAssertEqual(viewModel.jetSheetVelocityColor, Theme.Colors.efficiencyGreen,
                    "Initial jetSheetVelocityColor should be Efficiency Green")

                // Now update all values to cross thresholds
                var updatedTelemetry = dataService.telemetry
                updatedTelemetry[tail] = TelemetrySnapshot(
                    tailNumber: tail,
                    timestamp: Date(),
                    ramAirIntakePressure: Thresholds.ramAirPressureWarning + 10.0,
                    gyroidFlowUniformity: Thresholds.gyroidFlowWarning + 0.05,
                    jetSheetVelocity: Thresholds.jetSheetVelocityWarning + 10.0,
                    dragCoefficientHistory: []
                )
                dataService.telemetry = updatedTelemetry
            }
            .store(in: &cancellables)

        // Wait for updated values and verify all colors are now Alert Orange
        viewModel.$ramAirIntakePressure
            .filter { $0 > Thresholds.ramAirPressureWarning }
            .first()
            .sink { _ in
                DispatchQueue.main.async {
                    XCTAssertEqual(viewModel.ramAirPressureColor, Theme.Colors.alertOrange,
                        "ramAirPressureColor should be Alert Orange after crossing threshold")
                    XCTAssertEqual(viewModel.gyroidFlowColor, Theme.Colors.alertOrange,
                        "gyroidFlowColor should be Alert Orange after crossing threshold")
                    XCTAssertEqual(viewModel.jetSheetVelocityColor, Theme.Colors.alertOrange,
                        "jetSheetVelocityColor should be Alert Orange after crossing threshold")
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // Start with all values below thresholds
        var initialTelemetry = dataService.telemetry
        initialTelemetry[tail] = TelemetrySnapshot(
            tailNumber: tail,
            timestamp: Date(),
            ramAirIntakePressure: Thresholds.ramAirPressureWarning - 10.0,
            gyroidFlowUniformity: Thresholds.gyroidFlowWarning - 0.05,
            jetSheetVelocity: Thresholds.jetSheetVelocityWarning - 10.0,
            dragCoefficientHistory: []
        )
        dataService.telemetry = initialTelemetry

        wait(for: [expectation], timeout: 3.0)
    }

    // MARK: - Boundary Value Tests

    /// When ramAirIntakePressure is exactly at threshold, color is Efficiency Green (not strictly above).
    func testRamAirPressure_exactlyAtThreshold_gaugeColorIsEfficiencyGreen() {
        let dataService = SimulatedDataService()
        let tail = "INTEGRATION-TEST-9"
        let atThreshold = Thresholds.ramAirPressureWarning

        let viewModel = DigitalTwinViewModel(tailNumber: tail, dataService: dataService)

        let expectation = XCTestExpectation(description: "ViewModel receives at-threshold value")

        viewModel.$ramAirIntakePressure
            .filter { $0 == atThreshold }
            .first()
            .sink { value in
                XCTAssertEqual(
                    viewModel.ramAirPressureColor,
                    Theme.Colors.efficiencyGreen,
                    "ramAirPressureColor should be Efficiency Green when value is exactly at threshold (not strictly above)"
                )
                expectation.fulfill()
            }
            .store(in: &cancellables)

        var updatedTelemetry = dataService.telemetry
        updatedTelemetry[tail] = TelemetrySnapshot(
            tailNumber: tail,
            timestamp: Date(),
            ramAirIntakePressure: atThreshold,
            gyroidFlowUniformity: 0.80,
            jetSheetVelocity: 250.0,
            dragCoefficientHistory: []
        )
        dataService.telemetry = updatedTelemetry

        wait(for: [expectation], timeout: 2.0)
    }
}
