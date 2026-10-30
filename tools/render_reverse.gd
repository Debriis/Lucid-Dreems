extends SceneTree

func _initialize() -> void:
	var stream: AudioStreamOggVorbis = load("res://assets/fever_dreams/audio/musicbox1_spooky_waltz.ogg")
	var playback := stream.instantiate_playback()
	playback.start()
	var frames: PackedVector2Array = playback.mix_audio(1.0, 44100 * 3)
	var bytes := PackedByteArray()
	bytes.resize(frames.size() * 2)
	for i in range(frames.size()):
		var value: Vector2 = frames[frames.size() - 1 - i]
		var sample := int(clampf((value.x + value.y) * 0.5, -1, 1) * 32767)
		bytes.encode_s16(i * 2, sample)
	var reversed := AudioStreamWAV.new()
	reversed.format = AudioStreamWAV.FORMAT_16_BITS
	reversed.mix_rate = 28000
	reversed.data = bytes
	reversed.save_to_wav("res://audio/unwind_reverse.wav")
	playback.stop()
	print("Saved reversed supplied music-box phrase")
	quit()
