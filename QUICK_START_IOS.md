# Quick Start: Run on iPhone Simulator

## TL;DR

```bash
# 1. Install the helper tools once
brew install xcodegen

# 2. Install full Xcode from Apple and select it
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer

# 3. Build and launch on the simulator
./run-ios-simulator.sh
```

## What Changed

This project now uses a generated Xcode iOS app project instead of trying to run the Swift package directly. The package still exists for source organization and tests, but the simulator launch path is:

1. `xcodegen generate`
2. `xcodebuild -project ReliefBridgeApp.xcodeproj`
3. `xcrun simctl install`
4. `xcrun simctl launch`

## Requirements

- Full Xcode installed at `/Applications/Xcode.app`
- Command line tools pointed at Xcode, not just Command Line Tools
- `xcodegen` installed with Homebrew

## Customizing the Simulator

By default, the script uses `iPhone 15 Pro`. To use a different simulator for a single run:

```bash
SIMULATOR_NAME="iPhone 16" ./run-ios-simulator.sh
```

To see available simulators:

```bash
xcrun simctl list devices available | grep iPhone
```

## Troubleshooting

### `xcodebuild` or `simctl` is unavailable

Install full Xcode and select it:

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -license accept
```

### `xcodegen` not found

Install it with Homebrew:

```bash
brew install xcodegen
```

### Simulator not found

The script will show the available devices and let you choose a different one.

## Useful Commands

```bash
xcrun simctl spawn booted log stream --predicate 'processImagePath contains "ReliefBridgeApp"'
xcrun simctl uninstall booted com.reliefbridge.app
xcrun simctl shutdown all
```
