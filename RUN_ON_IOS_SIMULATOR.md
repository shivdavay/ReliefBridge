# How to Run ReliefBridge Insight on iPhone Simulator

## Quick Start

This repo now builds through a generated Xcode iOS app project.

```bash
brew install xcodegen
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
./run-ios-simulator.sh
```

## Why This Works

`swift run` and the raw Swift package cannot create a runnable iOS app bundle. The updated flow generates an actual Xcode app project named `ReliefBridgeApp.xcodeproj`, then builds that project for the simulator.

## What the Script Does

1. Verifies `xcodegen` is installed
2. Verifies full Xcode is available
3. Generates `ReliefBridgeApp.xcodeproj` from `project.yml`
4. Boots the requested simulator
5. Builds the app with `xcodebuild`
6. Installs and launches the `.app` bundle

## Manual Commands

### 1. Generate the Xcode Project

```bash
xcodegen generate --spec project.yml
```

### 2. Build for the Simulator

```bash
xcodebuild \
  -project ReliefBridgeApp.xcodeproj \
  -scheme ReliefBridgeApp \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -configuration Debug \
  -derivedDataPath ./build \
  build
```

### 3. Install and Launch

```bash
xcrun simctl install booted ./build/Build/Products/Debug-iphonesimulator/ReliefBridgeApp.app
xcrun simctl launch booted com.reliefbridge.app
```

## Requirements

- Full Xcode installed at `/Applications/Xcode.app`
- Xcode selected as the active developer directory
- `xcodegen` installed via Homebrew
- An installed iOS simulator runtime

## Troubleshooting

### `xcodebuild` says full Xcode is required

The system is still pointed at Command Line Tools only. Fix it with:

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -license accept
```

### `simctl` is unavailable

That means simulator tooling is still not coming from full Xcode. Install Xcode and re-run `xcode-select`.

### `xcodegen` not found

Install it with:

```bash
brew install xcodegen
```

### Need a different simulator

Use:

```bash
SIMULATOR_NAME="iPhone 16" ./run-ios-simulator.sh
```

See available devices with:

```bash
xcrun simctl list devices available | grep iPhone
```

## Notes

The Swift package remains useful for source organization and tests, but the iOS simulator build path now goes through the generated Xcode app project. That avoids the previous failure mode where the package built successfully as a library but never produced a runnable `.app` bundle.
