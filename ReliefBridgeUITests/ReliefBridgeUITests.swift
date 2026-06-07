// ReliefBridgeUITests/ReliefBridgeUITests.swift
// XCUITest smoke tests for ReliefBridge Insight
// Validates: Requirements 1.1, 1.7, 2.12

import XCTest

/// Smoke tests verifying core navigation and tab functionality.
///
/// These tests validate:
/// - All five tabs are present and tappable on launch (Req 1.1, 1.7)
/// - Tapping a map annotation navigates to Digital Twin with correct tail number (Req 2.12)
final class ReliefBridgeUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        // Stop immediately when a failure occurs
        continueAfterFailure = false

        // Launch the application
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Tab Navigation Tests

    /// **Test: All five tabs are present and tappable on launch**
    ///
    /// Validates Requirements 1.1, 1.7:
    /// - The app SHALL render a TabView with exactly five tabs
    /// - The TabView SHALL default to the Fleet Command tab on launch
    func testAllFiveTabsArePresentAndTappable() throws {
        // Wait for the app to initialize
        // The app may show a loading spinner briefly before showing the main tab view
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(
            tabBar.waitForExistence(timeout: 5.0),
            "Tab bar should appear within 5 seconds of launch"
        )

        // Verify all five tabs exist by their labels
        let fleetCommandTab = tabBar.buttons["Fleet Command"]
        let digitalTwinTab = tabBar.buttons["Digital Twin"]
        let carbonTab = tabBar.buttons["Carbon"]
        let financialROITab = tabBar.buttons["Financial ROI"]
        let maintenanceTab = tabBar.buttons["Maintenance"]

        XCTAssertTrue(fleetCommandTab.exists, "Fleet Command tab should exist")
        XCTAssertTrue(digitalTwinTab.exists, "Digital Twin tab should exist")
        XCTAssertTrue(carbonTab.exists, "Carbon tab should exist")
        XCTAssertTrue(financialROITab.exists, "Financial ROI tab should exist")
        XCTAssertTrue(maintenanceTab.exists, "Maintenance tab should exist")

        // Verify Fleet Command tab is selected by default (Requirement 1.7)
        XCTAssertTrue(
            fleetCommandTab.isSelected,
            "Fleet Command tab should be selected on launch (Requirement 1.7)"
        )

        // Tap each tab to verify they are tappable and responsive
        digitalTwinTab.tap()
        XCTAssertTrue(
            digitalTwinTab.isSelected,
            "Digital Twin tab should be selected after tapping"
        )

        carbonTab.tap()
        XCTAssertTrue(
            carbonTab.isSelected,
            "Carbon tab should be selected after tapping"
        )

        financialROITab.tap()
        XCTAssertTrue(
            financialROITab.isSelected,
            "Financial ROI tab should be selected after tapping"
        )

        maintenanceTab.tap()
        XCTAssertTrue(
            maintenanceTab.isSelected,
            "Maintenance tab should be selected after tapping"
        )

        // Return to Fleet Command tab
        fleetCommandTab.tap()
        XCTAssertTrue(
            fleetCommandTab.isSelected,
            "Fleet Command tab should be selected after tapping"
        )
    }

    // MARK: - Navigation Tests

    /// **Test: Tapping a map annotation navigates to Digital Twin with correct tail number**
    ///
    /// Validates Requirement 2.12:
    /// - WHEN a map annotation is tapped, THE Fleet_Command SHALL navigate to the
    ///   Digital_Twin view pre-loaded with that aircraft's Tail_Number
    func testTappingMapAnnotationNavigatesToDigitalTwin() throws {
        // Wait for the app to initialize and show the Fleet Command view
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(
            tabBar.waitForExistence(timeout: 5.0),
            "Tab bar should appear within 5 seconds of launch"
        )

        // Ensure we're on the Fleet Command tab
        let fleetCommandTab = tabBar.buttons["Fleet Command"]
        if !fleetCommandTab.isSelected {
            fleetCommandTab.tap()
        }

        // Wait for the map to load
        // The map view should be present in the Fleet Command view
        let mapView = app.otherElements["Map"]
        XCTAssertTrue(
            mapView.waitForExistence(timeout: 5.0),
            "Map view should appear within 5 seconds"
        )

        // Wait for map annotations to appear
        // Map annotations are rendered as buttons or interactive elements
        // We'll look for any annotation by checking for elements with tail number patterns
        // Tail numbers follow the pattern like "G-AERO1", "N-AERO2", etc.
        
        // Give the simulated data service time to populate aircraft
        sleep(3)

        // Find the first map annotation
        // Annotations are typically rendered as buttons or other interactive elements
        // We'll search for any element that looks like a tail number
        let annotations = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'AERO'"))
        
        // If no annotations are found as buttons, try other element types
        var annotationElement: XCUIElement?
        if annotations.count > 0 {
            annotationElement = annotations.firstMatch
        } else {
            // Try finding annotations as other elements
            let otherAnnotations = app.otherElements.matching(NSPredicate(format: "label CONTAINS[c] 'AERO'"))
            if otherAnnotations.count > 0 {
                annotationElement = otherAnnotations.firstMatch
            }
        }

        guard let annotation = annotationElement, annotation.exists else {
            XCTFail("At least one map annotation should be present. Ensure SimulatedDataService seeds airborne aircraft.")
            return
        }

        // Extract the tail number from the annotation label
        let tailNumber = annotation.label

        // Tap the annotation
        annotation.tap()

        // Wait for navigation to Digital Twin view
        // The Digital Twin view should have a navigation title matching the tail number
        let navigationBar = app.navigationBars[tailNumber]
        XCTAssertTrue(
            navigationBar.waitForExistence(timeout: 3.0),
            "Digital Twin view with navigation title '\(tailNumber)' should appear after tapping annotation"
        )

        // Verify we're on the Digital Twin view by checking for telemetry gauges
        // The Digital Twin view contains gauge titles like "Ram Air Intake Pressure"
        let ramAirGauge = app.staticTexts["Ram Air Intake Pressure"]
        XCTAssertTrue(
            ramAirGauge.exists,
            "Digital Twin view should display telemetry gauges"
        )

        // Navigate back to Fleet Command
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        if backButton.exists {
            backButton.tap()
        }

        // Verify we're back on Fleet Command
        XCTAssertTrue(
            fleetCommandTab.isSelected,
            "Should return to Fleet Command tab after navigating back"
        )
    }

    // MARK: - Launch Performance Test

    /// **Test: App launch performance**
    ///
    /// Measures the time it takes for the app to launch and become interactive.
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
