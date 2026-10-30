extends Node

signal settings_changed
signal voice_started(text: String)
signal voice_finished

const SETTINGS_PATH := "user://settings.cfg"
const VOICE_BANK = preload("res://audio/voice/dialogue_bank.gd")
const CHATTER_BANK = preload("res://audio/chatter/chatter_bank.gd")
const CHATTER_RATE := 24000
const MUSIC_SPOOKY := "res://assets/fever_dreams/audio/musicbox1_spooky_waltz.ogg"
const MUSIC_SAD := "res://assets/fever_dreams/audio/musicbox3_sad_tune.ogg"
const MAIN_SCORE := "res://audio/music/general_release_loop.ogg"
const DEFAULT_SETTINGS := {
	"master_volume": 0.85, "music_volume": 0.65, "voice_volume": 1.0, "sfx_volume": 0.75,
	"music_muted": false, "voice_muted": false, "sfx_muted": false, "reduced_effects": false,
}

var memories: Dictionary = {}
var crossings := 0
var ending := ""
var music: AudioStreamPlayer
var score: AudioStreamPlayer
var voice: AudioStreamPlayer
var cues: Dictionary = {}
var active_player: Node
var audio_generation := 0
var reduced_effects := false
var dialogue_speaker := ""
var _settings: Dictionary = DEFAULT_SETTINGS.duplicate()
var _voice_lines: Dictionary = {}
var _chatter_palettes: Dictionary = {}
var _chatter_cache: Dictionary = {}
var _voice_envelope: Array = []
var _envelope_hz := 20.0
var _audio_paused := false
var _silence_locked := false
var _unwinding := false
var _music_base_db := -17.0
var _quitting := false
var _scare_duck_left := 0.0
var _score_base_db := -8.0
var _cue_duck_left := 0.0
var _title_music := false
var _chase_music := false
var score_context := ""

