#!/bin/bash
# One-time setup on a new Mac: fetches the Wine build, creates a fresh Wine prefix,
# installs Steam into it from Valve's own installer, then builds Steam.app.
# Usage: ./setup.sh        (safe to run again; finished steps are skipped)
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
WINE_APP="$HERE/Wine CX.app"
WINE_URL="${WINE_URL:-https://github.com/IsaacPDy/Steam-on-MAC/releases/download/wine-cx-11.0-1/Wine-CX.app.tar.xz}"
WINE_SHA256="${WINE_SHA256:-411e9c8a09943cf64993caf8dd3fedf4f651bec40f0b62d52415f1a4d56307af}"
STEAM_URL="https://cdn.cloudflare.steamstatic.com/client/installer/SteamSetup.exe"
STEAM_EXE="$HERE/prefix/drive_c/Program Files (x86)/Steam/steam.exe"
export WINEPREFIX="$HERE/prefix"
export WINEDEBUG="${WINEDEBUG:--all}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

step() { printf '\n==> %s\n' "$*"; }
die() { printf 'setup.sh: %s\n' "$*" >&2; exit 1; }

# A repo downloaded as a zip from a browser is quarantined, which stops Gatekeeper from running it.
xattr -dr com.apple.quarantine "$HERE" 2>/dev/null || true

# Wine is an Intel (x86_64) build, so Apple silicon Macs need Rosetta 2.
if [ "$(uname -m)" = arm64 ] && ! arch -x86_64 /usr/bin/true 2>/dev/null; then
  step "Installing Rosetta 2 (Wine is an Intel app; you may be asked for your password)"
  sudo softwareupdate --install-rosetta --agree-to-license
  arch -x86_64 /usr/bin/true 2>/dev/null || die "Rosetta is still not available. See https://support.apple.com/102527"
fi

if [ ! -x "$WINE_APP/Contents/Resources/wine/bin/wine" ]; then
  step "Downloading Wine 11.0 with DXMT"
  curl -fL --progress-bar -o "$TMP/wine.tar.xz" "$WINE_URL"
  echo "$WINE_SHA256  $TMP/wine.tar.xz" | shasum -a 256 -c - >/dev/null || die "Wine download failed its checksum; try again."
  tar -xJf "$TMP/wine.tar.xz" -C "$HERE"
  xattr -dr com.apple.quarantine "$WINE_APP" 2>/dev/null || true
fi
export PATH="$WINE_APP/Contents/Resources/wine/bin:$PATH"

if [ ! -f "$WINEPREFIX/system.reg" ]; then
  step "Creating a fresh Wine prefix in ./prefix"
  # Disabling mscoree/mshtml skips Wine's Mono and Gecko install prompts; Steam needs neither.
  WINEDLLOVERRIDES="mscoree,mshtml=" wine wineboot -i
  wineserver -w
fi

if [ ! -f "$STEAM_EXE" ]; then
  step "Downloading and installing Steam from Valve"
  curl -fL --progress-bar -o "$TMP/SteamSetup.exe" "$STEAM_URL"
  wine "$TMP/SteamSetup.exe" /S
  wineserver -w
  [ -f "$STEAM_EXE" ] || die "Steam's installer did not finish. Run ./setup.sh again."
fi

step "Building Steam.app"
"$HERE/make-app.sh"

step "Done. Open Steam.app (or run ./steam.sh) and log in with your own account."
echo "Steam updates itself on first launch; that can take a few minutes."
