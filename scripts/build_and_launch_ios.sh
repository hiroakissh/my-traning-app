#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/my-traning-app/my-traning-app.xcodeproj"
SCHEME="${SCHEME:-my-traning-app}"
CONFIGURATION="${CONFIGURATION:-Debug}"
SIMULATOR_NAME="${SIMULATOR_NAME:-iPhone 17}"
SIMULATOR_UDID="${SIMULATOR_UDID:-}"
BUNDLE_ID="${BUNDLE_ID:-com.hiroakiapp.my-traning-app}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-$ROOT_DIR/build/DerivedData}"
ARTIFACT_DIR="${ARTIFACT_DIR:-$ROOT_DIR/build/ios-launch}"
APP_PATH="$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION-iphonesimulator/$SCHEME.app"
SCREENSHOT_PATH="$ARTIFACT_DIR/${SCHEME}-launch.png"

mkdir -p "$ARTIFACT_DIR"

echo "Project: $PROJECT_PATH"
echo "Scheme: $SCHEME"
echo "Simulator: $SIMULATOR_NAME"

if [[ -z "$SIMULATOR_UDID" ]]; then
  SIMULATOR_UDID="$(
    xcrun simctl list devices available |
      grep -F "    $SIMULATOR_NAME (" |
      head -1 |
      sed -E 's/.*\(([A-F0-9-]{36})\).*/\1/'
  )"
fi

if [[ -z "$SIMULATOR_UDID" ]]; then
  echo "Could not find an available simulator named '$SIMULATOR_NAME'." >&2
  exit 1
fi

echo "Simulator UDID: $SIMULATOR_UDID"

xcrun simctl boot "$SIMULATOR_UDID" 2>/dev/null || true
xcrun simctl bootstatus "$SIMULATOR_UDID" -b

xcodebuild build \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination "platform=iOS Simulator,name=$SIMULATOR_NAME" \
  -derivedDataPath "$DERIVED_DATA_PATH"

xcrun simctl install "$SIMULATOR_UDID" "$APP_PATH"
xcrun simctl launch "$SIMULATOR_UDID" "$BUNDLE_ID"
sleep 2
xcrun simctl io "$SIMULATOR_UDID" screenshot "$SCREENSHOT_PATH"

echo "Launched $BUNDLE_ID"
echo "Screenshot: $SCREENSHOT_PATH"
