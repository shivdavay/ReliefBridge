# Creating an Xcode iOS App Project for ReliefBridge Insight

## The Problem

Your Swift Package builds successfully as a **library** (`.o` object file), but iOS apps need to be packaged as **app bundles** (`.app` directories) with:
- Info.plist
- App icons
- Launch screens
- Code signing
- Entitlements

Swift Package Manager cannot create iOS app bundles - you need an Xcode project.

## Solution: Create Xcode iOS App Project

### Option 1: Automated Script (Recommended)

I'll create a script that generates the Xcode project structure for you.

### Option 2: Manual Xcode GUI (5 minutes)

This is the most reliable approach:

#### Step 1: Create New iOS App Project

1. Open Xcode
2. File → New → Project
3. Select **iOS** → **App**
4. Click **Next**

#### Step 2: Configure Project

- **Product Name**: `ReliefBridgeApp`
- **Team**: Select your team (or leave as "None" for simulator-only)
- **Organization Identifier**: `com.reliefbridge`
- **Bundle Identifier**: `com.reliefbridge.app`
- **Interface**: **SwiftUI**
- **Language**: **Swift**
- **Storage**: None
- **Include Tests**: Unchecked (we already have tests)

Click **Next**, then save it in your current directory: `/Users/shivdavay/ReliefBridgeApp`

#### Step 3: Add Swift Package as Local Dependency

1. In Xcode, select the project in the navigator (top item)
2. Select the **ReliefBridgeApp** target
3. Go to **General** tab
4. Scroll to **Frameworks, Libraries, and Embedded Content**
5. Click the **+** button
6. Click **Add Other...** → **Add Package Dependency...**
7. Click **Add Local...** button (bottom left)
8. Navigate to and select the current directory (where `Package.swift` is)
9. Click **Add Package**
10. Select **ReliefBridge** library
11. Click **Add Package**

#### Step 4: Replace App Entry Point

1. In the project navigator, find `ReliefBridgeAppApp.swift` (the auto-generated file)
2. Delete its contents
3. Copy the contents from `ReliefBridge/App/ReliefBridgeApp.swift`
4. Paste into `ReliefBridgeAppApp.swift`
5. Add this import at the top:
   ```swift
   import ReliefBridge
   ```

#### Step 5: Build and Run

1. Select an iPhone simulator from the device menu (e.g., iPhone 15 Pro)
2. Press **⌘R** to build and run
3. The app should launch on the simulator!

### Option 3: Command-Line Project Generation

Unfortunately, there's no reliable command-line tool to create Xcode iOS projects. The `swift package generate-xcodeproj` command is deprecated and doesn't support iOS app targets properly.

## After Creating the Project

Once you have the Xcode project, you can use command-line tools:

```bash
# Build
xcodebuild -project ReliefBridgeApp.xcodeproj \
           -scheme ReliefBridgeApp \
           -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
           build

# Install on simulator
xcrun simctl install booted ./build/Build/Products/Debug-iphonesimulator/ReliefBridgeApp.app

# Launch
xcrun simctl launch booted com.reliefbridge.app
```

## Why This Is Necessary

Swift Package Manager is designed for:
- Libraries and frameworks
- Command-line tools (macOS only)
- Server-side Swift

It **cannot** create iOS app bundles because:
1. iOS apps require specific bundle structure
2. Code signing is mandatory (even for simulator)
3. Info.plist with specific keys is required
4. Launch screens and app icons need asset catalogs
5. Entitlements for iOS features

Xcode handles all of this automatically when you create an iOS App project.

## Recommended Workflow

1. **Use Xcode GUI** to create the project (one-time, 5 minutes)
2. **Use command-line** for subsequent builds and runs
3. Keep your Swift Package as the source of truth for code
4. The Xcode project is just a thin wrapper

## Alternative: Use Xcode Exclusively

If command-line isn't critical, just use Xcode:
1. Open `Package.swift` in Xcode
2. Xcode will create a workspace automatically
3. Select iPhone simulator
4. Press ⌘R

This works but doesn't give you command-line automation.
