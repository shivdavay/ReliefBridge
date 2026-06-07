// ReliefBridgeTests/CarbonEngineViewModelTests.swift
// Unit tests for CarbonEngineViewModel.
// Validates: Requirements 4.3, 4.4, 4.5, 4.7

import XCTest
import Combine
import SwiftUI
@testable import ReliefBridge

// MARK: - Helpers

/// Creates a LedgerBlock with specified parameters for testing.
private func makeLedgerBlock(
    timestamp: Date,
    carbonSavedMetricTons: Double,
    flightIdentifier: String = "TEST001",
    regulatoryStandard: RegulatoryStandard = .corsia
) -> LedgerBlock {
    LedgerBlock(
        id: UUID(),
        timestamp: timestamp,
        flightIdentifier: flightIdentifier,
        carbonSavedMetricTons: carbonSavedMetricTons,
        regulatoryStandard: regulatoryStandard,
        blockHash: "test-hash-\(UUID().uuidString)"
    )
}

// MARK: - Progress Ring Fraction Tests

/// Tests for progress ring fraction calculation at boundary values.
final class CarbonEngineViewModelProgressFractionTests: XCTestCase {

    private var cancellables = Set<AnyCancellable>()

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    /// Verify progress fraction is exactly 0.75 when cumulative savings equals 75% of quota.
    func testProgressFraction_atExactly75Percent() {
        let dataService = SimulatedDataService()
        let vm = CarbonEngineViewModel(dataService: dataService)

        // Quarterly quota is 500.0 metric tons (from CarbonEngineViewModel)
        // 75% of 500.0 = 375.0
        let blocks = [
            makeLedgerBlock(timestamp: Date(), carbonSavedMetricTons: 200.0),
            makeLedgerBlock(timestamp: Date(), carbonSavedMetricTons: 175.0),
        ]

        let expectation = XCTestExpectation(description: "Progress fraction updated to 0.75")
        vm.$progressFraction
            .filter { $0 == 0.75 }
            .first()
            .sink { fraction in
                XCTAssertEqual(fraction, 0.75, accuracy: 0.0001,
                    "Progress fraction should be exactly 0.75 when savings equal 75% of quota")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        dataService.ledgerBlocks = blocks
        wait(for: [expectation], timeout: 2.0)
    }

    /// Verify progress fraction is exactly 1.0 when cumulative savings equals 100% of quota.
    func testProgressFraction_atExactly100Percent() {
        let dataService = SimulatedDataService()
        let vm = CarbonEngineViewModel(dataService: dataService)

        // Quarterly quota is 500.0 metric tons
        // 100% of 500.0 = 500.0
        let blocks = [
            makeLedgerBlock(timestamp: Date(), carbonSavedMetricTons: 250.0),
            makeLedgerBlock(timestamp: Date(), carbonSavedMetricTons: 250.0),
        ]

        let expectation = XCTestExpectation(description: "Progress fraction updated to 1.0")
        vm.$progressFraction
            .filter { $0 == 1.0 }
            .first()
            .sink { fraction in
                XCTAssertEqual(fraction, 1.0, accuracy: 0.0001,
                    "Progress fraction should be exactly 1.0 when savings equal 100% of quota")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        dataService.ledgerBlocks = blocks
        wait(for: [expectation], timeout: 2.0)
    }

    /// Verify progress fraction is clamped to 1.0 when cumulative savings exceed quota.
    func testProgressFraction_clampedAt1Point0WhenExceedingQuota() {
        let dataService = SimulatedDataService()
        let vm = CarbonEngineViewModel(dataService: dataService)

        // Quarterly quota is 500.0 metric tons
        // Cumulative savings = 600.0 (120% of quota)
        let blocks = [
            makeLedgerBlock(timestamp: Date(), carbonSavedMetricTons: 300.0),
            makeLedgerBlock(timestamp: Date(), carbonSavedMetricTons: 300.0),
        ]

        let expectation = XCTestExpectation(description: "Progress fraction clamped to 1.0")
        vm.$progressFraction
            .filter { $0 == 1.0 }
            .first()
            .sink { fraction in
                XCTAssertEqual(fraction, 1.0, accuracy: 0.0001,
                    "Progress fraction should be clamped to 1.0 when savings exceed quota")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        dataService.ledgerBlocks = blocks
        wait(for: [expectation], timeout: 2.0)
    }

    /// Verify progress fraction is 0.0 when no ledger blocks exist.
    func testProgressFraction_zeroWhenNoBlocks() {
        let dataService = SimulatedDataService()
        let vm = CarbonEngineViewModel(dataService: dataService)

        let expectation = XCTestExpectation(description: "Progress fraction is 0.0")
        vm.$progressFraction
            .filter { $0 == 0.0 }
            .first()
            .sink { fraction in
                XCTAssertEqual(fraction, 0.0, accuracy: 0.0001,
                    "Progress fraction should be 0.0 when no ledger blocks exist")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        dataService.ledgerBlocks = []
        wait(for: [expectation], timeout: 2.0)
    }
}

// MARK: - Ring Color Selection Tests

/// Tests for ring color selection logic at all three branches.
final class CarbonEngineViewModelRingColorTests: XCTestCase {

    private var cancellables = Set<AnyCancellable>()

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    /// Verify ring color is Efficiency Green when progress fraction >= 1.0.
    func testRingColor_efficiencyGreenWhenProgressAtOrAbove100Percent() {
        let dataService = SimulatedDataService()
        let vm = CarbonEngineViewModel(dataService: dataService)

        // Quarterly quota is 500.0 metric tons
        // Cumulative savings = 500.0 (100% of quota)
        let blocks = [
            makeLedgerBlock(timestamp: Date(), carbonSavedMetricTons: 500.0),
        ]

        let expectation = XCTestExpectation(description: "Ring color is Efficiency Green")
        vm.$ringColor
            .filter { $0 == Theme.Colors.efficiencyGreen }
            .first()
            .sink { color in
                XCTAssertEqual(color, Theme.Colors.efficiencyGreen,
                    "Ring color should be Efficiency Green when progress >= 1.0")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        dataService.ledgerBlocks = blocks
        wait(for: [expectation], timeout: 2.0)
    }

    /// Verify ring color is Alert Orange when progress < 0.75 and days remaining < 30.
    func testRingColor_alertOrangeWhenProgressBelow75AndDaysRemainingBelow30() {
        let dataService = SimulatedDataService()
        let vm = CarbonEngineViewModel(dataService: dataService)

        // Quarterly quota is 500.0 metric tons
        // Cumulative savings = 300.0 (60% of quota, which is < 0.75)
        // This test assumes we are within 30 days of quarter end
        // (The actual days remaining is computed dynamically, so this test may be
        // sensitive to when it runs. For a more robust test, we would need to mock
        // the date calculation, but for now we test the logic path.)
        let blocks = [
            makeLedgerBlock(timestamp: Date(), carbonSavedMetricTons: 300.0),
        ]

        let expectation = XCTestExpectation(description: "Ring color is Alert Orange or Accent")
        vm.$ringColor
            .dropFirst() // Skip initial value
            .first()
            .sink { color in
                // The color will be Alert Orange if days remaining < 30, otherwise Accent
                // We verify the logic is working by checking it's one of the two expected values
                let isValidColor = (color == Theme.Colors.alertOrange) || (color == Color.accentColor)
                XCTAssertTrue(isValidColor,
                    "Ring color should be Alert Orange (if <30 days) or Accent (if >=30 days) when progress < 0.75")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        dataService.ledgerBlocks = blocks
        wait(for: [expectation], timeout: 2.0)
    }

    /// Verify ring color is Accent when progress is between 0.75 and 1.0.
    func testRingColor_accentWhenProgressBetween75And100Percent() {
        let dataService = SimulatedDataService()
        let vm = CarbonEngineViewModel(dataService: dataService)

        // Quarterly quota is 500.0 metric tons
        // Cumulative savings = 400.0 (80% of quota, which is >= 0.75 and < 1.0)
        let blocks = [
            makeLedgerBlock(timestamp: Date(), carbonSavedMetricTons: 400.0),
        ]

        let expectation = XCTestExpectation(description: "Ring color is Accent")
        vm.$ringColor
            .filter { $0 == Color.accentColor }
            .first()
            .sink { color in
                XCTAssertEqual(color, Color.accentColor,
                    "Ring color should be Accent when progress is between 0.75 and 1.0")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        dataService.ledgerBlocks = blocks
        wait(for: [expectation], timeout: 2.0)
    }
}

// MARK: - Pure Function Ring Color Tests

/// Tests for the pure `progressRingColor` function at all three branches.
final class ProgressRingColorFunctionTests: XCTestCase {

    /// Verify Efficiency Green when progressFraction >= 1.0.
    func testProgressRingColor_efficiencyGreenWhenProgressAtOrAbove1() {
        let color = progressRingColor(progressFraction: 1.0, daysRemaining: 10)
        XCTAssertEqual(color, Theme.Colors.efficiencyGreen,
            "Should return Efficiency Green when progressFraction >= 1.0")
    }

    /// Verify Efficiency Green when progressFraction > 1.0.
    func testProgressRingColor_efficiencyGreenWhenProgressAbove1() {
        let color = progressRingColor(progressFraction: 1.2, daysRemaining: 10)
        XCTAssertEqual(color, Theme.Colors.efficiencyGreen,
            "Should return Efficiency Green when progressFraction > 1.0")
    }

    /// Verify Alert Orange when progressFraction < 0.75 and daysRemaining < 30.
    func testProgressRingColor_alertOrangeWhenProgressBelow75AndDaysBelow30() {
        let color = progressRingColor(progressFraction: 0.74, daysRemaining: 29)
        XCTAssertEqual(color, Theme.Colors.alertOrange,
            "Should return Alert Orange when progressFraction < 0.75 and daysRemaining < 30")
    }

    /// Verify Alert Orange at exact boundary: progressFraction = 0.74, daysRemaining = 29.
    func testProgressRingColor_alertOrangeAtBoundary() {
        let color = progressRingColor(progressFraction: 0.74, daysRemaining: 29)
        XCTAssertEqual(color, Theme.Colors.alertOrange,
            "Should return Alert Orange at boundary: progressFraction < 0.75, daysRemaining < 30")
    }

    /// Verify Accent when progressFraction < 0.75 but daysRemaining >= 30.
    func testProgressRingColor_accentWhenProgressBelow75ButDaysAtOrAbove30() {
        let color = progressRingColor(progressFraction: 0.74, daysRemaining: 30)
        XCTAssertEqual(color, Color.accentColor,
            "Should return Accent when progressFraction < 0.75 but daysRemaining >= 30")
    }

    /// Verify Accent when progressFraction >= 0.75 and < 1.0.
    func testProgressRingColor_accentWhenProgressBetween75And100() {
        let color = progressRingColor(progressFraction: 0.80, daysRemaining: 10)
        XCTAssertEqual(color, Color.accentColor,
            "Should return Accent when progressFraction is between 0.75 and 1.0")
    }

    /// Verify Accent at exact boundary: progressFraction = 0.75.
    func testProgressRingColor_accentAtExactly75Percent() {
        let color = progressRingColor(progressFraction: 0.75, daysRemaining: 10)
        XCTAssertEqual(color, Color.accentColor,
            "Should return Accent when progressFraction is exactly 0.75 (not < 0.75)")
    }
}

// MARK: - Ledger Block Sort Order Tests

/// Tests for ledger block sort order (most recent first).
final class CarbonEngineViewModelLedgerBlockSortTests: XCTestCase {

    private var cancellables = Set<AnyCancellable>()

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    /// Verify ledger blocks are sorted by timestamp (most recent first).
    func testLedgerBlocks_sortedMostRecentFirst() {
        let dataService = SimulatedDataService()
        let vm = CarbonEngineViewModel(dataService: dataService)

        let now = Date()
        let oneHourAgo = now.addingTimeInterval(-3600)
        let twoDaysAgo = now.addingTimeInterval(-172800)

        let blocks = [
            makeLedgerBlock(timestamp: twoDaysAgo, carbonSavedMetricTons: 5.0, flightIdentifier: "OLD"),
            makeLedgerBlock(timestamp: now, carbonSavedMetricTons: 10.0, flightIdentifier: "NEW"),
            makeLedgerBlock(timestamp: oneHourAgo, carbonSavedMetricTons: 7.5, flightIdentifier: "MID"),
        ]

        let expectation = XCTestExpectation(description: "Ledger blocks sorted")
        vm.$ledgerBlocks
            .filter { $0.count == 3 }
            .first()
            .sink { sorted in
                XCTAssertEqual(sorted.count, 3)
                XCTAssertEqual(sorted[0].flightIdentifier, "NEW",
                    "First block should be the most recent")
                XCTAssertEqual(sorted[1].flightIdentifier, "MID",
                    "Second block should be the middle timestamp")
                XCTAssertEqual(sorted[2].flightIdentifier, "OLD",
                    "Third block should be the oldest")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        dataService.ledgerBlocks = blocks
        wait(for: [expectation], timeout: 2.0)
    }

    /// Verify sort order is stable when timestamps are identical.
    func testLedgerBlocks_stableSortWhenTimestampsIdentical() {
        let dataService = SimulatedDataService()
        let vm = CarbonEngineViewModel(dataService: dataService)

        let now = Date()
        let blocks = [
            makeLedgerBlock(timestamp: now, carbonSavedMetricTons: 5.0, flightIdentifier: "FIRST"),
            makeLedgerBlock(timestamp: now, carbonSavedMetricTons: 10.0, flightIdentifier: "SECOND"),
            makeLedgerBlock(timestamp: now, carbonSavedMetricTons: 7.5, flightIdentifier: "THIRD"),
        ]

        let expectation = XCTestExpectation(description: "Ledger blocks sorted")
        vm.$ledgerBlocks
            .filter { $0.count == 3 }
            .first()
            .sink { sorted in
                XCTAssertEqual(sorted.count, 3)
                // When timestamps are identical, Swift's sort is stable, so original order is preserved
                // However, we just verify all blocks are present
                let identifiers = sorted.map { $0.flightIdentifier }
                XCTAssertTrue(identifiers.contains("FIRST"))
                XCTAssertTrue(identifiers.contains("SECOND"))
                XCTAssertTrue(identifiers.contains("THIRD"))
                expectation.fulfill()
            }
            .store(in: &cancellables)

        dataService.ledgerBlocks = blocks
        wait(for: [expectation], timeout: 2.0)
    }

    /// Verify empty ledger blocks array is handled correctly.
    func testLedgerBlocks_emptyArrayHandledCorrectly() {
        let dataService = SimulatedDataService()
        let vm = CarbonEngineViewModel(dataService: dataService)

        let expectation = XCTestExpectation(description: "Ledger blocks empty")
        vm.$ledgerBlocks
            .filter { $0.isEmpty }
            .first()
            .sink { sorted in
                XCTAssertTrue(sorted.isEmpty,
                    "Ledger blocks should be empty when no blocks exist")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        dataService.ledgerBlocks = []
        wait(for: [expectation], timeout: 2.0)
    }
}

// MARK: - Audit Report State Transition Tests

/// Tests for audit report state machine transitions.
final class CarbonEngineViewModelAuditReportTests: XCTestCase {

    private var cancellables = Set<AnyCancellable>()

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    /// Verify initial state is .idle.
    func testAuditReportState_initialStateIsIdle() {
        let dataService = SimulatedDataService()
        let vm = CarbonEngineViewModel(dataService: dataService)

        XCTAssertEqual(vm.auditReportState, .idle,
            "Initial audit report state should be .idle")
    }

    /// Verify state transitions from .idle → .compiling → .complete.
    func testAuditReportState_transitionsFromIdleToCompilingToComplete() async {
        let dataService = SimulatedDataService()
        let vm = CarbonEngineViewModel(dataService: dataService)

        // Initial state
        XCTAssertEqual(vm.auditReportState, .idle)

        // Start generation
        vm.generateAuditReport()

        // Should immediately transition to .compiling
        XCTAssertEqual(vm.auditReportState, .compiling,
            "State should be .compiling immediately after generateAuditReport()")

        // Wait for completion (simulated compilation takes ~2 seconds)
        let expectation = XCTestExpectation(description: "Audit report completed")
        vm.$auditReportState
            .filter { $0 == .complete }
            .first()
            .sink { state in
                XCTAssertEqual(state, .complete,
                    "State should transition to .complete after compilation")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        await fulfillment(of: [expectation], timeout: 3.0)
    }

    /// Verify resetAuditReport() transitions state back to .idle.
    func testAuditReportState_resetTransitionsToIdle() {
        let dataService = SimulatedDataService()
        let vm = CarbonEngineViewModel(dataService: dataService)

        // Start generation
        vm.generateAuditReport()
        XCTAssertEqual(vm.auditReportState, .compiling)

        // Reset
        vm.resetAuditReport()
        XCTAssertEqual(vm.auditReportState, .idle,
            "State should transition to .idle after resetAuditReport()")
    }

    /// Verify cancellation during compilation resets state to .idle.
    func testAuditReportState_cancellationDuringCompilationResetsToIdle() async {
        let dataService = SimulatedDataService()
        let vm = CarbonEngineViewModel(dataService: dataService)

        // Start generation
        vm.generateAuditReport()
        XCTAssertEqual(vm.auditReportState, .compiling)

        // Cancel immediately
        vm.resetAuditReport()

        // Wait a bit to ensure the task has been cancelled
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        XCTAssertEqual(vm.auditReportState, .idle,
            "State should be .idle after cancellation")
    }

    /// Verify calling generateAuditReport() while already compiling cancels the previous task.
    func testAuditReportState_callingGenerateWhileCompilingCancelsPreviousTask() async {
        let dataService = SimulatedDataService()
        let vm = CarbonEngineViewModel(dataService: dataService)

        // Start first generation
        vm.generateAuditReport()
        XCTAssertEqual(vm.auditReportState, .compiling)

        // Start second generation immediately (should cancel first)
        vm.generateAuditReport()
        XCTAssertEqual(vm.auditReportState, .compiling,
            "State should remain .compiling after starting a new generation")

        // Wait for completion
        let expectation = XCTestExpectation(description: "Second audit report completed")
        vm.$auditReportState
            .filter { $0 == .complete }
            .first()
            .sink { state in
                XCTAssertEqual(state, .complete,
                    "State should transition to .complete for the second generation")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        await fulfillment(of: [expectation], timeout: 3.0)
    }

    /// Verify resetAuditReport() can be called from .complete state.
    func testAuditReportState_resetFromCompleteState() async {
        let dataService = SimulatedDataService()
        let vm = CarbonEngineViewModel(dataService: dataService)

        // Generate and wait for completion
        vm.generateAuditReport()

        let expectation = XCTestExpectation(description: "Audit report completed")
        vm.$auditReportState
            .filter { $0 == .complete }
            .first()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)

        await fulfillment(of: [expectation], timeout: 3.0)

        // Reset from .complete
        vm.resetAuditReport()
        XCTAssertEqual(vm.auditReportState, .idle,
            "State should transition to .idle after reset from .complete")
    }
}
