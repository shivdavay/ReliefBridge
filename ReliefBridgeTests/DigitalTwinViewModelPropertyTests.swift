// ReliefBridgeTests/DigitalTwinViewModelPropertyTests.swift
// Property-based tests for DigitalTwinViewModel — Property 4.
// Feature: reliefbridge-insight, Property 4: Gauge color SHALL be Alert Orange iff value strictly exceeds threshold
// Validates: Requirements 3.8, 2.7

import XCTest
import SwiftCheck
@testable import ReliefBridge

// MARK: - Property 4: Telemetry Threshold Color Mapping

/// Property 4: Telemetry Threshold Color Mapping
///
/// For any telemetry gauge value and its defined warning threshold, the gauge
/// indicator color SHALL be Alert Orange (`#FF5722`) if and only if the value
/// strictly exceeds the threshold, and Efficiency Green (`#00FF87`) otherwise.
///
/// This property is tested against the pure `gaugeColor(value:threshold:)` function
/// extracted from `DigitalTwinViewModel` for direct, Combine-free testability.
final class TelemetryThresholdColorPropertyTests: XCTestCase {

    // MARK: - Property 4: Core Biconditional

    /// Property 4: `gaugeColor` returns Alert Orange iff `value > threshold`.
    ///
    /// Runs 100+ iterations over randomly generated (value, threshold) pairs.
    func testProperty4_GaugeColorIsAlertOrangeIffValueExceedsThreshold() {
        // Feature: reliefbridge-insight, Property 4: Gauge color SHALL be Alert Orange iff value strictly exceeds threshold
        property("Gauge color is Alert Orange iff value strictly exceeds threshold") <- forAll(
            Double.arbitrary.resize(20),
            Double.arbitrary.resize(20)
        ) { (value: Double, threshold: Double) in
            // Skip NaN / infinity — not valid sensor readings
            guard value.isFinite, threshold.isFinite else { return true }

            let color = gaugeColor(value: value, threshold: threshold)

            if value > threshold {
                return color == Theme.Colors.alertOrange
            } else {
                return color == Theme.Colors.efficiencyGreen
            }
        }
    }

    // MARK: - Property 4: Strict Inequality (at-threshold is Green)

    /// Property 4 (boundary): When `value == threshold`, color is Efficiency Green (not Alert Orange).
    ///
    /// This verifies the strict `>` inequality — equality does NOT trigger the alert.
    func testProperty4_AtThreshold_IsEfficiencyGreen() {
        // Feature: reliefbridge-insight, Property 4: Gauge color SHALL be Alert Orange iff value strictly exceeds threshold
        property("Color at exactly the threshold is Efficiency Green") <- forAll(
            Double.arbitrary.suchThat { $0.isFinite }.resize(20)
        ) { (threshold: Double) in
            let color = gaugeColor(value: threshold, threshold: threshold)
            return color == Theme.Colors.efficiencyGreen
        }
    }

    // MARK: - Property 4: Complementary (below threshold is always Green)

    /// Property 4 (complement): When `value < threshold`, color is always Efficiency Green.
    func testProperty4_BelowThreshold_IsAlwaysEfficiencyGreen() {
        // Feature: reliefbridge-insight, Property 4: Gauge color SHALL be Alert Orange iff value strictly exceeds threshold
        property("Color below threshold is always Efficiency Green") <- forAll(
            Double.arbitrary.suchThat { $0.isFinite }.resize(20),
            Double.arbitrary.suchThat { $0.isFinite }.resize(20)
        ) { (a: Double, b: Double) in
            // Construct a pair where value < threshold
            let (value, threshold) = a < b ? (a, b) : (b + 1.0, b + 2.0)
            guard value < threshold else { return true }
            let color = gaugeColor(value: value, threshold: threshold)
            return color == Theme.Colors.efficiencyGreen
        }
    }

    // MARK: - Property 4: Above threshold is always Alert Orange

    /// Property 4 (above): When `value > threshold`, color is always Alert Orange.
    func testProperty4_AboveThreshold_IsAlwaysAlertOrange() {
        // Feature: reliefbridge-insight, Property 4: Gauge color SHALL be Alert Orange iff value strictly exceeds threshold
        property("Color above threshold is always Alert Orange") <- forAll(
            Double.arbitrary.suchThat { $0.isFinite }.resize(20),
            Double.arbitrary.suchThat { $0.isFinite }.resize(20)
        ) { (a: Double, b: Double) in
            // Construct a pair where value > threshold
            let (value, threshold) = a > b ? (a, b) : (b + 2.0, b + 1.0)
            guard value > threshold else { return true }
            let color = gaugeColor(value: value, threshold: threshold)
            return color == Theme.Colors.alertOrange
        }
    }

    // MARK: - Property 4: Exactly two possible colors

    /// Property 4 (exhaustive): The result is always one of exactly two colors.
    func testProperty4_ResultIsAlwaysOneOfTwoColors() {
        // Feature: reliefbridge-insight, Property 4: Gauge color SHALL be Alert Orange iff value strictly exceeds threshold
        property("Gauge color is always either Alert Orange or Efficiency Green") <- forAll(
            Double.arbitrary.suchThat { $0.isFinite }.resize(20),
            Double.arbitrary.suchThat { $0.isFinite }.resize(20)
        ) { (value: Double, threshold: Double) in
            let color = gaugeColor(value: value, threshold: threshold)
            return color == Theme.Colors.alertOrange || color == Theme.Colors.efficiencyGreen
        }
    }

    // MARK: - Property 4: Real-world threshold ranges

    /// Property 4 (realistic): Verify with values in realistic sensor ranges for all three gauges.
    func testProperty4_RealisticSensorRanges() {
        // Feature: reliefbridge-insight, Property 4: Gauge color SHALL be Alert Orange iff value strictly exceeds threshold
        // Ram Air Intake Pressure: 950–1100 hPa, threshold 1050
        property("Ram Air Pressure color mapping is correct in realistic range") <- forAll(
            Gen<Double>.fromElements(in: 950.0...1100.0).resize(20)
        ) { (pressure: Double) in
            let color = gaugeColor(value: pressure, threshold: Thresholds.ramAirPressureWarning)
            return pressure > Thresholds.ramAirPressureWarning
                ? color == Theme.Colors.alertOrange
                : color == Theme.Colors.efficiencyGreen
        }

        // Gyroid Flow Uniformity: 0.60–1.0, threshold 0.70
        property("Gyroid Flow Uniformity color mapping is correct in realistic range") <- forAll(
            Gen<Double>.fromElements(in: 0.60...1.0).resize(20)
        ) { (uniformity: Double) in
            let color = gaugeColor(value: uniformity, threshold: Thresholds.gyroidFlowWarning)
            return uniformity > Thresholds.gyroidFlowWarning
                ? color == Theme.Colors.alertOrange
                : color == Theme.Colors.efficiencyGreen
        }

        // Jet Sheet Velocity: 200–320 m/s, threshold 280
        property("Jet Sheet Velocity color mapping is correct in realistic range") <- forAll(
            Gen<Double>.fromElements(in: 200.0...320.0).resize(20)
        ) { (velocity: Double) in
            let color = gaugeColor(value: velocity, threshold: Thresholds.jetSheetVelocityWarning)
            return velocity > Thresholds.jetSheetVelocityWarning
                ? color == Theme.Colors.alertOrange
                : color == Theme.Colors.efficiencyGreen
        }
    }
}
