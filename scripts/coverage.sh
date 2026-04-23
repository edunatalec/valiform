#!/bin/bash
set -e

TOTAL_STEPS=3
STEP=0
step() {
  STEP=$((STEP + 1))
  echo
  echo "[$STEP/$TOTAL_STEPS] $1"
}

step "Cleaning previous coverage"
rm -rf coverage

step "Running tests with coverage"
flutter test --coverage

step "Generating HTML report"
genhtml -o coverage/html coverage/lcov.info

echo
echo "✅ Coverage report generated successfully!"
open coverage/html/index.html
