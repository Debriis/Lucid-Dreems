extends Node

var failures := 0

func _ready() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
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
	for i in range(8):
		if not UI.busy:
			break
		await press("interact")

func capture(filename: String) -> void:
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://assets/" + filename + ".png")

func run() -> void:
	# Keep the test runner alive while exercising real scene changes.
	get_tree().current_scene = null
	Game.travel("res://scenes/WitchCabin.tscn")
	await frames()
	var cabin = get_tree().current_scene
	check(cabin.name == "WitchCabin", "WitchCabin loads")
	check(cabin.get_node("CabinTiles") is TileMapLayer, "Godot 4.3+ TileMapLayer exists")
	check(cabin.tiles.get_used_cells().size() == 300, "20 x 15 tile layout")
	check(cabin.get_node("Objects/Player/Camera2D") is Camera2D, "Player camera path")
	check(get_tree().get_nodes_in_group("interactables").size() == 5, "Five interactable props")
	await dismiss()
	await capture("WitchCabin-preview")
	if "--capture" in OS.get_cmdline_user_args():
		cabin.player.position = Vector2(160, 82)
		await frames()
		await capture("WitchCabin-north-preview")
		cabin.player.position = Vector2(160, 210)
	cabin.get_node("Objects/Box").interact()
	check(UI.busy and UI.choices.is_empty(), "Music box locked before memories")
	await dismiss()
	var player = cabin.player
	player.position = Vector2(160, 151)
	Input.action_press("up")
	await frames(35)
	Input.action_release("up")
	check(player.position.y >= 130.0 and player.position.y < 135.0, "Center table blocks movement")
	await frames()
	check(player.target == cabin.get_node("Objects/Table"), "Nearest interaction target is table")
	await press("interact")
	check(Game.memories.has("letter"), "E interaction collects letter")
	await dismiss()
	# Walk against the west and north walls through empty lanes.
	player.position = Vector2(28, 120)
	Input.action_press("left")
	await frames(25)
	Input.action_release("left")
	check(player.position.x >= 20.0, "West wall collision")
	player.position = Vector2(120, 52)
	Input.action_press("up")
	await frames(25)
	Input.action_release("up")
	check(player.position.y >= 37.0, "North wallpaper collision")
	# Every memory is reachable by the real proximity system from open floor.
	for item in [["Altar", Vector2(53, 84), "altar"], ["Animatronic", Vector2(53, 205), "guardian"]]:
		player.position = item[1]
		await frames()
		check(player.target == cabin.get_node("Objects/" + item[0]), item[0] + " reachable")
		await press("interact")
		check(Game.memories.has(item[2]), item[0] + " memory collected")
		await dismiss()
	check(Game.memories.size() == 3, "Three unique memories")
	cabin.get_node("Objects/Altar").interact()
	await dismiss()
	check(Game.memories.size() == 3, "Repeated memory is not duplicated")
	var old_guard: Vector2 = cabin.get_node("Objects/Animatronic").position
	cabin.get_node("Objects/Door").interact()
	await get_tree().create_timer(1.7).timeout
	await frames()
	cabin = get_tree().current_scene
	check(cabin.name == "DreamCabin" and cabin.distorted, "Dream door transitions to distorted cabin")
	check(cabin.get_node("Objects/Animatronic").position != old_guard, "Guardian relocates across rooms")
	check(Game.memories.size() == 3, "Memories persist across transition")
	await dismiss()
	await capture("DreamCabin-preview")
	cabin.get_node("Objects/Door").interact()
	await get_tree().create_timer(1.7).timeout
	await frames()
	check(get_tree().current_scene.name == "WitchCabin", "Dream door returns to original cabin")
	get_tree().current_scene.get_node("Objects/Box").interact()
	check(UI.choices.size() == 2, "Three memories unlock two ending choices")
	await press("interact")
	await frames()
	check(get_tree().current_scene.name == "Ending" and Game.ending == "listen", "Listen ending loads")
	await capture("Ending-preview")
	await press("restart")
	await frames()
	check(get_tree().current_scene.name == "TherapyRoom" and Game.memories.is_empty(), "Restart resets state and loads therapy")
	await capture("TherapyRoom-preview")
	await dismiss()
	await get_tree().create_timer(1.7).timeout
	await frames()
	check(get_tree().current_scene.name == "WitchCabin", "Therapy dialogue enters dream")
	await dismiss()
	Game.memories = {"altar": true, "letter": true, "guardian": true}
	get_tree().current_scene.get_node("Objects/Box").interact()
	await press("right")
	await press("interact")
	await frames()
	check(get_tree().current_scene.name == "Ending" and Game.ending == "seal", "Seal ending loads")
	print("SMOKE RESULT: %d failure(s)" % failures)
	get_tree().quit(0 if failures == 0 else 1)
