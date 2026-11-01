# The Last Lala-Bye — promotional assets

The itch.io title is now **The Last Lala-Bye**. Existing game builds and artwork retain their original **The Last Lullaby** filenames and lettering.

- `screenshots/`: actual in-engine PNG captures. `12-ending-credits-review.png` contains an ending spoiler; the other eleven are promotional captures.
- `TheLastLullaby-Official-Trailer-1080p.mp4`: final 44.3-second 1080p trailer, using staged in-engine footage, CC0 music-box music and original game sounds.
- `itch-theme-handmade/`: banner, tiled page background, embed background, ZIP and upload guide. These are compositions of existing game screenshots, textures and fonts; no new image generation was used for this set. Some underlying game art was originally AI-assisted.
- `itch-cover.png`: earlier generated cover artwork, retained separately from gameplay screenshots.
- `tagline.txt` and `CREDITS.txt`: page copy and attribution.

Rebuild the itch theme with `python tools/build_itch_theme.py` after installing Pillow. The final trailer is included; temporary raw AVI footage and encoding logs are not.

Play: https://sammy-ryed.itch.io/the-last-lala-bye

First devlog: https://sammy-ryed.itch.io/the-last-lala-bye/devlog/1740140/four-music-boxes-one-very-bad-dream-meet-the-last-lala-bye

The `docs/release-v0.2.1` reports record validation at packaging time; their statements about uploads describe that earlier point in time. The itch page and devlog have since been published.
