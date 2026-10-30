extends Node

var failures := 0
var checks := 0

func _ready() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
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
	event.pressed = false
	Input.parse_input_event(event)
	await frames(1)

func dismiss() -> void:
	for i in range(9):
		if not UI.busy:
			break
		await press("interact")

func capture(name: String) -> void:
	if "--capture" in OS.get_cmdline_user_args():
		await frames(3)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://assets/" + name + ".png")

func face(player: Node3D, object: Node3D) -> void:
	var aim := object.global_position
	aim.y = player.global_position.y
	player.look_at(aim, Vector3.UP)

func approach(cabin: Node, kind: String, offset: Vector3 = Vector3(0, 0, 1.6)) -> void:
	var object: Node3D = cabin.get_node("World/Objects/" + kind)
	cabin.player.position = object.position + offset
	face(cabin.player, object)
	await frames()
	check(cabin.player.target == object, kind + " reachable with reticle and line of sight")

func all_landmarks_connected(cabin: Node) -> bool:
	var queue: Array[Vector2i] = [Vector2i(7, 15)]
	var seen := {Vector2i(7, 15): true}
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + direction
			if not cabin.solid(next.x, next.y) and not seen.has(next):
				seen[next] = true
				queue.append(next)
	for object in cabin.objects.get_children():
		var cell := Vector2i(floori(object.position.x / cabin.CELL), floori(object.position.z / cabin.CELL))
		if not seen.has(cell):
			return false
	return true

