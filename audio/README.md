# Audio

The menu and first dream room play `musicbox1_spooky_waltz.ogg`; later dream
rooms use `musicbox3_sad_tune.ogg`. These are existing CC0 tracks by
Aureolus_Omicron, from https://opengameart.org/content/4-music-box-tracks.
Original tracks, MIDI, credit, and licenses remain in `assets/fever_dreams`.
Speech automatically lowers the song by 8 dB, then restores the chosen level.

Every box unwinds over two seconds: 0.8 seconds of the song slowing, then a
1.2-second reversed phrase with a short fade. `unwind_reverse_short.wav` is
trimmed from the existing `unwind_reverse.wav`, itself derived from the supplied
spooky waltz. The fourth box then stops all music, ambience, and cues; patient
dialogue can still be heard. The final scene keeps its existing single ending
click. Menu/reset/scene transitions invalidate pending audio sequences.

`voice/patient_01.wav` through `patient_24.wav` cover every patient line in
`scripts/story.gd` and `scripts/ending.gd`. They are prerecorded synthetic
Microsoft David Desktop speech, produced locally with Windows System.Speech
at rate -1, not a recording or imitation of the photographed friend. Processing
lowers pitch by four percent, removes very low/high frequencies, and adds a
small amount of 12-bit grain. A final limiter leaves at least 1.4 dB of sample
headroom without automatic makeup gain. All lines remain intelligible mono 24 kHz PCM.
There is no network or runtime text-to-speech dependency.

The doctor, Rue and Ayush use original voiced gibberish instead of recorded
language. `audio/chatter` contains six formant-synthesized syllables per character:
the doctor has a dry mid-low mutter, Rue has a high springy mechanical voice,
and Ayush has low rough reversed syllables. No voice recordings or clones were
used. `tools/generate_character_chatter.py` reproduces the palettes and provenance.
WAVs are retained for authoring; explicit PCM `.tres` preloads avoid compressed
WAV import formats when assembling sounds. The three preview palettes are in
an ignored `audio/chatter/previews` folder.

`Game.play_dialogue` assembles one interruptible stream per NPC line, varying
syllables with word length and inserting punctuation pauses. `DOCTOR`, `RUE` /
`PERFORMER`, and `AYUSH` / `WITCH` labels are recognized. The unprefixed denial
lines also use Ayush. Narration stays silent. All dialogue uses the Voice bus,
pauses with the menu, stops on advance, and ducks music; the final music silence
still allows dialogue. `voice_is_playing()` covers every speaker, while
`voice_level()` returns a mouth envelope only for the patient. `dialogue_speaker`
is `PATIENT`, `DOCTOR`, `RUE`, `AYUSH`, or empty.

`voice/manifest.json` records exact dialogue, spoken text, source voice,
processing, durations, and RMS envelopes. `voice/dialogue_bank.gd` contains
the same runtime lookup/envelopes and explicit WAV preloads as a Godot script
resource, so exported games include both metadata and speech even when exporting
selected scenes. `voice/source` retains the unprocessed WAVs and has `.gdignore`.

To regenerate on Windows with Microsoft David and FFmpeg installed:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/generate_patient_voice.ps1
python tools/voice_envelopes.py
```

Game API: `play_dialogue(text)`, `stop_voice()`, `voice_is_playing()`,
`voice_level()` (patient-only 0–1 mouth envelope), `dialogue_speaker`, `set_audio_paused(bool)`,
`play_menu_music()`, `play_music_box(dream)`, `unwind_music(id)`, `silence()`.
`start_session()` enters the appointment; `reset()` remains its canonical direct
entry point. `return_to_menu()` cancels current playback and clears story state.

`play_scare("catch")` plays an original 0.70-second metallic impact; `"glimpse"`
plays an original 0.30-second dry noise rasp. Peak amplitudes are capped at
0.78 and 0.68 respectively. The cues use the SFX bus, cannot stack, and briefly
lower music by 12 dB. Reduced effects lowers their playback by another 9 dB.
Pause, final silence and shutdown block new scare sounds. UI owns the one
audio trigger per jumpscare. `tools/generate_scares.py` regenerates these WAVs;
`audio/scare_manifest.json` records their durations and measured peaks.

Menu Quit and root-window close use `Game.request_quit()`: stop and release
playback streams, briefly drain the audio mixer, then exit. Forced engine
shutdown (`--quit-after`) bypasses this path and can report outstanding OGG
playback references even when ordinary game shutdown is clean.

Settings persist in `user://settings.cfg`: master/music/voice/sfx volume from
0–1, music/voice/sfx mute, and reduced effects. Use `get_settings()` and
`set_setting(key,value)`; listen for `settings_changed`. Dream room ambience
uses the Music bus. Speech, cues and music pause/resume without restarting.
