extends Node

var checks := 0
var failures := 0

func _ready() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if ok:
		print("PASS: " + message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func require(ok: bool, message: String) -> bool:
	check(ok, message)
	if not ok:
		print("CANONICAL ABORT: prerequisite failed; refusing to continue through an invalid scene.")
		Game.silence()
		get_tree().quit(1)
	return ok

func frames(count: int = 3) -> void:
	for i in range(count):
		await get_tree().physics_frame
		await get_tree().process_frame # Scene changes are committed between rendered frames.

func press(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await frames(1)
	event = InputEventAction.new()
	event.action = action
	Input.parse_input_event(event)
	await frames(1)

func finish_dialogue() -> void:
	for i in range(45):
		if not UI.busy or UI._transition_phase != 0:
			return
		await press("interact")
	check(false, "Dialogue completed within bounded input sequence")

func click_button(index: int) -> void:
	var center: Vector2 = UI.buttons[index].get_global_rect().get_center()
	var move := InputEventMouseMotion.new()
	move.position = center
	move.global_position = center
	get_viewport().push_input(move, true)
	await frames(1)
	for pressed in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.position = center
		click.global_position = center
		click.pressed = pressed
		get_viewport().push_input(click, true)
		await frames(1)

func motion(relative: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.relative = relative
	Input.parse_input_event(event)
	await frames()

func capture(name: String) -> void:
	if "--capture" in OS.get_cmdline_user_args():
		await frames()
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://.tools/captures")
		get_viewport().get_texture().get_image().save_png("res://.tools/captures/" + name + ".png")

func wait_for_memory(id: int, timeout_seconds: float = 3.0) -> bool:
	var start := Time.get_ticks_msec()
	while Story.boxes.get(id, "") == "unwinding" and Time.get_ticks_msec() - start < int(timeout_seconds * 1000.0):
		await get_tree().process_frame
	return Story.boxes.get(id, "") == "remembering" and UI.busy

func wait_for_scene(scene_name: String, timeout_seconds: float = 8.0) -> bool:
	var start := Time.get_ticks_msec()
	while Time.get_ticks_msec() - start < int(timeout_seconds * 1000.0):
		var current := get_tree().current_scene
		if is_instance_valid(current) and current.name == scene_name and UI._transition_phase == 0:
			return true
		await get_tree().process_frame
	return false

func wait_for_scare(room: Node, timeout_seconds: float = 2.0) -> bool:
	var start := Time.get_ticks_msec()
	while room.scare_active and Time.get_ticks_msec() - start < int(timeout_seconds * 1000.0):
		await get_tree().process_frame
	return not room.scare_active and not UI._scare_active

func test_random_scare(room: Node) -> void:
	check(room.random_scare_cooldown > 20.0, "Random scares have an initial exploration cooldown")
	UI.say(["Scare interruption guard."])
	room.random_scare_cooldown = 0.0
	check(not room.trigger_scare("glimpse"), "Random scare cannot interrupt dialogue")
	room.random_scare_cooldown = 30.0
	await finish_dialogue()
	await press("ui_cancel")
	room.random_scare_cooldown = 0.0
	check(not room.trigger_scare("glimpse"), "Random scare cannot interrupt a menu")
	room.random_scare_cooldown = 30.0
	await get_tree().create_timer(0.12).timeout
	check(is_equal_approx(room.random_scare_cooldown, 30.0), "Random scare cooldown freezes while paused")
	await press("ui_cancel")
	var was_reduced: bool = Game.reduced_effects
	Game.reduced_effects = true
	room.random_scare_cooldown = 0.0
	check(not room.trigger_scare("glimpse"), "Reduced effects disables random scares")
	Game.reduced_effects = was_reduced
	# Exercise the normal-effects path without writing user settings to disk.
	Game.reduced_effects = false
	check(room.trigger_scare("glimpse"), "Deterministic random-scare hook starts an eligible glimpse")
	check(not room.trigger_scare("glimpse"), "Scares do not stack")
	await capture("Current-Random-Glimpse")
	check(await wait_for_scare(room), "Random scare finishes and returns input")
	check(room.random_scares_played == 1 and room.random_scare_cooldown > 29.0, "Random scare counts once and resets a thirty-second cooldown")
	room.random_scare_cooldown = 0.0
	check(not room.trigger_scare("glimpse"), "At most one random scare can occur per room")
	room.random_scare_cooldown = 30.0
	Game.reduced_effects = was_reduced

func test_catch_and_companion(room: Node) -> void:
	var saved_boxes: Dictionary = Story.boxes.duplicate()
	var saved_notes: Dictionary = Story.notes.duplicate()
	room.catch_grace = 0.0
	room.damage_invulnerability = 0.0
	room.chase_remaining = 5.0
	room.witch.show()
	room.witch.position = room.player.position + Vector3(0, 0, -0.65)
	await frames(1)
	check(room.scare_active and UI._scare_active, "A nearby pursuing witch triggers the catch scare")
	check(room.health == 75, "A witch hit removes twenty-five health instead of ending the room")
	check(not room.trigger_scare("catch"), "A catch cannot stack another scare")
	await capture("Current-Witch-Catch")
	await press("ui_cancel")
	await get_tree().create_timer(0.2).timeout
	check(UI.menu_open and room.scare_active, "Pause preserves an active catch and its checkpoint callback")
	await press("ui_cancel")
	check(await wait_for_scare(room), "Catch completes once after resuming")
	check(room.catch_count == 1 and room.player.position.is_equal_approx(room.checkpoint), "Catch respawns at this room's checkpoint")
	check(Story.boxes == saved_boxes and Story.notes == saved_notes, "Catch preserves completed boxes and optional notes")
	check(room.catch_grace > 3.5 and room.damage_invulnerability > 3.5 and not room.trigger_scare("catch") and not room.player.input_locked, "Respawn gives four-second invulnerability and restores controls")
	await approach(room, room.guardian)
	await press("interact")
	check(UI.choices.size() == 3 and UI.choices[2] == "KEEP HER BUSY.", "A collected note unlocks Rue's companion option")
	if UI.choices.size() == 3:
		await click_button(2)
		check(room.distract_used and is_equal_approx(room.distraction_remaining, 8.0) and UI.body.text.contains("Eight seconds"), "Rue's selected response starts an eight-second distraction")
		await finish_dialogue()
	check(not room.distract_witch(), "Rue can distract only once per room")
	room.player.position = room.box.position + Vector3(0, 0, 1.8)
	room.catch_grace = 0.0
	room.damage_invulnerability = 0.0
	room.chase_remaining = 5.0
	room.witch.show()
	room.witch.position = room.player.position + Vector3(0, 0, -0.6)
	await frames(3)
	check(not room.is_rue_protected() and not room.scare_active and room.distraction_remaining > 7.0, "Rue's active distraction protects even outside his proximity shield")
	# End the controlled pursuit so the rest of the canonical route stays deterministic.
	room.distraction_remaining = 0.0
	room.chase_remaining = 0.0
	room.catch_grace = 6.0
	room.witch.hide()

func test_vitals_and_retry(room: Node) -> void:
	var saved_boxes: Dictionary = Story.boxes.duplicate()
	var saved_notes: Dictionary = Story.notes.duplicate()
	await approach(room, room.guardian)
	var protected_health: int = room.health
	room.room_time_left = 0.0
	room.timeout_elapsed = 4.95
	room.damage_invulnerability = 0.0
	room.catch_grace = 0.0
	await frames(6)
	check(room.is_rue_protected() and room.guardian.shield_ring.visible, "Standing within three metres of Rue visibly activates his shield")
	check(room.health == protected_health and not room.trigger_scare("catch"), "Rue blocks both expired-clock damage and witch contact")
	room.room_time_left = 1.0
	await get_tree().create_timer(0.12).timeout
	check(room.room_time_left < 1.0, "The room clock keeps running inside Rue's sanctuary")
	# This box is already complete and intentionally no longer an E target.
	room.player.position = room.box.position + Vector3(0, 0, 1.8)
	await frames()
	room.room_time_left = 0.0
	room.timeout_elapsed = 4.95
	room.damage_invulnerability = 0.0
	await frames(6)
	check(room.health == protected_health - 15 and not room.failed, "After time expires, a five-second tick removes fifteen health without a one-shot failure")
	var after_tick: int = room.health
	await get_tree().create_timer(0.2).timeout
	check(room.health == after_tick, "Timeout damage does not repeat every frame")
	room.room_time_left = 20.0
	UI.say(["Vitals pause guard."])
	await get_tree().create_timer(0.12).timeout
	check(is_equal_approx(room.room_time_left, 20.0) and not room.apply_damage(15), "Dialogue freezes the room clock and rejects damage")
	await finish_dialogue()
	await press("ui_cancel")
	var held_clock: float = room.room_time_left
	await get_tree().create_timer(0.12).timeout
	check(is_equal_approx(room.room_time_left, held_clock), "Pause menu freezes the health-pressure clock")
	await press("ui_cancel")
	room.health = 15
	room.room_time_left = 0.0
	room.timeout_elapsed = 4.95
	room.damage_invulnerability = 0.0
	await frames(6)
	check(room.failed and room.health == 0 and UI.menu_open, "Zero health opens a room retry screen")
	await capture("Current-Room-Failed")
	await press("ui_cancel")
	check(room.failed and UI.menu_open, "Escape cannot resume a zero-health room")
	await press("interact")
	check(not room.failed and not UI.menu_open and room.health == 100 and room.room_time_left > 119.0, "Retry restores full health, a fresh two-minute clock, and playable input")
	check(Story.boxes == saved_boxes and Story.notes == saved_notes and room.player.position.is_equal_approx(room.checkpoint), "Retry preserves recovered memories and notes at the room checkpoint")
	room.player.position = room.box.position + Vector3(0, 0, 1.8)
	room.health = 25
	room.catch_grace = 0.0
	room.damage_invulnerability = 0.0
	check(room.trigger_scare("catch"), "A final witch hit still plays its catch animation")
	check(await wait_for_scare(room) and room.failed and room.health == 0 and UI.menu_open, "Lethal witch contact reaches the same usable retry screen after the scare")
	await press("interact")
	check(room.health == 100 and not room.failed and not room.player.input_locked, "Retry also recovers cleanly after a lethal witch catch")

func approach(room: Node, object: Node3D, offset: Vector3 = Vector3(0, 0, 1.8)) -> void:
	room.player.position = object.position + offset
	room.player.pitch = 0
	room.player.camera.rotation = Vector3.ZERO
	var target: Vector3 = object.global_position
	target.y = room.player.global_position.y
	room.player.look_at(target)
	await frames()
	check(room.player.target == object, "E target reachable: " + object.name)

func connected(room: Node, object: Node3D) -> bool:
	var spawn: Vector3 = room.spawn_point()
	var start := Vector2i(floori(spawn.x / room.CELL), floori(spawn.z / room.CELL))
	var destination := Vector2i(floori(object.position.x / room.CELL), floori(object.position.z / room.CELL))
	var seen := {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		if cell == destination:
			return true
		for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + direction
			if not room.solid(next.x, next.y) and not seen.has(next):
				seen[next] = true
				queue.append(next)
	return false

func run() -> void:
	get_tree().create_timer(90.0).timeout.connect(func():
		push_error("CANONICAL TIMEOUT: route exceeded 90 seconds")
		Game.silence()
		get_tree().quit(2)
	)
	Input.use_accumulated_input = false
	check(ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/MainMenu.tscn", "Configured startup is the main menu")
	get_tree().current_scene = null
	Game.reset()
	await frames()
	if not require(is_instance_valid(get_tree().current_scene) and get_tree().current_scene.name == "TherapyRoom", "Game.reset starts appointment directly"):
		return
	check(UI.body.get_theme_font_size("font_size") == 26, "Native 26px dialogue font")
	check(get_viewport().get_visible_rect().size == Vector2(1280, 720), "1280x720 UI viewport")
	check(UI.body.material == null and UI.panel.material == null, "Dialogue excluded from retro shaders")
	for i in range(12):
		if not UI.choices.is_empty():
			break
		await press("interact")
	if not require(UI.choices.size() == 3 and UI.buttons.size() == 3, "Appointment has all three canonical questions"):
		return
	await capture("Current-Readable-Appointment")
	await click_button(0)
	check(UI.body.text.begins_with("PATIENT: It looks like a witch's cabin."), "Mouse click selects appointment response")
	check(UI.body.get_line_count() * UI.body.get_line_height() <= UI.body.size.y, "Dialogue wraps without clipping")
	await finish_dialogue()
	check(UI._transition_phase == 1, "Appointment completion begins its dream transition")
	await press("interact")
	await press("interact")
	if not require(await wait_for_scene("WitchCabin"), "Repeated E during fade does not cancel the dream transition"):
		return
	await frames()
	var room = get_tree().current_scene
	if not require(is_instance_valid(room) and room.name == "WitchCabin" and Story.stage == 1, "Appointment enters first-person performance room"):
		return
	check(room.world_viewport.size == Vector2i(320, 180), "3D world uses separate 320x180 viewport")
	check(room.world_viewport.has_node("WorldEffects") and not UI.has_node("WorldEffects"), "Distortion is isolated to world viewport")
	check(Game.active_player == room.player and room.player is CharacterBody3D, "Existing first-person movement controller retained")
	await finish_dialogue()
	check(Story.tutorial_seen and not Story.met_performer, "Arrival briefing explains the four-box loop before optional Performer conversation")
	check(UI._objective_text.contains("MUSIC BOX 01") and UI._objective_count.text.contains("0 / 4"), "Persistent initial objective and zero-of-four counter")
	check(room.box.sprite.texture.resource_path.ends_with("replacements_v2/props/music_box_closed.png"), "Wooden V2 closed music box is visible")
	check(room.guardian.sprite.texture.resource_path.ends_with("purple_performer_head.png") and room.guardian.find_children("SuppliedModel", "", true, false).is_empty(), "Performer uses floating V2 head, with no old GLB")
	check(room.witch.sprite.texture.resource_path.ends_with("ayush_grain_closed.png"), "Witch uses V2 Ayush head")
	check(room.box_sign.font.resource_path.ends_with("DotGothic16-Regular.ttf"), "World objective signs use supplied native font")
	check(room.can_see(room.guardian.position), "Rue is visible with a clear line of sight immediately from dream spawn")
	check(room.guardian.has_node("ModelPivot/BunnyEars/LeftEar") and room.guardian.has_node("ModelPivot/BunnyEars/RightEar"), "Rue has two actual faceted bunny ears")
	check(room.guardian.has_node("ModelPivot/TeddyBody/SoftSquareChest") and room.guardian.has_node("ModelPivot/TeddyBody/LeftArm"), "Rue has a protective childhood-toy body with limbs")
	check(room.health == 100 and room.room_time_left > 119.0, "Dream entry starts with full health and two minutes")
	check(room.guardian.actor_name.text == "RUE" and room.witch.actor_name.text == "AYUSH" and room.guardian.caption.contains("Performer"), "Characters have readable short names and named interaction roles")
	check(room.objects.has_node("CrookedIronStove") and room.objects.has_node("WitchCauldron"), "Recognizable witch-cabin stove and cauldron exist")
	await capture("Current-Dream-Entrance")
	await approach(room, room.guardian)
	await press("interact")
	await press("interact")
	if not require(UI.choices.size() == 3, "Rue offers three distinct greeting responses"):
		return
	await click_button(1)
	check(UI.body.text.begins_with("RUE: Every music box remembers a door."), "Choosing the exit question produces its specific Rue response")
	await finish_dialogue()
	check(Story.met_performer, "Approaching Performer preserves its greeting and player choices")
	await test_random_scare(room)
	var player = room.player
	var yaw: float = player.rotation.y
	await motion(Vector2(100, 40))
	check(absf(player.rotation.y - yaw) > 0.05, "Mouse X rotates body yaw")
	check(player.camera.rotation.x < -0.01, "Mouse Y rotates camera pitch")
	await motion(Vector2(0, -10000))
	check(is_equal_approx(player.pitch, deg_to_rad(80)), "Upward pitch clamped at +80 degrees")
	await capture("Current-Looking-Up")
	await motion(Vector2(0, 20000))
	check(is_equal_approx(player.pitch, deg_to_rad(-80)), "Downward pitch clamped at -80 degrees")
	check(is_zero_approx(player.rotation.x) and is_zero_approx(player.rotation.z) and is_zero_approx(player.camera.rotation.z), "No body tilt or camera roll")
	player.pitch = 0
	player.camera.rotation = Vector3.ZERO
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	Input.parse_input_event(escape)
	await frames()
	check(UI.menu_open and not player.mouse_captured, "Escape opens pause menu and releases mouse")
	var paused_position: Vector3 = player.position
	var paused_yaw: float = player.rotation.y
	Input.action_press("forward")
	await motion(Vector2(100, 30))
	await frames(10)
	Input.action_release("forward")
	check(player.position.is_equal_approx(paused_position) and is_equal_approx(player.rotation.y, paused_yaw) and player.target == null, "Pause blocks movement, mouse look, and interaction targeting")
	await press("ui_cancel")
	await frames()
	check(not UI.menu_open and player.mouse_captured, "Second Escape resumes gameplay and recaptures mouse")
	player.rotation.y = 0
	player.position = Vector3(15, 0, 12)
	Input.action_press("strafe_right")
	await frames(20)
	Input.action_release("strafe_right")
	check(player.position.x > 15.9, "WASD strafing works")
	# Test the same entrance wall in the clear lane beside Rue's new starting position.
	player.position = Vector3(8.3 * 1.8, 0, 13.5 * 1.8)
	Input.action_press("forward")
	await frames(40)
	Input.action_release("forward")
	check(player.position.z >= 23.63 and player.position.z < 23.8, "Wall collisions preserved")
	UI.say(["Readability check. The world remains pixelated; this text is rendered directly at 1280 by 720."])
	await capture("Current-Sharp-Dialogue")
	await finish_dialogue()
	yaw = player.rotation.y
	await motion(Vector2(40, 20))
	check(player.mouse_captured and absf(player.rotation.y - yaw) > 0.01, "Camera controls resume after dialogue closes")
	for id in range(1, 5):
		room = get_tree().current_scene
		if not require(is_instance_valid(room) and room.has_method("run_unwind") and room.room_id == id and Story.stage == id, "Canonical room order %d" % id):
			return
		check(connected(room, room.box) and connected(room, room.dream_door), "Box and exit connected through room %d" % id)
		await finish_dialogue()
		check(Story.completed_count() == id - 1 and UI._objective_count.text.contains("%d / 4" % (id - 1)), "Room %d starts with accurate persistent progress" % id)
		if id > 1:
			check(room.health == 100 and room.room_time_left > 118.0, "Entering room %d restores health and resets its clock" % id)
		if id == 2:
			check(room.witch.visible and room.objects.has_node("KeepersThrone") and Story.TITLES[id].contains("CHAMBER"), "The second room is a dedicated, visibly occupied Keeper's chamber")
			room.player.position = room.witch.position + Vector3(3.5, 0, 3.5)
			await frames(3)
			check(room.chase_remaining > 0 and not Story.boxes.has(2), "Entering the Keeper's awareness radius starts pursuit before the second music box")
			room.player.position = room.spawn_point()
		if id <= 3:
			var note_id: String = ["", "unsent_message", "birthday_ticket", "last_note"][id]
			await approach(room, room.note_props[note_id])
			await press("interact")
			check(UI.busy and Story.notes.has(note_id) and Story.notes.size() == id, "Accessible note %d records persistent side-quest progress" % id)
			check(UI.body.get_line_count() * UI.body.get_line_height() <= UI.body.size.y, "Note %d is readable without text clipping" % id)
			await capture("Current-Note-%d" % id)
			await finish_dialogue()
			await press("interact")
			check(Story.notes.size() == id, "Rereading note %d does not duplicate progress" % id)
			await finish_dialogue()
		room.interact("door")
		check(UI.busy and Story.stage == id and not room.transitioning, "Exit %d stays locked before its memory" % id)
		await finish_dialogue()
		if id == 3:
			check(UI._objective_text.contains("SEARCH") or UI._objective_text.contains("search"), "School objective directs player to search the marked door")
			await approach(room, room.marked_door)
			await press("interact")
			check(not room.marked_door.visible and room.marked_door.collision_layer == 0, "Marked school door opens")
			check(room.memory_door_searched and UI._objective_text.contains("MUSIC BOX 03"), "Searching updates school objective to its music box")
		await approach(room, room.box, Vector3(1.8, 0, 0) if id == 2 else Vector3(0, 0, 1.8))
		await capture("Current-Room-%d" % id)
		var unwind_started := Time.get_ticks_msec()
		var paused_milliseconds := 0
		await press("interact")
		if not require(Story.boxes.get(id) == "unwinding" and room.unwinding and is_instance_valid(room.player), "Box %d starts a visible timed unwind before dialogue" % id):
			return
		check(room.player.input_locked and not UI.busy and UI._progress.visible, "Unwind %d locks movement and shows progress without fake dialogue" % id)
		var clock_at_unwind: float = room.room_time_left
		check(not Story.room_unlocked, "Exit locked until all box %d dialogue finishes" % id)
		check(not Story.activate_box(id, room), "Box %d cannot activate twice" % id)
		var cooldown_before: float = room.random_scare_cooldown
		room.random_scare_cooldown = 0.0
		check(not room.trigger_scare("glimpse"), "Unwinding box %d blocks random scares" % id)
		room.random_scare_cooldown = cooldown_before
		check(Story.completed_count() == id - 1, "Unwinding box %d does not prematurely increment counter" % id)
		if id == 1:
			await get_tree().create_timer(0.35).timeout
			check(room.box.unwind_progress > 0.1 and room.box.unwind_progress < 0.8 and room.box.winding_key.visible, "Box has intermediate animation progress and a visible winding key")
			check(room.box.sprite.texture.resource_path.ends_with("music_box_open.png"), "Box opens visibly while key unwinds")
			await capture("Current-Box-Unwinding")
			var pause_started := Time.get_ticks_msec()
			await press("ui_cancel")
			var held_progress: float = room.box.unwind_progress
			var held_key: float = room.box.winding_key.rotation.z
			var held_actor: float = room.guardian.actor_clock
			await get_tree().create_timer(0.3).timeout
			check(UI.menu_open and is_equal_approx(room.box.unwind_progress, held_progress) and is_equal_approx(room.box.winding_key.rotation.z, held_key), "Pause freezes unwind progress and key rotation")
			check(is_equal_approx(room.guardian.actor_clock, held_actor), "Pause also freezes actor animation")
			check(not Story.activate_box(id, room), "Paused box cannot start a second unwind")
			await capture("Current-Paused-Unwind")
			await press("ui_cancel")
			paused_milliseconds = Time.get_ticks_msec() - pause_started
			check(not UI.menu_open and room.unwinding, "Unwind resumes after Escape")
		if not require(await wait_for_memory(id), "Box %d finishes two-second animation and enters memory dialogue" % id):
			return
		check(Time.get_ticks_msec() - unwind_started - paused_milliseconds >= 1750, "Box %d takes approximately two active seconds before its memory" % id)
		check(room.box.opened and is_equal_approx(room.box.unwind_progress, 1.0) and not room.box.winding_key.visible and not UI._progress.visible, "Box %d remains open after its visible action" % id)
		check(is_equal_approx(room.room_time_left, clock_at_unwind), "Unwinding and memory dialogue freeze room %d's timer" % id)
		check(not Story.room_unlocked and Story.completed_count() == id - 1, "Remembering box %d still does not unlock exit or increment counter" % id)
		if id == 1:
			await capture("Current-First-Memory")
		await finish_dialogue()
		if not require(Story.boxes.get(id) == "complete" and Story.room_unlocked, "Box %d dialogue unlocks next section" % id):
			return
		check(Story.completed_count() == id and UI._objective_count.text.contains("%d / 4" % id) and (UI._objective_text.contains("EXIT") or id == 4), "Memory %d updates counter and exit objective" % id)
		check(not room.box.interaction_enabled and not Story.activate_box(id, room), "Completed box %d cannot replay or count twice" % id)
		if id == 1:
			check(room.witch.visible and room.exit_sign.text == "EXIT / CONTINUE", "First memory reveals witch and clearly marks unlocked exit")
			await test_catch_and_companion(room)
			await test_vitals_and_retry(room)
		elif id == 2:
			check(room.chase_remaining > 0 and room.plates[0].texture.resource_path.ends_with("ayush_grain_closed.png"), "Dining V2 faces stare and short pursuit begins")
		elif id == 3:
			check("YOU MUST HAVE REMEMBERED IT WRONG." in UI.history and room.chase_remaining > 0, "School testimony is overwritten; witch approaches")
			check(room.plates[0].texture.resource_path.ends_with("ayush_grain_closed.png"), "School portrait faces also use V2 witch texture")
		else:
			check(not Game.music.playing and not room.ambient.playing and room.guardian.completely_still, "Fourth box stops Performer, music and ambience")
		await approach(room, room.dream_door, Vector3(0, 0, -1.8) if id == 3 else Vector3(0, 0, 1.8))
		check(not room.transitioning, "Approaching exit %d waits for explicit E" % id)
		if id < 4:
			room.health = 73
			room.room_time_left = 42.0
		await press("interact")
		if id < 4:
			var next_name: String = ["", "", "DiningRoom", "SchoolHall", "Theatre"][id + 1]
			if not require(await wait_for_scene(next_name), "Door transition reaches " + next_name):
				return
			await frames()
			await finish_dialogue()
	if not require(Story.boxes.size() == 4 and Story.completed_count() == 4 and Story.stage == 5, "Four separate completed boxes reach final exit"):
		return
	room = get_tree().current_scene
	check(not Game.music.playing and not room.ambient.playing, "Final escape preserves fourth-box silence")
	check(Story.notes.size() == 3 and UI.history.has("PATIENT: I don't need a perfect message. I could start with: I'm not fine. Are you there?"), "Completing all three optional notes changes the patient's final-box dialogue")
	await get_tree().create_timer(3.2).timeout
	if not require(room.final_escape and UI.choices.size() == 3, "Receding doorway and final three affirmations"):
		return
	await capture("Current-Final-Affirmations")
	await press("interact")
	check(UI.body.text.begins_with("AYUSH:"), "Final affirmation receives its own Keeper response")
	await press("interact")
	if not require(UI.body.text == "NOTHING HAPPENED." and UI.choices == ["I'M STILL LISTENING."], "Witch erases choices; exact final response remains"):
		return
	await click_button(0)
	var swallow_image: TextureRect = UI.get_node_or_null("WitchSwallowsScreen")
	check(is_instance_valid(swallow_image) and swallow_image.texture.resource_path.ends_with("ayush_grain_open.png"), "Final swallow uses the V2 open witch head")
	if not require(await wait_for_scene("Ending"), "Witch swallow completes its scene transition"):
		return
	await frames()
	if not require(is_instance_valid(get_tree().current_scene) and get_tree().current_scene.name == "Ending" and Game.ending == "someone_heard", "Only canonical ending is reachable"):
		return
	await capture("Current-Someone-Heard")
	await finish_dialogue()
	await get_tree().create_timer(0.9).timeout
	check("PATIENT: You heard me." in UI.history and Story.finished, "Exact patient final dialogue preserved")
	check(get_tree().current_scene.complete, "Cut to black, single click, END")
	await capture("Current-END")
	await press("restart")
	await frames()
	check(Story.stage == 0 and Story.boxes.is_empty() and Story.notes.is_empty() and not Story.finished, "Restart clears centralized canonical progression and optional notes")
	print("CANONICAL RESULT: %d checks, %d failures" % [checks, failures])
	Game.silence()
	OS.delay_msec(200)
	get_tree().quit(0 if failures == 0 else 1)
