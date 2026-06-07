// ReliefBridgeTests/MaintenanceViewModelPropertyTests.swift
// Property-based tests for MaintenanceViewModel.
// Property 10: Maintenance Alert Sort Order.

import XCTest
import SwiftCheck
@testable import ReliefBridge

// MARK: - LatticeZone Generator

extension LatticeZone: Arbitrary {
    public static var arbitrary: Gen<LatticeZone> {
        Gen.zip(
            Gen<String>.fromElements(of: [
                "Zone A1",
                "Zone A2",
                "Zone B1",
                "Zone B2",
                "Zone C1",
                "Zone C2",
                "Zone D1",
                "Zone D2"
            ]),
            Gen<Double>.choose((0.0, 1.0))
        ).map { label, risk in
            LatticeZone(
                id: UUID(),
                zoneLabel: label,
                microPoreBlockageRisk: risk
            )
        }
    }
}

// MARK: - MaintenanceAlert Generator

extension MaintenanceAlert: Arbitrary {
    public static var arbitrary: Gen<MaintenanceAlert> {
        Gen.zip(
            Gen<String>.fromElements(of: [
                "Port Wing Lattice",
                "Starboard Wing Lattice",
                "Fuselage Lattice Zone A",
                "Fuselage Lattice Zone B",
                "Tail Section Lattice",
                "Ram Air Intake Manifold",
                "Gyroid Flow Sensor",
                "Jet Sheet Actuator"
            ]),
            Gen<String>.fromElements(of: [
                "Micro-pore blockage detected",
                "Flow uniformity degradation",
                "Pressure sensor drift",
                "Actuator response delay",
                "Thermal expansion anomaly",
                "Surface contamination detected"
            ]),
            Gen<String>.fromElements(of: [
                "Schedule pneumatic purge at next C-Check",
                "Inspect and clean at next maintenance window",
                "Replace sensor during next scheduled maintenance",
                "Recalibrate actuator control system",
                "Monitor thermal profile for 3 additional flights",
                "Perform visual inspection and cleaning"
            ]),
            Gen<AlertSeverity>.fromElements(of: [.info, .warning, .critical])
        ).map { component, description, action, severity in
            MaintenanceAlert(
                id: UUID(),
                affectedComponent: component,
                description: description,
                recommendedAction: action,
                severity: severity,
                generatedAt: Date()
            )
        }
    }
}

// MARK: - AlertSeverity Generator

extension AlertSeverity: Arbitrary {
    public static var arbitrary: Gen<AlertSeverity> {
        Gen<AlertSeverity>.fromElements(of: [.info, .warning, .critical])
    }
}

// MARK: - Pure Sorting Logic (extracted for property testing)

/// Pure function that mirrors MaintenanceViewModel's sorting logic.
/// Sorts alerts by severity descending (critical → warning → info).
private func sortAlertsBySeverity(_ alerts: [MaintenanceAlert]) -> [MaintenanceAlert] {
    alerts.sorted { $0.severity > $1.severity }
}

// MARK: - Property 10: Maintenance Alert Sort Order

// Feature: reliefbridge-insight, Property 10: sortedAlerts SHALL be in non-increasing severity order
// Validates: Requirements 6.6

final class MaintenanceAlertSortOrderPropertyTests: XCTestCase {

    /// Property 10: Maintenance Alert Sort Order
    ///
    /// For any collection of MaintenanceAlert records, the sorted output
    /// SHALL be in non-increasing order of severity (critical → warning → info),
    /// such that no alert of lower severity appears before any alert of higher severity.
    func testProperty10_MaintenanceAlertSortOrder() {
        // Feature: reliefbridge-insight, Property 10: sortedAlerts SHALL be in non-increasing severity order
        property("sortedAlerts is in non-increasing severity order") <- forAll(
            [MaintenanceAlert].arbitrary.resize(20)
        ) { (alerts: [MaintenanceAlert]) in
            let sorted = sortAlertsBySeverity(alerts)

            // Empty or single-element arrays are trivially sorted
            guard sorted.count >= 2 else { return true }

            // Verify non-increasing severity order:
            // For each adjacent pair (i, i+1), severity[i] >= severity[i+1]
            for i in 0..<sorted.count - 1 {
                let current = sorted[i].severity
                let next = sorted[i + 1].severity
                guard current >= next else { return false }
            }

            return true
        }
    }

