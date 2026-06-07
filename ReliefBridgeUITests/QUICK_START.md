# Quick Start: Running XCUITests

## Prerequisites

- ✅ Xcode 16.0+ installed
- ✅ iOS 17.0+ Simulator available
- ✅ Xcode project created (see INTEGRATION_GUIDE.md if not)

## Run Tests in Xcode (Recommended)

1. Open `ReliefBridge.xcodeproj` in Xcode
2. Select **ReliefBridgeUITests** scheme
3. Choose **iPhone 15 Pro** simulator
4. Press **⌘U** (or Product → Test)

## Run Tests from Terminal

```bash
xcodebuild test \
  -project ReliefBridge.xcodeproj \
  -scheme ReliefBridgeUITests \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=17.0'
```

## What Gets Tested

### ✅ Test 1: Tab Navigation
- All five tabs are present
- Fleet Command tab is selected by default
- Each tab is tappable and responsive

### ✅ Test 2: Map Annotation Navigation
- Tapping a map annotation navigates to Digital Twin
- Correct tail number is displayed
- Back navigation works correctly

### ✅ Test 3: Launch Performance
- Measures app launch time

## Expected Results

All tests should **PASS** ✅

```
Test Suite 'ReliefBridgeUITests' passed
     ✓ testAllFiveTabsArePresentAndTappable (3.2 seconds)
     ✓ testTappingMapAnnotationNavigatesToDigitalTwin (4.1 seconds)
     ✓ testLaunchPerformance (2.8 seconds)
```

## If Tests Fail

### "Tab bar should appear within 5 seconds"
- Check `SimulatedDataService` initialization
- Verify no errors in console
- Increase timeout if needed

### "At least one map annotation should be present"
- Verify aircraft are seeded with `isAirborne = true`
- Check aircraft coordinates are valid
- Increase wait time in test

### "Digital Twin view should appear"
- Verify navigation is working
- Check `DigitalTwinView` has correct navigation title
- Ensure tail number matches exactly

## Need Help?

1. **Setup Issues:** See [INTEGRATION_GUIDE.md](INTEGRATION_GUIDE.md)
2. **Test Details:** See [README.md](README.md)
3. **Requirements:** See `.kiro/specs/reliefbridge-insight/requirements.md`

## Quick Commands

```bash
# List available simulators
xcrun simctl list devices

# Boot a simulator
xcrun simctl boot "iPhone 15 Pro"

# Run tests with verbose output
xcodebuild test \
  -project ReliefBridge.xcodeproj \
  -scheme ReliefBridgeUITests \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=17.0' \
  -verbose

# Clean build folder
xcodebuild clean \
  -project ReliefBridge.xcodeproj \
  -scheme ReliefBridgeUITests
```

## Test Duration

- **Total:** ~10-15 seconds
- **Per test:** 2-5 seconds
- **First run:** May take longer (simulator boot, app install)

## Validated Requirements

- ✅ **Requirement 1.1:** TabView with five tabs
- ✅ **Requirement 1.7:** Default to Fleet Command tab
- ✅ **Requirement 2.12:** Map annotation navigation to Digital Twin
