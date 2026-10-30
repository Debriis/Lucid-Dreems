# THE LAST LULLABY

A playable psychological horror game-jam prototype for **Godot 4.7.2**. The
existing first-person renderer, controller, collisions, supplied FEVER DREAMS
assets, music and sound effects have been extended rather than replaced.

## Play

Import `project.godot` in Godot 4.7.2, allow asset import, and press **F5**.
No manual scene assembly or extra runtime dependencies are required.

- **WASD:** walk / strafe. **Mouse:** horizontal and vertical look.
- **Q/C** or **left/right arrows:** keyboard turning; up/down arrows move.
- **E / Enter / Space:** interact or continue dialogue.
- **W/S or arrows:** select a dialogue response; **E/Enter** confirms.
- **Left click:** select a response or advance dialogue. During gameplay,
  left click recaptures the mouse after it has been released.
- **Escape:** release the mouse. Dialogue also releases it automatically.
  Finishing dialogue recaptures it and resumes the camera and movement.
- **R:** begin again after the final END screen.

Mouse sensitivity is exported as `mouse_sensitivity` in
`scripts/first_person_player.gd` (default 0.0028 radians per relative pixel).
Mouse X rotates only the body yaw. Mouse Y changes Camera3D pitch, clamped to
-80/+80 degrees. Camera yaw and roll remain zero. Movement stays horizontal,
so looking up or down does not change speed or collision behaviour.

## Sharp UI, low-resolution world

The main viewport is **1280 x 720**, using canvas_items stretching. The UI is a
root CanvasLayer at that resolution, with a clean antialiased 26px dialogue
font, 25px choice buttons, 24px HUD and generous padding. The supplied retro
ivory panel remains; text is rendered directly at native resolution.

Only the 3D world goes into `WorldViewport`, a **320 x 180 SubViewport** with its
own World3D. `WorldDisplay` enlarges that texture using nearest filtering.
Dithering/fog are on world materials, and the distortion/chromatic shader is
inside that SubViewport's `WorldEffects` layer. No retro shader touches the UI.
Input is routed from the native UI viewport to the existing player controller,
so mouse sensitivity and choice coordinates are independent of world resolution.

## Canonical story and progression

The player is a psychotherapist who can enter dreams. The patient has not slept
properly for weeks. A purple Performer dances beside a music box in a witch's
cabin. He always wakes before the music ends.

There are now **four separate music-box states and one ending**. `Story`, an
autoload in `scripts/story.gd`, owns the stage, box states, room unlock and
ending phase. Scenes never maintain their own copies of canonical progress.
An activation first reserves that box as `unwinding`; it cannot be activated
again. Only the final dialogue callback changes it to `complete` and unlocks
the next exit. The old three-memory/two-ending route is no longer active.

| Scene | Playable sequence |
| --- | --- |
| TherapyRoom | Appointment; three keyboard/mouse questions and patient responses; occasional double clock tick; dream entry. |
| WitchCabin | Performer greeting and choices; first box in performance room; forced-smile memory; exit sign rewritten; witch revealed. |
| DiningRoom | Long table, chairs facing walls, closed boxes replacing food; second memory and choices; faces replace the plates; short witch pursuit. |
| SchoolHall | Wooden locker doors and wallpaper ceiling; marked door; third memory and supportive choices; denial overwrites testimony; escape back toward the cabin. |
| Theatre | The central cabin becomes a small theatre. The seated Performer explains its protective role. Fourth box in its lap; all music/ambience stop; final exit opens. |
| Ending | Doorway recedes; cabin folds; witch erases three affirmations with NOTHING HAPPENED. Only I'M STILL LISTENING. remains. The doctor dies inside the dream. Consultation room, flatline, PATIENT: You heard me. Cut to black, one click, END. |

The Performer and patient have separate speaker labels and roles. The Performer
is protective, not an evil combat enemy. The witch represents denial and the
punishment of speaking. Abuse is implied only through the supplied non-graphic
dialogue. Chases last eight seconds, are slower than the player, and have no
combat or damage system. The final death is a scripted non-graphic ending.

The performance room has a physical window opening into the adjoining interior.
Each subsequent room reuses the existing textured grid builder with a different
layout. The school box is behind the marked doorway; open it with E. Exits show
a sign and accept E or walking into the threshold once unlocked.

## Audio and assets

All 576 original supplied files remain under `assets/fever_dreams/`, with their
licenses and provenance. Actual wallpaper, wood, tiles, ceilings, frames and
doors are used on navigable geometry. The performer and witch use the supplied
GLBs. The antique music-box cutout is placed on a wooden table or in the
Performer's lap. Room-background images are only used for the consultation
cinematics and the impossible office doorway, never as the dream environment.

Winding, rattle and dream cues remain connected. Music-box unwinding lowers
pitch, plays a genuinely reversed phrase, and stops. `audio/unwind_reverse.wav`
is derived from the supplied spooky waltz; `tools/render_reverse.gd` recreates
it with Godot's audio decoder. The original WAV and all supplied OGGs are kept.
The fourth box calls centralized silence; the ending's final click plays once
without starting a melody. CC0 music/texture and model credits remain in
`assets/fever_dreams/CREDITS.md`; the included unused font retains its OFL file.

## Verification

Validated in Godot **4.7.2**: **67 checks passed** in both headless and rendered
OpenGL Compatibility runs, with no runtime errors or warnings. Startup, scene
resource paths and the original lullaby checksum were checked separately.

```powershell
godot --headless --path . --editor --import --quit
godot --headless --path . --fixed-fps 60 res://tests/Smoke.tscn
# Run the same route with graphics and native-resolution screenshots:
godot --path . --fixed-fps 60 res://tests/Smoke.tscn -- --capture
```

`tests/Smoke.tscn` selects `tests/canonical_smoke.gd`. It checks native UI sizing,
text wrapping, keyboard and mouse choices, yaw/pitch/clamps, no roll, cursor
release/recapture, movement, collisions, interaction targets, four box IDs,
duplicate protection, dialogue locks, room order, chases, silence, exact final
response, final patient line, END and reset. Historical tests are retained but
are not the active test entry point.

Captures named `assets/Current-*.png` come from the actual running game. Older
FP-*.png images and the original environment-builder sources are historical.
Prototype limits: fixed-height grid geometry, simplified seated character poses,
short scripted chases, no save system, and a scripted ending rather than combat.
