#!/bin/zsh
# Builds a universal (Apple Silicon + Intel) app into build/.
#   ./build.sh
# Optional environment variables:
#   NAME           app name              (default: Backloggd)
#   BUNDLE_ID      bundle identifier     (default: com.local.backloggd)
#   VERSION, BUILD version numbers       (default: 1.0.0 / 1)
#   SIGN_IDENTITY  "Developer ID Application: Your Name (TEAMID)"; default "-" = ad-hoc signature
set -euo pipefail
cd "$(dirname "$0")"

NAME="${NAME:-Backloggd}"
BUNDLE_ID="${BUNDLE_ID:-com.local.backloggd}"
VERSION="${VERSION:-1.0.0}"
BUILD="${BUILD:-1}"
SIGN_IDENTITY="${SIGN_IDENTITY:--}"
OUT="build"
APP="$OUT/$NAME.app"

rm -rf "$APP" "$OUT/$NAME-arm64" "$OUT/$NAME-x86_64"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

echo "Compiling (arm64 + x86_64)…"
swiftc -O -target arm64-apple-macos12.0  Sources/main.swift -o "$OUT/$NAME-arm64"
swiftc -O -target x86_64-apple-macos12.0 Sources/main.swift -o "$OUT/$NAME-x86_64"
lipo -create "$OUT/$NAME-arm64" "$OUT/$NAME-x86_64" -output "$APP/Contents/MacOS/$NAME"
rm "$OUT/$NAME-arm64" "$OUT/$NAME-x86_64"

cp Resources/AppIcon.icns "$APP/Contents/Resources/"
sed -e "s|@NAME@|$NAME|g" -e "s|@BUNDLE_ID@|$BUNDLE_ID|g" \
    -e "s|@VERSION@|$VERSION|g" -e "s|@BUILD@|$BUILD|g" \
    Resources/Info.plist.in > "$APP/Contents/Info.plist"

if [[ "$SIGN_IDENTITY" == "-" ]]; then
  codesign --force --sign - "$APP"
else
  # Hardened runtime + secure timestamp are required for notarization.
  codesign --force --options runtime --timestamp --sign "$SIGN_IDENTITY" "$APP"
fi
codesign --verify --strict "$APP"
echo "Built $APP  ($(lipo -archs "$APP/Contents/MacOS/$NAME"))"
