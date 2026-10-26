#!/bin/bash
# Launch Steam in the cloned bottle using the bundled open-source Wine Staging.
# Usage: ./steam.sh [steam args...]   |   ./steam.sh --wine <wine args...>   |   ./steam.sh --dxmt-check
HERE="$(cd "$(dirname "$0")" && pwd)"
WINE_APP="${WINE_APP:-Wine CX}"
WINE_ROOT="$HERE/$WINE_APP.app/Contents/Resources/wine"
export WINEPREFIX="$HERE/prefix"
export WINEDEBUG="${WINEDEBUG:--all}"
export WINEMSYNC="${WINEMSYNC:-0}"
# wined3d on macOS OpenGL left Steam black; the Vulkan (MoltenVK) renderer is the one being tested.
[ -n "$USE_WINED3D_VK" ] && export WINE_D3D_CONFIG="renderer=vulkan"
export PATH="$WINE_ROOT/bin:$PATH"
if [ ! -x "$WINE_ROOT/bin/wine" ] || [ ! -f "$WINEPREFIX/system.reg" ]; then
  echo "Wine or the prefix is missing. Run ./setup.sh first." >&2
  exit 1
fi
# Steam's UI is Chromium (CEF); these flags avoid the usual blank-window problems under Wine.
STEAM_FLAGS=(-no-cef-sandbox -cef-disable-gpu)

case "$1" in
  --wine) shift; exec wine "$@" ;;
  --stop) exec wineserver -k ;;
  --dxmt-check)
    # DXMT needs winemac.so to export macdrv_* Metal symbols; stock WineHQ builds hide them.
    if nm -gU "$WINE_ROOT/lib/wine/x86_64-unix/winemac.so" | grep -q macdrv_functions; then
      echo "This Wine exports the Metal symbols: DXMT can be installed (see README.md)."
    else
      echo "This Wine does NOT export the Metal symbols DXMT needs. Games use wined3d (OpenGL) for now."
      exit 1
    fi ;;
  *) exec wine "C:\\Program Files (x86)\\Steam\\steam.exe" "${STEAM_FLAGS[@]}" "$@" ;;
esac
