extends Node2D

@export var distorted := false
const PROP = preload("res://scripts/prop.gd")
const PLAYER = preload("res://scripts/player.gd")
var player: Node
var tiles: TileMapLayer

func _ready() -> void:
	build_tiles()
	var objects := Node2D.new()
	objects.name = "Objects"
	objects.y_sort_enabled = true
	add_child(objects)
	add_prop(objects, "altar", Vector2(53, 65), Vector2(38, 18), "Touch the candle altar")
	add_prop(objects, "box", Vector2(265, 63), Vector2(28, 15), "Wind the music box")
	add_prop(objects, "table", Vector2(160, 125), Vector2(60, 28), "Read the folded letter")
	var locations := [Vector2(53, 184), Vector2(224, 160), Vector2(98, 85), Vector2(56, 180)]
	add_prop(objects, "animatronic", locations[Game.crossings % locations.size()], Vector2(24, 16), "Speak to the guardian")
	add_prop(objects, "door", Vector2(278, 206), Vector2(32, 16), "Cross the dream door")
	player = PLAYER.new()
	player.name = "Player"
	player.position = Vector2(160, 210) if Game.crossings == 0 else Vector2(278, 220)
	objects.add_child(player)
	update_status()
	if not Game.music.playing:
		Game.music.play()
	if Game.crossings == 0:
		UI.say(["THE WITCH'S CABIN\nThree objects remember what the patient cannot.", "WASD / arrows to walk. E to interact.\nThe guardian watches over the music box."], update_status)
	elif Game.crossings == 1:
		UI.say(["The room has turned inside its own memory.\nThe guardian is no longer where you left it."], update_status)

func update_status() -> void:
	UI.status.text = ("THE OTHER SIDE" if distorted else "WITCH'S CABIN") + "    MEMORY %d/3" % Game.memories.size()

func build_tiles() -> void:
	var image := Image.create(64, 16, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 8123
	for tile in range(4):
		for y in range(16):
			for x in range(16):
				var base: Color
				if tile == 0:
					base = Color("65533a") if not distorted else Color("63506d")
					if y % 8 == 0 or (x == (0 if y < 8 else 8)):
						base = Color("3c3230") if not distorted else Color("342c46")
				elif tile == 1:
					base = Color("827d42") if not distorted else Color("72607e")
					if x % 8 == 0:
						base = Color("4f5636") if not distorted else Color("a05b80")
					if absi(x % 8 - 4) + absi(y % 8 - 4) < 3:
						base = Color("625336") if not distorted else Color("4b3d61")
				elif tile == 2:
					base = Color("382b2d") if not distorted else Color("3b2c4c")
					if y < 3:
						base = Color("a1884e") if not distorted else Color("a4678c")
				else:
					base = Color("4b4140")
				var noise := rng.randf_range(-0.055, 0.055)
				if (x + y) % 2 == 0:
					noise -= 0.025
				image.set_pixel(tile * 16 + x, y, Color(base.r + noise, base.g + noise, base.b + noise, 1))
	var atlas := TileSetAtlasSource.new()
	atlas.texture = ImageTexture.create_from_image(image)
	atlas.texture_region_size = Vector2i(16, 16)
	var set := TileSet.new()
	set.tile_size = Vector2i(16, 16)
	set.add_physics_layer()
	set.set_physics_layer_collision_layer(0, 1)
	set.add_source(atlas, 0)
	for i in range(4):
		atlas.create_tile(Vector2i(i, 0))
		if i == 1 or i == 2:
			var data := atlas.get_tile_data(Vector2i(i, 0), 0)
			data.set_collision_polygons_count(0, 1)
			data.set_collision_polygon_points(0, 0, PackedVector2Array([Vector2(-8,-8), Vector2(8,-8), Vector2(8,8), Vector2(-8,8)]))
	tiles = TileMapLayer.new()
	tiles.name = "CabinTiles"
	tiles.show_behind_parent = true
	tiles.tile_set = set
	add_child(tiles)
	for y in range(15):
		for x in range(20):
			var type := 0
			if y < 2:
				type = 1
			elif x == 0 or x == 19 or y == 14:
				type = 2
			tiles.set_cell(Vector2i(x, y), 0, Vector2i(type, 0))
	queue_redraw()

func add_prop(parent: Node2D, kind: String, pos: Vector2, size: Vector2, caption: String) -> void:
	var object := PROP.new()
	object.name = kind.capitalize()
	object.kind = kind
	object.caption = caption
	object.position = pos
	object.solid_size = size
	object.distorted = distorted
	if distorted and kind != "door":
		object.skew = 0.07 if kind == "table" else -0.05
	object.activated.connect(interact)
	parent.add_child(object)

func interact(kind: String) -> void:
	match kind:
		"altar":
			memory("altar", "MEMORY / THE RITUAL\n'I lit a candle every night. If it stayed lit, she might come home.'")
		"table":
			memory("letter", "MEMORY / THE LETTER\n'You were a child. Keeping her alive was never your responsibility.'")
		"animatronic":
			memory("guardian", "MEMORY / THE GUARDIAN\n'I made a friend who could never leave. I taught it her lullaby.'")
		"box":
			if Game.memories.size() < 3:
				UI.say(["The key turns. The melody catches on a missing note.\nFind the altar, the letter, and the guardian.\nMemories: %d / 3" % Game.memories.size()], update_status)
			else:
				UI.choose()
		"door":
			Game.crossings += 1
			UI.sleep_into("res://scenes/WitchCabin.tscn" if distorted else "res://scenes/DreamCabin.tscn")

func memory(id: String, text: String) -> void:
	if Game.remember(id):
		UI.say([text, "A small sound returns to the music box.\nMemory recovered: %d / 3" % Game.memories.size()], update_status)
	else:
		UI.say(["You hold this memory already.\nIt feels warmer when you stop trying to change it."], update_status)

func _draw() -> void:
	# The southern threshold marks the entrance the dream sealed behind you.
	draw_rect(Rect2(143, 211, 34, 13), Color("302637"))
	draw_rect(Rect2(145, 213, 30, 2), Color("a88658" if not distorted else "b16694"))
	for y in range(32, 224):
		for x in range(16, 304):
			if (x + y) % 3 == 0 and (y < 40 or x < 23 or x > 296 or y > 215):
				draw_rect(Rect2(x, y, 1, 1), Color(0.035, 0.015, 0.05, 0.5))
	for x in [102, 210]:
		draw_rect(Rect2(x, 10, 10, 19), Color("272336"))
		draw_rect(Rect2(x + 3, 12, 1, 15), Color("cc7897" if distorted else "b7a15d"))