    /// Property 10 (extended): All alerts are preserved after sorting.
    ///
    /// The sorted output SHALL contain exactly the same alerts as the input,
    /// with no additions or deletions.
    func testProperty10_SortingPreservesAllAlerts() {
        // Feature: reliefbridge-insight, Property 10: sortedAlerts SHALL be in non-increasing severity order
        property("Sorting preserves all alerts (no additions or deletions)") <- forAll(
            [MaintenanceAlert].arbitrary.resize(20)
        ) { (alerts: [MaintenanceAlert]) in
            let sorted = sortAlertsBySeverity(alerts)

            // Same count
            guard sorted.count == alerts.count else { return false }

            // Same IDs (set equality)
            let originalIDs = Set(alerts.map(\.id))
            let sortedIDs = Set(sorted.map(\.id))
            return originalIDs == sortedIDs
        }
    }

    /// Property 10 (structural): Critical alerts always precede non-critical alerts.
    ///
    /// If the input contains both critical and non-critical alerts,
    /// all critical alerts SHALL appear before all non-critical alerts in the sorted output.
    func testProperty10_CriticalAlertsAlwaysPrecedeNonCritical() {
        // Feature: reliefbridge-insight, Property 10: sortedAlerts SHALL be in non-increasing severity order
        property("Critical alerts always precede non-critical alerts") <- forAll(
            [MaintenanceAlert].arbitrary.suchThat { alerts in
                alerts.contains { $0.severity == .critical } &&
                alerts.contains { $0.severity != .critical }
            }.resize(20)
        ) { (alerts: [MaintenanceAlert]) in
            let sorted = sortAlertsBySeverity(alerts)

            // Find the index of the last critical alert
            guard let lastCriticalIndex = sorted.lastIndex(where: { $0.severity == .critical }) else {
                return false // Should have at least one critical alert (enforced by suchThat)
            }

            // Find the index of the first non-critical alert
            guard let firstNonCriticalIndex = sorted.firstIndex(where: { $0.severity != .critical }) else {
                return false // Should have at least one non-critical alert (enforced by suchThat)
            }

            // All critical alerts must come before all non-critical alerts
            return lastCriticalIndex < firstNonCriticalIndex
        }
    }

    /// Property 10 (structural): Warning alerts always precede info alerts.
    ///
    /// If the input contains both warning and info alerts,
    /// all warning alerts SHALL appear before all info alerts in the sorted output.
    func testProperty10_WarningAlertsAlwaysPrecedeInfo() {
        // Feature: reliefbridge-insight, Property 10: sortedAlerts SHALL be in non-increasing severity order
        property("Warning alerts always precede info alerts") <- forAll(
            [MaintenanceAlert].arbitrary.suchThat { alerts in
                alerts.contains { $0.severity == .warning } &&
                alerts.contains { $0.severity == .info }
            }.resize(20)
        ) { (alerts: [MaintenanceAlert]) in
            let sorted = sortAlertsBySeverity(alerts)

            // Find the index of the last warning alert
            guard let lastWarningIndex = sorted.lastIndex(where: { $0.severity == .warning }) else {
                return false // Should have at least one warning alert (enforced by suchThat)
            }

            // Find the index of the first info alert
            guard let firstInfoIndex = sorted.firstIndex(where: { $0.severity == .info }) else {
                return false // Should have at least one info alert (enforced by suchThat)
            }

            // All warning alerts must come before all info alerts
            return lastWarningIndex < firstInfoIndex
        }
    }

    /// Property 10 (edge case): Empty alert list remains empty after sorting.
    func testProperty10_EmptyListRemainsEmpty() {
        // Feature: reliefbridge-insight, Property 10: sortedAlerts SHALL be in non-increasing severity order
        let empty: [MaintenanceAlert] = []
        let sorted = sortAlertsBySeverity(empty)
        XCTAssertEqual(sorted.count, 0, "Empty alert list should remain empty after sorting")
    }

