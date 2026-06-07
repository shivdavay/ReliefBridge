// ReliefBridgeTests/AviationDarkModeSnapshotTests.swift
// Snapshot tests for Aviation Dark Mode appearance across all five modules.
// Validates: Requirements 1.2, 1.3, 1.4

import XCTest
import SwiftUI
import SnapshotTesting
@testable import ReliefBridge

#if os(macOS)
import AppKit
typealias PlatformColor = NSColor
typealias PlatformHostingController = NSHostingController
#else
import UIKit
typealias PlatformColor = UIColor
typealias PlatformHostingController = UIHostingController
#endif

/// Snapshot tests for Aviation Dark Mode appearance.
///
/// These tests capture the visual appearance of each module's root view with
/// seeded mock data to verify:
/// - Aviation Dark Mode color scheme (#121212 background)
/// - Efficiency Green (#00FF87) for positive metrics
/// - Alert Orange (#FF5722) for warnings
///
/// **Validates: Requirements 1.2, 1.3, 1.4**
@available(iOS 17.0, macOS 14.0, *)
final class AviationDarkModeSnapshotTests: XCTestCase {

    // MARK: - Setup

    /// Shared data service with seeded mock data for all tests.
    private var dataService: SimulatedDataService!

    override func setUp() {
        super.setUp()
        // Create a fresh data service with seeded mock data for each test
        dataService = SimulatedDataService()
        
        // Wait briefly to ensure initialization completes
        XCTAssertTrue(dataService.isInitialized, "Data service should initialize successfully")
        XCTAssertNil(dataService.initializationError, "Data service should not have initialization errors")
    }

    override func tearDown() {
        dataService = nil
        super.tearDown()
    }

    // MARK: - Snapshot Tests

