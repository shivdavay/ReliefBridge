// ReliefBridgeTests/MaintenanceViewModelTests.swift
// Unit tests for MaintenanceViewModel.
// Validates: Requirements 6.6, 6.7, 6.8, 6.9, 6.10

import XCTest
import Combine
@testable import ReliefBridge

// MARK: - Helpers

private func makeAlert(
    affectedComponent: String = "Test Component",
    description: String = "Test description",
    recommendedAction: String = "Test action",
    severity: AlertSeverity
) -> MaintenanceAlert {
    MaintenanceAlert(
        id: UUID(),
        affectedComponent: affectedComponent,
        description: description,
        recommendedAction: recommendedAction,
        severity: severity,
        generatedAt: Date()
    )
}

// MARK: - Alert Sort Order Tests

/// Tests for the maintenance alert sort order logic.
///
/// Requirement 6.6: Alerts SHALL be displayed in descending order of severity
/// (critical before warning before info).
final class MaintenanceViewModelSortOrderTests: XCTestCase {

    private var cancellables = Set<AnyCancellable>()

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    /// Verify alerts are sorted critical → warning → info.
    func testAlertSortOrder_criticalWarningInfo() {
        let dataService = SimulatedDataService()
        let vm = MaintenanceViewModel(dataService: dataService)

        let alerts = [
            makeAlert(affectedComponent: "A", severity: .info),
            makeAlert(affectedComponent: "B", severity: .critical),
            makeAlert(affectedComponent: "C", severity: .warning),
        ]

        let expectation = XCTestExpectation(description: "Alerts sorted")
        vm.$sortedAlerts
            .filter { $0.count == 3 }
            .first()
            .sink { sorted in
                XCTAssertEqual(sorted[0].severity, .critical, "First alert should be critical")
                XCTAssertEqual(sorted[1].severity, .warning, "Second alert should be warning")
                XCTAssertEqual(sorted[2].severity, .info, "Third alert should be info")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        dataService.maintenanceAlerts = alerts
        wait(for: [expectation], timeout: 2.0)
    }

    /// Verify all critical alerts appear before all warning alerts.
    func testAlertSortOrder_allCriticalsBeforeWarnings() {
        let dataService = SimulatedDataService()
        let vm = MaintenanceViewModel(dataService: dataService)

        let alerts = [
            makeAlert(affectedComponent: "W1", severity: .warning),
            makeAlert(affectedComponent: "C1", severity: .critical),
            makeAlert(affectedComponent: "W2", severity: .warning),
            makeAlert(affectedComponent: "C2", severity: .critical),
        ]

        let expectation = XCTestExpectation(description: "Alerts sorted")
        vm.$sortedAlerts
            .filter { $0.count == 4 }
            .first()
            .sink { sorted in
                // First two should be critical
                XCTAssertEqual(sorted[0].severity, .critical)
                XCTAssertEqual(sorted[1].severity, .critical)
                // Last two should be warning
                XCTAssertEqual(sorted[2].severity, .warning)
                XCTAssertEqual(sorted[3].severity, .warning)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        dataService.maintenanceAlerts = alerts
        wait(for: [expectation], timeout: 2.0)
    }

    /// Verify all warning alerts appear before all info alerts.
    func testAlertSortOrder_allWarningsBeforeInfo() {
        let dataService = SimulatedDataService()
        let vm = MaintenanceViewModel(dataService: dataService)

        let alerts = [
            makeAlert(affectedComponent: "I1", severity: .info),
            makeAlert(affectedComponent: "W1", severity: .warning),
            makeAlert(affectedComponent: "I2", severity: .info),
            makeAlert(affectedComponent: "W2", severity: .warning),
        ]

        let expectation = XCTestExpectation(description: "Alerts sorted")
        vm.$sortedAlerts
            .filter { $0.count == 4 }
            .first()
            .sink { sorted in
                // First two should be warning
                XCTAssertEqual(sorted[0].severity, .warning)
                XCTAssertEqual(sorted[1].severity, .warning)
                // Last two should be info
                XCTAssertEqual(sorted[2].severity, .info)
                XCTAssertEqual(sorted[3].severity, .info)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        dataService.maintenanceAlerts = alerts
        wait(for: [expectation], timeout: 2.0)
    }

    /// Verify mixed severities are sorted correctly (all permutations).
    func testAlertSortOrder_mixedSeveritiesAllPermutations() {
        let dataService = SimulatedDataService()
        let vm = MaintenanceViewModel(dataService: dataService)

        // Test all 6 permutations of (critical, warning, info)
        let permutations: [[(String, AlertSeverity)]] = [
            [("C", .critical), ("W", .warning), ("I", .info)],
            [("C", .critical), ("I", .info), ("W", .warning)],
            [("W", .warning), ("C", .critical), ("I", .info)],
            [("W", .warning), ("I", .info), ("C", .critical)],
            [("I", .info), ("C", .critical), ("W", .warning)],
            [("I", .info), ("W", .warning), ("C", .critical)],
        ]

        for (index, permutation) in permutations.enumerated() {
            let expectation = XCTestExpectation(description: "Permutation \(index) sorted")
            
            let alerts = permutation.map { makeAlert(affectedComponent: $0.0, severity: $0.1) }
            
            vm.$sortedAlerts
                .filter { $0.count == 3 }
                .first()
                .sink { sorted in
                    XCTAssertEqual(sorted[0].severity, .critical,
                        "Permutation \(index): First should be critical")
                    XCTAssertEqual(sorted[1].severity, .warning,
                        "Permutation \(index): Second should be warning")
                    XCTAssertEqual(sorted[2].severity, .info,
                        "Permutation \(index): Third should be info")
                    expectation.fulfill()
                }
                .store(in: &cancellables)

            dataService.maintenanceAlerts = alerts
            wait(for: [expectation], timeout: 2.0)
        }
    }

    /// Verify sort order is stable when all alerts have the same severity.
    func testAlertSortOrder_allSameSeverity() {
        let dataService = SimulatedDataService()
        let vm = MaintenanceViewModel(dataService: dataService)

        let alerts = [
            makeAlert(affectedComponent: "A", severity: .warning),
            makeAlert(affectedComponent: "B", severity: .warning),
            makeAlert(affectedComponent: "C", severity: .warning),
        ]

        let expectation = XCTestExpectation(description: "Alerts sorted")
        vm.$sortedAlerts
            .filter { $0.count == 3 }
            .first()
            .sink { sorted in
                // All should be warning
                XCTAssertTrue(sorted.allSatisfy { $0.severity == .warning },
                    "All alerts should have warning severity")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        dataService.maintenanceAlerts = alerts
        wait(for: [expectation], timeout: 2.0)
    }

    /// Verify empty alert list is handled correctly.
    func testAlertSortOrder_emptyList() {
        let dataService = SimulatedDataService()
        let vm = MaintenanceViewModel(dataService: dataService)

        let expectation = XCTestExpectation(description: "Empty alerts handled")
        vm.$sortedAlerts
            .filter { $0.isEmpty }
            .first()
            .sink { sorted in
                XCTAssertTrue(sorted.isEmpty, "Sorted alerts should be empty")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        dataService.maintenanceAlerts = []
        wait(for: [expectation], timeout: 2.0)
    }

    /// Verify single alert is handled correctly.
    func testAlertSortOrder_singleAlert() {
        let dataService = SimulatedDataService()
        let vm = MaintenanceViewModel(dataService: dataService)

        let alerts = [makeAlert(affectedComponent: "A", severity: .critical)]

        let expectation = XCTestExpectation(description: "Single alert handled")
        vm.$sortedAlerts
            .filter { $0.count == 1 }
            .first()
            .sink { sorted in
                XCTAssertEqual(sorted.count, 1)
                XCTAssertEqual(sorted[0].severity, .critical)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        dataService.maintenanceAlerts = alerts
        wait(for: [expectation], timeout: 2.0)
    }
}

// MARK: - EFB Sync State Tests

/// Tests for the EFB synchronization toggle and timestamp logic.
///
/// Requirements 6.7, 6.8, 6.9, 6.10: EFB sync toggle, status indicators, and timestamp.
final class MaintenanceViewModelEFBSyncTests: XCTestCase {

    private var cancellables = Set<AnyCancellable>()

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    /// Verify initial state: EFB sync is disabled and timestamp is nil.
    func testEFBSync_initialState() {
        let dataService = SimulatedDataService()
        let vm = MaintenanceViewModel(dataService: dataService)

        XCTAssertFalse(vm.isEFBSyncEnabled, "EFB sync should be disabled initially")
        XCTAssertNil(vm.lastSyncTimestamp, "Last sync timestamp should be nil initially")
    }

    /// Verify toggling EFB sync on updates the timestamp.
    func testEFBSync_toggleOn_updatesTimestamp() {
        let dataService = SimulatedDataService()
        let vm = MaintenanceViewModel(dataService: dataService)

        let beforeToggle = Date()
        vm.isEFBSyncEnabled = true
        let afterToggle = Date()

        XCTAssertTrue(vm.isEFBSyncEnabled, "EFB sync should be enabled")
        XCTAssertNotNil(vm.lastSyncTimestamp, "Last sync timestamp should be set")

        if let timestamp = vm.lastSyncTimestamp {
            XCTAssertGreaterThanOrEqual(timestamp, beforeToggle,
                "Timestamp should be >= time before toggle")
            XCTAssertLessThanOrEqual(timestamp, afterToggle,
                "Timestamp should be <= time after toggle")
        }
    }

    /// Verify toggling EFB sync off does not clear the timestamp.
    func testEFBSync_toggleOff_preservesTimestamp() {
        let dataService = SimulatedDataService()
        let vm = MaintenanceViewModel(dataService: dataService)

        // Enable sync first
        vm.isEFBSyncEnabled = true
        let timestampWhenEnabled = vm.lastSyncTimestamp

        // Disable sync
        vm.isEFBSyncEnabled = false

        XCTAssertFalse(vm.isEFBSyncEnabled, "EFB sync should be disabled")
        XCTAssertEqual(vm.lastSyncTimestamp, timestampWhenEnabled,
            "Timestamp should be preserved when toggling off")
    }

    /// Verify toggling EFB sync on multiple times updates the timestamp each time.
    func testEFBSync_multipleToggles_updatesTimestampEachTime() {
        let dataService = SimulatedDataService()
        let vm = MaintenanceViewModel(dataService: dataService)

        // First toggle on
        vm.isEFBSyncEnabled = true
        let firstTimestamp = vm.lastSyncTimestamp
        XCTAssertNotNil(firstTimestamp)

        // Small delay to ensure timestamp difference
        Thread.sleep(forTimeInterval: 0.01)

        // Toggle off then on again
        vm.isEFBSyncEnabled = false
        vm.isEFBSyncEnabled = true
        let secondTimestamp = vm.lastSyncTimestamp

        XCTAssertNotNil(secondTimestamp)
        if let first = firstTimestamp, let second = secondTimestamp {
            XCTAssertGreaterThan(second, first,
                "Second timestamp should be later than first")
        }
    }

    /// Verify new alerts trigger timestamp update when EFB sync is enabled.
    func testEFBSync_newAlerts_updatesTimestampWhenEnabled() {
        let dataService = SimulatedDataService()
        let vm = MaintenanceViewModel(dataService: dataService)

        // Enable sync and record initial timestamp
        vm.isEFBSyncEnabled = true
        let initialTimestamp = vm.lastSyncTimestamp
        XCTAssertNotNil(initialTimestamp)

        // Small delay to ensure timestamp difference
        Thread.sleep(forTimeInterval: 0.01)

        let expectation = XCTestExpectation(description: "Timestamp updated after new alerts")
        
        // Observe timestamp changes
        vm.$lastSyncTimestamp
            .dropFirst() // Skip the initial value
            .first()
            .sink { newTimestamp in
                XCTAssertNotNil(newTimestamp)
                if let initial = initialTimestamp, let new = newTimestamp {
                    XCTAssertGreaterThan(new, initial,
                        "Timestamp should be updated when new alerts arrive with sync enabled")
                }
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Add new alerts
        dataService.maintenanceAlerts = [
            makeAlert(affectedComponent: "New Component", severity: .critical)
        ]

        wait(for: [expectation], timeout: 2.0)
    }

    /// Verify new alerts do NOT trigger timestamp update when EFB sync is disabled.
    func testEFBSync_newAlerts_doesNotUpdateTimestampWhenDisabled() {
        let dataService = SimulatedDataService()
        let vm = MaintenanceViewModel(dataService: dataService)

        // Ensure sync is disabled
        vm.isEFBSyncEnabled = false
        let initialTimestamp = vm.lastSyncTimestamp
        XCTAssertNil(initialTimestamp, "Initial timestamp should be nil when sync is disabled")

        // Add new alerts
        dataService.maintenanceAlerts = [
            makeAlert(affectedComponent: "New Component", severity: .warning)
        ]

        // Wait a moment to ensure any potential updates would have occurred
        let expectation = XCTestExpectation(description: "Wait for potential updates")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // Timestamp should still be nil
        XCTAssertNil(vm.lastSyncTimestamp,
            "Timestamp should remain nil when new alerts arrive with sync disabled")
    }

    /// Verify timestamp reflects the most recent sync event.
    func testEFBSync_timestampReflectsMostRecentSync() {
        let dataService = SimulatedDataService()
        let vm = MaintenanceViewModel(dataService: dataService)

        // Enable sync
        vm.isEFBSyncEnabled = true
        let firstTimestamp = vm.lastSyncTimestamp

        Thread.sleep(forTimeInterval: 0.01)

        // Trigger another sync by adding alerts
        let expectation = XCTestExpectation(description: "Timestamp updated")
        vm.$lastSyncTimestamp
            .dropFirst()
            .first()
            .sink { newTimestamp in
                if let first = firstTimestamp, let new = newTimestamp {
                    XCTAssertGreaterThan(new, first,
                        "Most recent timestamp should be later than previous")
                }
                expectation.fulfill()
            }
            .store(in: &cancellables)

        dataService.maintenanceAlerts = [
            makeAlert(affectedComponent: "Component", severity: .info)
        ]

        wait(for: [expectation], timeout: 2.0)
    }
}
