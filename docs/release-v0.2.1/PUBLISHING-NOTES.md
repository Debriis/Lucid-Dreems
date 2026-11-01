# Browser-only itch.io release candidate — v0.2.1

Nothing has been uploaded to itch.io or pushed to GitHub for this revision.

## Upload this file

**TheLastLullaby-HTML5-v0.2.1.zip**

This contains index.html at the archive root, the Godot web runtime, game data, credits and license notices. Upload the ZIP intact; do not upload the Windows ZIP or the source repository for a browser-only page.

## itch.io settings

1. Create or edit the project; keep Visibility set to Draft until reviewed.
2. Set Kind of project to HTML (a game playable in the browser).
3. Upload TheLastLullaby-HTML5-v0.2.1.zip and check “This file will be played in the browser”.
4. Choose Embed in page, 1280 x 720. Enable Click to Play and the fullscreen button.
5. Leave SharedArrayBuffer support disabled: this export is single-threaded. Leave Mobile Friendly disabled: keyboard and mouse are required and touch has not been tested.
6. Use ITCH-PAGE.md for page copy and page-assets for the cover and five screenshots.
7. Preview the draft on itch, click Run Game, then test sound, movement, pause/resume and fullscreen. The local browser build has been smoke-tested; the actual itch embed has not been uploaded or tested.
8. Publish only when you decide to do so. For browser-only distribution, do not add any downloadable build files.

## Soundtrack permission remains unresolved

The included Buckshot Roulette OST — General Release recording was supplied locally without a redistribution license. Confirm permission to distribute it in this game, or replace it with a track licensed for the release. This local candidate preserves the requested song; it is not a rights-cleared release.

## Compatibility

Tested locally in Chromium on Windows, served over ordinary HTTP without cross-origin isolation. Requires WebGL 2 and WebAssembly. No mobile, Safari or Firefox validation has been performed. The game has no persistent story save; reload/restart begins a new session. Browser settings may persist locally. Use a moderate system volume: the game contains sudden loud sounds.

The requested score plays only on the title, pause menu and during Ayush pursuit. The original music remains during ordinary exploration. Web audio uses the streaming backend so the long track is not duplicated into large Web Audio sample buffers.

## Official reference

https://itch.io/docs/creators/html5

Local validation and limits are recorded in WEB-BUILD-REPORT.txt.
