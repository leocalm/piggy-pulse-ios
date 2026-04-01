#!/bin/bash
set -e

# xcodebuild uses this ID (from xcodebuild destination list)
XCODE_DEVICE_ID="00008150-0006210C1E40401C"
# devicectl uses CoreDevice UUID (from xcrun devicectl list devices)
CORE_DEVICE_ID="02FAD9B4-9B07-56F5-A8D3-1754C96CD3C3"

SCHEME="PiggyPulse"
PROJECT="PiggyPulse.xcodeproj"

# Find built products dir
PRODUCTS_DIR=$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -destination "id=$XCODE_DEVICE_ID" -showBuildSettings 2>/dev/null | grep -m1 'BUILT_PRODUCTS_DIR' | awk '{print $3}')

echo "🐷 Building $SCHEME for device..."
xcodebuild -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination "id=$XCODE_DEVICE_ID" \
    -configuration Debug \
    build \
    CODE_SIGNING_ALLOWED=YES \
    -quiet

APP_PATH="$PRODUCTS_DIR/$SCHEME.app"

if [ ! -d "$APP_PATH" ]; then
    echo "❌ App not found at: $APP_PATH"
    exit 1
fi

echo "📱 Installing to Leonardo's iPhone..."
xcrun devicectl device install app --device "$CORE_DEVICE_ID" "$APP_PATH"

echo "✅ Deployed to device!"
