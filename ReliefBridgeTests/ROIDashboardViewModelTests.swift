// ReliefBridgeTests/ROIDashboardViewModelTests.swift
// Unit tests for ROIDashboardViewModel.
// Validates: Requirements 5.9, 5.10, 5.5, 5.6

import XCTest
@testable import ReliefBridge

final class ROIDashboardViewModelTests: XCTestCase {
    
    var dataService: SimulatedDataService!
    var viewModel: ROIDashboardViewModel!
    
    override func setUp() {
        super.setUp()
        dataService = SimulatedDataService()
        viewModel = ROIDashboardViewModel(dataService: dataService)
    }
    
    override func tearDown() {
        viewModel = nil
        dataService = nil
        super.tearDown()
    }
    
    // MARK: - Slider Projection Calculation Tests
    
    func testSliderProjectionAtMinValue() {
        // Given: hypotheticalRetrofits = 0 (minimum)
        viewModel.hypotheticalRetrofits = 0
        
        // Wait for async updates
        let expectation = XCTestExpectation(description: "Projection computed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Then: chartDataSeries should equal base data (scale factor = 1.0)
        let baseTotal = dataService.financialMonths.reduce(0.0) { total, month in
            total + month.fuelSavingsUSD + month.monetizedCarbonCreditsUSD + month.avoidedNoiseFinesUSD
        }
        
        let projectedTotal = viewModel.chartDataSeries.reduce(0.0) { total, month in
            total + month.fuelSavingsUSD + month.monetizedCarbonCreditsUSD + month.avoidedNoiseFinesUSD
        }
        
        XCTAssertEqual(projectedTotal, baseTotal, accuracy: 0.01, "Projected total at min slider should equal base total")
    }
    
    func testSliderProjectionAtMidValue() {
        // Given: hypotheticalRetrofits = 5 (mid-range)
        viewModel.hypotheticalRetrofits = 5
        
        // Wait for async updates
        let expectation = XCTestExpectation(description: "Projection computed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Then: chartDataSeries should be scaled by 1.5x (1 + 5/10)
        let baseTotal = dataService.financialMonths.reduce(0.0) { total, month in
            total + month.fuelSavingsUSD + month.monetizedCarbonCreditsUSD + month.avoidedNoiseFinesUSD
        }
        
        let projectedTotal = viewModel.chartDataSeries.reduce(0.0) { total, month in
            total + month.fuelSavingsUSD + month.monetizedCarbonCreditsUSD + month.avoidedNoiseFinesUSD
        }
        
        let expectedTotal = baseTotal * 1.5
        XCTAssertEqual(projectedTotal, expectedTotal, accuracy: 0.01, "Projected total at mid slider should be 1.5x base total")
    }
    
    func testSliderProjectionAtMaxValue() {
        // Given: hypotheticalRetrofits = 20 (high value)
        viewModel.hypotheticalRetrofits = 20
        
        // Wait for async updates
        let expectation = XCTestExpectation(description: "Projection computed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Then: chartDataSeries should be scaled by 3.0x (1 + 20/10)
        let baseTotal = dataService.financialMonths.reduce(0.0) { total, month in
            total + month.fuelSavingsUSD + month.monetizedCarbonCreditsUSD + month.avoidedNoiseFinesUSD
        }
        
        let projectedTotal = viewModel.chartDataSeries.reduce(0.0) { total, month in
            total + month.fuelSavingsUSD + month.monetizedCarbonCreditsUSD + month.avoidedNoiseFinesUSD
        }
        
        let expectedTotal = baseTotal * 3.0
        XCTAssertEqual(projectedTotal, expectedTotal, accuracy: 0.01, "Projected total at max slider should be 3.0x base total")
    }
    
    // MARK: - Currency Formatting Tests
    
    func testCurrencyFormattingCorrectness() {
        // Given: various dollar amounts
        let testCases: [(input: Double, expected: String)] = [
            (0.0, "$0"),
            (1234.56, "$1,235"),
            (1000000.0, "$1,000,000"),
            (999.99, "$1,000"),
            (12345678.90, "$12,345,679")
        ]
        
        // When/Then: formatCurrency produces correct strings
        for testCase in testCases {
            let result = viewModel.formatCurrency(testCase.input)
            XCTAssertEqual(result, testCase.expected, "Currency formatting failed for \(testCase.input)")
        }
    }
    
    func testProjectedTotalStringIsValidCurrency() {
        // Given: hypotheticalRetrofits = 10
        viewModel.hypotheticalRetrofits = 10
        
        // Wait for async updates
        let expectation = XCTestExpectation(description: "Projection computed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Then: projectedTotalString should start with "$" and contain digits
        XCTAssertTrue(viewModel.projectedTotalString.hasPrefix("$"), "Projected total string should start with $")
        XCTAssertTrue(viewModel.projectedTotalString.contains(where: { $0.isNumber }), "Projected total string should contain digits")
    }
    
    // MARK: - Acoustic Threshold Comparison Tests
    
    func testAcousticThresholdBelowCurfew() {
        // Given: noise level below Heathrow curfew (87.0 dB)
        viewModel.selectedAirport = .heathrow
        viewModel.acousticNoiseLevelDB = 86.0
        
        // Wait for async updates
        let expectation = XCTestExpectation(description: "Acoustic status computed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Then: isAboveNoiseCurfew should be false
        XCTAssertFalse(viewModel.isAboveNoiseCurfew, "Noise level below curfew should result in isAboveNoiseCurfew = false")
    }
    
    func testAcousticThresholdExactlyAtCurfew() {
        // Given: noise level exactly at Heathrow curfew (87.0 dB)
        viewModel.selectedAirport = .heathrow
        viewModel.acousticNoiseLevelDB = 87.0
        
        // Wait for async updates
        let expectation = XCTestExpectation(description: "Acoustic status computed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Then: isAboveNoiseCurfew should be true (meets threshold)
        XCTAssertTrue(viewModel.isAboveNoiseCurfew, "Noise level exactly at curfew should result in isAboveNoiseCurfew = true")
    }
    
    func testAcousticThresholdAboveCurfew() {
        // Given: noise level above Heathrow curfew (87.0 dB)
        viewModel.selectedAirport = .heathrow
        viewModel.acousticNoiseLevelDB = 88.0
        
        // Wait for async updates
        let expectation = XCTestExpectation(description: "Acoustic status computed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Then: isAboveNoiseCurfew should be true
        XCTAssertTrue(viewModel.isAboveNoiseCurfew, "Noise level above curfew should result in isAboveNoiseCurfew = true")
    }
    
    func testAcousticThresholdFrankfurtBelowCurfew() {
        // Given: noise level below Frankfurt curfew (85.0 dB)
        viewModel.selectedAirport = .frankfurt
        viewModel.acousticNoiseLevelDB = 84.0
        
        // Wait for async updates
        let expectation = XCTestExpectation(description: "Acoustic status computed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Then: isAboveNoiseCurfew should be false
        XCTAssertFalse(viewModel.isAboveNoiseCurfew, "Noise level below Frankfurt curfew should result in isAboveNoiseCurfew = false")
    }
    
    func testAcousticThresholdFrankfurtExactlyAtCurfew() {
        // Given: noise level exactly at Frankfurt curfew (85.0 dB)
        viewModel.selectedAirport = .frankfurt
        viewModel.acousticNoiseLevelDB = 85.0
        
        // Wait for async updates
        let expectation = XCTestExpectation(description: "Acoustic status computed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Then: isAboveNoiseCurfew should be true (meets threshold)
        XCTAssertTrue(viewModel.isAboveNoiseCurfew, "Noise level exactly at Frankfurt curfew should result in isAboveNoiseCurfew = true")
    }
    
    func testAcousticThresholdFrankfurtAboveCurfew() {
        // Given: noise level above Frankfurt curfew (85.0 dB)
        viewModel.selectedAirport = .frankfurt
        viewModel.acousticNoiseLevelDB = 86.0
        
        // Wait for async updates
        let expectation = XCTestExpectation(description: "Acoustic status computed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Then: isAboveNoiseCurfew should be true
        XCTAssertTrue(viewModel.isAboveNoiseCurfew, "Noise level above Frankfurt curfew should result in isAboveNoiseCurfew = true")
    }
    
    func testAirportSwitchUpdatesThreshold() {
        // Given: noise level at 86.0 dB (below Heathrow 87.0, above Frankfurt 85.0)
        viewModel.acousticNoiseLevelDB = 86.0
        
        // When: selected airport is Heathrow
        viewModel.selectedAirport = .heathrow
        
        // Wait for async updates
        var expectation = XCTestExpectation(description: "Acoustic status computed for Heathrow")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Then: isAboveNoiseCurfew should be false (86.0 < 87.0)
        XCTAssertFalse(viewModel.isAboveNoiseCurfew, "86.0 dB should be below Heathrow curfew")
        
        // When: switch to Frankfurt
        viewModel.selectedAirport = .frankfurt
        
        // Wait for async updates
        expectation = XCTestExpectation(description: "Acoustic status computed for Frankfurt")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Then: isAboveNoiseCurfew should be true (86.0 >= 85.0)
        XCTAssertTrue(viewModel.isAboveNoiseCurfew, "86.0 dB should be above Frankfurt curfew")
    }
}
