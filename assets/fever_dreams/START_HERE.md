# FEVER DREAMS — assets for Ayush

This is an asset handoff, not a playable game or an engine project. PNGs, GLBs, audio, font, and optional editable art sources are organized by use.

## Start with these

- **Background:** `backgrounds/witch_cabin_640x480.png`
- **Purple animatronic:** `characters/performer/performer.png`
- **Ayush witch head:** `characters/ayush_witch/witch_closed.png` and `witch_open.png`
- **Patient:** `characters/patient/patient_idle.png`
- **Music box:** `props/music_box_cutout.png`
- **Dialogue frame:** `ui/dialogue_panel.png`
- **Choices:** `ui/choice_panel.png`, `ui/selected_row.png`, `ui/choice_cursor.png`
- **Font:** `fonts/DotGothic16-Regular.ttf`
- **Music:** `audio/musicbox1_spooky_waltz.ogg`

## What is here

| Folder | Contents |
| --- | --- |
| `backgrounds/` | Six empty rooms: consultation office, witch cabin, school hall, dining room, final stage, chase corridor. Each is supplied at 640×480 and 1280×960. Characters and main music box are separate. |
| `characters/` | Transparent character stills and animation frames/strips, plus three editable animated `.glb` models. See the character README and `sprite_frames.json`. |
| `textures/abstract_128/` | All 50 seamless abstract wallpaper patterns at 128×128. |
| `textures/abstract_256/` | The same 50 patterns at 256×256, inside the publisher's `256x256` subfolder. |
| `textures/abstract_512/` | The same 50 patterns at 512×512, inside the publisher's `512x512` subfolder. |
| `textures/dungeon_perspective/` | The publisher's complete downloaded base pack: brick walls, doors, windows and perspective layers. |
| `textures/dungeon_caves/` | The complete cave add-on, with nine materials in two perspective layers. |
| `textures/kenney_fantasy/` | The complete downloaded Kenney PNG texture folder. |
| `props/` | Transparent music-box cutout, unmodified museum photograph, provenance and edit notes. |
| `audio/` | All four looping music-box OGG tracks, MIDI source tracks, and seven original WAV sound effects. |
| `fonts/` | DotGothic16 TTF and its required OFL license. |
| `ui/` | Blank transparent dialogue/choice panels, row states, cursor/arrow, editable SVG versions, example layout and exact dimensions. |
| `dialogue.json` | Optional fictional consultation, four memories, pursuit lines, and ending. Use or change independently of the art. |

There are **459 texture PNG files** across the texture folders. This includes the three resolutions of the 50 wallpaper patterns; it is not 459 unique wallpaper designs.

## Drop into Godot

For the 2D version, use a 640×480 base viewport. Put one background PNG on a Sprite2D or TextureRect, layer transparent character sprites above it, then put the dialogue UI in a CanvasLayer. Use nearest texture filtering for the deliberate hard pixel edges.

Each character animation frame is 512×768. Individual frames can be added to SpriteFrames / AnimatedSprite2D. Horizontal strips have one row; the accompanying manifest specifies frame count, timing and looping. Keep consistent frame dimensions so the character does not jump between frames.

For a 3D character implementation, drag the GLBs from `characters/models/` into Godot. They include meshes, photo textures, and animation clips. The witch jaw is a separate hinged part. The custom character source files are optional modeling sources, not game logic.

For the dialogue layout at 640×480: panel at (8,344), size 624×128. Choices stack above it at the upper right; `ui/ui_manifest.json` gives exact placement and 9-slice guidance. Keep text separate from the blank panels. The sample PNG is a visual reference, not the reusable panel.

Suggested animation rates: idle 6 fps, frantic about 8 fps, witch chomp about 7 fps, patient talking about 6 fps. The manifest contains the exact render timing; adjust to the rhythm of the music if desired.

The museum music box is a circular, pocket-watch-shaped musical mechanism. Four game boxes can reuse this prop with different labels, scale or color modulation.

The MIDI tracks are editable music sources. Use the OGG versions for direct Godot playback. WAV cues are 22,050 Hz, 16-bit mono; the chase pulse is four seconds long and intended to loop.

## Credits

Read `CREDITS.md`. The stock textures and music are CC0, the museum photograph is public domain, and the font is SIL OFL. Preserve `fonts/OFL.txt` with the distributed font. User-provided face likenesses and custom character meshes are separate project material. The music-box cutout's built-in image-generation edit and exact prompt are recorded in `props/MUSIC_BOX_EDIT_PROMPT.txt`.
