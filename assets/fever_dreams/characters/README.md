# Character assets

All individual PNG frames are **512 × 768 RGBA**, with a genuinely transparent background. Their framing is consistent, so frames can be swapped without repositioning the character. The solid black areas inside the witch's mouth are intentional geometry; the surrounding canvas is transparent.

## Quick files

- `performer/performer.png`: bright violet humanoid animatronic, no animal ears.
- `ayush_witch/witch_closed.png`: Ayush's recognizable photographic face mapped onto a thick, faceted floating head.
- `ayush_witch/witch_open.png`: the same head with the lower jaw open.
- `patient/patient_idle.png`: the supplied patient portrait mapped onto a low-poly seated figure in a dark jacket.

## Animation strips

Use `AnimatedSprite2D` with individual numbered frames, or slice the horizontal strips into 512 × 768 cells. Use **nearest** texture filtering for the intended hard-edged appearance.

| Strip | Frames | Suggested FPS |
|---|---:|---:|
| `performer/performer_idle_strip.png` | 6 | 6 |
| `performer/performer_frantic_strip.png` | 6 | 8 |
| `ayush_witch/witch_chomp_strip.png` | 6 | 7 |
| `patient/patient_talking_strip.png` | 4 | 6 |

The strips contain one row; cells are ordered left to right. Exact frame names and timings are also recorded in `sprite_frames.json`.

## Editable 3D models

Drag these GLBs into Godot as 3D scenes:

- `models/performer.glb` — `idle` and `frantic` animations.
- `models/ayush_witch.glb` — `idle` and `chomp` animations; photo embedded.
- `models/patient.glb` — `idle` and `talking` animations; photo embedded.

The models are assembled from separate mesh nodes. Look for `RobotHead`, `RobotJaw`, `LeftArm`, `RightArm`, `PhotoHead`, `HingedPhotoJaw`, `PatientPhotoHead`, and `PatientPhotoJaw` when editing movement. These are object-transform animations, not a skinned skeleton. In 3D, the front of each character faces positive Z.

The photographic textures are imported at a 256-pixel maximum dimension, making the visible faces roughly 128–150 pixels across before rendering. The GLBs embed those smaller textures and explicitly use nearest minification/magnification samplers. Original supplied photographs are retained unchanged in the source folder.

`models/source/dream_character.gd` is the editable procedural source. It creates a transparent SubViewport character renderer with these calls:

```gdscript
character.configure("performer") # also "witch" or "patient"
character.set_intensity(1.0)     # 0 = idle, 1 = frantic
character.set_mouth(0.8)         # 0 = closed, 1 = open
character.set_gentle(true)      # reduces incidental motion
```

If using that source in another project, copy its `assets/characters` photos to the same path in the receiving project. The GLBs and PNGs are self-contained and do not require the source script.

Meshes were created for this project and rendered in Godot 4.6.1. The two photographic faces are the images supplied in this chat. No earlier rabbit illustration is used in these characters.
