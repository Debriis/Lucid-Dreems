extends Node

func _ready() -> void:
	await get_tree().process_frame
	var previous_reduced := Game.reduced_effects
	Game.reduced_effects = false
	Game.play_menu_music()
	Game.play_scare("catch")
	assert(Game.cues["scare_catch"].playing)
	assert(Game.cues["scare_catch"].bus == "SFX")
	assert(is_equal_approx(Game.cues["scare_catch"].stream.get_length(), 0.7))
	Game.play_scare("glimpse")
	assert(not Game.cues["scare_catch"].playing)
	assert(Game.cues["scare_glimpse"].playing)
	assert(is_equal_approx(Game.cues["scare_glimpse"].stream.get_length(), 0.3))
	Game.reduced_effects = true
	Game.play_scare("catch")
	assert(is_equal_approx(Game.cues["scare_catch"].volume_db, -9.0))
	assert(not Game.cues["scare_glimpse"].playing)
	Game.set_audio_paused(true)
	var remaining: float = Game._scare_duck_left
	await get_tree().create_timer(0.12).timeout
	assert(Game.cues["scare_catch"].stream_paused)
	assert(is_equal_approx(Game._scare_duck_left, remaining))
	Game.play_scare("glimpse")
	assert(not Game.cues["scare_glimpse"].playing)
	Game.set_audio_paused(false)
	Game.silence()
	Game.play_scare("catch")
	assert(not Game.cues["scare_catch"].playing)
	Game.play_menu_music()
	Game.play_dialogue("PATIENT: You heard me.")
	assert(Game.voice.playing)
	Game.play_scare("catch")
	Game.set_audio_paused(true)
	Game.reduced_effects = previous_reduced
	print("AUDIO_SCARE_PASS: durations, SFX bus, no stacking, reduced volume, pause, final silence, quit with active paused music/voice/cue")
	Game.request_quit()
