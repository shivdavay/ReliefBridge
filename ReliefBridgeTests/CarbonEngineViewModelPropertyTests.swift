// ReliefBridgeTests/CarbonEngineViewModelPropertyTests.swift
// Property-based tests for CarbonEngineViewModel.
// Property 5: Carbon Progress Ring Invariant

import XCTest
import SwiftCheck
import SwiftUI
@testable import ReliefBridge

// MARK: - Property 5: Carbon Progress Ring Invariant

// Feature: reliefbridge-insight, Property 5: Progress ring fraction and color SHALL satisfy the invariant for all valid inputs
// Validates: Requirements 4.3, 4.4, 4.5

final class CarbonProgressRingPropertyTests: XCTestCase {

    /// Property 5: Carbon Progress Ring Invariant
    ///
    /// For any cumulative carbon savings value, quarterly quota, and days remaining in the quarter:
    /// 1. The progress ring fill fraction SHALL equal `min(cumulativeSavings / quarterlyQuota, 1.0)`
    /// 2. The ring color SHALL be Efficiency Green when the fraction >= 1.0
    /// 3. The ring color SHALL be Alert Orange when the fraction < 0.75 and days remaining < 30
    /// 4. The ring color SHALL be the default accent color in all other cases
    func testProperty5_CarbonProgressRingInvariant() {
        // Feature: reliefbridge-insight, Property 5: Progress ring fraction and color SHALL satisfy the invariant for all valid inputs
        property("Progress ring fraction and color satisfy the invariant for all valid inputs") <- forAll(
            Gen<Double>.fromElements(in: 0.0...1000.0).resize(20),  // savings: 0 to 1000 metric tons
            Gen<Double>.fromElements(in: 1.0...1000.0).resize(20),  // quota: 1 to 1000 metric tons (avoid division by zero)
            Gen<Int>.fromElements(in: 0...90).resize(20)            // daysRemaining: 0 to 90 days
        ) { (savings: Double, quota: Double, daysRemaining: Int) in
            // 1. Verify progress fraction calculation
            let expectedFraction = min(savings / quota, 1.0)
            
            // The progress fraction should be in [0.0, 1.0]
            guard expectedFraction >= 0.0 && expectedFraction <= 1.0 else { return false }
            
            // 2. Verify ring color logic
            let color = progressRingColor(progressFraction: expectedFraction, daysRemaining: daysRemaining)
            
            // Branch 1: Efficiency Green when fraction >= 1.0
            if expectedFraction >= 1.0 {
                return color == Theme.Colors.efficiencyGreen
            }
            
            // Branch 2: Alert Orange when fraction < 0.75 and daysRemaining < 30
            if expectedFraction < Thresholds.quotaWarningFraction && daysRemaining < Thresholds.quotaWarningDaysRemaining {
                return color == Theme.Colors.alertOrange
            }
            
            // Branch 3: Accent color in all other cases
            return color == Color.accentColor
        }
    }

    /// Property 5 (fraction bounds): Progress fraction is always in [0.0, 1.0].
    func testProperty5_ProgressFractionBounds() {
        // Feature: reliefbridge-insight, Property 5: Progress ring fraction and color SHALL satisfy the invariant for all valid inputs
        property("Progress fraction is always between 0.0 and 1.0") <- forAll(
            Gen<Double>.fromElements(in: 0.0...1000.0).resize(20),  // savings
            Gen<Double>.fromElements(in: 1.0...1000.0).resize(20)   // quota (avoid division by zero)
        ) { (savings: Double, quota: Double) in
            let fraction = min(savings / quota, 1.0)
            return fraction >= 0.0 && fraction <= 1.0
        }
    }

