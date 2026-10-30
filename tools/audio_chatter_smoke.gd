extends Node

func _ready() -> void:
	await get_tree().process_frame
	var settings_before := Game.get_settings()
	Game._settings["voice_muted"] = false
	Game._settings["voice_volume"] = 1.0
	Game._settings["master_volume"] = 0.85
	Game._apply_settings()
	var phrase := "Before you answer, listen to the spaces between the notes. You do not need a perfect explanation. We can wait here until the words feel less heavy."
	var samples: Dictionary = {}
	for speaker in ["DOCTOR", "RUE", "AYUSH"]:
		var started := Time.get_ticks_usec()
		Game.play_dialogue(speaker + ": " + phrase)
		var cost_ms := float(Time.get_ticks_usec() - started) / 1000.0
		assert(cost_ms < 50.0, "First-line chatter construction stalled")
		assert(Game.dialogue_speaker == speaker)
		assert(Game.voice.playing and Game.voice.bus == "Voice")
		assert(Game.voice_level() == 0.0, "NPC speech must not animate patient mouth")
		var stream: AudioStreamWAV = Game.voice.stream
		assert(stream.format == AudioStreamWAV.FORMAT_16_BITS)
		assert(stream.mix_rate == 24000 and not stream.stereo)
		var pcm := stream.data
		var peak := 0
		for index in range(0, pcm.size(), 2):
			peak = maxi(peak, absi(pcm.decode_s16(index)))
		assert(peak <= 21000, "PCM overflow or uninitialized silence")
		for value in pcm.slice(pcm.size() - 1000):
			assert(value == 0, "Punctuation gap must contain silence")
		samples[speaker] = pcm
		print("CHATTER_PERF ", speaker, " chars=", phrase.length(), " first_build_ms=", cost_ms, " duration_s=", stream.get_length(), " peak=", float(peak)/32768.0)
	assert(samples["DOCTOR"] != samples["RUE"] and samples["RUE"] != samples["AYUSH"])
	Game.play_dialogue("DOCTOR: Yes.")
	assert(Game.voice.stream.get_length() < 1.0)
	await get_tree().create_timer(1.1).timeout
	assert(not Game.voice.playing and Game.dialogue_speaker.is_empty())
	Game.play_dialogue("PERFORMER: I only knew one song.")
	assert(Game.dialogue_speaker == "RUE")
	Game.play_dialogue("WITCH: You are safe in here.")
	assert(Game.dialogue_speaker == "AYUSH")
	await get_tree().create_timer(0.08).timeout
	Game.set_audio_paused(true)
	var position := Game.voice.get_playback_position()
	await get_tree().create_timer(0.16).timeout
	assert(Game.voice.stream_paused and not Game.voice_is_playing())
	assert(absf(position - Game.voice.get_playback_position()) < 0.05)
	Game.set_audio_paused(false)
	Game._settings["voice_muted"] = true
	Game._apply_settings()
	assert(not Game.voice_is_playing() and AudioServer.is_bus_mute(AudioServer.get_bus_index("Voice")))
	Game._settings["voice_muted"] = false
	Game._apply_settings()
	Game.play_dialogue("The empty room waits.")
	assert(not Game.voice.playing and Game.dialogue_speaker.is_empty())
	Game.play_menu_music()
	Game.silence()
	for text in ["YOU MUST HAVE REMEMBERED IT WRONG.", "NOTHING HAPPENED."]:
		Game.play_dialogue(text)
		assert(Game.dialogue_speaker == "AYUSH" and Game.voice.playing)
		assert(not Game.music.playing)
	Game.play_dialogue("PATIENT: You heard me.")
	assert(Game.dialogue_speaker == "PATIENT" and Game.voice.playing)
	assert(Game.voice.stream.resource_path == "res://audio/voice/patient_24.wav")
	assert(not Game._voice_envelope.is_empty() and is_equal_approx(Game.voice.volume_db, -2.0))
	Game.stop_voice()
	assert(not Game.voice.playing and Game.dialogue_speaker.is_empty())
	Game._settings = settings_before
	Game._apply_settings()
	print("AUDIO_CHATTER_PASS: distinct palettes, text pacing, real PCM peaks, build cost, patient-only mouth, aliases, pause/mute/stop, narration silence, ending voices")
	Game.request_quit()
