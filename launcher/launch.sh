#!/bin/bash
# Runtime of Steam on Mac.app, run by its native launcher (Contents/MacOS/Steam).
# Wine lives inside the app (Contents/Resources/wine); the Wine prefix with Steam, its login and
# games lives in ~/Library/Application Support/Steam on Mac, so the app can be replaced freely.
# The first launch checks Rosetta, creates the prefix and installs Steam from Valve's installer.
# From Terminal:  launch.sh [steam args] | --wine <cmd...> | --stop | --dxmt-check
RES="$(cd "$(dirname "$0")" && pwd)"
APP="$(cd "$RES/../.." && pwd)"
WINE_ROOT="$RES/wine"
DATA="${STEAM_ON_MAC_DATA:-$HOME/Library/Application Support/Steam on Mac}"
export WINEPREFIX="$DATA/prefix"
export WINEDEBUG="${WINEDEBUG:--all}"
# WINEMSYNC=1 caused thread-creation failures in Steam.
export WINEMSYNC="${WINEMSYNC:-0}"
export MVK_CONFIG_LOG_LEVEL="${MVK_CONFIG_LOG_LEVEL:-0}"
# wined3d on macOS OpenGL left Steam black; the Vulkan (MoltenVK) renderer is the one being tested.
[ -n "$USE_WINED3D_VK" ] && export WINE_D3D_CONFIG="renderer=vulkan"
export PATH="$WINE_ROOT/bin:$PATH"
STEAM_URL="https://cdn.cloudflare.steamstatic.com/client/installer/SteamSetup.exe"
STEAM_DIR="$WINEPREFIX/drive_c/Program Files (x86)/Steam"
# Steam's UI is Chromium (CEF); these flags avoid the usual blank-window problems under Wine.
STEAM_FLAGS=(-no-cef-sandbox -cef-disable-gpu)

# Opened from Finder, nothing is watching stdout: log to a file instead.
if [ ! -t 1 ]; then
  mkdir -p "$HOME/Library/Logs"
  exec >>"$HOME/Library/Logs/Steam on Mac.log" 2>&1
fi
echo "=== $(date) launch $* ==="

alert() {
  /usr/bin/osascript -e 'on run {m}' -e 'display alert "Steam on Mac" message m as critical' -e 'end run' "$1" >/dev/null
}
notify() {
  /usr/bin/osascript -e 'on run {m}' -e 'display notification m with title "Steam on Mac"' -e 'end run' "$1" >/dev/null 2>&1
}
rosetta_ok() { /usr/bin/arch -x86_64 /usr/bin/true 2>/dev/null; }

# A quarantined app opened from Downloads runs from a random read-only copy (App Translocation),
# where the quarantine on Wine's files can't be cleared.
case "$APP" in
  */AppTranslocation/*)
    alert "Move Steam on Mac to your Applications folder, then open it again."
    exit 1 ;;
esac
# Once the user has allowed the app, clear the download quarantine from the Wine files inside it,
# or macOS blocks each Wine program separately.
if /usr/bin/xattr -p com.apple.quarantine "$WINE_ROOT/bin/wine" >/dev/null 2>&1; then
  /usr/bin/xattr -dr com.apple.quarantine "$APP" 2>/dev/null
fi

# Wine is an Intel (x86_64) app, so on Apple silicon it only runs through Rosetta.
# https://support.apple.com/102527
if [ "$(/usr/bin/uname -m)" = arm64 ] && ! rosetta_ok; then
  echo "Rosetta missing, asking to install"
  /usr/bin/osascript -e 'display dialog "Steam runs on Wine, which is an Intel-based app. It needs Rosetta to run on this Mac.

Install Rosetta now? You will be asked for your password." with title "Steam on Mac" buttons {"Cancel", "Install Rosetta"} default button "Install Rosetta" with icon caution' >/dev/null || exit 1
  /usr/bin/osascript -e 'do shell script "/usr/sbin/softwareupdate --install-rosetta --agree-to-license" with administrator privileges'
  if ! rosetta_ok; then
    alert "Rosetta could not be installed, so Wine (an Intel app) cannot run. Check your internet connection and try again. On macOS 28 or later, Rosetta may no longer be available for general Intel apps. See support.apple.com/102527."
    exit 1
  fi
  echo "Rosetta installed"
fi

case "$1" in
  --stop) exec wineserver -k ;;
  --dxmt-check)
    # DXMT needs winemac.so to export macdrv_* Metal symbols; stock WineHQ builds hide them.
    if nm -gU "$WINE_ROOT/lib/wine/x86_64-unix/winemac.so" | grep -q macdrv_functions; then
      echo "This Wine exports the Metal symbols DXMT needs."
    else
      echo "This Wine does NOT export the Metal symbols DXMT needs."
      exit 1
    fi
    exit 0 ;;
esac

# First launch: a fresh prefix, then Steam from Valve's own installer.
if [ ! -f "$STEAM_DIR/steam.exe" ]; then
  notify "Setting up Steam. The first launch takes a few minutes."
  mkdir -p "$DATA"
  if [ ! -f "$WINEPREFIX/system.reg" ]; then
    echo "Creating prefix"
    # Disabling mscoree/mshtml skips Wine's Mono and Gecko install prompts; Steam needs neither.
    WINEDLLOVERRIDES="mscoree,mshtml=" wine wineboot -i
    wineserver -w
  fi
  echo "Installing Steam"
  TMP="$(mktemp -d)"
  if ! /usr/bin/curl -fsSL -o "$TMP/SteamSetup.exe" "$STEAM_URL"; then
    rm -rf "$TMP"
    alert "Couldn't download Steam from Valve. Check your internet connection and open Steam on Mac again."
    exit 1
  fi
  wine "$TMP/SteamSetup.exe" /S
  wineserver -w
  rm -rf "$TMP"
  if [ ! -f "$STEAM_DIR/steam.exe" ]; then
    alert "Steam's installer didn't finish. Open Steam on Mac again to retry."
    exit 1
  fi
fi

# Show Steam's own logo (from this Mac's Steam install) as the app's icon. Steam's logo is
# Valve's trademark, so the downloaded app ships with a neutral icon instead. On the first launch
# the logo only arrives with Steam's first self-update, so wait for it in the background.
set_steam_icon() {
  local ico="$STEAM_DIR/public/steam_tray.ico" png
  for _ in $(seq 1 120); do [ -f "$ico" ] && break; sleep 10; done
  [ -f "$ico" ] || return
  png="$(mktemp -d)/steam.png"
  /usr/bin/sips -s format png "$ico" --out "$png" >/dev/null &&
    /usr/bin/osascript -l JavaScript -e 'function run(a) { ObjC.import("AppKit");
      return $.NSWorkspace.sharedWorkspace.setIconForFileOptions($.NSImage.alloc.initWithContentsOfFile(a[0]), a[1], 0) }' "$png" "$APP" >/dev/null &&
    echo "Set app icon to Steam's logo"
  rm -rf "$(dirname "$png")"
}
[ -f "$APP/Icon"$'\r' ] || set_steam_icon &

case "$1" in
  --wine) shift; exec wine "$@" ;;
  *) exec wine "C:\\Program Files (x86)\\Steam\\steam.exe" "${STEAM_FLAGS[@]}" "$@" ;;
esac