func run() -> void:
	get_tree().current_scene = null
	Game.travel("res://scenes/TherapyRoom.tscn")
	await frames()
	check(UI.busy and get_tree().current_scene.has_node("Patient"), "Preserved therapy introduction and patient")
	await capture("FP-Therapy")
	await dismiss()
	await get_tree().create_timer(1.7).timeout
	await frames()
	var cabin = get_tree().current_scene
	check(cabin.name == "WitchCabin", "Startup flow enters WitchCabin")
	check(cabin.player is CharacterBody3D, "First-person CharacterBody3D controller")
	check(cabin.has_node("World/Player/Camera3D"), "Consistent first-person camera path")
	check(is_equal_approx(cabin.player.camera.fov, 70.0), "70 degree field of view")
	check(cabin.grid.size() == 17 and cabin.grid[0].size() == 17, "Integer grid level")
	check(all_landmarks_connected(cabin), "All landmarks connected to entrance through corridors")
	check(cabin.has_node("World/Floor") and cabin.has_node("World/Ceiling"), "Textured floor and ceiling geometry")
	check(get_tree().get_nodes_in_group("dream_interactables").size() == 5, "Five first-person interactables")
	check(cabin.world.find_children("*", "", true, false).size() < 300, "Compact world with imported models")
	check(cabin.guardian.has_node("ModelPivot/SuppliedModel"), "Supplied performer GLB is the guardian")
	check(cabin.objects.get_node("Altar").has_node("ModelPivot/SuppliedModel"), "Supplied witch GLB decorates the altar")
	check(cabin.world.get_node("WallBatch1").material_override.get_shader_parameter("tex").resource_path.ends_with("fever_dreams/textures/cabin/wallpaper_01.png"), "Walls use actual asset-pack wallpaper")
	check(cabin.world.get_node("Floor").material_override.get_shader_parameter("tex").resource_path.ends_with("kenney_floor_wood_planks.png"), "Floor uses supplied wooden texture")
	check(cabin.objects.get_node("Box/Billboard").texture.resource_path.ends_with("fever_dreams/props/music_box_cutout.png"), "Music box uses supplied antique cutout")
	check(cabin.has_node("World/Objects/Box/MusicBoxTable") and cabin.has_node("World/RitualTiles"), "Music box table and tiled ritual floor exist")
	check(Game.cues["rattle"].stream.resource_path.ends_with("mechanical_rattle.wav") and Game.cues["dream"].stream.resource_path.ends_with("dream_transition.wav"), "Supplied mechanical and dream sounds wired")
	await dismiss()
	await capture("FP-Entrance")
	var player = cabin.player
	# Mouse horizontal rotation and Escape cursor toggling use real input events.
	var old_yaw: float = player.rotation.y
	var mouse := InputEventMouseMotion.new()
	mouse.relative = Vector2(100, 0)
	mouse.screen_relative = Vector2(100, 0)
	Input.parse_input_event(mouse)
	await frames()
	check(absf(player.rotation.y - old_yaw) > 0.01, "Mouse turns first-person view")
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	Input.parse_input_event(escape)
	await frames()
	check(not player.mouse_captured, "Escape releases cursor")
	Input.parse_input_event(escape.duplicate())
	await frames()
	check(player.mouse_captured, "Escape recaptures cursor")
	player.rotation.y = 0
	player.position = Vector3(15, 0, 12)
	Input.action_press("strafe_right")
	await frames(20)
	Input.action_release("strafe_right")
	check(player.position.x > 15.9 and absf(player.position.z - 12.0) < 0.05, "D strafes relative to camera")
	player.position = Vector3(7.5 * 1.8, 0, 13.5 * 1.8)
	Input.action_press("forward")
	await frames(40)
	Input.action_release("forward")
	check(player.position.z >= 23.63 and player.position.z < 23.8, "Grid walls block forward movement")
	player.position = Vector3(8.3 * 1.8, 0, 8.5 * 1.8 + 1.6)
	Input.action_press("forward")
	await frames(30)
	Input.action_release("forward")
	check(player.position.z >= 16.08 and player.position.z < 16.25, "Ritual table has solid collision")
	await frames()
	await press("interact")
	check(Game.memories.has("letter"), "E recovers existing letter memory")
	await dismiss()
	await approach(cabin, "Box")
	await capture("FP-Box-Close")
	await press("interact")
	check(UI.choices.is_empty() and UI.busy, "Music box remains locked before three memories")
	check(Game.music.playing and cabin.pulse > 0.9 and Game.music.stream.resource_path.ends_with("musicbox1_spooky_waltz.ogg"), "Music box plays supplied spooky waltz and distorts surfaces")
	await dismiss()
	for item in [["Altar", "altar"], ["Animatronic", "guardian"]]:
		await approach(cabin, item[0])
		await capture("FP-" + item[0])
		await press("interact")
		check(Game.memories.has(item[1]), item[0] + " preserves memory dialogue")
		await dismiss()
	check(Game.memories.size() == 3, "Three unique memories persist")
	await approach(cabin, "Altar")
	await press("interact")
	await dismiss()
	check(Game.memories.size() == 3, "Repeated object does not duplicate memory")
	# A nearby object behind the partition cannot be used through the wall.
	var saved_guard: Vector3 = cabin.guardian.position
	cabin.guardian.position = Vector3(12.35, 0, 2.2 * 1.8)
	player.position = Vector3(14.65, 0, 2.2 * 1.8)
	face(player, cabin.guardian)
	await frames()
	check(player.target == null, "Interaction does not pass through partition")
	cabin.guardian.position = saved_guard
	player.position = Vector3(8.1 * 1.8, 0, 10.8 * 1.8)
	player.rotation.y = 0
	var previous_guard: Vector3 = cabin.guardian.position
	cabin.relocate_guardian()
	check(cabin.guardian.position != previous_guard and not cabin.can_see(cabin.guardian.position), "Guardian relocates only outside line of sight")
	player.position = Vector3(8.0 * 1.8, 0, 10.8 * 1.8)
	player.rotation.y = -0.16
	await capture("FP-WitchCabin")
	player.position = Vector3(12.7 * 1.8, 0, 4.4 * 1.8)
	face(player, cabin.objects.get_node("Box"))
	await capture("FP-MusicBox")
	previous_guard = cabin.guardian.position
	# Walk into the dream threshold: transition requires no button press.
	player.position = cabin.dream_door.position + Vector3(0, 0, -1.4)
	player.rotation.y = PI
	Input.action_press("forward")
	await frames(12)
	Input.action_release("forward")
	await get_tree().create_timer(1.7).timeout
	await frames()
	cabin = get_tree().current_scene
	check(cabin.name == "DreamCabin" and cabin.distorted, "Walking through door enters DreamCabin")
	check(cabin.world.get_node("WallBatch1").material_override.get_shader_parameter("tex").resource_path.ends_with("wallpaper_03.png"), "Dream cabin uses different supplied wallpaper")
	Game.play_music_box(true)
	check(Game.music.stream.resource_path.ends_with("musicbox3_sad_tune.ogg") and Game.music.playing, "Dream music box uses supplied sad tune")
	check(cabin.guardian.position != previous_guard, "Guardian changes location between rooms")
	check(Game.memories.size() == 3, "Memories survive dream crossing")
	await dismiss()
	cabin.player.position = Vector3(8 * 1.8, 0, 10.8 * 1.8)
	cabin.player.rotation.y = -0.16
	await capture("FP-DreamCabin")
	await approach(cabin, "Door", Vector3(0, 0, -1.6))
	await press("interact")
	await get_tree().create_timer(1.7).timeout
	await frames()
	cabin = get_tree().current_scene
	check(cabin.name == "WitchCabin", "E at dream door returns to cabin")
	await approach(cabin, "Box")
	await press("interact")
	check(UI.choices.size() == 2, "Music box unlocks both original ending choices")
	await press("interact")
	await frames()
	check(Game.ending == "listen" and get_tree().current_scene.name == "Ending", "Listen ending preserved")
	await press("restart")
	await frames()
	check(Game.memories.is_empty() and get_tree().current_scene.name == "TherapyRoom", "Restart resets story")
	await dismiss()
	await get_tree().create_timer(1.7).timeout
	await frames()
	await dismiss()
	cabin = get_tree().current_scene
	Game.memories = {"altar": true, "letter": true, "guardian": true}
	await approach(cabin, "Box")
	await press("interact")
	await press("right")
	await press("interact")
	await frames()
	check(Game.ending == "seal" and get_tree().current_scene.name == "Ending", "Seal ending preserved")
	print("FIRST-PERSON RESULT: %d checks, %d failures" % [checks, failures])
	# Give the real audio mixer time to retire stopped streams in fast headless runs.
	OS.delay_msec(180)
	get_tree().quit(0 if failures == 0 else 1)
