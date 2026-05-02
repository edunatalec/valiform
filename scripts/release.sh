#!/bin/bash
set -e

TOTAL_STEPS=9
STEP=0
step() {
  STEP=$((STEP + 1))
  echo
  echo "[$STEP/$TOTAL_STEPS] $1"
}

step "Installing dependencies"
flutter pub get

step "Running tests"
flutter test

VERSION=$(grep '^version:' pubspec.yaml | awk '{print $2}')
VALIDART_VERSION=$(grep -E '^\s+validart: \^' pubspec.yaml | head -n1 | sed -E 's/.*\^([0-9]+\.[0-9]+\.[0-9]+).*/\1/')

step "Verifying README installation snippet matches pubspec versions"

README_VALIFORM_VERSION=$(grep -E '^\s*valiform: \^' README.md | head -n1 | sed -E 's/.*\^([0-9]+\.[0-9]+\.[0-9]+).*/\1/')
if [ -z "$README_VALIFORM_VERSION" ]; then
  echo
  echo "❌ Aborting release: could not find 'valiform: ^X.Y.Z' in README.md."
  echo "   The Installation section must pin the current pubspec.yaml version."
  exit 1
fi
if [ "$README_VALIFORM_VERSION" != "$VERSION" ]; then
  echo
  echo "❌ Aborting release: README pins valiform ^${README_VALIFORM_VERSION}, but pubspec.yaml is ${VERSION}."
  echo "   Update the README '## Installation' block to '^${VERSION}' before releasing."
  exit 1
fi

README_VALIDART_VERSION=$(grep -E '^\s*validart: \^' README.md | head -n1 | sed -E 's/.*\^([0-9]+\.[0-9]+\.[0-9]+).*/\1/')
if [ -z "$README_VALIDART_VERSION" ]; then
  echo
  echo "❌ Aborting release: could not find 'validart: ^X.Y.Z' in README.md."
  echo "   The Installation section must pin the current validart constraint."
  exit 1
fi
if [ "$README_VALIDART_VERSION" != "$VALIDART_VERSION" ]; then
  echo
  echo "❌ Aborting release: README pins validart ^${README_VALIDART_VERSION}, but pubspec.yaml requires ^${VALIDART_VERSION}."
  echo "   Update the README '## Installation' block to '^${VALIDART_VERSION}' before releasing."
  exit 1
fi

echo "README pinned at valiform ^${README_VALIFORM_VERSION}, validart ^${README_VALIDART_VERSION} ✓"

step "Validating package (dry-run)"
flutter pub publish --dry-run

step "Running pana (pub.dev score)"
PANA_OUT=$(pana --no-warning . | tee /dev/stderr)
if ! grep -q "Points: 160/160" <<<"$PANA_OUT"; then
  echo
  echo "❌ Aborting release: pana score is below 160/160. Fix the issues above."
  exit 1
fi

step "Creating tag v$VERSION"
if git rev-parse "v$VERSION" >/dev/null 2>&1; then
  echo "Tag v$VERSION already exists, skipping"
else
  git tag "v$VERSION"
fi

step "Pushing"
git push origin master
git push --tags

step "Publishing to pub.dev"
flutter pub publish --force

echo
echo "🎉 Done! Published v$VERSION"
