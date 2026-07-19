#!/bin/sh

set -eu

SCRIPT_DIRECTORY=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECT_DIRECTORY=$(dirname -- "$SCRIPT_DIRECTORY")
cd "$PROJECT_DIRECTORY"

echo "==> Linting Swift sources"
xcrun swift-format lint --strict --recursive \
  TaskBoardCore \
  TaskBoardCoreTests \
  TaskBoardCoreSmokeTests \
  TaskBoardiOS

echo "==> Running unit tests"
swift test

echo "==> Running core smoke checks"
swift run TaskBoardCoreSmokeTests

echo "==> Building the iOS app"
TASKBOARD_DERIVED_DATA=$(mktemp -d "${TMPDIR:-/tmp}/taskboard-ios-quality.XXXXXX")
case "$TASKBOARD_DERIVED_DATA" in
  "${TMPDIR:-/tmp}"/taskboard-ios-quality.*) ;;
  *)
    echo "Unexpected temporary build path: $TASKBOARD_DERIVED_DATA" >&2
    exit 1
    ;;
esac
trap 'rm -rf -- "$TASKBOARD_DERIVED_DATA"' EXIT HUP INT TERM

xcodebuild \
  -project TaskBoardiOS.xcodeproj \
  -scheme TaskBoardiOS \
  -sdk iphonesimulator \
  -configuration Debug \
  -derivedDataPath "$TASKBOARD_DERIVED_DATA" \
  CODE_SIGNING_ALLOWED=NO \
  build

echo "==> All quality checks passed"
