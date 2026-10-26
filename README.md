# Steam on Mac (CrossOver-source Wine + DXMT)

Runs the Windows Steam client and Windows games on macOS with Wine 11.0 built from CodeWeavers' published
CrossOver 26.0.0 source (LGPL) and DXMT v0.80 (Direct3D 10/11 to Metal). These are not CrossOver's own binaries,
and this project is not affiliated with CodeWeavers or Valve.

## Install

Needs macOS 11 or later. On Apple silicon it also needs Rosetta 2, because the Wine build is Intel-only;
`setup.sh` installs it if it is missing.

```bash
git clone https://github.com/IsaacPDy/Steam-on-MAC.git
cd Steam-on-MAC
./setup.sh
```

`setup.sh` does this, skipping any step that is already done:
1. Downloads the Wine build (`Wine-CX.app.tar.xz`, about 90 MB) from this repo's Releases and checks its SHA-256.
2. Creates a fresh Wine prefix in `prefix/`.
3. Downloads `SteamSetup.exe` from Valve and installs Steam into the prefix.
4. Builds `Steam.app` with `make-app.sh`. It is a Universal app if Xcode's command line tools are installed,
   and a script app otherwise.

Then open `Steam.app` and log in with your own account. Keep `Steam.app` in this folder.

## Use

- `./steam.sh` launches Steam. Logs from `Steam.app` go to `~/Library/Logs/Steam in Mac.log`.
- `./steam.sh --wine <cmd>` runs any Windows program in the prefix, for example
  `./steam.sh --wine "C:\Path\Game.exe"` or `./steam.sh --wine /path/to/Game.exe`.
- `./steam.sh --stop` quits Wine.
- `./steam.sh --dxmt-check` confirms the Metal symbols DXMT needs are exported.
- `WINEMSYNC=1` is off by default (it caused thread-creation failures in Steam).
  `WINE_APP="Other Wine"` picks a different `Other Wine.app` next to `steam.sh`.

Your Steam login, settings and games live only in `prefix/`, which is in `.gitignore`. Don't share that folder.

## How it works

- Steam's window: fixed by `tests/win32u-cross-process-paint.patch` (applied in the release build). Chromium's
  compositor process paints into the browser process's window; stock Wine on macOS discarded that drawing (black
  window). The patch gives such DCs a shared-memory surface that is copied onto the owner's window, reusing CX HACK
  23950's plumbing.
- DXMT's DLLs are installed into the Wine build as builtin DLLs, so every new prefix gets them.

## Rebuild Wine

1. Get the CrossOver 26.0.0 source from https://www.codeweavers.com/crossover/source and unpack it so Wine is in
   `~/cxwine/sources/wine`. Wine's build breaks on paths with spaces.
2. Apply `tests/win32u-cross-process-paint.patch` to `~/cxwine/sources/wine`.
3. Install the Homebrew build tools the scripts expect (bison, flex, mingw-w64, freetype, gnutls, molten-vk).
4. Run `tests/cxwine-configure.sh` from `~/cxwine/wine64`, then `tests/cxwine-make.sh`.
5. Copy DXMT v0.80 (https://github.com/3Shain/dxmt/releases) into `lib/wine/` of the install, then wrap the
   install as `Wine CX.app/Contents/Resources/wine`.

## Licences

The Wine build in Releases is LGPL-2.1 (source: CrossOver
26.0.0 source plus the patch above). DXMT is under its own licence. Steam is Valve's software and is downloaded from
Valve at setup time; it is not redistributed here.
