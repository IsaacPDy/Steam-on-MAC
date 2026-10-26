#!/bin/bash
# Build dist/Steam on Mac.app, a self-contained app with Wine inside, and zip it for download.
# The launcher is native Universal (Apple silicon + Intel); it checks for Rosetta and offers to
# install it, since the bundled Wine is Intel-only.
# Wine comes from ./Wine CX.app if present, otherwise from this repo's wine-cx-11.0-1 release.
# Usage: ./make-app.sh            -> dist/Steam on Mac.app and dist/Steam-on-Mac.zip
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
NAME="Steam on Mac"
VERSION="1.0"
DIST="$HERE/dist"
APP="$DIST/$NAME.app"
ZIP="$DIST/Steam-on-Mac.zip"
WINE_SRC="${WINE_SRC:-$HERE/Wine CX.app/Contents/Resources/wine}"
WINE_URL="https://github.com/IsaacPDy/Steam-on-MAC/releases/download/wine-cx-11.0-1/Wine-CX.app.tar.xz"
WINE_SHA256="411e9c8a09943cf64993caf8dd3fedf4f651bec40f0b62d52415f1a4d56307af"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

xcode-select -p >/dev/null 2>&1 || { echo "Needs Xcode's command line tools: xcode-select --install" >&2; exit 1; }

if [ ! -x "$WINE_SRC/bin/wine" ]; then
  echo "Downloading Wine from the wine-cx-11.0-1 release"
  curl -fL --progress-bar -o "$TMP/wine.tar.xz" "$WINE_URL"
  echo "$WINE_SHA256  $TMP/wine.tar.xz" | shasum -a 256 -c - >/dev/null || { echo "Wine download failed its checksum" >&2; exit 1; }
  tar -xJf "$TMP/wine.tar.xz" -C "$TMP"
  WINE_SRC="$TMP/Wine CX.app/Contents/Resources/wine"
fi

rm -rf "$APP" "$ZIP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

clang -O2 -arch arm64 -arch x86_64 -mmacosx-version-min=11.0 \
  -o "$APP/Contents/MacOS/Steam" "$HERE/launcher/main.c"
cp "$HERE/launcher/launch.sh" "$APP/Contents/Resources/launch.sh"
chmod +x "$APP/Contents/Resources/launch.sh"
# Headers are only for building against Wine; the app doesn't need them.
rsync -a --exclude /include "$WINE_SRC/" "$APP/Contents/Resources/wine/"

swift "$HERE/launcher/make-icon.swift" "$TMP/icon.png"
mkdir "$TMP/AppIcon.iconset"
for s in 16 32 128 256 512; do
  sips -z $s $s "$TMP/icon.png" --out "$TMP/AppIcon.iconset/icon_${s}x${s}.png" >/dev/null
  sips -z $((s * 2)) $((s * 2)) "$TMP/icon.png" --out "$TMP/AppIcon.iconset/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns "$TMP/AppIcon.iconset" -o "$APP/Contents/Resources/AppIcon.icns"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key><string>Steam</string>
  <key>CFBundleIdentifier</key><string>io.github.isaacpdy.steam-on-mac</string>
  <key>CFBundleName</key><string>$NAME</string>
  <key>CFBundleDisplayName</key><string>$NAME</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>$VERSION</string>
  <key>CFBundleVersion</key><string>$VERSION</string>
  <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
  <key>LSMinimumSystemVersion</key><string>11.0</string>
  <!-- The launcher hands off to Wine, which shows its own windows; no Dock icon for the launcher. -->
  <key>LSUIElement</key><true/>
</dict>
</plist>
PLIST

codesign --force --deep --sign - "$APP"
touch "$APP"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$ZIP"
echo "Built $APP ($(lipo -archs "$APP/Contents/MacOS/Steam"))"
echo "Zipped $ZIP ($(du -h "$ZIP" | cut -f1))"
