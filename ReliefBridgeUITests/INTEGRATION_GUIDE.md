# XCUITest Integration Guide for ReliefBridge Insight

This guide explains how to integrate the XCUITest smoke tests into your ReliefBridge Insight project.

## Background

The ReliefBridge Insight project is currently structured as a Swift Package Manager (SPM) package. XCUITest requires an Xcode project (`.xcodeproj`) to run UI tests. This guide provides step-by-step instructions for creating the necessary project structure.

## Quick Start

### Step 1: Create an Xcode Project

1. **Open Xcode**
2. **File → New → Project...**
3. Select **iOS → App**
4. Configure the project:
   - **Product Name:** `ReliefBridge`
   - **Team:** Your development team
   - **Organization Identifier:** `com.reliefbridge` (or your identifier)
   - **Interface:** SwiftUI
   - **Language:** Swift
   - **Storage:** None
   - **Include Tests:** ✅ (check this box)
   - **Include UI Tests:** ✅ (check this box)
5. **Save** the project in the same directory as your `Package.swift`

### Step 2: Link the Swift Package

1. In Xcode, select the project in the navigator
2. Select the **ReliefBridge** target
3. Go to the **General** tab
4. Under **Frameworks, Libraries, and Embedded Content**, click **+**
5. Click **Add Other... → Add Package Dependency...**
6. Click **Add Local...**
7. Navigate to and select the directory containing `Package.swift`
8. Click **Add Package**
9. Select the `ReliefBridge` library and click **Add**

### Step 3: Configure the App Target

1. Delete the default `ContentView.swift` and `ReliefBridgeApp.swift` files created by Xcode
2. In the project navigator, right-click the app target folder
3. Select **Add Files to "ReliefBridge"...**
4. Navigate to `ReliefBridge/App/ReliefBridgeApp.swift`
5. **Important:** Uncheck "Copy items if needed" (we want to reference the original file)
6. Click **Add**

### Step 4: Add UI Test Files

1. In the project navigator, find the `ReliefBridgeUITests` group (created automatically)
2. Delete the default test file
3. Right-click the `ReliefBridgeUITests` group
4. Select **Add Files to "ReliefBridge"...**
5. Navigate to `ReliefBridgeUITests/ReliefBridgeUITests.swift`
6. **Important:** Uncheck "Copy items if needed"
7. Ensure the file is added to the `ReliefBridgeUITests` target
8. Click **Add**

### Step 5: Configure Build Settings

1. Select the project in the navigator
2. Select the **ReliefBridge** app target
3. Go to **Build Settings**
4. Search for "Deployment Target"
5. Set **iOS Deployment Target** to **17.0**

### Step 6: Run the Tests

1. Select the **ReliefBridgeUITests** scheme from the scheme selector
2. Choose a simulator (iPhone 15 Pro recommended)
3. Press **⌘U** or go to **Product → Test**

## Alternative: Minimal Xcode Project Setup

If you prefer to keep the SPM structure and create a minimal Xcode wrapper:

### Create App Wrapper

Create a new file `ReliefBridgeApp/main.swift`:

```swift
import SwiftUI
import ReliefBridge

@main
struct ReliefBridgeAppWrapper: App {
    var body: some Scene {
        WindowGroup {
            ReliefBridgeApp()
        }
    }
}
```

Then follow the steps above to create the Xcode project and link this wrapper.

## Troubleshooting

### Issue: "No such module 'ReliefBridge'"

**Solution:**
1. Verify the SPM package is added as a dependency
2. Clean the build folder: **Product → Clean Build Folder** (⇧⌘K)
3. Rebuild the project: **Product → Build** (⌘B)

### Issue: "Cannot find 'ReliefBridgeApp' in scope"

**Solution:**
1. Ensure `ReliefBridgeApp.swift` is added to the app target
2. Check that the file is not excluded from the SPM target in `Package.swift`
3. Verify the import statement: `import SwiftUI`

### Issue: UI tests fail with "Failed to launch app"

**Solution:**
1. Verify the app builds and runs successfully first
2. Check that the simulator is running and responsive
3. Reset the simulator: **Device → Erase All Content and Settings...**
4. Clean and rebuild: **Product → Clean Build Folder**, then **Product → Build**

### Issue: Map annotations not found in tests

