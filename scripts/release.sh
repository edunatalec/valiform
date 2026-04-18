#!/bin/bash
set -e

echo "=== Installing dependencies ==="
flutter pub get

echo ""
echo "=== Running tests ==="
flutter test

echo ""
echo "=== Validating package (dry-run) ==="
flutter pub publish --dry-run

VERSION=$(grep "version:" pubspec.yaml | head -1 | awk '{print $2}')
echo "Version: $VERSION"

echo ""
echo "=== Creating tag v$VERSION ==="
if git rev-parse "v$VERSION" >/dev/null 2>&1; then
  echo "Tag v$VERSION already exists, skipping"
else
  git tag "v$VERSION"
fi

echo ""
echo "=== Pushing ==="
git push origin master
git push --tags

echo ""
echo "=== Publishing to pub.dev ==="
flutter pub publish --force

echo ""
echo "=== Done! Published v$VERSION ==="