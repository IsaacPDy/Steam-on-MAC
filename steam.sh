#!/bin/bash
# Terminal front end for Steam on Mac.app (in /Applications, or dist/ after ./make-app.sh).
# Usage: ./steam.sh [steam args...]   |   ./steam.sh --wine <wine args...>   |   ./steam.sh --stop   |   ./steam.sh --dxmt-check
APP="${STEAM_ON_MAC_APP:-/Applications/Steam on Mac.app}"
[ -d "$APP" ] || APP="$(cd "$(dirname "$0")" && pwd)/dist/Steam on Mac.app"
if [ ! -d "$APP" ]; then
  echo "Steam on Mac.app not found in /Applications or dist/. Download it from Releases or run ./make-app.sh." >&2
  exit 1
fi
exec "$APP/Contents/Resources/launch.sh" "$@"
