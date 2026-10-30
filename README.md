# THE LAST LULLABY

A local Godot psychological-horror jam game. You are the sleep doctor, entering a patient's recurring nightmare. Four music boxes hold the dream together. Unwind them while Rue protects you from Ayush and the house's countdown.

**[Download the Windows game](https://github.com/sammy-ryed/the-last-lullaby/releases/latest)** — run `TheLastLullaby.exe`. The Godot project, character art, textures, music, voices, tools and tests are included in this repository. Built from [Debriis/Lucid-Dreems](https://github.com/Debriis/Lucid-Dreems), with its history and asset credits retained.

## Run on this laptop

- Open `project.godot` in Godot **4.6.1** and press **F5**. The project starts at the title menu.
- The Windows export preset writes `../Build/TheLastLullaby.exe`.
- No network, runtime TTS installation, or extra game dependencies are required after importing/exporting.

## Controls and objective

- **WASD** to move; **mouse** to look. **Q/C** or left/right arrows turn; up/down arrows move.
- **E / Enter / Space** to inspect, speak, open doors, or begin unwinding a music box.
- Find and unwind **four music boxes**, one in each dream room. Approach a box, look at it, and press E. The camera shows the lid opening and the key rotating backward for two seconds. Hear the memory, then follow the updated objective to the exit and press E.
- Read **three optional message scraps**, one in each of the first three rooms. They reveal why the patient stopped answering Maya. Finding some or all of them changes his final response; they are not required to finish.
- **Rue / The Performer** is the patient's childhood teddy bunny, transformed into a purple animatronic. He is visible at the dream entrance. Stay within his shield to block damage. After finding a scrap, ask him to keep Ayush busy: he distracts the witch for **eight seconds, once per room**.
- Each room starts with **100 health and 120 seconds**. A witch attack costs **25 health**; an expired clock costs **15 health every five seconds** outside Rue's protection. Talking, reading, unwinding and pausing stop the clock. Entering the next room restores health and time.
- **Ayush / The Keeper** has her own chamber and pursues you through the house. A catch gives a brief face/sound scare and returns you to that room's entry checkpoint, preserving boxes and notes, with a short protection window. At zero health, choose Retry Room or Main Menu. Occasional shorter glimpses happen only during exploration, at most once per room.
- **W/S or arrows** select dialogue/menu options; **E/Enter** or left click confirms.
- **Escape** opens pause. Resume preserves the current speech position and unwind progress.
- **R** begins another session after END. Restart and Main Menu are also available from pause.

The title and pause menus include How to Play, Settings and Credits. Master, voice, music and sound-effect controls persist under Godot's `user://settings.cfg`. Reduced Effects disables random glimpses and the strongest world distortion, reduces incidental movement, and lowers scare audio. Scares never interrupt dialogue, menus or unwinding.

## Presentation and audio

The patient sits directly opposite the psychiatrist's desk in the appointment and waking scenes. The V2 sad floating-head PNG sits over an intentionally angular seated figure and moves subtly with the measured speech envelope. This is a stylized talking portrait, not phoneme lip-sync.

All active dream character art uses the supplied V2 PNG heads; the witch alternates closed/open jaw states and Rue has faceted purple ears and an articulated metal body. Their names appear in-world and in dialogue. Music boxes use the V2 wooden closed/open sprites, with a separately animated key and progress indication. Four completion slots, room-specific directions, health and a room clock stay visible during exploration. The first room has timber beams, a crooked door, an iron stove and a green cauldron to identify it as the witch's cabin; the second belongs to Ayush.

The 3D world is rendered at 320 x 180 and enlarged with nearest filtering; the 1280 x 720 UI remains readable. Chipped paper panels, detached speaker/choice pieces, pink/acid accents and three fonts replace the default text treatment: DotGothic16 for dialogue, Special Elite for clinical labels, Rubik Glitch for titles. The original structural room textures remain in use.

Twenty-four patient lines are included as local WAVs using synthetic **Microsoft David Desktop**, lightly slowed/pitched and textured. They are not a clone of the photographed person's voice. Advancing stops the previous line, pause holds playback, and music ducks during speech. The licensed music-box tracks play in the menu/dream, slow and reverse during unwinding, and stop after the fourth box. The final patient line still plays after the dream falls silent. Two original scare stingers use the SFX/master volume settings and do not stack or clip. Normal Quit and window close release audio before exiting.

Everyone else speaks in original Animalese-like syllables assembled to the subtitle's rhythm. The doctor has a dry, lower mutter, Rue a high mechanical chatter, and Ayush a rough low voice with reversed syllables. These share the voice-volume and pause/advance controls; they never animate the patient's portrait. The subtitles remain the source of the actual words.

## Story and implementation

The appointment leads through the witch's cabin, Ayush's chamber, school hall and theatre, then a single ending. The patient keeps saying "I'm fine" and withdrawing from a friend who saved him a slice of birthday cake. Rue's comforting song has become a way to avoid answering; Ayush keeps the doors locked so nobody can reject him. Rue realizes that keeping someone safe must also mean helping them leave, and protects the doctor as each box opens another door. The doctor dies inside the dream, the patient wakes, and the final line remains **"You heard me."** Finding the notes adds a small, concrete intention to answer his friend rather than an instant cure. Dialogue choices get different replies without adding more rooms or a long branching plot.

`Story` owns the box states: `unwinding`, `remembering`, `complete`, and the three note IDs. A box reserves its ID before animation, cannot be activated twice, and unlocks the next exit only after the memory conversation. The last exit requires all four completions. Restart clears both boxes and notes.

Scene transitions are generation-checked: repeated interaction cannot cancel a fade, pause freezes it, and returning to the menu cancels the old transition. Audio has matching cancellation so an abandoned unwind cannot restart its song later.

## Validation

The canonical suite exercises startup, keyboard/mouse choices, movement/collision, four-room progression, timed unwinding, duplicate protection, notes, Rue's shield/distraction, witch damage, room countdowns, health restoration, both lethal-catch and timeout retries, random-scare gating, pause/resume, objectives, V2 sprites, final silence, ending and reset. Presentation checks cover the centered patient, spoken-line switching, title/pause transitions, entry bunny visibility, note layout, catch presentation and actual timeout/retry flow. Separate audio checks cover distinct character chatter, scare duration/volume/pause/silence and graceful shutdown.

```powershell
godot --headless --path . --editor --import --quit
godot --headless --path . --fixed-fps 60 res://tests/Smoke.tscn
godot --path . --fixed-fps 60 res://tests/Smoke.tscn -- --capture
godot --path . --fixed-fps 60 res://tests/PresentationReview.tscn -- --capture
godot --headless --path . res://tools/AudioChatterSmoke.tscn
godot --headless --path . res://tools/AudioScareSmoke.tscn
godot --headless --path . --export-release "Windows Desktop" ../Build/TheLastLullaby.exe
```

Review captures are written under `.tools/captures` and `.tools/review` and are excluded from version control. Historical prototype scripts and original assets remain available but are not the startup route.

## Sources

- Original project: https://github.com/Debriis/Lucid-Dreems
- Supplied V2 archive is extracted under `assets/replacements_v2`; its source prompts and font license are retained.
- Original asset provenance: `assets/fever_dreams/CREDITS.md`.
- New font provenance/licenses: `assets/fonts/SOURCES.md` and adjacent license files.
- Audio source, speech processing and reproduction steps: `audio/README.md` and `tools/generate_patient_voice.ps1` / `tools/voice_envelopes.py`.

This is still a short jam game: fixed-height grid environments, stylized sprite actors and scripted pursuits/ending; no save system or combat.
