#!/bin/bash
set -e

APP_NAME="NetLimiter"
BUILD_DIR=".build/release"
APP_BUNDLE="$APP_NAME.app"

echo "Building $APP_NAME..."

# Build release version
swift build -c release

# Remove old app bundle if exists
rm -rf "$APP_BUNDLE"

# Create app bundle structure
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy executable
cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/"

# Create Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>NetLimiter</string>
    <key>CFBundleDisplayName</key>
    <string>NetLimiter</string>
    <key>CFBundleIdentifier</key>
    <string>com.local.netlimiter</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>NetLimiter</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSUIElement</key>
    <false/>
</dict>
</plist>
EOF

# Create PkgInfo
echo -n "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"

echo ""
echo "Done! Created $APP_BUNDLE"
echo ""
echo "To run:  open $APP_BUNDLE"
echo "To install: mv $APP_BUNDLE /Applications/"
