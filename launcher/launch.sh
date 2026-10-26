#!/bin/bash
# Run by Steam.app's native launcher. Makes sure Rosetta can run the Intel-only Wine,
# then starts steam.sh (any args are passed through, e.g. --wine winecfg).
RES="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cat "$RES/root-path" 2>/dev/null)"
# Prefer a steam.sh next to Steam.app; fall back to where make-app.sh was run.
[ -x "$RES/../../../steam.sh" ] && ROOT="$(cd "$RES/../../.." && pwd)"

LOG="$HOME/Library/Logs/Steam in Mac.log"
exec >>"$LOG" 2>&1
echo "=== $(date) launch $* ==="

alert() {
  /usr/bin/osascript -e 'on run {m}' -e 'display alert "Steam" message m as critical' -e 'end run' "$1" >/dev/null
}
rosetta_ok() { /usr/bin/arch -x86_64 /usr/bin/true 2>/dev/null; }

if [ ! -x "$ROOT/steam.sh" ]; then
  alert "Can't find steam.sh (looked in: $ROOT). Keep Steam.app in the folder it was built in, or run make-app.sh again."
  exit 1
fi
if [ ! -x "$ROOT/Wine CX.app/Contents/Resources/wine/bin/wine" ] || [ ! -f "$ROOT/prefix/system.reg" ]; then
  alert "Steam isn't set up on this Mac yet. Open Terminal in $ROOT and run ./setup.sh first."
  exit 1
fi

# Wine is an Intel (x86_64) app, so on Apple silicon it only runs through Rosetta.
# https://support.apple.com/102527
if [ "$(/usr/bin/uname -m)" = arm64 ] && ! rosetta_ok; then
  echo "Rosetta missing, asking to install"
  /usr/bin/osascript -e 'display dialog "Steam runs on Wine, which is an Intel-based app. It needs Rosetta to run on this Mac.

Install Rosetta now? You will be asked for your password." with title "Steam" buttons {"Cancel", "Install Rosetta"} default button "Install Rosetta" with icon caution' >/dev/null || exit 1
  /usr/bin/osascript -e 'do shell script "/usr/sbin/softwareupdate --install-rosetta --agree-to-license" with administrator privileges'
  if ! rosetta_ok; then
    alert "Rosetta could not be installed, so Wine (an Intel app) cannot run. Check your internet connection and try again. On macOS 28 or later, Rosetta may no longer be available for general Intel apps. See support.apple.com/102527."
    exit 1
  fi
  echo "Rosetta installed"
fi

exec "$ROOT/steam.sh" "$@"