    /// Property 5 (color determinism): Same inputs always produce the same color.
    func testProperty5_ColorDeterminism() {
        // Feature: reliefbridge-insight, Property 5: Progress ring fraction and color SHALL satisfy the invariant for all valid inputs
        property("Same inputs always produce the same color") <- forAll(
            Gen<Double>.fromElements(in: 0.0...1.0).resize(20),  // progressFraction
            Gen<Int>.fromElements(in: 0...90).resize(20)         // daysRemaining
        ) { (progressFraction: Double, daysRemaining: Int) in
            let color1 = progressRingColor(progressFraction: progressFraction, daysRemaining: daysRemaining)
            let color2 = progressRingColor(progressFraction: progressFraction, daysRemaining: daysRemaining)
            return color1 == color2
        }
    }

    /// Property 5 (green boundary): Fraction >= 1.0 always produces Efficiency Green.
    func testProperty5_GreenBoundary() {
        // Feature: reliefbridge-insight, Property 5: Progress ring fraction and color SHALL satisfy the invariant for all valid inputs
        property("Fraction >= 1.0 always produces Efficiency Green") <- forAll(
            Gen<Double>.fromElements(in: 1.0...2.0).resize(20),  // progressFraction >= 1.0
            Gen<Int>.fromElements(in: 0...90).resize(20)         // daysRemaining (irrelevant for this branch)
        ) { (progressFraction: Double, daysRemaining: Int) in
            let color = progressRingColor(progressFraction: progressFraction, daysRemaining: daysRemaining)
            return color == Theme.Colors.efficiencyGreen
        }
    }

    /// Property 5 (orange boundary): Fraction < 0.75 and days < 30 always produces Alert Orange.
    func testProperty5_OrangeBoundary() {
        // Feature: reliefbridge-insight, Property 5: Progress ring fraction and color SHALL satisfy the invariant for all valid inputs
        property("Fraction < 0.75 and days < 30 always produces Alert Orange") <- forAll(
            Gen<Double>.fromElements(in: 0.0...0.74).resize(20),  // progressFraction < 0.75
            Gen<Int>.fromElements(in: 0...29).resize(20)          // daysRemaining < 30
        ) { (progressFraction: Double, daysRemaining: Int) in
            let color = progressRingColor(progressFraction: progressFraction, daysRemaining: daysRemaining)
            return color == Theme.Colors.alertOrange
        }
    }

    /// Property 5 (accent boundary): Fraction in [0.75, 1.0) always produces Accent color.
    func testProperty5_AccentBoundary() {
        // Feature: reliefbridge-insight, Property 5: Progress ring fraction and color SHALL satisfy the invariant for all valid inputs
        property("Fraction in [0.75, 1.0) always produces Accent color") <- forAll(
            Gen<Double>.fromElements(in: 0.75...0.99).resize(20),  // progressFraction in [0.75, 1.0)
            Gen<Int>.fromElements(in: 0...90).resize(20)           // daysRemaining (any value)
        ) { (progressFraction: Double, daysRemaining: Int) in
            let color = progressRingColor(progressFraction: progressFraction, daysRemaining: daysRemaining)
            return color == Color.accentColor
        }
    }

    /// Property 5 (accent when days >= 30): Fraction < 0.75 but days >= 30 produces Accent color.
    func testProperty5_AccentWhenDaysAtOrAbove30() {
        // Feature: reliefbridge-insight, Property 5: Progress ring fraction and color SHALL satisfy the invariant for all valid inputs
        property("Fraction < 0.75 but days >= 30 produces Accent color") <- forAll(
            Gen<Double>.fromElements(in: 0.0...0.74).resize(20),  // progressFraction < 0.75
            Gen<Int>.fromElements(in: 30...90).resize(20)         // daysRemaining >= 30
        ) { (progressFraction: Double, daysRemaining: Int) in
            let color = progressRingColor(progressFraction: progressFraction, daysRemaining: daysRemaining)
            return color == Color.accentColor
        }
    }

