#!/bin/sh
# Creates a GitHub release with the Android APK attached.
# Usage: sh scripts/release.sh
#
# What it does:
#   1. Reads version from package.json, validates clean git state
#   2. Builds the Android debug APK (via stamp-build + gradle)
#   3. Tags the commit as v<version> and pushes the tag
#   4. Creates a GitHub release with auto-generated notes and the APK attached
#   5. Bumps the patch version in package.json and commits it

set -e

# Read version from package.json
VERSION=$(node -p "require('./package.json').version")
if [ -z "$VERSION" ]; then
  echo "Error: could not read version from package.json" >&2
  exit 1
fi

TAG="v${VERSION}"
APK_PATH="android/app/build/outputs/apk/debug/app-debug.apk"
APK_NAME="solax-fve-realtime-${TAG}.apk"

echo "==> Releasing ${TAG}..."

# Ensure working tree is clean
if [ -n "$(git status --porcelain)" ]; then
  echo "Error: working tree is not clean. Commit or stash changes first." >&2
  exit 1
fi

# Ensure tag doesn't already exist
if git rev-parse "$TAG" >/dev/null 2>&1; then
  echo "Error: tag $TAG already exists." >&2
  exit 1
fi

# Ensure gh CLI is available
if ! command -v gh >/dev/null 2>&1; then
  echo "Error: gh CLI is required. Install from https://cli.github.com" >&2
  exit 1
fi

echo "==> Building Android APK..."
sh scripts/stamp-build.sh
npx cap sync android
(cd android && ./gradlew assembleDebug)

if [ ! -f "$APK_PATH" ]; then
  echo "Error: APK not found at $APK_PATH" >&2
  exit 1
fi

echo "==> Tagging $TAG..."
git tag "$TAG"
git push origin "$TAG"

echo "==> Creating GitHub release $TAG..."
gh release create "$TAG" \
  --title "$TAG" \
  --generate-notes \
  "${APK_PATH}#${APK_NAME}"

echo "==> Bumping patch version..."
NEXT_VERSION=$(node -p "const v='${VERSION}'.split('.'); v[2]=+v[2]+1; v.join('.')")
node -e "
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
pkg.version = '${NEXT_VERSION}';
fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\n');
"
git add package.json
git commit -m "chore: bump version to ${NEXT_VERSION}"
git push origin

echo "Done: ${TAG} released, version bumped to ${NEXT_VERSION}."