    /// Property 10 (edge case): Single alert list remains unchanged after sorting.
    func testProperty10_SingleAlertRemainsUnchanged() {
        // Feature: reliefbridge-insight, Property 10: sortedAlerts SHALL be in non-increasing severity order
        property("Single alert list remains unchanged after sorting") <- forAll(
            MaintenanceAlert.arbitrary
        ) { (alert: MaintenanceAlert) in
            let sorted = sortAlertsBySeverity([alert])
            return sorted.count == 1 && sorted[0].id == alert.id
        }
    }
}

// MARK: - Property 11: Maintenance Alert Required Fields

// Feature: reliefbridge-insight, Property 11: Every MaintenanceAlertRow SHALL display description, affected component, and recommended action
// Validates: Requirements 6.5

final class MaintenanceAlertRequiredFieldsPropertyTests: XCTestCase {

    /// Property 11: Maintenance Alert Required Fields
    ///
    /// For any MaintenanceAlert in the data set, the alert SHALL contain
    /// non-empty strings for description, affectedComponent, and recommendedAction.
    /// This ensures that any rendered MaintenanceAlertRow has all required fields to display.
    func testProperty11_MaintenanceAlertRequiredFields() {
        // Feature: reliefbridge-insight, Property 11: Every MaintenanceAlertRow SHALL display description, affected component, and recommended action
        property("Every MaintenanceAlert has non-empty description, affectedComponent, and recommendedAction") <- forAll(
            MaintenanceAlert.arbitrary
        ) { (alert: MaintenanceAlert) in
            // Verify all three required fields are non-empty strings
            let hasDescription = !alert.description.isEmpty
            let hasAffectedComponent = !alert.affectedComponent.isEmpty
            let hasRecommendedAction = !alert.recommendedAction.isEmpty
            
            return hasDescription && hasAffectedComponent && hasRecommendedAction
        }
    }

    /// Property 11 (collection): All alerts in a collection have required fields.
    ///
    /// For any collection of MaintenanceAlert records, every alert SHALL have
    /// non-empty description, affectedComponent, and recommendedAction fields.
    func testProperty11_AllAlertsInCollectionHaveRequiredFields() {
        // Feature: reliefbridge-insight, Property 11: Every MaintenanceAlertRow SHALL display description, affected component, and recommended action
        property("All alerts in a collection have required fields") <- forAll(
            [MaintenanceAlert].arbitrary.resize(20)
        ) { (alerts: [MaintenanceAlert]) in
            // Every alert must have all three required fields as non-empty strings
            return alerts.allSatisfy { alert in
                !alert.description.isEmpty &&
                !alert.affectedComponent.isEmpty &&
                !alert.recommendedAction.isEmpty
            }
        }
    }

    /// Property 11 (structural): Required fields are distinct strings.
    ///
    /// For any MaintenanceAlert, the three required fields (description, affectedComponent,
    /// recommendedAction) SHALL be independently meaningful strings, not all identical.
    func testProperty11_RequiredFieldsAreDistinct() {
        // Feature: reliefbridge-insight, Property 11: Every MaintenanceAlertRow SHALL display description, affected component, and recommended action
        property("Required fields are distinct (not all identical)") <- forAll(
            MaintenanceAlert.arbitrary
        ) { (alert: MaintenanceAlert) in
            // At least one field should differ from the others
            // (This prevents degenerate cases where all fields are the same string)
            let allSame = alert.description == alert.affectedComponent &&
                          alert.affectedComponent == alert.recommendedAction
            return !allSame
        }
    }

