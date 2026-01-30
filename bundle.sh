#!/bin/bash

APP_NAME="PingMeter"
EXECUTABLE_NAME="pingmeter"
BUNDLE_ID="io.neutrino.pingmeter"
OUTPUT_DIR="dist"

echo "Building release..."
swift build -c release

echo "Creating app bundle structure..."
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR/$APP_NAME.app/Contents/MacOS"
mkdir -p "$OUTPUT_DIR/$APP_NAME.app/Contents/Resources"

echo "Copying executable..."
cp ".build/release/$EXECUTABLE_NAME" "$OUTPUT_DIR/$APP_NAME.app/Contents/MacOS/$APP_NAME"

echo "Creating Info.plist..."
cat > "$OUTPUT_DIR/$APP_NAME.app/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${MARKETING_VERSION:-1.0}</string>
    <key>CFBundleVersion</key>
    <string>${PROJECT_VERSION:-1}</string>
    <key>LSMinimumSystemVersion</key>
    <string>11.0</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

EOF

echo "Signing app bundle..."
codesign --force --deep --sign - "$OUTPUT_DIR/$APP_NAME.app"

echo "Done! $OUTPUT_DIR/$APP_NAME.app created."
