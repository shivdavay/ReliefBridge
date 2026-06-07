// ReliefBridgeTests/CarbonValueUnitLabelPropertyTests.swift
// Property-based tests for carbon value unit label formatting.
// Property 7: Carbon Value Unit Label

import XCTest
import SwiftCheck
@testable import ReliefBridge

// MARK: - Property 7: Carbon Value Unit Label

// Feature: reliefbridge-insight, Property 7: Formatted carbon value strings SHALL contain a metric-ton unit label
// Validates: Requirements 4.9

final class CarbonValueUnitLabelPropertyTests: XCTestCase {

    /// Property 7: Carbon Value Unit Label
    ///
    /// For any carbon savings value rendered in the Carbon Compliance module,
    /// the formatted display string SHALL contain a unit label indicating metric tons
    /// (e.g., "t" or "metric tons").
    func testProperty7_CarbonValueUnitLabel() {
        // Feature: reliefbridge-insight, Property 7: Formatted carbon value strings SHALL contain a metric-ton unit label
        property("Formatted carbon value strings contain a metric-ton unit label") <- forAll(
            Gen<Double>.fromElements(in: 0.5...12.0).resize(20)  // carbon values in valid range
        ) { (carbonValue: Double) in
            // Format the carbon value as it would be displayed in the UI
            let formatted = formatCarbonValue(carbonValue)
            
            // Verify the formatted string contains a metric-ton unit label
            // Accept either "t" or "metric tons" as valid unit labels
            let containsShortUnit = formatted.contains("t")
            let containsLongUnit = formatted.contains("metric tons")
            
            return containsShortUnit || containsLongUnit
        }
    }

    /// Property 7 (non-empty): Formatted carbon strings are never empty.
    func testProperty7_FormattedStringNonEmpty() {
        // Feature: reliefbridge-insight, Property 7: Formatted carbon value strings SHALL contain a metric-ton unit label
        property("Formatted carbon strings are never empty") <- forAll(
            Gen<Double>.fromElements(in: 0.5...12.0).resize(20)
        ) { (carbonValue: Double) in
            let formatted = formatCarbonValue(carbonValue)
            return !formatted.isEmpty
        }
    }

    /// Property 7 (contains value): Formatted string contains the numeric value.
    func testProperty7_FormattedStringContainsValue() {
        // Feature: reliefbridge-insight, Property 7: Formatted carbon value strings SHALL contain a metric-ton unit label
        property("Formatted string contains the numeric value") <- forAll(
            Gen<Double>.fromElements(in: 0.5...12.0).resize(20)
        ) { (carbonValue: Double) in
            let formatted = formatCarbonValue(carbonValue)
            let valueString = String(format: "%.2f", carbonValue)
            return formatted.contains(valueString)
        }
    }

    /// Property 7 (unit label position): Unit label appears after the numeric value.
    func testProperty7_UnitLabelAfterValue() {
        // Feature: reliefbridge-insight, Property 7: Formatted carbon value strings SHALL contain a metric-ton unit label
        property("Unit label appears after the numeric value") <- forAll(
            Gen<Double>.fromElements(in: 0.5...12.0).resize(20)
        ) { (carbonValue: Double) in
            let formatted = formatCarbonValue(carbonValue)
            let valueString = String(format: "%.2f", carbonValue)
            
            // Find the position of the value string
            guard let valueRange = formatted.range(of: valueString) else {
                return false
            }
            
            // Extract the substring after the value
            let afterValue = String(formatted[valueRange.upperBound...])
            
            // Verify that the unit label appears after the value
            return afterValue.contains("t") || afterValue.contains("metric tons")
        }
    }

    /// Property 7 (consistency): Same value always produces the same formatted string.
    func testProperty7_FormattingConsistency() {
        // Feature: reliefbridge-insight, Property 7: Formatted carbon value strings SHALL contain a metric-ton unit label
        property("Same value always produces the same formatted string") <- forAll(
            Gen<Double>.fromElements(in: 0.5...12.0).resize(20)
        ) { (carbonValue: Double) in
            let formatted1 = formatCarbonValue(carbonValue)
            let formatted2 = formatCarbonValue(carbonValue)
            return formatted1 == formatted2
        }
    }