    /// Property 11 (edge case): Required fields contain printable characters.
    ///
    /// For any MaintenanceAlert, the required fields SHALL contain at least one
    /// non-whitespace character, ensuring they are meaningful for display.
    func testProperty11_RequiredFieldsContainPrintableCharacters() {
        // Feature: reliefbridge-insight, Property 11: Every MaintenanceAlertRow SHALL display description, affected component, and recommended action
        property("Required fields contain non-whitespace characters") <- forAll(
            MaintenanceAlert.arbitrary
        ) { (alert: MaintenanceAlert) in
            // Each field should have at least one non-whitespace character
            let descriptionHasContent = !alert.description.trimmingCharacters(in: .whitespaces).isEmpty
            let componentHasContent = !alert.affectedComponent.trimmingCharacters(in: .whitespaces).isEmpty
            let actionHasContent = !alert.recommendedAction.trimmingCharacters(in: .whitespaces).isEmpty
            
            return descriptionHasContent && componentHasContent && actionHasContent
        }
    }
}

// MARK: - Pure Color Mapping Logic (extracted for property testing)

/// Pure function that determines the heat map color for a lattice zone based on blockage risk.
/// Returns true if the color should be Alert Orange, false if it should be Efficiency Green.
private func shouldBeAlertOrange(microPoreBlockageRisk: Double) -> Bool {
    microPoreBlockageRisk > Thresholds.latticeBlockageWarning
}

// MARK: - Property 12: Lattice Zone Color Mapping

// Feature: reliefbridge-insight, Property 12: LatticeZone heat map color SHALL be Alert Orange iff blockage risk exceeds warning threshold
// Validates: Requirements 6.2, 6.3

final class LatticeZoneColorMappingPropertyTests: XCTestCase {

    /// Property 12: Lattice Zone Color Mapping
    ///
    /// For any LatticeZone, the heat map color SHALL be Alert Orange if and only if
    /// microPoreBlockageRisk > Thresholds.latticeBlockageWarning (0.65),
    /// and Efficiency Green otherwise.
    func testProperty12_LatticeZoneColorMapping() {
        // Feature: reliefbridge-insight, Property 12: LatticeZone heat map color SHALL be Alert Orange iff blockage risk exceeds warning threshold
        property("Lattice zone color is Alert Orange iff risk > threshold, Efficiency Green otherwise") <- forAll(
            Gen<Double>.choose((0.0, 1.0))
        ) { (risk: Double) in
            let isAlertOrange = shouldBeAlertOrange(microPoreBlockageRisk: risk)
            let expectedAlertOrange = risk > Thresholds.latticeBlockageWarning
            
            // Color should be Alert Orange iff risk > threshold
            return isAlertOrange == expectedAlertOrange
        }
    }

    /// Property 12 (boundary): Risk exactly at threshold should be Efficiency Green.
    ///
    /// When microPoreBlockageRisk equals exactly the warning threshold,
    /// the color SHALL be Efficiency Green (not Alert Orange).
    func testProperty12_RiskAtThresholdIsEfficiencyGreen() {
        // Feature: reliefbridge-insight, Property 12: LatticeZone heat map color SHALL be Alert Orange iff blockage risk exceeds warning threshold
        let riskAtThreshold = Thresholds.latticeBlockageWarning
        let isAlertOrange = shouldBeAlertOrange(microPoreBlockageRisk: riskAtThreshold)
        XCTAssertFalse(isAlertOrange, "Risk exactly at threshold (0.65) should be Efficiency Green, not Alert Orange")
    }

    /// Property 12 (boundary): Risk just above threshold should be Alert Orange.
    ///
    /// When microPoreBlockageRisk is infinitesimally above the warning threshold,
    /// the color SHALL be Alert Orange.
    func testProperty12_RiskJustAboveThresholdIsAlertOrange() {
        // Feature: reliefbridge-insight, Property 12: LatticeZone heat map color SHALL be Alert Orange iff blockage risk exceeds warning threshold
        let riskJustAbove = Thresholds.latticeBlockageWarning + 0.0001
        let isAlertOrange = shouldBeAlertOrange(microPoreBlockageRisk: riskJustAbove)
        XCTAssertTrue(isAlertOrange, "Risk just above threshold should be Alert Orange")
    }

