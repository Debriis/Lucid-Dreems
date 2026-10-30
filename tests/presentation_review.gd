extends Node

var checks := 0
var failures := 0

func _ready() -> void:
	call_deferred("run")

func frames(count := 4) -> void:
	for i in range(count):
		await get_tree().process_frame

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)
	else:
		print("PASS: ", message)

func capture(filename: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args():
		return
	await frames()
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.tools/review/" + filename + ".png")

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://.tools/review")
	get_tree().current_scene = null
	Game.return_to_menu()
	await frames(12)
	check(get_tree().current_scene.name == "MainMenu", "Main menu loads")
	await capture("menu")
	UI.begin_session()
	await frames(12)
	var office: Node = get_tree().current_scene
	check(office.name == "TherapyRoom", "Begin session opens consultation")
	check(office.consultation.patient.texture.resource_path.ends_with("patient_grain_sad.png"), "Patient uses V2 PNG")
	check(office.consultation.patient.position.x > 440 and office.consultation.patient.position.x < 760, "Patient is seated across the physician's desk")
	await capture("consultation")
	for i in range(8):
		if not UI.choices.is_empty():
			break
		UI.advance()
	await frames()
	check(UI.choices.size() == 3, "Appointment options fit beside patient")
	await capture("consultation-choices")
	UI.select_choice(0)
	await frames(20)
	check(Game.voice_is_playing(), "Patient speech starts with patient subtitle")
	check(Game.dialogue_speaker == "PATIENT", "Patient speaker reported for animation")
	await capture("patient-speaking")
	UI.open_pause_menu()
	await frames()
	check(Game.voice.stream_paused, "Pausing holds speech")
	await capture("pause")
	UI.close_menu()
	UI.advance()
	await frames()
	check(Game.voice_is_playing(), "Advancing replaces previous spoken line")
	Game.return_to_menu()
	await frames(10)
	check(not Game.voice.playing, "Returning to title stops patient speech")
	Game.start_session()
	Story.stage = 1
	Story.tutorial_seen = true
	get_tree().change_scene_to_file(Story.ROOM_PATHS[1])
	await frames(16)
	var cabin: Node = get_tree().current_scene
	await capture("dream-entry-rue")
	check(cabin.player.camera.is_position_in_frustum(cabin.guardian.global_position + Vector3.UP), "Rue is in the entry camera's view")
	check(Story.read_note("unsent_message", cabin), "Optional note opens")
	await frames()
	check(UI.body.get_line_count() <= 4 and UI.body.size.y < 150, "Note fits the readable dialogue panel")
	await capture("readable-note")
	UI.advance()
	UI.advance()
	await frames()
	cabin.player.position = Vector3(8.5 * cabin.CELL, 0, 11.8 * cabin.CELL)
	cabin.player.rotation.y = 0
	await capture("witch-cabin")
	cabin.player.rotation.y = 0.8
	await capture("witch-cauldron")
	cabin.player.rotation.y = -1.0
	await capture("witch-stove")
	cabin.catch_grace = 0
	check(cabin.trigger_scare("catch"), "Catch starts the face scare")
	await capture("witch-catch")
	await frames(90)
	check(cabin.catch_count == 1 and Story.notes.has("unsent_message"), "Catch preserves the note at the checkpoint")
	UI.clear()
	Story.stage = 2
	get_tree().change_scene_to_file(Story.ROOM_PATHS[2])
	await frames(12)
	await capture("ayush-chamber-intro")
	for i in range(8):
		if not UI.busy:
			break
		UI.advance()
	await capture("ayush-chamber")
	var chamber: Node = get_tree().current_scene
	check(chamber.health == 100 and chamber.room_time_left > 118.0, "New room restores health and its clock")
	chamber.begin_chase()
	await frames(8)
	check(Game.score.playing and Game.score_context == "chase", "Actual witch pursuit switches soundtrack")
	chamber.chase_remaining = 0
	chamber.chamber_alert_cooldown = 30
	await frames(30)
	check(not Game.score.playing and Game.music.playing, "Pursuit ending restores room music")
	chamber.player.position = Vector3(6.5 * chamber.CELL, 0, 8.0 * chamber.CELL)
	chamber.health = 20
	chamber.room_time_left = 0
	chamber.timeout_elapsed = 4.9
	chamber.damage_invulnerability = 0
	await frames(16)
	check(chamber.health == 5, "Expired room clock takes one timed health hit")
	await capture("overtime-health")
	chamber.damage_invulnerability = 0
	check(chamber.apply_damage(15), "Unprotected overtime can break the connection")
	await frames()
	check(chamber.failed and UI.menu_open, "Zero health opens the room retry menu")
	await capture("connection-lost")
	UI._retry_failed_room()
	await frames()
	check(not chamber.failed and chamber.health == 100 and Story.notes.has("unsent_message"), "Retry restores health and preserves found notes")
	Game.return_to_menu()
	await frames(12)
	await capture("menu-after-session")
	Game.silence()
	UI.clear()
	print("PRESENTATION RESULT: %d checks, %d failures" % [checks,failures])
	await frames(3)
	Game.request_quit(0 if failures == 0 else 1)
