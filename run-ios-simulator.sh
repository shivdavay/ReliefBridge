#!/bin/bash
# run-ios-simulator.sh
# Generates an iOS app project, builds it, and launches it on the iOS Simulator.

set -euo pipefail

# Configuration
SIMULATOR_NAME="${SIMULATOR_NAME:-iPhone 17 Pro}"
PROJECT_NAME="ReliefBridgeApp"
SCHEME_NAME="ReliefBridgeApp"
PROJECT_FILE="${PROJECT_NAME}.xcodeproj"
APP_NAME="${PROJECT_NAME}"
BUILD_DIR="./build"
BUNDLE_ID="com.reliefbridge.app"
XCODE_APP="/Applications/Xcode.app"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 ReliefBridge Insight iOS Simulator Launcher${NC}"
echo ""

# Step 1: Check project generator availability
if ! command -v xcodegen &> /dev/null; then
    echo -e "${RED}❌ Error: xcodegen not found.${NC}"
    echo ""
    echo "Install it with Homebrew:"
    echo "  brew install xcodegen"
    exit 1
fi

# Step 2: Prefer full Xcode if it is installed but not selected globally
if [ -d "$XCODE_APP" ] && [ "$(xcode-select -p 2>/dev/null || true)" = "/Library/Developer/CommandLineTools" ]; then
    export DEVELOPER_DIR="$XCODE_APP/Contents/Developer"
fi

# Step 3: Check if full Xcode is available
if ! xcodebuild -version &> /dev/null; then
    echo -e "${RED}❌ Error: full Xcode is required to build for the iOS Simulator.${NC}"
    echo ""
    echo "Install Xcode from the App Store, then run one of:"
    echo "  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
    echo "  sudo xcodebuild -license accept"
    if command -v xcodes &> /dev/null; then
        echo ""
        echo "Or install Xcode with Apple's CLI downloader after signing in:"
        echo "  xcodes install --latest"
    fi
    exit 1
fi

# Step 4: Check for the project spec
if [ ! -f "project.yml" ]; then
    echo -e "${RED}❌ Error: project.yml not found. Run this script from the project root.${NC}"
    exit 1
fi

# Step 5: Check simulator tooling
if ! xcrun simctl help &> /dev/null; then
    echo -e "${RED}❌ Error: simctl is unavailable. Full Xcode and simulator runtimes are required.${NC}"
    exit 1
fi

# Step 6: Generate the Xcode project
echo -e "${BLUE}🧱 Generating Xcode project...${NC}"
xcodegen generate --spec project.yml

# Step 7: Check if simulator exists
echo -e "${BLUE}📱 Checking simulator availability...${NC}"
if ! xcrun simctl list devices available | grep -q "$SIMULATOR_NAME"; then
    echo -e "${YELLOW}⚠️  Warning: Simulator '$SIMULATOR_NAME' not found.${NC}"
    echo "Available iPhone simulators:"
    xcrun simctl list devices available | grep "iPhone"
    echo ""
    read -p "Enter simulator name to use (or press Enter to exit): " CUSTOM_SIMULATOR
    if [ -z "$CUSTOM_SIMULATOR" ]; then
        exit 1
    fi
    SIMULATOR_NAME="$CUSTOM_SIMULATOR"
fi

# Step 8: Boot simulator if not already booted
echo -e "${BLUE}🔌 Booting simulator...${NC}"
SIMULATOR_ID=$(xcrun simctl list devices available | grep "$SIMULATOR_NAME" | head -1 | grep -oE '\([A-F0-9-]+\)' | tr -d '()')

if [ -z "$SIMULATOR_ID" ]; then
    echo -e "${RED}❌ Error: Could not find simulator ID for '$SIMULATOR_NAME'${NC}"
    exit 1
fi

# Check if simulator is already booted
if xcrun simctl list devices | grep "$SIMULATOR_ID" | grep -q "Booted"; then
    echo "Simulator already booted."
else
    echo "Booting simulator..."
    xcrun simctl boot "$SIMULATOR_ID" 2>/dev/null || true
    sleep 3
fi

# Step 9: Open Simulator app
echo -e "${BLUE}📲 Opening Simulator app...${NC}"
open -a Simulator

# Step 10: Build the generated iOS app project
echo -e "${BLUE}🏗️  Building app for iOS Simulator...${NC}"
echo "This may take a few minutes on first build..."
echo ""

xcodebuild \
    -project "$PROJECT_FILE" \
    -scheme "$SCHEME_NAME" \
    -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
    -configuration Debug \
    -derivedDataPath "$BUILD_DIR" \
    build

# Step 11: Find the built app
echo ""
echo -e "${BLUE}🔍 Locating built app...${NC}"
APP_PATH="${BUILD_DIR}/Build/Products/Debug-iphonesimulator/${APP_NAME}.app"

if [ -z "$APP_PATH" ]; then
    echo -e "${RED}❌ Error: Could not find built .app bundle${NC}"
    echo "Expected to find ${APP_NAME}.app in ${BUILD_DIR}/Build/Products/Debug-iphonesimulator/"
    echo ""
    echo "Please check the build output above for errors."
    exit 1
fi

echo "Found app at: $APP_PATH"

# Step 12: Get bundle identifier from Info.plist
BUNDLE_ID=$(defaults read "$APP_PATH/Info.plist" CFBundleIdentifier 2>/dev/null || echo "$BUNDLE_ID")
echo "Bundle ID: $BUNDLE_ID"

# Step 13: Install app on simulator
echo ""
echo -e "${BLUE}📦 Installing app on simulator...${NC}"
xcrun simctl install "$SIMULATOR_ID" "$APP_PATH"

# Step 14: Launch app
echo -e "${BLUE}🎯 Launching app...${NC}"
xcrun simctl launch "$SIMULATOR_ID" "$BUNDLE_ID"

echo ""
echo -e "${GREEN}✅ Success! ReliefBridge Insight is now running on the iOS Simulator.${NC}"
echo ""
echo "Useful commands:"
echo "  View logs:"
echo "    xcrun simctl spawn $SIMULATOR_ID log stream --predicate 'processImagePath contains \"$APP_NAME\"'"
echo ""
echo "  Uninstall app:"
echo "    xcrun simctl uninstall $SIMULATOR_ID $BUNDLE_ID"
echo ""
echo "  Shutdown simulator:"
echo "    xcrun simctl shutdown $SIMULATOR_ID"
