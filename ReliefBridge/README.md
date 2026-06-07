# ReliefBridge Insight — Project Setup

## Overview

ReliefBridge Insight is an enterprise-grade B2B iOS application built with SwiftUI (iOS 17+), targeting airline executives, sustainability officers, maintenance chiefs, and CFOs.

## Creating the Xcode Project

Because Xcode project files (`.xcodeproj`) cannot be generated from the command line, follow these steps:

1. Open Xcode → **File → New → Project**
2. Choose **iOS → App**
3. Set the following options:
   - **Product Name**: `ReliefBridge`
   - **Interface**: SwiftUI
   - **Language**: Swift
   - **Minimum Deployment**: iOS 17.0
4. Save the project at the root of this repository
5. Add all existing Swift source files from the `ReliefBridge/` directory to the Xcode target

## Adding Swift Package Dependencies

In Xcode, go to **File → Add Package Dependencies…** and add:

| Package | URL | Version |
|---|---|---|
| SwiftCheck | `https://github.com/typelift/SwiftCheck.git` | `0.12.0` |
| swift-snapshot-testing | `https://github.com/pointfreeco/swift-snapshot-testing.git` | `1.15.0` |

**Swift Charts** is a built-in Apple framework (iOS 16+) — add `import Charts` where needed, no SPM entry required.

## Asset Catalog — Accent Color

To set Efficiency Green (`#00FF87`) as the global accent color:

1. Open `Assets.xcassets` in Xcode
2. Create a new **Color Set** named `AccentColor`
3. Set the color to:
   - **Hex**: `#00FF87`
   - **Appearance**: Any / Dark (both set to the same value for Aviation Dark Mode)

The `ReliefBridgeApp.swift` entry point also applies `.tint(Theme.Colors.efficiencyGreen)` programmatically as a fallback.

## Directory Structure

```
ReliefBridge/
├── App/
│   └── ReliefBridgeApp.swift        # @main entry point, ContentView, MainTabView, DataUnavailableView
├── Models/
│   ├── Models.swift                # All core domain model types
│   └── Thresholds.swift            # Warning threshold constants
├── Theme/
│   └── Theme.swift                 # Aviation Dark Mode colors, fonts, ViewModifier
├── Features/                       # (created in subsequent tasks)
│   ├── FleetCommand/
│   ├── DigitalTwin/
│   ├── CarbonCompliance/
│   ├── ROIDashboard/
│   └── Maintenance/
└── Services/                       # (created in Task 3)
    └── SimulatedDataService.swift
```

## Aviation Dark Mode Theme

| Token | Hex | Usage |
|---|---|---|
| Background | `#121212` | All background surfaces |
| Efficiency Green | `#00FF87` | Positive metrics, active state, accent |
| Alert Orange | `#FF5722` | Warnings, threshold breaches, errors |

All real-time numeric readouts use a **monospaced font** for digit alignment stability.
All section headers and labels use a **modern sans-serif font**.