    /// Snapshot test for FleetCommandView with seeded mock data.
    ///
    /// Verifies:
    /// - Aviation Dark Mode background (#121212)
    /// - Map with aircraft annotations
    /// - KPI carousel with Efficiency Green values
    /// - Search bar and filter controls
    ///
    /// **Validates: Requirements 1.2, 1.3, 1.4**
    func testFleetCommandView_AviationDarkMode() {
        let view = FleetCommandView(dataService: dataService)
            .environmentObject(dataService)
            .frame(width: 390, height: 844) // iPhone 14 Pro dimensions
            .aviationDarkMode()

        #if os(macOS)
        let hostingController = NSHostingController(rootView: view)
        hostingController.view.frame = NSRect(x: 0, y: 0, width: 390, height: 844)
        
        assertSnapshot(
            of: hostingController.view,
            as: .image,
            record: false
        )
        #else
        let hostingController = UIHostingController(rootView: view)
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhone13Pro),
            record: false
        )
        #endif
    }

    /// Snapshot test for DigitalTwinView with seeded mock data.
    ///
    /// Verifies:
    /// - Aviation Dark Mode background (#121212)
    /// - 3D SceneKit view with aircraft model
    /// - Telemetry gauges with appropriate colors (Efficiency Green or Alert Orange)
    /// - Drag coefficient chart
    ///
    /// **Validates: Requirements 1.2, 1.3, 1.4**
    func testDigitalTwinView_AviationDarkMode() {
        // Use the first airborne aircraft with telemetry
        guard let aircraft = dataService.aircraft.first(where: { $0.isAirborne }),
              dataService.telemetry[aircraft.tailNumber] != nil else {
            XCTFail("No airborne aircraft with telemetry available")
            return
        }

        let view = DigitalTwinView(tailNumber: aircraft.tailNumber, dataService: dataService)
            .environmentObject(dataService)
            .frame(width: 390, height: 844)
            .aviationDarkMode()

        #if os(macOS)
        let hostingController = NSHostingController(rootView: view)
        hostingController.view.frame = NSRect(x: 0, y: 0, width: 390, height: 844)
        
        assertSnapshot(
            of: hostingController.view,
            as: .image,
            record: false
        )
        #else
        let hostingController = UIHostingController(rootView: view)
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhone13Pro),
            record: false
        )
        #endif
    }

    /// Snapshot test for CarbonEngineView with seeded mock data.
    ///
    /// Verifies:
    /// - Aviation Dark Mode background (#121212)
    /// - Progress ring with appropriate color (Efficiency Green or Alert Orange)
    /// - Generate Audit Report button in Efficiency Green
    /// - Ledger block list with immutability indicators
    ///
    /// **Validates: Requirements 1.2, 1.3, 1.4**
    func testCarbonEngineView_AviationDarkMode() {
        let view = CarbonEngineView(dataService: dataService)
            .environmentObject(dataService)
            .frame(width: 390, height: 844)
            .aviationDarkMode()

        #if os(macOS)
        let hostingController = NSHostingController(rootView: view)
        hostingController.view.frame = NSRect(x: 0, y: 0, width: 390, height: 844)
        
        assertSnapshot(
            of: hostingController.view,
            as: .image,
            record: false
        )
        #else
        let hostingController = UIHostingController(rootView: view)
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhone13Pro),
            record: false
        )
        #endif
    }

    /// Snapshot test for ROIDashboardView with seeded mock data.
    ///
    /// Verifies:
    /// - Aviation Dark Mode background (#121212)
    /// - Stacked bar chart with three color-coded layers
    /// - Acoustic footprint tracker with appropriate color
    /// - Airport selector
    /// - Hypothetical retrofits slider with Efficiency Green tint
    /// - Projected total savings in monospaced Efficiency Green font
    ///
    /// **Validates: Requirements 1.2, 1.3, 1.4**
    func testROIDashboardView_AviationDarkMode() {
        let view = ROIDashboardView(dataService: dataService)
            .environmentObject(dataService)
            .frame(width: 390, height: 844)
            .aviationDarkMode()

        #if os(macOS)
        let hostingController = NSHostingController(rootView: view)
        hostingController.view.frame = NSRect(x: 0, y: 0, width: 390, height: 844)
        
        assertSnapshot(
            of: hostingController.view,
            as: .image,
            record: false
        )
        #else
        let hostingController = UIHostingController(rootView: view)
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhone13Pro),
            record: false
        )
        #endif
    }

    /// Snapshot test for MaintenanceView with seeded mock data.
    ///
    /// Verifies:
    /// - Aviation Dark Mode background (#121212)
    /// - Lattice heat map with color-coded zones (Efficiency Green or Alert Orange)
    /// - Predictive alerts list sorted by severity
    /// - EFB sync control with toggle and status indicator
    ///
    /// **Validates: Requirements 1.2, 1.3, 1.4**
    func testMaintenanceView_AviationDarkMode() {
        let view = MaintenanceView(dataService: dataService)
            .environmentObject(dataService)
            .frame(width: 390, height: 844)
            .aviationDarkMode()

        #if os(macOS)
        let hostingController = NSHostingController(rootView: view)
        hostingController.view.frame = NSRect(x: 0, y: 0, width: 390, height: 844)
        
        assertSnapshot(
            of: hostingController.view,
            as: .image,
            record: false
        )
        #else
        let hostingController = UIHostingController(rootView: view)
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhone13Pro),
            record: false
        )
        #endif
    }

    // MARK: - Color Verification Tests

    /// Verify that the Aviation Dark Mode background color is correctly defined.
    ///
    /// **Validates: Requirements 1.2**
    func testAviationDarkMode_BackgroundColor() {
        let backgroundColor = Theme.Colors.background
        
        // Convert to platform color to extract RGB components
        #if os(macOS)
        let platformColor = NSColor(backgroundColor)
        guard let rgbColor = platformColor.usingColorSpace(.sRGB) else {
            XCTFail("Could not convert to sRGB color space")
            return
        }
        let red = rgbColor.redComponent
        let green = rgbColor.greenComponent
        let blue = rgbColor.blueComponent
        #else
        let platformColor = UIColor(backgroundColor)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        platformColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #endif
        
        // #121212 = RGB(18, 18, 18) = (0.0706, 0.0706, 0.0706) in 0-1 range
        XCTAssertEqual(red, 0.0706, accuracy: 0.001, "Background red component should match #121212")
        XCTAssertEqual(green, 0.0706, accuracy: 0.001, "Background green component should match #121212")
        XCTAssertEqual(blue, 0.0706, accuracy: 0.001, "Background blue component should match #121212")
    }

    /// Verify that Efficiency Green is correctly defined.
    ///
    /// **Validates: Requirements 1.3**
    func testAviationDarkMode_EfficiencyGreenColor() {
        let efficiencyGreen = Theme.Colors.efficiencyGreen
        
        // Convert to platform color to extract RGB components
        #if os(macOS)
        let platformColor = NSColor(efficiencyGreen)
        guard let rgbColor = platformColor.usingColorSpace(.sRGB) else {
            XCTFail("Could not convert to sRGB color space")
            return
        }
        let red = rgbColor.redComponent
        let green = rgbColor.greenComponent
        let blue = rgbColor.blueComponent
        #else
        let platformColor = UIColor(efficiencyGreen)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        platformColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #endif
        
        // #00FF87 = RGB(0, 255, 135) = (0.0, 1.0, 0.529) in 0-1 range
        XCTAssertEqual(red, 0.0, accuracy: 0.001, "Efficiency Green red component should match #00FF87")
        XCTAssertEqual(green, 1.0, accuracy: 0.001, "Efficiency Green green component should match #00FF87")
        XCTAssertEqual(blue, 0.529, accuracy: 0.01, "Efficiency Green blue component should match #00FF87")
    }

    /// Verify that Alert Orange is correctly defined.
    ///
    /// **Validates: Requirements 1.4**
    func testAviationDarkMode_AlertOrangeColor() {
        let alertOrange = Theme.Colors.alertOrange
        
        // Convert to platform color to extract RGB components
        #if os(macOS)
        let platformColor = NSColor(alertOrange)
        guard let rgbColor = platformColor.usingColorSpace(.sRGB) else {
            XCTFail("Could not convert to sRGB color space")
            return
        }
        let red = rgbColor.redComponent
        let green = rgbColor.greenComponent
        let blue = rgbColor.blueComponent
        #else
        let platformColor = UIColor(alertOrange)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        platformColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #endif
        
        // #FF5722 = RGB(255, 87, 34) = (1.0, 0.341, 0.133) in 0-1 range
        XCTAssertEqual(red, 1.0, accuracy: 0.001, "Alert Orange red component should match #FF5722")
        XCTAssertEqual(green, 0.341, accuracy: 0.01, "Alert Orange green component should match #FF5722")
        XCTAssertEqual(blue, 0.133, accuracy: 0.01, "Alert Orange blue component should match #FF5722")
    }
}