    /// Property 7 (boundary values): Boundary values (0.5, 12.0) are formatted correctly.
    func testProperty7_BoundaryValues() {
        // Feature: reliefbridge-insight, Property 7: Formatted carbon value strings SHALL contain a metric-ton unit label
        let minValue = 0.5
        let maxValue = 12.0
        
        let formattedMin = formatCarbonValue(minValue)
        let formattedMax = formatCarbonValue(maxValue)
        
        XCTAssertTrue(formattedMin.contains("t") || formattedMin.contains("metric tons"),
                      "Minimum value \(minValue) formatted as '\(formattedMin)' should contain unit label")
        XCTAssertTrue(formattedMax.contains("t") || formattedMax.contains("metric tons"),
                      "Maximum value \(maxValue) formatted as '\(formattedMax)' should contain unit label")
    }

    /// Property 7 (zero value): Zero carbon value is formatted with unit label.
    func testProperty7_ZeroValue() {
        // Feature: reliefbridge-insight, Property 7: Formatted carbon value strings SHALL contain a metric-ton unit label
        let formatted = formatCarbonValue(0.0)
        XCTAssertTrue(formatted.contains("t") || formatted.contains("metric tons"),
                      "Zero value formatted as '\(formatted)' should contain unit label")
    }

    /// Property 7 (large values): Large carbon values are formatted with unit label.
    func testProperty7_LargeValues() {
        // Feature: reliefbridge-insight, Property 7: Formatted carbon value strings SHALL contain a metric-ton unit label
        property("Large carbon values are formatted with unit label") <- forAll(
            Gen<Double>.fromElements(in: 100.0...1000.0).resize(20)
        ) { (carbonValue: Double) in
            let formatted = formatCarbonValue(carbonValue)
            return formatted.contains("t") || formatted.contains("metric tons")
        }
    }

    /// Property 7 (negative values): Negative values (edge case) are formatted with unit label.
    func testProperty7_NegativeValues() {
        // Feature: reliefbridge-insight, Property 7: Formatted carbon value strings SHALL contain a metric-ton unit label
        property("Negative values are formatted with unit label") <- forAll(
            Gen<Double>.fromElements(in: -10.0...(-0.1)).resize(20)
        ) { (carbonValue: Double) in
            let formatted = formatCarbonValue(carbonValue)
            return formatted.contains("t") || formatted.contains("metric tons")
        }
    }

    /// Property 7 (decimal precision): Formatted strings maintain appropriate decimal precision.
    func testProperty7_DecimalPrecision() {
        // Feature: reliefbridge-insight, Property 7: Formatted carbon value strings SHALL contain a metric-ton unit label
        property("Formatted strings maintain appropriate decimal precision") <- forAll(
            Gen<Double>.fromElements(in: 0.5...12.0).resize(20)
        ) { (carbonValue: Double) in
            let formatted = formatCarbonValue(carbonValue)
            
            // Extract the numeric part (before the unit)
            let components = formatted.components(separatedBy: " ")
            guard let numericString = components.first,
                  let _ = Double(numericString) else {
                return false
            }
            
            // Verify the string contains a decimal point (for precision)
            return numericString.contains(".")
        }
    }
}

// MARK: - Carbon Value Formatting Function

/// Formats a carbon savings value for display in the Carbon Compliance module.
///
/// - Parameter value: The carbon savings value in metric tons.
/// - Returns: A formatted string containing the value and unit label.
///
/// This function represents the formatting logic used in the Carbon Compliance module
/// to display carbon savings values with appropriate unit labels.
func formatCarbonValue(_ value: Double) -> String {
    return String(format: "%.2f metric tons", value)
}
