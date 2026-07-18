#!/bin/sh

set -eu

SCRIPT_DIRECTORY=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECT_DIRECTORY=$(dirname -- "$SCRIPT_DIRECTORY")
cd "$PROJECT_DIRECTORY"

xcrun swift-format format --in-place --recursive \
  TaskBoardCore \
  TaskBoardCoreTests \
  TaskBoardCoreSmokeTests \
  TaskBoardiOS
