#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"
SCHEME="${SCHEME:-Nexo Admin}"
DESTINATION="${DESTINATION:-platform=iOS Simulator,name=iPhone 16}"
CONFIGURATION="${CONFIGURATION:-Debug}"

cd "$PROJECT_ROOT"

echo "==> Running tests"
xcodebuild test \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination "$DESTINATION"

echo "==> Checking archive build"
xcodebuild archive \
  -scheme "$SCHEME" \
  -configuration Release \
  -archivePath "$PROJECT_ROOT/build/NexoAdmin.xcarchive" \
  CODE_SIGNING_ALLOWED=NO \
  SKIP_INSTALL=NO

echo "==> Smoke finished"
