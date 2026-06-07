# ReliefBridge Insight UI Tests

This directory contains XCUITest smoke tests for the ReliefBridge Insight iOS application.

## Overview

The UI tests validate core navigation and tab functionality:

1. **Tab Navigation Test** (`testAllFiveTabsArePresentAndTappable`)
   - Verifies all five tabs are present on launch
   - Verifies Fleet Command tab is selected by default
   - Verifies each tab is tappable and responsive
   - **Validates Requirements:** 1.1, 1.7

2. **Map Annotation Navigation Test** (`testTappingMapAnnotationNavigatesToDigitalTwin`)
   - Verifies tapping a map annotation navigates to Digital Twin view
   - Verifies the correct tail number is passed to Digital Twin
   - Verifies navigation back to Fleet Command works correctly
   - **Validates Requirements:** 2.12

3. **Launch Performance Test** (`testLaunchPerformance`)
   - Measures app launch time and performance

## Setup Instructions

### Option 1: Add to Existing Xcode Project

If you have an existing Xcode project (`.xcodeproj`):

1. Open your Xcode project
2. Go to **File → New → Target...**
3. Select **iOS → Test → UI Testing Bundle**
4. Name it `ReliefBridgeUITests`
5. Set the target to be tested to your main app target
6. Replace the generated test file with `ReliefBridgeUITests.swift` from this directory
7. Add the `Info.plist` from this directory to the UI test target

### Option 2: Create New Xcode Project from SPM Package

If you're working with a Swift Package Manager project:

1. Open Xcode
2. Go to **File → New → Project...**
3. Select **iOS → App**
4. Name it `ReliefBridge`
5. Choose SwiftUI for Interface and Swift for Language
6. Set minimum deployment target to iOS 17.0
7. In the project navigator, add the SPM package as a local dependency:
   - Select the project in the navigator
   - Go to the project settings → **Package Dependencies**
   - Click **+** and select **Add Local...**
   - Choose the directory containing `Package.swift`
8. Add a UI Testing Bundle target:
   - Go to **File → New → Target...**
   - Select **iOS → Test → UI Testing Bundle**
   - Name it `ReliefBridgeUITests`
9. Copy the test files from this directory into the UI test target

### Option 3: Open Package.swift Directly in Xcode

Modern Xcode versions can open Swift packages directly:

1. Open `Package.swift` in Xcode (double-click or use **File → Open**)
2. Xcode will automatically resolve dependencies
3. To add UI tests, you'll need to create an Xcode project wrapper (see Option 2)

**Note:** Pure Swift Package Manager projects don't support UI test targets. You need an Xcode project to run XCUITests.

## Running the Tests

### From Xcode

1. Open the Xcode project
2. Select the `ReliefBridgeUITests` scheme
3. Choose a simulator (iPhone 15 Pro or similar recommended)
4. Press **⌘U** or go to **Product → Test**

### From Command Line

```bash
# List available simulators
xcrun simctl list devices

# Run tests on a specific simulator
xcodebuild test \
  -project ReliefBridge.xcodeproj \
  -scheme ReliefBridgeUITests \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=17.0'
```

## Test Requirements

### Prerequisites

- **Xcode 16.0+** (for iOS 17 support)
- **iOS 17.0+ Simulator** or device
- **SimulatedDataService** must be properly initialized with:
  - At least 10 aircraft records
  - At least one aircraft with `isAirborne = true` (for map annotation test)
  - Unique tail numbers for each aircraft

### Expected Behavior

1. **App Launch:**
   - App should launch within 5 seconds
   - Tab bar should appear after initialization
   - Fleet Command tab should be selected by default

2. **Tab Navigation:**
   - All five tabs should be visible and labeled correctly
   - Tapping each tab should select it and show the corresponding view
   - Tab selection state should be visually indicated

3. **Map Annotation Navigation:**
   - Map should load within 5 seconds
   - At least one aircraft annotation should be visible (airborne aircraft only)
   - Tapping an annotation should navigate to Digital Twin view
   - Digital Twin view should display the correct tail number in the navigation bar
   - Digital Twin view should show telemetry gauges
   - Back navigation should return to Fleet Command

## Troubleshooting

### No Map Annotations Visible

If the map annotation test fails because no annotations are found:

1. Verify `SimulatedDataService` is seeding aircraft with `isAirborne = true`
2. Check that aircraft coordinates are valid (latitude: -90 to 90, longitude: -180 to 180)
3. Increase the sleep time in the test to allow more time for data loading
4. Check the map camera position covers the area where aircraft are located

### Navigation Bar Not Found

If the Digital Twin navigation bar is not found:

1. Verify the `DigitalTwinView` sets `.navigationTitle(tailNumber)`
2. Check that the navigation is using `NavigationStack` (iOS 16+) or `NavigationView`
3. Ensure the tail number string matches exactly (case-sensitive)

### Tabs Not Appearing

If tabs don't appear within the timeout:

1. Check `SimulatedDataService` initialization completes successfully
2. Verify `ContentView` shows `MainTabView` when `isInitialized == true`
3. Check for any initialization errors in the console
4. Increase the timeout in `waitForExistence(timeout:)`

## Accessibility Identifiers

For more robust UI testing, consider adding accessibility identifiers to key UI elements:

```swift
// In FleetCommandView
Map(position: $cameraPosition) { ... }
    .accessibilityIdentifier("fleetCommandMap")

// In AircraftMapAnnotation
AircraftMapAnnotation(aircraft: aircraft)
    .accessibilityIdentifier("mapAnnotation_\(aircraft.tailNumber)")

// In DigitalTwinView
TelemetryGaugeView(...)
    .accessibilityIdentifier("ramAirPressureGauge")
```

Then update the tests to use these identifiers:

```swift
let mapView = app.otherElements["fleetCommandMap"]
let annotation = app.buttons["mapAnnotation_G-AERO1"]
```

## Test Coverage

These smoke tests provide basic coverage of:

- ✅ App launch and initialization
- ✅ Tab bar presence and navigation
- ✅ Default tab selection
- ✅ Map annotation interaction
- ✅ Navigation to Digital Twin view
- ✅ Tail number propagation
- ✅ Back navigation

For comprehensive testing, consider adding:

- Search functionality tests
- Filter functionality tests
- KPI card interaction tests
- Telemetry gauge value verification
- Carbon ledger scrolling and interaction
- ROI slider interaction
- Maintenance alert interaction
- EFB sync toggle tests
- Error state handling (data unavailable view)

## Related Documentation

- **Requirements:** `.kiro/specs/reliefbridge-insight/requirements.md`
- **Design:** `.kiro/specs/reliefbridge-insight/design.md`
- **Tasks:** `.kiro/specs/reliefbridge-insight/tasks.md`
- **Unit Tests:** `ReliefBridgeTests/`
- **Property Tests:** `ReliefBridgeTests/*PropertyTests.swift`
