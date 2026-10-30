extends Node

var memories: Dictionary = {}
var crossings := 0
var ending := ""
var music: AudioStreamPlayer
var cues: Dictionary = {}
var active_player: Node
var audio_generation := 0

func _ready() -> void:
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
	music = AudioStreamPlayer.new()
	var melody: AudioStreamWAV = load("res://audio/lullaby.wav")
	melody.loop_mode = AudioStreamWAV.LOOP_FORWARD
	melody.loop_end = int(melody.get_length() * melody.mix_rate)
	music.stream = melody
	music.volume_db = -17.0
	add_child(music)
	var cue_files := {"wind": "wind_key.wav", "rattle": "mechanical_rattle.wav", "dream": "dream_transition.wav", "tick": "ui_click.wav", "click": "ui_click.wav", "flatline": "session_terminated.wav"}
	for cue in cue_files:
		var sound := AudioStreamPlayer.new()
		sound.name = "Cue_" + cue
		sound.stream = load("res://assets/fever_dreams/audio/sfx/" + cue_files[cue])
		sound.volume_db = -18.0 if cue == "rattle" else -13.0
		add_child(sound)
		cues[cue] = sound

func play_cue(cue: String) -> void:
	if cues.has(cue):
		cues[cue].play()

func stop_cues() -> void:
	for sound in cues.values():
		sound.stop()

func play_music_box(dream: bool) -> void:
	music.pitch_scale = 1.0
	var path := "res://assets/fever_dreams/audio/" + ("musicbox3_sad_tune.ogg" if dream else "musicbox1_spooky_waltz.ogg")
	if music.stream.resource_path != path:
		music.stop()
		var tune: AudioStreamOggVorbis = load(path)
		tune.loop = true
		music.stream = tune
	music.play()

func _exit_tree() -> void:
	# Release playback before the audio server shuts down, including headless runs.
	if is_instance_valid(music):
		music.stop()
		music.stream = null
	for sound in cues.values():
		sound.stop()
		sound.stream = null

func bind(action: String, keys: Array) -> void:
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		InputMap.action_add_event(action, event)

func travel(path: String) -> void:
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
	music.stop()
	stop_cues()
	travel("res://scenes/TherapyRoom.tscn")

func silence() -> void:
	audio_generation += 1
	music.stop()
	music.pitch_scale = 1.0
	stop_cues()
	for ambient in get_tree().get_nodes_in_group("dream_audio"):
		ambient.stop()

func unwind_music(id: int) -> void:
	audio_generation += 1
	var generation := audio_generation
	play_cue("wind")
	if id == 4:
		silence()
		return
	play_music_box(id > 1)
	var tween := create_tween()
	tween.tween_property(music, "pitch_scale", 0.55, 0.8)
	await tween.finished
	if generation != audio_generation:
		return
	music.stop()
	music.pitch_scale = 1.0
	music.stream = load("res://audio/unwind_reverse.wav")
	music.play()
