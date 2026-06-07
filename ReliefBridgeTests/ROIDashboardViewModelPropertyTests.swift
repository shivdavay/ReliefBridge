// ReliefBridgeTests/ROIDashboardViewModelPropertyTests.swift
// Property-based tests for ROIDashboardViewModel using SwiftCheck.
// Validates: Requirements 5.9, 5.10, 5.5, 5.6

import XCTest
import SwiftCheck
@testable import ReliefBridge

// MARK: - Arbitrary Conformance for Airport

extension Airport: Arbitrary {
    public static var arbitrary: Gen<Airport> {
        return Gen<Airport>.fromElements(of: [.heathrow, .frankfurt])
    }
}

// MARK: - Custom Generators

struct NoiseLevel: Arbitrary {
    let value: Double
    
    static var arbitrary: Gen<NoiseLevel> {
        return Gen<Double>.fromElements(in: 70.0...100.0).resize(20).map { NoiseLevel(value: $0) }
    }
}

final class ROIDashboardViewModelPropertyTests: XCTestCase {
    
    // MARK: - Property 8: ROI Slider Projection Monotonicity
    
    // Feature: reliefbridge-insight, Property 8: For any two slider values n1 < n2, projected savings(n2) >= projected savings(n1) and both format as valid currency strings
    func testROISliderProjectionMonotonicity() {
        // Property: For any two slider values n1 < n2, projected savings SHALL be monotonically non-decreasing
        property("ROI slider projection monotonicity") <- forAll(
            Gen<Int>.fromElements(in: 0...50).resize(20),
            Gen<Int>.fromElements(in: 0...50).resize(20)
        ) { (value1: Int, value2: Int) in
            // Ensure n1 < n2
            guard value1 < value2 else { return Discard() }
            
            let n1 = value1
            let n2 = value2
            
            // Create data service and view model
            let dataService = SimulatedDataService()
            let viewModel = ROIDashboardViewModel(dataService: dataService)
            
            // Wait for initial data to load
            let initialExpectation = XCTestExpectation(description: "Initial data loaded")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                initialExpectation.fulfill()
            }
            self.wait(for: [initialExpectation], timeout: 1.0)
            
            // Compute projected savings for n1
            viewModel.hypotheticalRetrofits = n1
            let expectation1 = XCTestExpectation(description: "Projection for n1 computed")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                expectation1.fulfill()
            }
            self.wait(for: [expectation1], timeout: 1.0)
            
            let savings1 = viewModel.chartDataSeries.reduce(0.0) { total, month in
                total + month.fuelSavingsUSD + month.monetizedCarbonCreditsUSD + month.avoidedNoiseFinesUSD
            }
            let currencyString1 = viewModel.projectedTotalString
            
            // Compute projected savings for n2
            viewModel.hypotheticalRetrofits = n2
            let expectation2 = XCTestExpectation(description: "Projection for n2 computed")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                expectation2.fulfill()
            }
            self.wait(for: [expectation2], timeout: 1.0)
            
            let savings2 = viewModel.chartDataSeries.reduce(0.0) { total, month in
                total + month.fuelSavingsUSD + month.monetizedCarbonCreditsUSD + month.avoidedNoiseFinesUSD
            }
            let currencyString2 = viewModel.projectedTotalString
            
            // Verify monotonicity: savings(n2) >= savings(n1)
            let isMonotonic = savings2 >= savings1
            
            // Verify both are valid currency strings (start with "$" and contain digits)
            let isValidCurrency1 = currencyString1.hasPrefix("$") && currencyString1.contains(where: { $0.isNumber })
            let isValidCurrency2 = currencyString2.hasPrefix("$") && currencyString2.contains(where: { $0.isNumber })
            
            return isMonotonic <?> "Savings monotonicity violated: n1=\(n1) savings=\(savings1), n2=\(n2) savings=\(savings2)"
                ^&&^ isValidCurrency1 <?> "Currency string 1 invalid: \(currencyString1)"
                ^&&^ isValidCurrency2 <?> "Currency string 2 invalid: \(currencyString2)"
        }
    }
    
    // MARK: - Property 9: Acoustic Threshold Color Mapping
    
    // Feature: reliefbridge-insight, Property 9: For any noise level and curfew threshold, color SHALL be Efficiency Green iff noise < curfew, Alert Orange otherwise
    func testAcousticThresholdColorMapping() {
        // Property: Acoustic metric color SHALL be Efficiency Green iff noise level is strictly below curfew threshold
        property("Acoustic threshold color mapping") <- forAll { (noiseLevel: NoiseLevel, airport: Airport) in
            let noiseDB = noiseLevel.value
            // Create data service and view model
            let dataService = SimulatedDataService()
            let viewModel = ROIDashboardViewModel(dataService: dataService)
            
            // Set noise level and airport
            viewModel.acousticNoiseLevelDB = noiseDB
            viewModel.selectedAirport = airport
            
            // Wait for async updates
            let expectation = XCTestExpectation(description: "Acoustic status computed")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                expectation.fulfill()
            }
            self.wait(for: [expectation], timeout: 1.0)
            
            // Expected: isAboveNoiseCurfew should be true iff noiseDB >= curfew
            let curfewThreshold = airport.noiseCurfewDB
            let expectedAboveCurfew = noiseDB >= curfewThreshold
            let actualAboveCurfew = viewModel.isAboveNoiseCurfew
            
            return (actualAboveCurfew == expectedAboveCurfew) <?> "Acoustic threshold mapping failed: noise=\(noiseDB), curfew=\(curfewThreshold), expected=\(expectedAboveCurfew), actual=\(actualAboveCurfew)"
        }
    }
}