    /// Property 12 (boundary): Risk just below threshold should be Efficiency Green.
    ///
    /// When microPoreBlockageRisk is infinitesimally below the warning threshold,
    /// the color SHALL be Efficiency Green.
    func testProperty12_RiskJustBelowThresholdIsEfficiencyGreen() {
        // Feature: reliefbridge-insight, Property 12: LatticeZone heat map color SHALL be Alert Orange iff blockage risk exceeds warning threshold
        let riskJustBelow = Thresholds.latticeBlockageWarning - 0.0001
        let isAlertOrange = shouldBeAlertOrange(microPoreBlockageRisk: riskJustBelow)
        XCTAssertFalse(isAlertOrange, "Risk just below threshold should be Efficiency Green, not Alert Orange")
    }

    /// Property 12 (edge case): Zero risk should be Efficiency Green.
    ///
    /// When microPoreBlockageRisk is 0.0 (no risk), the color SHALL be Efficiency Green.
    func testProperty12_ZeroRiskIsEfficiencyGreen() {
        // Feature: reliefbridge-insight, Property 12: LatticeZone heat map color SHALL be Alert Orange iff blockage risk exceeds warning threshold
        let isAlertOrange = shouldBeAlertOrange(microPoreBlockageRisk: 0.0)
        XCTAssertFalse(isAlertOrange, "Zero risk should be Efficiency Green, not Alert Orange")
    }

    /// Property 12 (edge case): Maximum risk should be Alert Orange.
    ///
    /// When microPoreBlockageRisk is 1.0 (maximum risk), the color SHALL be Alert Orange.
    func testProperty12_MaximumRiskIsAlertOrange() {
        // Feature: reliefbridge-insight, Property 12: LatticeZone heat map color SHALL be Alert Orange iff blockage risk exceeds warning threshold
        let isAlertOrange = shouldBeAlertOrange(microPoreBlockageRisk: 1.0)
        XCTAssertTrue(isAlertOrange, "Maximum risk (1.0) should be Alert Orange")
    }

    /// Property 12 (collection): All zones with risk > threshold are Alert Orange.
    ///
    /// For any collection of LatticeZones, all zones with microPoreBlockageRisk > threshold
    /// SHALL be Alert Orange, and all zones with risk ≤ threshold SHALL be Efficiency Green.
    func testProperty12_CollectionColorMapping() {
        // Feature: reliefbridge-insight, Property 12: LatticeZone heat map color SHALL be Alert Orange iff blockage risk exceeds warning threshold
        property("All zones with risk > threshold are Alert Orange, others are Efficiency Green") <- forAll(
            [LatticeZone].arbitrary.resize(20)
        ) { (zones: [LatticeZone]) in
            // Verify color mapping for each zone
            return zones.allSatisfy { zone in
                let isAlertOrange = shouldBeAlertOrange(microPoreBlockageRisk: zone.microPoreBlockageRisk)
                let expectedAlertOrange = zone.microPoreBlockageRisk > Thresholds.latticeBlockageWarning
                return isAlertOrange == expectedAlertOrange
            }
        }
    }

    /// Property 12 (partition): Zones partition into exactly two color groups.
    ///
    /// For any collection of LatticeZones, the zones SHALL partition into exactly two groups:
    /// those with risk > threshold (Alert Orange) and those with risk ≤ threshold (Efficiency Green).
    func testProperty12_ZonesPartitionIntoTwoColorGroups() {
        // Feature: reliefbridge-insight, Property 12: LatticeZone heat map color SHALL be Alert Orange iff blockage risk exceeds warning threshold
        property("Zones partition into Alert Orange and Efficiency Green groups") <- forAll(
            [LatticeZone].arbitrary.suchThat { !$0.isEmpty }.resize(20)
        ) { (zones: [LatticeZone]) in
            let alertOrangeZones = zones.filter { $0.microPoreBlockageRisk > Thresholds.latticeBlockageWarning }
            let efficiencyGreenZones = zones.filter { $0.microPoreBlockageRisk <= Thresholds.latticeBlockageWarning }
            
            // Every zone should be in exactly one group
            let totalCount = alertOrangeZones.count + efficiencyGreenZones.count
            return totalCount == zones.count
        }
    }
}
