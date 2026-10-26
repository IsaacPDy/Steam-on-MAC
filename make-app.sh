#!/bin/bash
# Build Steam.app: a native Universal (Apple silicon + Intel) launcher for steam.sh.
# The app checks for Rosetta and offers to install it, since the bundled Wine is Intel-only.
# Usage: ./make-app.sh            -> builds ./Steam.app
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
APP="$HERE/Steam.app"
ICO="$HERE/prefix/drive_c/Program Files (x86)/Steam/public/steam_tray.ico"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

# Without Xcode's command line tools (where /usr/bin/clang is only an installer stub),
# fall back to a script entry point that does the same hand-off.
if xcode-select -p >/dev/null 2>&1; then
  clang -O2 -arch arm64 -arch x86_64 -mmacosx-version-min=11.0 \
    -o "$APP/Contents/MacOS/Steam" "$HERE/launcher/main.c"
else
  printf '#!/bin/bash\nexec /bin/bash "$(dirname "$0")/../Resources/launch.sh" "$@"\n' > "$APP/Contents/MacOS/Steam"
  chmod +x "$APP/Contents/MacOS/Steam"
fi
cp "$HERE/launcher/launch.sh" "$APP/Contents/Resources/launch.sh"
chmod +x "$APP/Contents/Resources/launch.sh"
printf '%s\n' "$HERE" > "$APP/Contents/Resources/root-path"

# Icon from Steam's own 256px .ico.
if [ -f "$ICO" ]; then
  sips -s format png "$ICO" --out "$TMP/steam.png" >/dev/null
  mkdir "$TMP/Steam.iconset"
  for s in 16 32 128 256; do
    sips -z $s $s "$TMP/steam.png" --out "$TMP/Steam.iconset/icon_${s}x${s}.png" >/dev/null
    d=$((s * 2)); [ $d -le 256 ] && sips -z $d $d "$TMP/steam.png" --out "$TMP/Steam.iconset/icon_${s}x${s}@2x.png" >/dev/null
  done
  iconutil -c icns "$TMP/Steam.iconset" -o "$APP/Contents/Resources/Steam.icns"
fi

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key><string>Steam</string>
  <key>CFBundleIdentifier</key><string>local.steam-in-mac.launcher</string>
  <key>CFBundleName</key><string>Steam</string>
  <key>CFBundleDisplayName</key><string>Steam</string>
  <key>CFBundleIconFile</key><string>Steam</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
  <key>LSMinimumSystemVersion</key><string>11.0</string>
  <!-- The launcher hands off to Wine, which shows its own windows; no Dock icon for the launcher. -->
  <key>LSUIElement</key><true/>
</dict>
</plist>
PLIST

codesign --force --deep --sign - "$APP"
touch "$APP"
echo "Built $APP ($(lipo -archs "$APP/Contents/MacOS/Steam" 2>/dev/null || echo script))"