func _ready() -> void:
	# A window close follows the same audio-drain path as the menu Quit action.
	get_tree().auto_accept_quit = false
	get_tree().root.close_requested.connect(request_quit)
	for action in ["left", "right", "up", "down", "interact", "restart", "strafe_left", "strafe_right", "forward", "back"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
	bind("left", [KEY_A, KEY_LEFT])
	bind("right", [KEY_D, KEY_RIGHT])
	bind("up", [KEY_W, KEY_UP])
	bind("down", [KEY_S, KEY_DOWN])
	bind("interact", [KEY_E, KEY_SPACE, KEY_ENTER])
	bind("restart", [KEY_R])
	bind("strafe_left", [KEY_A])
	bind("strafe_right", [KEY_D])
	bind("forward", [KEY_W, KEY_UP])
	bind("back", [KEY_S, KEY_DOWN])
	for bus_name in ["Music", "Voice", "SFX"]:
		if AudioServer.get_bus_index(bus_name) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
			AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
	music = AudioStreamPlayer.new()
	music.name = "Music"
	music.bus = "Music"
	music.stream = load(MUSIC_SPOOKY)
	music.volume_db = _music_base_db
	add_child(music)
	score = AudioStreamPlayer.new()
	score.name = "MainSoundtrack"
	score.bus = "Music"
	var soundtrack: AudioStreamOggVorbis = load(MAIN_SCORE)
	soundtrack.loop = true
	# The tail crossfades into the first two seconds; continue from that point.
	soundtrack.loop_offset = 2.0
	score.stream = soundtrack
	score.volume_db = -60.0
	add_child(score)
	voice = AudioStreamPlayer.new()
	voice.name = "DialogueVoice"
	voice.bus = "Voice"
	voice.volume_db = -2.0
	add_child(voice)
	voice.finished.connect(_on_voice_finished)
	_load_voice_manifest()
	for speaker: String in CHATTER_BANK.STREAMS:
		var palette: Array[PackedByteArray] = []
		for syllable: AudioStreamWAV in CHATTER_BANK.STREAMS[speaker]:
			palette.append(syllable.data)
		_chatter_palettes[speaker] = palette
	var cue_files := {"wind": "wind_key.wav", "rattle": "mechanical_rattle.wav", "dream": "dream_transition.wav", "tick": "ui_click.wav", "click": "ui_click.wav", "flatline": "session_terminated.wav"}
	for cue in cue_files:
		var sound := AudioStreamPlayer.new()
		sound.name = "Cue_" + cue
		sound.bus = "SFX"
		sound.stream = load("res://assets/fever_dreams/audio/sfx/" + cue_files[cue])
		sound.volume_db = -18.0 if cue == "rattle" else -13.0
		add_child(sound)
		cues[cue] = sound
	for kind in ["catch", "glimpse"]:
		var sound := AudioStreamPlayer.new()
		sound.name = "Scare_" + kind
		sound.bus = "SFX"
		sound.stream = load("res://audio/scare_" + kind + ".wav")
		add_child(sound)
		cues["scare_" + kind] = sound
	_load_settings()

func _process(delta: float) -> void:
	if _quitting:
		return
	_update_score_context()
	# Dialogue gently lowers the song without changing the player's volume setting.
	if not _audio_paused:
		_scare_duck_left = maxf(0.0, _scare_duck_left - delta)
		_cue_duck_left = maxf(0.0, _cue_duck_left - delta)
	var duck_db := 8.0 if voice_is_playing() else 0.0
	if _scare_duck_left > 0.0:
		duck_db = maxf(duck_db, 12.0)
	var target_db := _music_base_db - duck_db
	if not score_context.is_empty():
		target_db = -60.0 # Crossfade away from the original melody during a chase.
	music.volume_db = lerpf(music.volume_db, target_db, minf(delta * 7.0, 1.0))
	if score.playing:
		var score_duck := 12.0 if voice_is_playing() else 0.0
		if _unwinding and not _audio_paused:
			score_duck = maxf(score_duck, 18.0)
		if _scare_duck_left > 0.0 and not _audio_paused:
			score_duck = maxf(score_duck, 20.0)
		elif _cue_duck_left > 0.0 and not _audio_paused:
			score_duck = maxf(score_duck, 5.0)
		var score_target := -60.0 if score_context.is_empty() else _score_base_db - score_duck
		var rate := 22.0 if score_target < score.volume_db else 1.5
		score.volume_db = lerpf(score.volume_db, score_target, 1.0 - exp(-rate * delta))
		if score_context.is_empty() and score.volume_db <= -59.5:
			score.stop()

func _update_score_context() -> void:
	var next := ""
	if _audio_paused and not UI._failure_active:
		next = "pause"
	elif _title_music:
		next = "title"
	elif _chase_music and not _audio_paused:
		next = "chase"
	score_context = next
	if not next.is_empty():
		_start_score(-2.0 if next == "title" else (-8.0 if next == "pause" else -6.0))

func set_chase_music(active: bool) -> void:
	_chase_music = active

func _start_score(level: float) -> void:
	if _quitting:
		return
	_score_base_db = level
	if not score.playing:
		score.volume_db = -60.0
		score.play()
	score.stream_paused = false # Pause freezes the world, but plays its own menu music.

func _load_voice_manifest() -> void:
	# A script resource keeps this data in exported games without JSON export filters.
	for row: Dictionary in VOICE_BANK.LINES:
		_voice_lines[_normalise_dialogue(str(row.get("dialogue", "")))] = row

func _normalise_dialogue(text: String) -> String:
	return text.strip_edges().replace("’", "'").replace("\n", " ")

func play_dialogue(text: String) -> void:
	if _quitting:
		return
	stop_voice()
	var key := _normalise_dialogue(text)
	if _voice_lines.has(key):
		var row: Dictionary = _voice_lines[key]
		var stream: AudioStream = VOICE_BANK.STREAMS.get(str(row["path"]))
		if stream == null:
			push_warning("Patient speech could not be loaded: " + str(row["path"]))
			return
		voice.stream = stream
		voice.volume_db = -2.0
		_voice_envelope = row.get("envelope", []).duplicate()
		_envelope_hz = float(row.get("envelope_hz", 20.0))
		dialogue_speaker = "PATIENT"
	else:
		var speaker := _chatter_speaker(key)
		if speaker.is_empty():
			return # Narration and interface text stay silent.
		voice.stream = _build_chatter(key, speaker)
		voice.volume_db = -4.0 if speaker == "DOCTOR" else (-7.0 if speaker == "RUE" else -5.0)
		dialogue_speaker = speaker
	voice.pitch_scale = 1.0
	voice.play()
	voice.stream_paused = _audio_paused
	voice_started.emit(text)

func _chatter_speaker(text: String) -> String:
	var prefix := text.get_slice(":", 0).strip_edges().to_upper()
	match prefix:
		"DOCTOR":
			return "DOCTOR"
		"RUE", "PERFORMER":
			return "RUE"
		"AYUSH", "WITCH":
			return "AYUSH"
	var upper := text.to_upper()
	if upper.begins_with("YOU MUST HAVE REMEMBERED IT WRONG") or upper == "NOTHING HAPPENED.":
		return "AYUSH"
	return ""

func _build_chatter(text: String, speaker: String) -> AudioStreamWAV:
	var cache_key := speaker + ":" + text
	if _chatter_cache.has(cache_key):
		return _chatter_cache[cache_key]
	var spoken := text.substr(text.find(":") + 1).strip_edges() if text.contains(":") else text
	var palette: Array = _chatter_palettes[speaker]
	var syllable_gap := 0.018 if speaker == "RUE" else (0.028 if speaker == "DOCTOR" else 0.045)
	var word_gap := 0.035 if speaker == "RUE" else (0.055 if speaker == "DOCTOR" else 0.075)
	var sentence_gap := 0.16 if speaker == "RUE" else (0.22 if speaker == "DOCTOR" else 0.28)
	var pcm := PackedByteArray()
	pcm.resize(int(CHATTER_RATE * 0.025) * 2)
	var word_index := 0
	for word: String in spoken.to_lower().split(" ", false):
		var letters := word.rstrip(".,!?:;\"'—-").lstrip("\"'")
		var count := clampi(ceili(float(letters.length()) / 3.0), 1, 5)
		for syllable in range(count):
			var index := posmod(int(word.hash()) + syllable * 13 + word_index * 7, palette.size())
			pcm.append_array(palette[index])
			pcm.resize(pcm.size() + int(CHATTER_RATE * syllable_gap) * 2)
		var punctuation := word.rstrip("\"'").right(1)
		var pause := word_gap
		if punctuation in [".", "!", "?"]:
			pause += sentence_gap
		elif punctuation in [",", ":", ";"]:
			pause += sentence_gap * 0.5
		pcm.resize(pcm.size() + int(CHATTER_RATE * pause) * 2)
		word_index += 1
		if pcm.size() >= CHATTER_RATE * 2 * 16:
			break
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = CHATTER_RATE
	stream.stereo = false
	stream.data = pcm
	if _chatter_cache.size() >= 64:
		_chatter_cache.clear()
	_chatter_cache[cache_key] = stream
	return stream

func stop_voice() -> void:
	if is_instance_valid(voice):
		voice.stop()
	var had_speaker := not dialogue_speaker.is_empty()
	dialogue_speaker = ""
	_voice_envelope.clear()
	if had_speaker:
		voice_finished.emit()

func _on_voice_finished() -> void:
	dialogue_speaker = ""
	_voice_envelope.clear()
	voice_finished.emit()

func voice_is_playing() -> bool:
	return is_instance_valid(voice) and voice.playing and not voice.stream_paused and not bool(_settings["voice_muted"]) and float(_settings["voice_volume"]) > 0.0 and float(_settings["master_volume"]) > 0.0

func voice_level() -> float:
	if dialogue_speaker != "PATIENT" or not voice_is_playing() or _voice_envelope.is_empty():
		return 0.0
	var position := maxf(0.0, voice.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency())
	var index := clampi(int(position * _envelope_hz), 0, _voice_envelope.size() - 1)
	return float(_voice_envelope[index])

func play_cue(cue: String) -> void:
	if not _quitting and cues.has(cue):
		if cue in ["wind", "rattle", "dream"]:
			_cue_duck_left = 0.65
		cues[cue].play()
		cues[cue].stream_paused = _audio_paused

func play_scare(kind: String) -> void:
	if _quitting or _audio_paused or _silence_locked or kind not in ["catch", "glimpse"]:
		return
	# UI owns the single trigger. Replacing a cue also prevents audio stacking.
	for other in ["catch", "glimpse"]:
		cues["scare_" + other].stop()
	var sound: AudioStreamPlayer = cues["scare_" + kind]
	sound.volume_db = (0.0 if kind == "catch" else -4.0) - (9.0 if reduced_effects else 0.0)
	sound.play()
	_scare_duck_left = 0.75 if kind == "catch" else 0.35
	score.volume_db = minf(score.volume_db, _score_base_db - 20.0)

func stop_cues() -> void:
	_scare_duck_left = 0.0
	_cue_duck_left = 0.0
	for sound in cues.values():
		sound.stop()

func play_music_box(dream: bool) -> void:
	if _silence_locked:
		return
	_title_music = false
	_begin_music(MUSIC_SAD if dream else MUSIC_SPOOKY, -17.0)

func play_menu_music() -> void:
	if _quitting:
		return
	_silence_locked = false
	_title_music = true
	set_audio_paused(false)
	music.stop()
	_update_score_context()

func _begin_music(path: String, volume: float) -> void:
	if _quitting:
		return
	audio_generation += 1
	_unwinding = false
	_music_base_db = volume
	music.pitch_scale = 1.0
	if music.stream == null or music.stream.resource_path != path:
		music.stop()
		var tune: AudioStreamOggVorbis = load(path)
		tune.loop = true
		music.stream = tune
	if not music.playing:
		music.play()
	music.stream_paused = _audio_paused

func set_audio_paused(value: bool) -> void:
	_audio_paused = value
	if is_instance_valid(music):
		music.stream_paused = value
	if is_instance_valid(voice):
		voice.stream_paused = value
	for sound in cues.values():
		sound.stream_paused = value
	for ambient in get_tree().get_nodes_in_group("dream_audio"):
		ambient.stream_paused = value
	_update_score_context()

func bind(action: String, keys: Array) -> void:
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		if not InputMap.action_has_event(action, event):
			InputMap.action_add_event(action, event)

func travel(path: String) -> void:
	if _quitting:
		return
	_title_music = false
	_chase_music = false
	# A departed room cannot resume a pending reverse phrase after its coroutine wakes.
	audio_generation += 1
	if _unwinding:
		music.stop()
		music.pitch_scale = 1.0
		_unwinding = false
	stop_voice()
	UI.clear()
	var error := get_tree().change_scene_to_file(path)
	if error != OK:
		push_error("Scene transition failed: " + path)

func remember(id: String) -> bool:
	if memories.has(id):
		return false
	memories[id] = true
	return true

func reset() -> void:
	Story.reset()
	silence()
	memories.clear()
	crossings = 0
	ending = ""
	_silence_locked = false
	set_audio_paused(false)
	if UI.has_method("close_menu"):
		UI.close_menu()
	travel("res://scenes/TherapyRoom.tscn")

func start_session() -> void:
	reset()

func return_to_menu() -> void:
	silence()
	Story.reset()
	memories.clear()
	crossings = 0
	ending = ""
	active_player = null
	set_audio_paused(false)
	if UI.has_method("close_menu"):
		UI.close_menu()
	travel("res://scenes/MainMenu.tscn")

func silence() -> void:
	audio_generation += 1
	_silence_locked = true
	_title_music = false
	_chase_music = false
	score_context = ""
	_unwinding = false
	music.stop()
	music.pitch_scale = 1.0
	score.stop()
	stop_voice()
	stop_cues()
	for ambient in get_tree().get_nodes_in_group("dream_audio"):
		ambient.stop()

func unwind_music(id: int) -> void:
	if _silence_locked or _quitting:
		return
	_begin_music(MUSIC_SAD if id > 1 else MUSIC_SPOOKY, -13.0)
	audio_generation += 1
	var generation := audio_generation
	_unwinding = true
	play_cue("wind")
	var elapsed := 0.0
	var reverse_started := false
	while elapsed < 2.0:
		await get_tree().process_frame
		if generation != audio_generation:
			return
		if _audio_paused:
			continue
		elapsed += get_process_delta_time()
		if elapsed < 0.8:
			music.pitch_scale = lerpf(1.0, 0.55, elapsed / 0.8)
		elif not reverse_started:
			reverse_started = true
			music.stop()
			music.pitch_scale = 1.0
			music.stream = load("res://audio/unwind_reverse_short.wav")
			music.play()
	if generation != audio_generation:
		return
	_unwinding = false
	music.stop()
	music.pitch_scale = 1.0
	if id == 4:
		silence()

func get_settings() -> Dictionary:
	return _settings.duplicate()

func get_setting(key: String) -> Variant:
	return _settings.get(key)

func set_setting(key: String, value: Variant) -> void:
	if not DEFAULT_SETTINGS.has(key):
		return
	_settings[key] = clampf(float(value), 0.0, 1.0) if key.ends_with("_volume") else bool(value)
	_apply_settings()
	var config := ConfigFile.new()
	for setting in _settings:
		config.set_value("settings", setting, _settings[setting])
	var error := config.save(SETTINGS_PATH)
	if error != OK:
		push_warning("Could not save audio settings: " + str(error))
	settings_changed.emit()

func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		for key in DEFAULT_SETTINGS:
			var value: Variant = config.get_value("settings", key, DEFAULT_SETTINGS[key])
			_settings[key] = clampf(float(value), 0.0, 1.0) if key.ends_with("_volume") else bool(value)
	_apply_settings()

func _apply_settings() -> void:
	reduced_effects = bool(_settings["reduced_effects"])
	for bus_name: String in ["Master", "Music", "Voice", "SFX"]:
		var key := bus_name.to_lower()
		var index := AudioServer.get_bus_index(bus_name)
		var volume := float(_settings[key + "_volume"])
		AudioServer.set_bus_volume_db(index, linear_to_db(volume) if volume > 0.0 else -80.0)
		AudioServer.set_bus_mute(index, volume <= 0.0 or bool(_settings.get(key + "_muted", false)))

func request_quit(exit_code: int = 0) -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.location.reload();")
		return
	if _quitting:
		return
	_quitting = true
	silence()
	_release_audio_streams()
	# stop() queues work for the mixer. Give it time to retire decoder/playback
	# references before SceneTree teardown; _exit_tree alone is too late.
	await get_tree().create_timer(0.12, true, false, true).timeout
	for frame in range(3):
		await get_tree().process_frame
	get_tree().quit(exit_code)

func _release_audio_streams() -> void:
	audio_generation += 1
	for sound in [music, score, voice]:
		if is_instance_valid(sound):
			sound.stop()
			sound.stream = null
	for sound in cues.values():
		if is_instance_valid(sound):
			sound.stop()
			sound.stream = null
	if is_inside_tree():
		for ambient in get_tree().get_nodes_in_group("dream_audio"):
			ambient.stop()
			ambient.stream = null

func _exit_tree() -> void:
	_release_audio_streams()
