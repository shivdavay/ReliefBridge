#!/bin/bash
# setup-ui-tests.sh
# Helper script to set up XCUITest target in an Xcode project

set -e

echo "🚀 ReliefBridge Insight UI Test Setup"
echo "===================================="
echo ""

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Error: Xcode command line tools not found."
    echo "   Please install Xcode and run: xcode-select --install"
    exit 1
fi

echo "✅ Xcode found: $(xcodebuild -version | head -n 1)"
echo ""

# Check for Xcode project
if [ ! -f "ReliefBridge.xcodeproj/project.pbxproj" ]; then
    echo "⚠️  No Xcode project found at ReliefBridge.xcodeproj"
    echo ""
    echo "To create an Xcode project:"
    echo "1. Open Xcode"
    echo "2. File → New → Project"
    echo "3. Choose iOS → App"
    echo "4. Name: ReliefBridge"
    echo "5. Interface: SwiftUI"
    echo "6. Language: Swift"
    echo "7. Minimum Deployment: iOS 17.0"
    echo ""
    echo "Then run this script again."
    exit 1
fi

echo "✅ Xcode project found"
echo ""

# Check if UI test target already exists
if xcodebuild -project ReliefBridge.xcodeproj -list | grep -q "ReliefBridgeUITests"; then
    echo "✅ UI test target already exists"
else
    echo "⚠️  UI test target not found"
    echo ""
    echo "To add a UI test target:"
    echo "1. Open ReliefBridge.xcodeproj in Xcode"
    echo "2. File → New → Target"
    echo "3. Choose iOS → Test → UI Testing Bundle"
    echo "4. Name: ReliefBridgeUITests"
    echo "5. Target to be Tested: ReliefBridge"
    echo ""
    echo "Then copy the test files:"
    echo "  - ReliefBridgeUITests/ReliefBridgeUITests.swift"
    echo "  - ReliefBridgeUITests/Info.plist"
    echo ""
    exit 1
fi

echo "✅ Setup complete!"
echo ""
echo "To run the UI tests:"
echo "  1. Open ReliefBridge.xcodeproj in Xcode"
echo "  2. Select the ReliefBridgeUITests scheme"
echo "  3. Choose a simulator (iPhone 15 Pro recommended)"
echo "  4. Press ⌘U or Product → Test"
echo ""
echo "Or from the command line:"
echo "  xcodebuild test \\"
echo "    -project ReliefBridge.xcodeproj \\"
echo "    -scheme ReliefBridgeUITests \\"
echo "    -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=17.0'"
echo ""
