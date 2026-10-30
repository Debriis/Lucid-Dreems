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

func frames(count: int = 3) -> void:
	for i in range(count):
		await get_tree().physics_frame

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
		if not UI.busy:
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
		get_viewport().get_texture().get_image().save_png("res://assets/" + name + ".png")

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
	Input.use_accumulated_input = false
	get_tree().current_scene = null
	Game.reset()
	await frames()
	check(get_tree().current_scene.name == "TherapyRoom", "Configured startup / appointment scene")
	check(UI.body.get_theme_font_size("font_size") == 26, "Native 26px dialogue font")
	check(get_viewport().get_visible_rect().size == Vector2(1280, 720), "1280x720 UI viewport")
	check(UI.body.material == null and UI.panel.material == null, "Dialogue excluded from retro shaders")
	await press("interact")
	await press("interact")
	check(UI.choices.size() == 3, "Appointment has all three canonical questions")
	await capture("Current-Readable-Appointment")
	await click_button(0)
	check(UI.body.text.begins_with("PATIENT: It looks like a witch's cabin."), "Mouse click selects appointment response")
	check(UI.body.get_line_count() * UI.body.get_line_height() <= UI.body.size.y, "Dialogue wraps without clipping")
	await finish_dialogue()
	await get_tree().create_timer(1.6).timeout
	await frames()
	var room = get_tree().current_scene
	check(room.name == "WitchCabin" and Story.stage == 1, "Appointment enters first-person performance room")
	check(room.world_viewport.size == Vector2i(320, 180), "3D world uses separate 320x180 viewport")
	check(room.world_viewport.has_node("WorldEffects") and not UI.has_node("WorldEffects"), "Distortion is isolated to world viewport")
	check(Game.active_player == room.player and room.player is CharacterBody3D, "Existing first-person movement controller retained")
	await finish_dialogue()
	check(Story.met_performer, "Performer greeting and player choices complete")
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
	check(not player.mouse_captured, "Escape releases mouse")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	Input.parse_input_event(click)
	await frames()
	check(player.mouse_captured, "Left click recaptures gameplay mouse")
	player.rotation.y = 0
	player.position = Vector3(15, 0, 12)
	Input.action_press("strafe_right")
	await frames(20)
	Input.action_release("strafe_right")
	check(player.position.x > 15.9, "WASD strafing works")
	player.position = Vector3(7.5 * 1.8, 0, 13.5 * 1.8)
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
		check(room.room_id == id and Story.stage == id, "Canonical room order %d" % id)
		check(connected(room, room.box) and connected(room, room.dream_door), "Box and exit connected through room %d" % id)
		await finish_dialogue()
		if id == 3:
			await approach(room, room.marked_door)
			await press("interact")
			check(not room.marked_door.visible and room.marked_door.collision_layer == 0, "Marked school door opens")
		await approach(room, room.box)
		await capture("Current-Room-%d" % id)
		await press("interact")
		check(Story.boxes.get(id) == "unwinding" and UI.busy, "Box %d triggers its own memory sequence" % id)
		check(not Story.room_unlocked, "Exit locked until all box %d dialogue finishes" % id)
		check(not Story.activate_box(id, room), "Box %d cannot activate twice" % id)
		if id == 1:
			await press("interact")
			await capture("Current-First-Memory")
		await finish_dialogue()
		check(Story.boxes.get(id) == "complete" and Story.room_unlocked, "Box %d dialogue unlocks next section" % id)
		if id == 1:
			check(room.witch.visible and room.exit_sign.text == "PLEASE LEAVE AS YOU ARE TOLD.", "First memory reveals witch and rewrites exit sign")
		elif id == 2:
			check(room.chase_remaining > 0 and room.plates[0].texture.resource_path.ends_with("witch_closed.png"), "Dining plates stare and short pursuit begins")
		elif id == 3:
			check("YOU MUST HAVE REMEMBERED IT WRONG." in UI.history and room.chase_remaining > 0, "School testimony is overwritten; witch approaches")
		else:
			check(not Game.music.playing and not room.ambient.playing and room.guardian.completely_still, "Fourth box stops Performer, music and ambience")
		await approach(room, room.dream_door, Vector3(0, 0, -1.8) if id == 3 else Vector3(0, 0, 1.8))
		await press("interact")
		if id < 4:
			await get_tree().create_timer(1.6).timeout
			await frames()
			await finish_dialogue()
	check(Story.boxes.size() == 4 and Story.stage == 5, "Four separate completed boxes reach final exit")
	room = get_tree().current_scene
	await get_tree().create_timer(3.2).timeout
	check(room.final_escape and UI.choices.size() == 3, "Receding doorway and final three affirmations")
	await capture("Current-Final-Affirmations")
	await press("interact")
	check(UI.body.text == "NOTHING HAPPENED." and UI.choices == ["I'M STILL LISTENING."], "Witch erases choices; exact final response remains")
	await click_button(0)
	await get_tree().create_timer(1.4).timeout
	await frames()
	check(get_tree().current_scene.name == "Ending" and Game.ending == "someone_heard", "Only canonical ending is reachable")
	await capture("Current-Someone-Heard")
	await finish_dialogue()
	await get_tree().create_timer(0.9).timeout
	check("PATIENT: You heard me." in UI.history and Story.finished, "Exact patient final dialogue preserved")
	check(get_tree().current_scene.complete, "Cut to black, single click, END")
	await capture("Current-END")
	await press("restart")
	await frames()
	check(Story.stage == 0 and Story.boxes.is_empty() and not Story.finished, "Restart clears centralized canonical progression")
	print("CANONICAL RESULT: %d checks, %d failures" % [checks, failures])
	Game.silence()
	OS.delay_msec(200)
	get_tree().quit(0 if failures == 0 else 1)
