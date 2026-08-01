#!/bin/bash
set -e

./scripts/verify.sh

VERSION=$(grep '^version:' pubspec.yaml | awk '{print $2}')
BRANCH=$(git rev-parse --abbrev-ref HEAD)

TOTAL_STEPS=3
STEP=0
step() {
  STEP=$((STEP + 1))
  echo
  echo "[$STEP/$TOTAL_STEPS] $1"
}

step "Creating tag v$VERSION"
if git rev-parse "v$VERSION" >/dev/null 2>&1; then
  echo "Tag v$VERSION already exists, skipping"
else
  git tag "v$VERSION"
fi

step "Pushing"
git push origin "$BRANCH"
git push --tags

step "Publishing to pub.dev"
flutter pub publish --force

echo
echo "🎉 Done! Published valiform v$VERSION"
