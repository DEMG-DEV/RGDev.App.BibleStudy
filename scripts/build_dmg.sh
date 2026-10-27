#!/usr/bin/env bash
set -e

# ==============================================================================
# build_dmg.sh
# Compiles BibleStudy for Release and creates an official macOS .dmg installer
# ==============================================================================

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

VERSION="1.1.0"
APP_NAME="BibleStudy"
DMG_NAME="${APP_NAME}-${VERSION}-macOS.dmg"
BUILD_DIR="${PROJECT_DIR}/build"
DMG_STAGING="${BUILD_DIR}/dmg_staging"
OUTPUT_DIR="${PROJECT_DIR}/dist"

echo "🔨 [1/4] Regenerating Xcode Project..."
python3 scripts/generate_xcodeproj.py

echo "📦 [2/4] Building ${APP_NAME} for Release (macOS)..."
rm -rf "$BUILD_DIR" "$OUTPUT_DIR"
mkdir -p "$BUILD_DIR" "$OUTPUT_DIR" "$DMG_STAGING"

xcodebuild -project "${APP_NAME}.xcodeproj" \
           -scheme "${APP_NAME}" \
           -configuration Release \
           -derivedDataPath "${BUILD_DIR}/DerivedData" \
           build

BUILT_APP="${BUILD_DIR}/DerivedData/Build/Products/Release/${APP_NAME}.app"

if [ ! -d "$BUILT_APP" ]; then
    echo "❌ Error: Built app bundle not found at: ${BUILT_APP}"
    exit 1
fi

echo "📋 [3/4] Staging DMG contents with /Applications shortcut..."
cp -R "$BUILT_APP" "$DMG_STAGING/"
ln -s /Applications "$DMG_STAGING/Applications"

# Copy icon to volume if available
if [ -f "${BUILT_APP}/Contents/Resources/AppIcon.icns" ]; then
    cp "${BUILT_APP}/Contents/Resources/AppIcon.icns" "$DMG_STAGING/.VolumeIcon.icns" || true
fi

echo "💿 [4/4] Creating compressed Disk Image (.dmg)..."
hdiutil create -volname "${APP_NAME}" \
               -srcfolder "$DMG_STAGING" \
               -ov \
               -format UDZO \
               "${OUTPUT_DIR}/${DMG_NAME}"

echo "✅ DMG generated successfully at: ${OUTPUT_DIR}/${DMG_NAME}"
ls -lh "${OUTPUT_DIR}/${DMG_NAME}"
