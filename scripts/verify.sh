#!/bin/bash
set -e

TOTAL_STEPS=9
STEP=0
step() {
  STEP=$((STEP + 1))
  echo
  echo "[$STEP/$TOTAL_STEPS] $1"
}

GLOBAL_BIN=""
if command -v fvm >/dev/null 2>&1; then
  GLOBAL_BIN=$(fvm api context 2>/dev/null | grep -o '"globalCacheBinPath": *"[^"]*"' | sed -E 's/.*: *"([^"]*)"/\1/')
fi

if [ -x .fvm/flutter_sdk/bin/flutter ]; then
  PATH="$(cd .fvm/flutter_sdk/bin && pwd):$PATH"
fi

PANA_PATH="$PATH"
if [ -n "$GLOBAL_BIN" ] && [ -x "$GLOBAL_BIN/dart" ]; then
  PANA_PATH="$GLOBAL_BIN:$PATH"
fi

sdk_label() {
  echo "Flutter $(flutter --version 2>/dev/null | head -n1 | awk '{print $2}') / Dart $(dart --version 2>&1 | sed -E 's/.*version: ([0-9.]+).*/\1/')"
}

echo "Package checks on $(sdk_label)"
echo "pana runs on $(PATH="$PANA_PATH" sdk_label) — pub.dev scores there"

step "Installing dependencies"
flutter pub get

VERSION=$(grep '^version:' pubspec.yaml | awk '{print $2}')
VALIDART_VERSION=$(grep -E '^\s+validart: \^' pubspec.yaml | head -n1 | sed -E 's/.*\^([0-9]+\.[0-9]+\.[0-9]+).*/\1/')

step "Verifying README installation snippet matches pubspec versions"

README_VALIFORM_VERSION=$(grep -E '^\s*valiform: \^' README.md | head -n1 | sed -E 's/.*\^([0-9]+\.[0-9]+\.[0-9]+).*/\1/')
if [ -z "$README_VALIFORM_VERSION" ]; then
  echo
  echo "❌ Aborting: could not find 'valiform: ^X.Y.Z' in README.md."
  echo "   The Installation section must pin the current pubspec.yaml version."
  exit 1
fi
if [ "$README_VALIFORM_VERSION" != "$VERSION" ]; then
  echo
  echo "❌ Aborting: README pins valiform ^${README_VALIFORM_VERSION}, but pubspec.yaml is ${VERSION}."
  echo "   Update the README '## Installation' block to '^${VERSION}'."
  exit 1
fi

README_VALIDART_VERSION=$(grep -E '^\s*validart: \^' README.md | head -n1 | sed -E 's/.*\^([0-9]+\.[0-9]+\.[0-9]+).*/\1/')
if [ -z "$README_VALIDART_VERSION" ]; then
  echo
  echo "❌ Aborting: could not find 'validart: ^X.Y.Z' in README.md."
  echo "   The Installation section must pin the current validart constraint."
  exit 1
fi
if [ "$README_VALIDART_VERSION" != "$VALIDART_VERSION" ]; then
  echo
  echo "❌ Aborting: README pins validart ^${README_VALIDART_VERSION}, but pubspec.yaml requires ^${VALIDART_VERSION}."
  echo "   Update the README '## Installation' block to '^${VALIDART_VERSION}'."
  exit 1
fi

echo "README pinned at valiform ^${README_VALIFORM_VERSION}, validart ^${README_VALIDART_VERSION} ✓"

step "Analyzing"
flutter analyze

step "Analyzing the example app"
(cd example && flutter pub get && flutter analyze)

step "Running tests"
flutter test

step "Verifying the examples inside the API docs"
./scripts/verify_doc_examples.sh

step "Generating API docs"
DOC_OUT=$(mktemp -d)
dart doc --output "$DOC_OUT" 2>&1 | tee /dev/stderr | grep -q "Found 0 warnings and 0 errors" || {
  echo
  echo "❌ Aborting: 'dart doc' reported warnings or errors."
  rm -rf "$DOC_OUT"
  exit 1
}
rm -rf "$DOC_OUT"

step "Validating package (dry-run)"
flutter pub publish --dry-run

step "Running pana (pub.dev score)"
PANA_LATEST=$(curl -sf https://pub.dev/api/packages/pana | grep -o '"latest":{"version":"[^"]*"' | sed -E 's/.*"version":"([^"]*)".*/\1/')
if [ -z "$PANA_LATEST" ]; then
  echo
  echo "❌ Aborting: could not read the latest pana version from pub.dev."
  echo "   pub.dev scores with the latest pana, so the release pins itself to it."
  exit 1
fi

if ! ACTIVATE_OUT=$(PATH="$PANA_PATH" dart pub global activate pana "$PANA_LATEST" 2>&1); then
  echo "$ACTIVATE_OUT"
  echo
  echo "❌ Aborting: pana $PANA_LATEST does not run on $(PATH="$PANA_PATH" sdk_label)."
  echo "   Never fall back to an older pana: pub.dev scores with the latest one, so an older"
  echo "   report predicts nothing. Update the global Flutter SDK."
  exit 1
fi

echo "Using pana $PANA_LATEST"

PANA_OUT=$(GIT_ASKPASS= GIT_TERMINAL_PROMPT=0 PATH="$PANA_PATH" dart pub global run pana --no-warning . | tee /dev/stderr)
if ! grep -q "Points: 160/160" <<<"$PANA_OUT"; then
  echo
  echo "❌ Aborting: pana score is below 160/160. Fix the issues above."
  exit 1
fi

echo
echo "✅ v$VERSION is release-ready"
