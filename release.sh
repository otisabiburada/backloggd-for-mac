#!/bin/zsh
# Builds, signs and packages a release DMG + ZIP into dist/.
#   ./release.sh                      # ad-hoc signed (testing / friends; shows a Gatekeeper warning)
#   SIGN_IDENTITY="Developer ID Application: Name (TEAMID)" NOTARY_PROFILE=notary ./release.sh
#                                     # signed + notarized + stapled (no warning for downloaders)
# One-time notarization setup (needs a paid Apple Developer account):
#   xcrun notarytool store-credentials notary --apple-id you@example.com --team-id TEAMID
set -euo pipefail
cd "$(dirname "$0")"

NAME="${NAME:-Backloggd}"
VERSION="${VERSION:-1.0.0}"
export NAME VERSION
./build.sh

APP="build/$NAME.app"
DIST="dist"
DMG="$DIST/$NAME-$VERSION.dmg"
ZIP="$DIST/$NAME-$VERSION.zip"
rm -rf "$DIST" build/dmg-root; mkdir -p "$DIST" build/dmg-root
cp -R "$APP" build/dmg-root/
ln -s /Applications build/dmg-root/Applications

hdiutil create -volname "$NAME" -srcfolder build/dmg-root -ov -format UDZO "$DMG" >/dev/null
rm -rf build/dmg-root

if [[ -n "${NOTARY_PROFILE:-}" && "${SIGN_IDENTITY:--}" != "-" ]]; then
  echo "Notarizing (this can take a few minutes)…"
  codesign --force --sign "$SIGN_IDENTITY" --timestamp "$DMG"
  xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$DMG"
  xcrun stapler staple "$APP"
else
  echo "Skipping notarization (set SIGN_IDENTITY and NOTARY_PROFILE to enable)."
fi

ditto -c -k --keepParent "$APP" "$ZIP"
echo; echo "Release files:"; ls -lh "$DMG" "$ZIP"
echo; shasum -a 256 "$DMG" "$ZIP"
