# THE LAST LALA-BYE

A local Godot psychological-horror jam game. You are the sleep doctor, entering a patient's recurring nightmare. Four music boxes hold the dream together. Unwind them while Rue protects you from Ayush and the house's countdown.

**[Download the Windows game](https://github.com/sammy-ryed/the-last-lullaby/releases/latest)** — run `TheLastLullaby.exe`. The Godot project, character art, textures, music, voices, tools and tests are included in this repository. Built from [Debriis/Lucid-Dreems](https://github.com/Debriis/Lucid-Dreems), with its history and asset credits retained.

## Run on this laptop

- Open `project.godot` in Godot **4.6.1** and press **F5**. The project starts at the title menu.
- The Windows export preset writes `../Build/TheLastLullaby.exe`.
- The **Web** export preset writes `../ItchRelease/Web/index.html`. This single-threaded WebGL 2 build runs in a desktop browser without installing Godot. Web audio uses streaming to avoid decoding the long soundtrack into oversized sample buffers.
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

Twenty-four patient lines are included as local WAVs using synthetic **Microsoft David Desktop**, lightly slowed/pitched and textured. They are not a clone of the photographed person's voice. Advancing stops the previous line, pause holds playback, and music ducks during speech. The original CC0 music-box melodies play during ordinary exploration and slow and reverse during unwinding. The final patient line still plays after the dream falls silent. Two original scare stingers use the SFX/master volume settings and do not stack or clip. Normal Quit and window close release audio before exiting.

Everyone else speaks in original Animalese-like syllables assembled to the subtitle's rhythm. The doctor has a dry, lower mutter, Rue a high mechanical chatter, and Ayush a rough low voice with reversed syllables. These share the voice-volume and pause/advance controls; they never animate the patient's portrait. The subtitles remain the source of the actual words.

The main background song is the supplied **Buckshot Roulette OST — General Release (extended)**, balanced with a softened speech-frequency range and a crossfaded loop. It plays only on the main menu, during pause, and during Ayush pursuits. Ordinary exploration uses the original music, and the consultation stays quiet. It ducks beneath dialogue, music-box interactions and scares, then stops after the final pursuit. Its volume follows the existing Music slider.

## Story and implementation

The appointment leads through the witch's cabin, Ayush's chamber, school hall and theatre, then a single ending. The patient keeps saying "I'm fine" and withdrawing from a friend who saved him a slice of birthday cake. Rue's comforting song has become a way to avoid answering; Ayush keeps the doors locked so nobody can reject him. Rue realizes that keeping someone safe must also mean helping them leave, and protects the doctor as each box opens another door. The doctor dies inside the dream, the patient wakes, and the final line remains **"You heard me."** Finding the notes adds a small, concrete intention to answer his friend rather than an instant cure. Dialogue choices get different replies without adding more rooms or a long branching plot.

`Story` owns the box states: `unwinding`, `remembering`, `complete`, and the three note IDs. A box reserves its ID before animation, cannot be activated twice, and unlocks the next exit only after the memory conversation. The last exit requires all four completions. Restart clears both boxes and notes.

Scene transitions are generation-checked: repeated interaction cannot cancel a fade, pause freezes it, and returning to the menu cancels the old transition. Audio has matching cancellation so an abandoned unwind cannot restart its song later.

## Validation

The canonical suite exercises startup, keyboard/mouse choices, movement/collision, four-room progression, timed unwinding, duplicate protection, notes, Rue's shield/distraction, witch damage, room countdowns, health restoration, both lethal-catch and timeout retries, random-scare gating, pause/resume, objectives, V2 sprites, final silence, ending and reset. Presentation checks cover the centered patient, spoken-line switching, title/pause transitions, entry bunny visibility, note layout, catch presentation and actual timeout/retry flow. Separate audio checks cover distinct character chatter, scare duration/volume/pause/silence and graceful shutdown.

```powershell
godot --headless --path . --editor --import --quit
godot --headless --path . --max-fps 60 res://tests/Smoke.tscn
godot --path . --max-fps 60 res://tests/Smoke.tscn -- --capture
godot --path . --max-fps 60 res://tests/PresentationReview.tscn -- --capture
godot --headless --path . res://tools/AudioChatterSmoke.tscn
godot --headless --path . res://tools/AudioScareSmoke.tscn
godot --headless --path . --export-release "Windows Desktop" ../Build/TheLastLullaby.exe
godot --headless --path . --export-release Web ../ItchRelease/Web/index.html
python tools/package_web.py ../ItchRelease/Web ../ItchRelease/TheLastLullaby-HTML5-v0.2.1.zip
```

Review captures are written under `.tools/captures` and `.tools/review` and are excluded from version control. Historical prototype scripts and original assets remain available but are not the startup route.

## Sources

- Original project: https://github.com/Debriis/Lucid-Dreems
- Supplied V2 archive is extracted under `assets/replacements_v2`; its source prompts and font license are retained.
- Original asset provenance: `assets/fever_dreams/CREDITS.md`.
- New font provenance/licenses: `assets/fonts/SOURCES.md` and adjacent license files.
- Audio source, speech processing and reproduction steps: `audio/README.md` and `tools/generate_patient_voice.ps1` / `tools/voice_envelopes.py`.

This is still a short jam game: fixed-height grid environments, stylized sprite actors and scripted pursuits/ending; no save system or combat.

## Browser-only itch.io package

Upload `TheLastLullaby-HTML5-v0.2.1.zip` as an **HTML Game** and select **This file will be played in the browser**. Keep `index.html` at the ZIP root. Use a 1280 x 720 embed, Click to Play and a fullscreen button. Leave SharedArrayBuffer and Mobile Friendly disabled. Do not add the Windows ZIP if the page should be browser-only. Full instructions and page copy are in the adjacent `ItchRelease` folder. The browser game is now available at https://sammy-ryed.itch.io/the-last-lala-bye.

Web smoke review covers the menu, intro, branching reply, dream entrance, movement and pause/resume in Chromium on this laptop; the full route suite runs natively. Other browsers and devices have not been verified. The supplied Buckshot Roulette soundtrack still needs redistribution permission before public release.

## Developers

- Sreevalli pallapothu
- Ayush (RA2411003010862)
- Samarth Ryan Edward


## Published page and launch materials

**[Play The Last Lala-Bye on itch.io](https://sammy-ryed.itch.io/the-last-lala-bye)**

The itch title is The Last Lala-Bye; existing builds and art retain The Last Lullaby naming. Source files, credits, Web export and soundtrack updates are included here. Final screenshots, trailer, cover and the screenshot-based itch theme are in [`promo/`](promo/README.md). The published first devlog is archived in [`docs/first-devlog.md`](docs/first-devlog.md). Packaging-time validation reports and publishing notes are in `docs/release-v0.2.1/`.

Godot ignores the `promo/` and `docs/` directories so promotional media is not imported into game builds. Rebuild exports using the commands above; compiled ZIPs, editor caches and temporary captures remain outside source control.