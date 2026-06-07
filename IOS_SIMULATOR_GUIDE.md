# Running ReliefBridge Insight on iOS Simulator

## The Problem

Swift Package Manager (`swift run`) **only supports macOS targets**. It cannot run iOS apps on the simulator. To run on iPhone simulator, you must use Xcode's build system (`xcodebuild`).

## The Solution

You have two options:

### Option 1: Automated Script (Recommended)

Run the provided script that handles everything automatically:

```bash
chmod +x run-ios-simulator.sh
./run-ios-simulator.sh
```

This script will:
1. Check for required tools (Xcode, xcodebuild)
2. Boot the iPhone simulator
3. Generate an Xcode project from Package.swift
4. Build the app for iOS Simulator
5. Install and launch the app

### Option 2: Manual Command-Line Steps

If you prefer to run commands manually:

#### Step 1: Boot the Simulator

```bash
# List available simulators
xcrun simctl list devices | grep iPhone

# Boot a specific simulator (replace with your preferred device)
xcrun simctl boot "iPhone 15 Pro"

# Open Simulator app
open -a Simulator
```

#### Step 2: Generate Xcode Project

Swift Package Manager can generate an Xcode project:

```bash
swift package generate-xcodeproj
```

This creates `ReliefBridge.xcodeproj` from your `Package.swift`.

#### Step 3: Build for iOS Simulator

```bash
xcodebuild \
  -project ReliefBridge.xcodeproj \
  -scheme ReliefBridge-Package \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -configuration Debug \
  -derivedDataPath ./build \
  build
```

#### Step 4: Install on Simulator

```bash
# Find the built app
APP_PATH=$(find ./build/Build/Products/Debug-iphonesimulator -name "*.app" -type d | head -1)

# Get simulator ID
SIMULATOR_ID=$(xcrun simctl list devices | grep "iPhone 15 Pro" | grep "Booted" | grep -oE '\([A-F0-9-]+\)' | tr -d '()')

# Install the app
xcrun simctl install "$SIMULATOR_ID" "$APP_PATH"
```

#### Step 5: Launch the App

```bash
# Launch using bundle identifier
xcrun simctl launch "$SIMULATOR_ID" com.reliefbridge.app
```

## One-Liner (After Initial Setup)

Once you've generated the Xcode project once, you can use this one-liner:

```bash
xcrun simctl boot "iPhone 15 Pro" && open -a Simulator && xcodebuild -project ReliefBridge.xcodeproj -scheme ReliefBridge-Package -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -derivedDataPath ./build build && xcrun simctl install booted $(find ./build/Build/Products/Debug-iphonesimulator -name "*.app" -type d | head -1) && xcrun simctl launch booted com.reliefbridge.app
```

## Troubleshooting

### "No such module 'ReliefBridge'"

The generated Xcode project might not include the App target properly. You need to:

1. Open `ReliefBridge.xcodeproj` in Xcode
2. Add a new iOS App target
3. Link the ReliefBridge library to the app target
4. Copy `ReliefBridgeApp.swift` to the app target

### "Unable to boot device"

The simulator might be in a bad state:

```bash
# Shutdown all simulators
xcrun simctl shutdown all

# Erase the simulator
xcrun simctl erase "iPhone 15 Pro"

# Try booting again
xcrun simctl boot "iPhone 15 Pro"
```

### "Build failed"

Make sure all dependencies are resolved:

```bash
swift package resolve
swift package update
```

### Different Simulator Device

To use a different simulator, replace "iPhone 15 Pro" with your preferred device from:

```bash
xcrun simctl list devices | grep iPhone
```

## Why Can't We Use `swift run`?

`swift run` is designed for command-line tools and macOS apps. iOS apps require:
- Code signing
- Provisioning profiles
- iOS-specific entitlements
- Simulator runtime environment
- App bundle structure with Info.plist

These are all handled by Xcode's build system (`xcodebuild`), not by Swift Package Manager's `swift run` command.

## Alternative: Use Xcode GUI

If command-line is too complex, you can:

1. Open `Package.swift` in Xcode (double-click it)
2. Xcode will automatically create a workspace
3. Select an iOS Simulator from the device menu
4. Click the Run button (⌘R)

This is the simplest approach but doesn't provide command-line automation.