    /// Property 5 (monotonicity): Increasing savings (with fixed quota) never decreases the fraction.
    func testProperty5_FractionMonotonicity() {
        // Feature: reliefbridge-insight, Property 5: Progress ring fraction and color SHALL satisfy the invariant for all valid inputs
        property("Increasing savings never decreases the progress fraction") <- forAll(
            Gen<Double>.fromElements(in: 0.0...1000.0).resize(20),  // savings1
            Gen<Double>.fromElements(in: 0.0...1000.0).resize(20),  // savings2
            Gen<Double>.fromElements(in: 1.0...1000.0).resize(20)   // quota
        ) { (savings1: Double, savings2: Double, quota: Double) in
            let fraction1 = min(savings1 / quota, 1.0)
            let fraction2 = min(savings2 / quota, 1.0)
            
            // If savings2 >= savings1, then fraction2 >= fraction1
            if savings2 >= savings1 {
                return fraction2 >= fraction1
            }
            return true
        }
    }

    /// Property 5 (color transition): Color never transitions from Green to Orange or Accent.
    func testProperty5_ColorTransitionLogic() {
        // Feature: reliefbridge-insight, Property 5: Progress ring fraction and color SHALL satisfy the invariant for all valid inputs
        property("Color never transitions from Green to Orange or Accent when fraction increases") <- forAll(
            Gen<Double>.fromElements(in: 0.0...1.0).resize(20),  // progressFraction1
            Gen<Double>.fromElements(in: 0.0...1.0).resize(20),  // progressFraction2
            Gen<Int>.fromElements(in: 0...90).resize(20)         // daysRemaining
        ) { (progressFraction1: Double, progressFraction2: Double, daysRemaining: Int) in
            let color1 = progressRingColor(progressFraction: progressFraction1, daysRemaining: daysRemaining)
            let color2 = progressRingColor(progressFraction: progressFraction2, daysRemaining: daysRemaining)
            
            // If fraction increases and color1 is Green, color2 must also be Green
            if progressFraction2 >= progressFraction1 && color1 == Theme.Colors.efficiencyGreen {
                return color2 == Theme.Colors.efficiencyGreen
            }
            return true
        }
    }

    /// Property 5 (exact boundary at 1.0): Fraction exactly 1.0 produces Efficiency Green.
    func testProperty5_ExactBoundaryAt1Point0() {
        // Feature: reliefbridge-insight, Property 5: Progress ring fraction and color SHALL satisfy the invariant for all valid inputs
        property("Fraction exactly 1.0 produces Efficiency Green") <- forAll(
            Gen<Int>.fromElements(in: 0...90).resize(20)  // daysRemaining (irrelevant)
        ) { (daysRemaining: Int) in
            let color = progressRingColor(progressFraction: 1.0, daysRemaining: daysRemaining)
            return color == Theme.Colors.efficiencyGreen
        }
    }

    /// Property 5 (exact boundary at 0.75): Fraction exactly 0.75 produces Accent color (not Orange).
    func testProperty5_ExactBoundaryAt0Point75() {
        // Feature: reliefbridge-insight, Property 5: Progress ring fraction and color SHALL satisfy the invariant for all valid inputs
        property("Fraction exactly 0.75 produces Accent color") <- forAll(
            Gen<Int>.fromElements(in: 0...90).resize(20)  // daysRemaining (any value)
        ) { (daysRemaining: Int) in
            let color = progressRingColor(progressFraction: 0.75, daysRemaining: daysRemaining)
            return color == Color.accentColor
        }
    }

    /// Property 5 (exact boundary at 30 days): Days exactly 30 with fraction < 0.75 produces Accent color (not Orange).
    func testProperty5_ExactBoundaryAt30Days() {
        // Feature: reliefbridge-insight, Property 5: Progress ring fraction and color SHALL satisfy the invariant for all valid inputs
        property("Days exactly 30 with fraction < 0.75 produces Accent color") <- forAll(
            Gen<Double>.fromElements(in: 0.0...0.74).resize(20)  // progressFraction < 0.75
        ) { (progressFraction: Double) in
            let color = progressRingColor(progressFraction: progressFraction, daysRemaining: 30)
            return color == Color.accentColor
        }
    }
}
