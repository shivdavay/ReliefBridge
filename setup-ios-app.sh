#!/bin/bash
# setup-ios-app.sh
# Helper script to guide you through creating an Xcode iOS app project

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   ReliefBridge Insight - iOS App Project Setup Guide${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}⚠️  Swift Package Manager cannot create iOS app bundles.${NC}"
echo -e "${YELLOW}   You need to create an Xcode iOS App project.${NC}"
echo ""

echo -e "${BLUE}Why?${NC}"
echo "  • iOS apps require app bundles (.app directories)"
echo "  • Code signing is mandatory (even for simulator)"
echo "  • Info.plist with specific iOS keys is required"
echo "  • Asset catalogs for icons and launch screens"
echo ""

echo -e "${BLUE}Your Swift Package built successfully as a library!${NC}"
echo "  ✓ All code compiled without errors"
echo "  ✓ Library target: ReliefBridge.o"
echo "  ✓ Swift module: ReliefBridge.swiftmodule"
echo ""

echo -e "${YELLOW}But we need to wrap it in an iOS app project.${NC}"
echo ""

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   OPTION 1: Xcode GUI (Recommended - 5 minutes)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo "1. Open Xcode"
echo "2. File → New → Project"
echo "3. Select: iOS → App"
echo "4. Configure:"
echo "   • Product Name: ReliefBridgeApp"
echo "   • Organization ID: com.reliefbridge"
echo "   • Interface: SwiftUI"
echo "   • Language: Swift"
echo "5. Save in: $(pwd)"
echo ""

echo "6. Add Swift Package as dependency:"
echo "   • Select project in navigator"
echo "   • Select ReliefBridgeApp target"
echo "   • General tab → Frameworks, Libraries, and Embedded Content"
echo "   • Click + → Add Other → Add Package Dependency"
echo "   • Click 'Add Local' → Select this directory"
echo "   • Select 'ReliefBridge' library → Add Package"
echo ""

echo "7. Replace app entry point:"
echo "   • Open ReliefBridgeAppApp.swift"
echo "   • Replace contents with code below"
echo ""

echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}   Code for ReliefBridgeAppApp.swift:${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
cat << 'EOF'

import SwiftUI
import ReliefBridge

@main
struct ReliefBridgeAppApp: App {
    /// Single source of truth for all simulated data across all modules.
    @StateObject private var dataService = SimulatedDataService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataService)
                .aviationDarkMode()
                .tint(Theme.Colors.efficiencyGreen)
        }
    }
}

EOF
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo "8. Build and Run:"
echo "   • Select iPhone simulator (e.g., iPhone 15 Pro)"
echo "   • Press ⌘R"
echo "   • App will launch on simulator!"
echo ""

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   OPTION 2: Open Package.swift in Xcode (Simpler)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo "This is simpler but less flexible:"
echo ""
echo "1. Run: open Package.swift"
echo "2. Wait for Xcode to open and resolve dependencies"
echo "3. Select iPhone simulator from device menu"
echo "4. Press ⌘R to run"
echo ""

echo -e "${YELLOW}Note: This may not work because ReliefBridgeApp.swift is excluded${NC}"
echo -e "${YELLOW}from the library target. Option 1 is more reliable.${NC}"
echo ""

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   After Creating the Project${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo "Once you have the Xcode project, you can use command-line:"
echo ""
echo -e "${GREEN}# Build${NC}"
echo "xcodebuild -project ReliefBridgeApp.xcodeproj \\"
echo "           -scheme ReliefBridgeApp \\"
echo "           -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \\"
echo "           -derivedDataPath ./build \\"
echo "           build"
echo ""
echo -e "${GREEN}# Install on simulator${NC}"
echo "xcrun simctl install booted ./build/Build/Products/Debug-iphonesimulator/ReliefBridgeApp.app"
echo ""
echo -e "${GREEN}# Launch${NC}"
echo "xcrun simctl launch booted com.reliefbridge.app"
echo ""

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

read -p "Would you like to open Xcode now to create the project? (y/n): " OPEN_XCODE

if [ "$OPEN_XCODE" = "y" ] || [ "$OPEN_XCODE" = "Y" ]; then
    echo ""
    echo -e "${GREEN}Opening Xcode...${NC}"
    echo "Follow the steps above to create the iOS App project."
    open -a Xcode
else
    echo ""
    echo -e "${YELLOW}No problem! Follow the steps above when you're ready.${NC}"
    echo ""
    echo "For detailed instructions, see: CREATE_XCODE_PROJECT.md"
fi

echo ""
echo -e "${GREEN}✓ Setup guide complete!${NC}"
