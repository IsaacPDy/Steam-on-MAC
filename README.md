# Steam on Mac (Wine 11.0 + DXMT)

Runs the Windows Steam client and Windows games on macOS with Wine 11.0 built from CodeWeavers' published
CrossOver 26.0.0 source (LGPL) and DXMT v0.80 (Direct3D 10/11 to Metal). These are not CrossOver's own binaries,
and this project is not affiliated with CodeWeavers or Valve.

## Install

Needs macOS 11 or later. On Apple silicon it also needs Rosetta 2, because the Wine build is Intel-only;
the app offers to install it.

1. Download `Steam-on-Mac.zip` from [Releases](https://github.com/IsaacPDy/Steam-on-MAC/releases/latest)
   and open it.
2. Drag `Steam on Mac` into your Applications folder.
3. Open it. macOS says it can't verify the app, because it isn't signed with a paid Apple Developer ID.
   Click **Done**, then go to System Settings → Privacy & Security and click **Open Anyway** next to
   "Steam on Mac". You only do this once.

The first launch takes a few minutes: it creates a Wine prefix, downloads Steam from Valve, and Steam then updates
itself. Log in with your own Steam account. Once Steam is installed, the app's icon switches to Steam's logo.

To keep it in the Dock, drag `Steam on Mac` from Applications into the Dock. Don't use "Keep in Dock" on the
running Steam icon: that pins Wine's own program, which shows up as a blank "exec" icon.

## Where things live

- `Steam on Mac.app` contains Wine and DXMT. Replacing it with a newer version keeps your Steam install.
- `~/Library/Application Support/Steam on Mac/prefix` holds Steam, your login, settings and games. Delete this
  folder to start over. Don't share it.
- `~/Library/Logs/Steam on Mac.log` is the launcher's log.

## Terminal

`./steam.sh` in this repo drives the installed app (or `dist/` after a build):
- `./steam.sh --wine <cmd>` runs any Windows program in the prefix, for example
  `./steam.sh --wine "C:\Path\Game.exe"` or `./steam.sh --wine /path/to/Game.exe`.
- `./steam.sh --stop` quits Wine.
- `./steam.sh --dxmt-check` confirms the Metal symbols DXMT needs are exported.
- `WINEMSYNC=1` is off by default (it caused thread-creation failures in Steam).

## Build the app

`./make-app.sh` builds `dist/Steam on Mac.app` and `dist/Steam-on-Mac.zip`. It needs Xcode's command line tools.
Wine comes from `./Wine CX.app` if present, otherwise from this repo's `wine-cx-11.0-1` release.

## How it works

- `launcher/main.c` is the app's native Universal entry point; it runs `launcher/launch.sh`, which clears the
  download quarantine from the Wine files inside the app (macOS kills quarantined unsigned programs), checks
  Rosetta, sets up the prefix on first launch and starts Steam.
- Steam's window: fixed by `tests/win32u-cross-process-paint.patch` (applied in the release build). Chromium's
  compositor process paints into the browser process's window; stock Wine on macOS discarded that drawing (black
  window). The patch gives such DCs a shared-memory surface that is copied onto the owner's window, reusing CX HACK
  23950's plumbing.
- DXMT's DLLs are installed into the Wine build as builtin DLLs, so every new prefix gets them.
- The app ships with its own icon (`launcher/make-icon.swift`); Steam's logo is Valve's trademark and is only
  taken from the user's own Steam install.

## Rebuild Wine

1. Get the CrossOver 26.0.0 source from https://www.codeweavers.com/crossover/source and unpack it so Wine is in
   `~/cxwine/sources/wine`. Wine's build breaks on paths with spaces.
2. Apply `tests/win32u-cross-process-paint.patch` to `~/cxwine/sources/wine`.
3. Install the Homebrew build tools the scripts expect (bison, flex, mingw-w64, freetype, gnutls, molten-vk).
4. Run `tests/cxwine-configure.sh` from `~/cxwine/wine64`, then `tests/cxwine-make.sh`.
5. Copy DXMT v0.80 (https://github.com/3Shain/dxmt/releases) into `lib/wine/` of the install, then wrap the
   install as `Wine CX.app/Contents/Resources/wine`.

## Licences

The Wine build inside the app and in Releases is LGPL-2.1 (source: CrossOver 26.0.0 source plus the patch above).
DXMT is under its own licence. Steam is Valve's software and is downloaded from Valve on first launch; it is not
redistributed here.
