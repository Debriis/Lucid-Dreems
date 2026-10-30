# Empty room backgrounds

Six PNG backgrounds, each supplied at **640 × 480** and **1280 × 960**. The larger files are exact 2× nearest-neighbor renders for the same pixel style. Use one size per scene; the composition is identical.

| Scene | Native PNG |
| --- | --- |
| Patient consultation | `consultation_office_640x480.png` |
| Witch's cabin | `witch_cabin_640x480.png` |
| School memory | `school_hall_640x480.png` |
| Dining-room memory | `dining_room_640x480.png` |
| Final performance stage | `final_stage_640x480.png` |
| Three-way chase choice | `chase_corridor_640x480.png` |

These are empty room plates. No doctor, patient, witch, animatronic, or main music-box prop is baked into them. Signs, tables, wall clocks, small bottles, cauldron, and other scenery are baked in.

## Suggested placement at 640 × 480

- In the cabin, school, and stage, the table top occupies approximately `Rect2(202, 317, 156, 23)`. Align the music-box sprite's bottom with y=338.
- The back door occupies approximately `Rect2(275, 130, 90, 155)`.
- The left window/witch area occupies approximately `Rect2(158, 79, 99, 148)`.
- A large animatronic fits on the right, approximately `Rect2(385, 100, 205, 300)`.
- In the dining room, use the central table's upper half for the music box.
- Chase doors are left `Rect2(60, 150, 100, 180)`, forward `Rect2(270, 125, 100, 180)`, and right `Rect2(480, 150, 100, 180)`.
- These coordinates describe the imagery only; add interaction areas and dialogue separately in Godot. Double the coordinates when using the 1280 × 960 images.

## Godot import

Use a Sprite2D or TextureRect, preserve the 4:3 aspect ratio, and choose **Nearest** texture filtering. The PNGs have opaque backgrounds. Display your separate dialogue panels and character PNGs above the background.

## Source and credits

Original room layouts and code-native furniture are in `source/dream_room.gd`. Its dependencies are included in `source/assets/`. If using this optional renderer, copy that assets folder to your project root so textures resolve under `res://assets/textures/` and DotGothic16 under `res://assets/fonts/`, or update the paths. The exported background PNGs are self-contained.

The exported rooms incorporate the user's selected CC0 Seamless Abstract Pack and Old School Dungeon Crawler Pack by Screaming Brain Studios, CC0 Retro Textures Fantasy by Kenney, and rendered lettering in DotGothic16 by The DotGothic16 Project Authors. Full third-party source and license details are in the kit's asset credits. The museum music-box image and music tracks are supplied separately; they are not baked into these backgrounds.

Rendered and checked with Godot 4.6.1 using the Compatibility renderer.