**Solution:**
1. Verify `SimulatedDataService` is seeding aircraft with `isAirborne = true`
2. Increase the wait time in the test (change `sleep(3)` to `sleep(5)`)
3. Check that aircraft coordinates are valid
4. Add accessibility identifiers to map annotations for more reliable testing

### Issue: Tests pass in Xcode but fail from command line

**Solution:**
1. Ensure the scheme is shared: **Product → Scheme → Manage Schemes...**
2. Check the "Shared" checkbox for `ReliefBridgeUITests`
3. Verify the scheme includes the UI test target in the Test action

## Project Structure

After setup, your project structure should look like:

```
ReliefBridge/
├── ReliefBridge.xcodeproj/       # Xcode project (new)
├── ReliefBridge/                 # SPM package source
│   ├── App/
│   │   └── ReliefBridgeApp.swift       # App entry point
│   ├── Models/
│   ├── Services/
│   ├── ViewModels/
│   └── Views/
├── ReliefBridgeTests/            # Unit tests
├── ReliefBridgeUITests/          # UI tests (new)
│   ├── ReliefBridgeUITests.swift
│   ├── Info.plist
│   └── README.md
└── Package.swift                       # SPM manifest
```

## Running Tests from Command Line

Once the Xcode project is set up:

```bash
# List available schemes
xcodebuild -project ReliefBridge.xcodeproj -list

# Run UI tests
xcodebuild test \
  -project ReliefBridge.xcodeproj \
  -scheme ReliefBridgeUITests \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=17.0'

# Run with verbose output
xcodebuild test \
  -project ReliefBridge.xcodeproj \
  -scheme ReliefBridgeUITests \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=17.0' \
  -verbose

# Run and save results
xcodebuild test \
  -project ReliefBridge.xcodeproj \
  -scheme ReliefBridgeUITests \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=17.0' \
  -resultBundlePath TestResults.xcresult
```

## Continuous Integration

For CI/CD pipelines (GitHub Actions, GitLab CI, etc.):

```yaml
# Example GitHub Actions workflow
name: UI Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Select Xcode version
        run: sudo xcode-select -s /Applications/Xcode_16.0.app
      
      - name: Run UI Tests
        run: |
          xcodebuild test \
            -project ReliefBridge.xcodeproj \
            -scheme ReliefBridgeUITests \
            -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=17.0' \
            -resultBundlePath TestResults.xcresult
      
      - name: Upload Test Results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: test-results
          path: TestResults.xcresult
```

## Best Practices

1. **Keep UI tests focused:** Test high-level user flows, not implementation details
2. **Use accessibility identifiers:** Add `.accessibilityIdentifier()` to key UI elements
3. **Wait for elements:** Always use `waitForExistence(timeout:)` instead of fixed delays
4. **Test on multiple devices:** Run tests on different screen sizes (iPhone SE, iPhone 15 Pro Max)
5. **Keep tests independent:** Each test should be able to run in isolation
6. **Use page objects:** For complex flows, consider the Page Object pattern
7. **Record tests:** Use Xcode's UI test recording feature to generate test code

## Next Steps

After setting up the UI tests:

1. **Run the tests** to verify they pass
2. **Add accessibility identifiers** to improve test reliability
3. **Expand test coverage** with additional scenarios:
   - Search functionality
   - Filter functionality
   - KPI card interactions
   - Telemetry gauge updates
   - Carbon ledger scrolling
   - ROI slider interactions
   - Maintenance alert interactions
4. **Integrate with CI/CD** for automated testing
5. **Add snapshot tests** for visual regression testing

## Support

For questions or issues:

1. Check the [README.md](README.md) in this directory
2. Review the [Design Document](.kiro/specs/reliefbridge-insight/design.md)
3. Review the [Requirements Document](.kiro/specs/reliefbridge-insight/requirements.md)
4. Check existing unit tests in `ReliefBridgeTests/` for examples

## References

- [XCTest Framework Documentation](https://developer.apple.com/documentation/xctest)
- [XCUITest Documentation](https://developer.apple.com/documentation/xctest/user_interface_tests)
- [Swift Package Manager Documentation](https://swift.org/package-manager/)
- [SwiftUI Testing Best Practices](https://developer.apple.com/documentation/swiftui/testing-your-swiftui-views)
