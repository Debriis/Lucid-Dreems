extends "res://scripts/cabin.gd"
## Reuses the existing cabin memory dialogue, ending choices, and door transition.
## Only exploration/presentation is replaced. The old 2D builder remains intact.

const FP_PLAYER = preload("res://scripts/first_person_player.gd")
const FP_PROP = preload("res://scripts/first_person_prop.gd")
const SURFACE = preload("res://shaders/retro_surface.gdshader")
const CELL := 1.8
const HEIGHT := 2.9
const KIT := "res://assets/fever_dreams/"
const KIT_TEXTURES := KIT + "textures/cabin/"
const V2 := "res://assets/replacements_v2/"
const WORLD_FONT = preload("res://assets/replacements_v2/ui/fonts/DotGothic16-Regular.ttf")
const TEXTURES := {
	"wall": "wallpaper_01.png", "portrait": "wallpaper_02.png", "eyes": "wallpaper_04.png",
	"wall_dream": "wallpaper_03.png", "portrait_dream": "wallpaper_05.png", "eyes_dream": "wallpaper_06.png",
	"wood": "kenney_floor_wood_planks.png", "floor": "kenney_floor_wood_planks.png",
	"floor_dream": "kenney_floor_wood_planks.png", "ceiling": "wallpaper_05.png",
	"ceiling_dream": "wallpaper_06.png", "timber": "kenney_wall_timber_structure.png",
	"tiles": "kenney_floor_tiles_blue_large.png", "door": "kenney_door_wood.png"
}
const PLAN := [
	"#################",
	"#......#........#",
	"#......#........#",
	"#...............#",
	"#......#........#",
	"###.####.###.####",
	"#...............#",
	"#...............#",
	"##..#.......#...#",
	"#...#.......#...#",
	"#...............#",
	"#...#.......#...#",
	"#####..###..#...#",
	"######...####...#",
	"######...########",
	"######...########",
	"#################"
]

var grid: Array[PackedInt32Array] = []
var world: Node3D
var objects: Node3D
var materials: Array[ShaderMaterial] = []
var guardian: StaticBody3D
var dream_door: StaticBody3D
var reticle: Label
var controls: Label
var ambient: AudioStreamPlayer
var pulse := 0.0
var elapsed := 0.0
var unseen := 0.0
var relocation_count := 0
var transitioning := false
@export var room_id := 1
var world_viewport: SubViewport
var box: StaticBody3D
var witch: StaticBody3D
var exit_sign: Label3D
var marked_door: StaticBody3D
var plates: Array[Sprite3D] = []
var chase_remaining := 0.0
var final_escape := false
var final_time := 0.0
var ending_started := false
var final_barrier: StaticBody3D
var box_sign: Label3D
var unwinding := false
var memory_door_searched := false
var checkpoint := Vector3.ZERO
var scare_active := false
var catch_grace := 6.0
var catch_count := 0
var random_scare_cooldown := 30.0
var random_scares_played := 0
var distract_used := false
var distraction_remaining := 0.0
var note_props: Dictionary = {}
var health := 100
var room_time_left := 120.0
var timeout_elapsed := 0.0
var damage_invulnerability := 0.0
var failed := false
var witch_home := Vector3.ZERO
var chamber_alert_cooldown := 0.0

func _ready() -> void:
	world = Node3D.new()
	world.name = "World"
	world_viewport = preload("res://scripts/low_resolution_view.gd").attach(self, world)
	var environment := WorldEnvironment.new()
	environment.name = "Environment"
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("100b16")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("9a8d75")
	settings.ambient_light_energy = 0.08 if room_id == 4 else 0.6
	environment.environment = settings
	world.add_child(environment)
	build_grid()
	build_shell()
	objects = Node3D.new()
	objects.name = "Objects"
	world.add_child(objects)
	build_story_objects()
	player = FP_PLAYER.new()
	player.name = "Player"
	player.position = spawn_point()
	world.add_child(player)
	checkpoint = spawn_point()
	random_scare_cooldown = randf_range(30.0, 42.0)
	reticle = UI.label(Vector2(630, 342), Vector2(20, 32), 26)
	reticle.text = "+"
	reticle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls = UI.label(Vector2(32, 678), Vector2(1216, 32), 22)
	controls.text = "WASD / arrows move   MOUSE / Q C look   E interact   ESC pause"
	controls.modulate = Color("b7a77d")
	ambient = AudioStreamPlayer.new()
	ambient.name = "DreamAmbience"
	ambient.bus = "Music"
	var drone: AudioStreamWAV = load("res://audio/dream_drone.wav" if distorted else "res://audio/cabin_drone.wav")
	drone.loop_mode = AudioStreamWAV.LOOP_FORWARD
	drone.loop_end = int(drone.get_length() * drone.mix_rate)
	ambient.stream = drone
	ambient.volume_db = -26.0
	add_child(ambient)
	ambient.play()
	ambient.add_to_group("dream_audio")
	update_status()
	Story.enter_room(room_id, self)

func build_grid() -> void:
	var layout: Array = room_layout()
	for z in range(layout.size()):
		var row := PackedInt32Array()
		for x in range(layout[z].length()):
			var is_wall: bool = layout[z][x] == "#"
			var tile := 1
			if (x * 13 + z * 3) % 11 == 0:
				tile = 2
			elif (x + z * 7) % 13 == 0:
				tile = 3
			if z >= 12 and x < 12:
				tile = 4
			row.append(tile if is_wall else 0)
		grid.append(row)

func room_layout() -> Array:
	if room_id == 1:
		return PLAN
	var rows: Array = ["#################"]
	var length := 24 if room_id == 3 else (23 if room_id == 2 else 16)
	for z in range(1, length - 1):
		if room_id == 3:
			rows.append("########.########" if z == 5 else "######.....######")
		elif room_id == 2:
			rows.append("#####.......#####" if z < 20 else "#######...#######")
		else:
			rows.append("#####.......#####")
	rows.append("#################")
	if room_id == 4:
		rows[0] = "########.########"
	return rows

func spawn_point() -> Vector3:
	match room_id:
		2: return Vector3(8.5 * CELL, 0, 20.8 * CELL)
		3: return Vector3(8.5 * CELL, 0, 21 * CELL)
		4: return Vector3(8.5 * CELL, 0, 12.8 * CELL)
	return Vector3(7.5 * CELL, 0, 15.1 * CELL)

func sign_at(text: String, pos: Vector3, size: int = 40) -> Label3D:
	var sign := Label3D.new()
	sign.font = WORLD_FONT
	sign.text = text
	sign.font_size = size
	sign.outline_size = 2
	sign.pixel_size = 0.008
	sign.position = pos
	sign.no_depth_test = false
	sign.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sign.modulate = Color("f7ed9c")
	world.add_child(sign)
	return sign

func build_story_objects() -> void:
	var box_spot := Vector2(8.3, 8.5)
	var performer_spot := Vector2(7.5, 13.5) # Visible down the entrance passage from frame one.
	var exit_spot := Vector2(14.5, 13.0)
	if room_id == 2:
		box_spot = Vector2(8.5, 14.5)
		performer_spot = Vector2(8.5, 3.0)
		exit_spot = Vector2(10.8, 2.0)
	elif room_id == 3:
		box_spot = Vector2(8.5, 3.0)
		performer_spot = Vector2(10.3, 3.0)
		exit_spot = Vector2(8.5, 22.0)
	elif room_id == 4:
		box_spot = Vector2(8.5, 7.9)
		performer_spot = Vector2(9.2, 7.3)
		exit_spot = Vector2(8.5, 2.0)
	box = make_prop("box", box_spot, Vector2(0.85, 0.65), 1.55, "UNWIND music box %02d" % room_id)
	box.box_id = room_id
	build_box_table(box)
	box_sign = sign_at("MUSIC BOX %02d\nTURN THE KEY BACKWARD" % room_id, box.position + Vector3(0, 2.08, 0), 22)
	guardian = make_prop("animatronic", performer_spot, Vector2(0.7, 0.6), 2.2, "TALK to RUE / the Performer")
	witch = make_prop("witch", Vector2(8.5, 2.2), Vector2(0.6, 0.3), 1.7, "")
	witch.hide()
	witch.collision_layer = 0
	dream_door = make_prop("door", exit_spot, Vector2(1.2, 0.22), 2.65, "EXIT - finish this room's music box first")
	if room_id == 3:
		dream_door.rotation.y = PI
	elif room_id == 1:
		dream_door.rotation.z = deg_to_rad(-3.0)
	build_doorframe()
	exit_sign = sign_at("PLEASE LEAVE AS YOU ARRIVED.", dream_door.position + Vector3(0, 2.78, 0.2), 24)
	if room_id == 1:
		var table := make_prop("table", Vector2(8.3, 10.2), Vector2(2.35, 1.1), 1, "")
		build_table(table)
		decorate_room()
		build_cabin_furnishings()
		sign_at("THE WITCH'S CABIN", Vector3(7.5 * CELL, 2.78, 13.1 * CELL), 18)
		sign_at("EXIT >", Vector3(11.4 * CELL, 1.8, 10.15 * CELL), 26)
	elif room_id == 2:
		build_dining_room()
		build_witch_chamber()
	elif room_id == 3:
		build_school_hall()
	else:
		build_theatre()
	build_note()
	witch_home = witch.position

func build_witch_chamber() -> void:
	witch.position = Vector3(8.5 * CELL, 0, 16.3 * CELL)
	witch.show()
	witch.animate("idle")
	witch.actor_name.position = Vector3(0, 2.6, 0.25)
	var throne := make_prop("table", Vector2(8.5, 16.1), Vector2(2.1, 0.9), 1, "")
	throne.name = "KeepersThrone"
	var timber := surface("timber")
	block(throne, "ThroneBack", Vector3(0, 1.25, -0.45), Vector3(2.15, 2.5, 0.25), timber)
	block(throne, "ThroneSeat", Vector3(0, 0.58, 0), Vector3(2.15, 0.2, 1.1), surface("wood"))
	for side in [-1.0, 1.0]:
		block(throne, "ThroneArm", Vector3(side * 0.95, 0.9, 0.15), Vector3(0.18, 0.6, 0.95), timber)
		var portrait := Sprite3D.new()
		portrait.name = "KeeperPortrait"
		portrait.texture = load(V2 + "characters/ayush_grain_closed.png")
		portrait.pixel_size = 1.45 / float(portrait.texture.get_height())
		portrait.position = witch.position + Vector3(side * 3.3, 1.7, -0.3)
		portrait.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		portrait.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		portrait.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		world.add_child(portrait)
		var basin := make_prop("table", Vector2(8.5 + side * 1.65, 16.2), Vector2(0.9, 0.9), 1, "")
		basin.name = "ChamberCauldronLeft" if side < 0 else "ChamberCauldronRight"
		var mesh := MeshInstance3D.new()
		var pot := CylinderMesh.new()
		pot.top_radius = 0.5
		pot.bottom_radius = 0.3
		pot.height = 0.72
		pot.radial_segments = 8
		mesh.mesh = pot
		mesh.position.y = 0.45
		var iron := StandardMaterial3D.new()
		iron.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		iron.albedo_color = Color("342638")
		mesh.material_override = iron
		basin.add_child(mesh)
		var brew := StandardMaterial3D.new()
		brew.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		brew.albedo_color = Color("c89be3")
		block(basin, "PurpleBrew", Vector3(0, 0.82, 0), Vector3(0.68, 0.015, 0.68), brew)
	var chamber_sign := sign_at("AYUSH'S\nCHAMBER", witch.position + Vector3(-3.3, 2.65, -0.25), 20)
	chamber_sign.pixel_size = 0.006

func build_note() -> void:
	if room_id > 3:
		return
	var ids := ["", "unsent_message", "birthday_ticket", "last_note"]
	var locations := [Vector2.ZERO, Vector2(6.65, 14.0), Vector2(9.6, 18.6), Vector2(9.8, 19.5)]
	var paper := make_prop("note", locations[room_id], Vector2(0.42, 0.42), 0.5, "READ note / " + ["", "Unsent message", "Birthday ticket", "Last note"][room_id])
	paper.note_id = ids[room_id]
	note_props[ids[room_id]] = paper
	block(paper, "NoteStand", Vector3(0, 0.45, 0), Vector3(0.45, 0.9, 0.36), surface("wood"))
	var marker := sign_at("NOTE\n[E]", paper.position + Vector3(0, 1.7, 0), 32)
	marker.pixel_size = 0.006

func build_cabin_furnishings() -> void:
	var timber := surface("timber")
	for z in [7.0, 10.5]:
		block(world, "CabinRoofBeam", Vector3(8.5 * CELL, 2.75, z * CELL), Vector3(12.7, 0.25, 0.23), timber)
	for x in [5.1, 11.9]:
		block(world, "CabinUpright", Vector3(x * CELL, 1.38, 11.4 * CELL), Vector3(0.22, 2.76, 0.22), timber)
	var iron := StandardMaterial3D.new()
	iron.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	iron.albedo_color = Color("292531")
	var ember := StandardMaterial3D.new()
	ember.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ember.albedo_color = Color("d86830")
	var stove := make_prop("table", Vector2(10.8, 11.1), Vector2(0.9, 0.8), 1, "")
	stove.name = "CrookedIronStove"
	stove.rotation.y = PI
	block(stove, "IronBody", Vector3(0, 0.68, 0), Vector3(0.82, 1.1, 0.75), iron)
	block(stove, "FireWindow", Vector3(0, 0.65, 0.38), Vector3(0.5, 0.4, 0.025), ember)
	for x in [-0.18, 0.0, 0.18]:
		block(stove, "FireBars", Vector3(x, 0.65, 0.405), Vector3(0.045, 0.43, 0.035), iron)
	block(stove, "BentChimney", Vector3(0.18, 1.94, -0.14), Vector3(0.26, 1.5, 0.26), iron)
	var pot := make_prop("table", Vector2(5.6, 11.0), Vector2(1.0, 1.0), 1, "")
	pot.name = "WitchCauldron"
	var bowl := MeshInstance3D.new()
	var cauldron := CylinderMesh.new()
	cauldron.top_radius = 0.47
	cauldron.bottom_radius = 0.3
	cauldron.height = 0.58
	cauldron.radial_segments = 8
	bowl.mesh = cauldron
	bowl.material_override = iron
	bowl.position.y = 0.48
	pot.add_child(bowl)
	var brew := MeshInstance3D.new()
	var liquid := CylinderMesh.new()
	liquid.top_radius = 0.39
	liquid.bottom_radius = 0.39
	liquid.height = 0.015
	liquid.radial_segments = 8
	brew.mesh = liquid
	var green := StandardMaterial3D.new()
	green.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	green.albedo_color = Color("b2d854")
	brew.material_override = green
	brew.position.y = 0.78
	pot.add_child(brew)
	for x in [-0.28, 0.28]:
		block(pot, "CauldronFoot", Vector3(x, 0.13, 0), Vector3(0.11, 0.25, 0.3), iron)

func build_dining_room() -> void:
	var table := make_prop("table", Vector2(8.5, 10.5), Vector2(2.5, 12.5), 1, "")
	var wood := surface("wood")
	block(table, "LongDiningTable", Vector3(0, 0.8, 0), Vector3(2.6, 0.18, 12.5), wood)
	for z in [5.5, 7.5, 9.5, 11.5, 13.5]:
		for x in [6.0, 11.0]:
			# Chairs face the outer walls instead of the dinner table.
			block(world, "ChairSeat", Vector3(x * CELL, 0.45, z * CELL), Vector3(0.6, 0.12, 0.6), wood)
			block(world, "ChairBack", Vector3((x + (0.25 if x > 8 else -0.25)) * CELL, 0.9, z * CELL), Vector3(0.12, 0.9, 0.65), wood)
		for x in [7.9, 9.1]:
			var plate := Sprite3D.new()
			plate.texture = load(V2 + "characters/patient_grain_sad.png")
			plate.pixel_size = 0.42 / float(plate.texture.get_height())
			plate.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
			plate.position = Vector3(x * CELL, 1.08, z * CELL)
			plate.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			plate.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
			plate.shaded = false
			world.add_child(plate)
			plates.append(plate)
	seat_performer()

func build_school_hall() -> void:
	marked_door = make_prop("memory_door", Vector2(8.5, 5.0), Vector2(1.2, 0.22), 2.65, "SEARCH the marked door")
	marked_door.name = "MarkedDoor"
	sign_at("NOTHING HAPPENED HERE", marked_door.position + Vector3(0, 2.75, 0.1), 28)
	for z in range(7, 21, 2):
		for x in [6.12, 10.88]:
			var locker := Sprite3D.new()
			locker.texture = load(KIT_TEXTURES + "kenney_door_wood.png")
			locker.pixel_size = 2.0 / 128.0
			locker.position = Vector3(x * CELL, 1.1, z * CELL)
			locker.rotation.y = PI / 2 if x < 8 else -PI / 2
			locker.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			world.add_child(locker)
			var face := Sprite3D.new()
			face.texture = load(V2 + "characters/patient_grain_sad.png")
			face.pixel_size = 0.45 / float(face.texture.get_height())
			face.position = locker.position + Vector3(0.04 if x < 8 else -0.04, 0.45, 0)
			face.rotation.y = locker.rotation.y
			face.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			face.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
			face.shaded = false
			world.add_child(face)
			plates.append(face)

func seat_performer() -> void:
	if room_id == 4:
		guardian.freeze_actor()
	else:
		guardian.animate("idle")
	var wood := surface("wood")
	block(guardian, "PerformerChair", Vector3(0, 0.5, 0), Vector3(0.8, 0.12, 0.65), wood)
	block(guardian, "ChairBack", Vector3(0, 0.9, -0.3), Vector3(0.8, 0.9, 0.1), wood)
	# The head hovers over an empty chair; no old photographic body remains.
	guardian.get_node("ModelPivot").position.y = -0.12

func build_theatre() -> void:
	seat_performer()
	block(world, "TinyStage", Vector3(8.5 * CELL, 0.08, 7.5 * CELL), Vector3(4, 0.16, 3), surface("timber"))
	var pool := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 1.15
	disc.bottom_radius = 1.15
	disc.height = 0.006
	disc.radial_segments = 24
	pool.mesh = disc
	pool.position = guardian.position + Vector3(0, 0.166, 0)
	pool.material_override = surface("wood")
	world.add_child(pool)
	var spotlight := SpotLight3D.new()
	spotlight.position = guardian.position + Vector3(0, 2.7, 1.0)
	world.add_child(spotlight)
	spotlight.look_at(guardian.position + Vector3.UP, Vector3.FORWARD)
	spotlight.light_color = Color("e9d7a6")
	spotlight.light_energy = 3.0
	spotlight.spot_range = 6.0
	spotlight.spot_angle = 28.0
	for mesh in guardian.find_children("*", "MeshInstance3D", true, false):
		for i in range(mesh.mesh.get_surface_count()):
			var mat = mesh.get_active_material(i)
			if mat is StandardMaterial3D:
				mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	for material in materials:
		material.set_shader_parameter("tint", Vector3(0.32, 0.22, 0.36))
	final_barrier = StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var boundary := BoxShape3D.new()
	boundary.size = Vector3(CELL, HEIGHT, CELL)
	shape.shape = boundary
	shape.position = Vector3(8.5 * CELL, HEIGHT / 2, CELL / 2)
	final_barrier.add_child(shape)
	world.add_child(final_barrier)

func solid(x: int, z: int) -> bool:
	return z < 0 or z >= grid.size() or x < 0 or x >= grid[0].size() or grid[z][x] != 0

func surface(texture_name: String, warped: bool = false) -> ShaderMaterial:
	var result := ShaderMaterial.new()
	result.shader = SURFACE
	result.set_shader_parameter("tex", load(KIT_TEXTURES + TEXTURES[texture_name]))
	result.set_shader_parameter("floor_warp", warped)
	result.set_meta("floor_warp_enabled", warped)
	materials.append(result)
	return result

func build_shell() -> void:
	var suffix := "_dream" if distorted or room_id == 3 else ""
	var types := ["wall" + suffix, "portrait" + suffix, "eyes" + suffix, "timber"]
	for tile in range(1, 5):
		var vertices := PackedVector3Array()
		var uvs := PackedVector2Array()
		var indices := PackedInt32Array()
		for z in range(grid.size()):
			for x in range(grid[z].size()):
				if grid[z][x] != tile:
					continue
				var a := Vector3(x * CELL, 0, z * CELL)
				if not solid(x, z - 1):
					wall_quad(vertices, uvs, indices, a, a + Vector3(CELL, 0, 0))
				if not solid(x + 1, z):
					wall_quad(vertices, uvs, indices, a + Vector3(CELL, 0, 0), a + Vector3(CELL, 0, CELL))
				if not solid(x, z + 1):
					wall_quad(vertices, uvs, indices, a + Vector3(CELL, 0, CELL), a + Vector3(0, 0, CELL))
				if not solid(x - 1, z):
					wall_quad(vertices, uvs, indices, a + Vector3(0, 0, CELL), a)
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_TEX_UV] = uvs
		arrays[Mesh.ARRAY_INDEX] = indices
		var mesh := ArrayMesh.new()
		if not vertices.is_empty():
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var node := MeshInstance3D.new()
		node.name = "WallBatch%d" % tile
		node.mesh = mesh
		node.material_override = surface(types[tile - 1])
		world.add_child(node)
	# Merge adjacent wall cells into collision runs. Four rendered wall batches,
	# roughly 40 static boxes, rather than a scene node for every rendered pixel.
	var walls := StaticBody3D.new()
	walls.name = "WallCollisions"
	world.add_child(walls)
	for z in range(grid.size()):
		var x := 0
		while x < grid[z].size():
			if not solid(x, z):
				x += 1
				continue
			var start := x
			while x < grid[z].size() and solid(x, z):
				x += 1
			var collision := CollisionShape3D.new()
			var box := BoxShape3D.new()
			box.size = Vector3((x - start) * CELL, HEIGHT, CELL)
			collision.shape = box
			collision.position = Vector3((start + x) * CELL / 2.0, HEIGHT / 2.0, (z + 0.5) * CELL)
			walls.add_child(collision)
	var extent := Vector2(grid[0].size() * CELL, grid.size() * CELL)
	plane("Floor", Vector3(extent.x / 2, 0, extent.y / 2), extent, surface("floor" + suffix, true), Vector2(17, 17))
	plane("Ceiling", Vector3(extent.x / 2, HEIGHT, extent.y / 2), extent, surface("ceiling" + suffix), Vector2(17, 17))
	plane("EntrancePlanks", Vector3(7.5 * CELL, 0.012, 14 * CELL), Vector2(3 * CELL, 4 * CELL), surface("wood"), Vector2(3, 4))
	var tiled_floor := surface("tiles", true)
	tiled_floor.set_shader_parameter("tint", Vector3(1.0, 0.91, 0.6) if not distorted else Vector3(1.0, 0.65, 0.94))
	plane("RitualTiles", Vector3(8.5 * CELL, 0.015, 8.5 * CELL), Vector2(7 * CELL, 6 * CELL), tiled_floor, Vector2(6, 5))

func wall_quad(vertices: PackedVector3Array, uvs: PackedVector2Array, indices: PackedInt32Array, a: Vector3, b: Vector3) -> void:
	# A real opening through the divider reveals the neighbouring interior.
	if room_id == 1 and is_equal_approx(a.x, b.x) and (is_equal_approx(a.x, 7 * CELL) or is_equal_approx(a.x, 8 * CELL)) and is_equal_approx(minf(a.z, b.z), 2 * CELL):
		wall_strip(vertices, uvs, indices, a, b, 0, 0.9)
		wall_strip(vertices, uvs, indices, a, b, 2.15, HEIGHT)
		wall_strip(vertices, uvs, indices, a, a.lerp(b, 0.15), 0.9, 2.15)
		wall_strip(vertices, uvs, indices, a.lerp(b, 0.85), b, 0.9, 2.15)
		return
	wall_strip(vertices, uvs, indices, a, b, 0, HEIGHT)

func wall_strip(vertices: PackedVector3Array, uvs: PackedVector2Array, indices: PackedInt32Array, a: Vector3, b: Vector3, low: float, high: float) -> void:
	var first := vertices.size()
	vertices.append_array(PackedVector3Array([a + Vector3.UP * low, b + Vector3.UP * low, b + Vector3.UP * high, a + Vector3.UP * high]))
	uvs.append_array(PackedVector2Array([Vector2(0, 1 - low / HEIGHT), Vector2(1, 1 - low / HEIGHT), Vector2(1, 1 - high / HEIGHT), Vector2(0, 1 - high / HEIGHT)]))
	indices.append_array(PackedInt32Array([first, first + 1, first + 2, first, first + 2, first + 3]))

func plane(node_name: String, pos: Vector3, size: Vector2, material: Material, uv_scale: Vector2) -> MeshInstance3D:
	var result := MeshInstance3D.new()
	result.name = node_name
	var mesh := PlaneMesh.new()
	mesh.size = size
	mesh.subdivide_width = 0
	mesh.subdivide_depth = 0
	mesh.material = material
	result.mesh = mesh
	result.position = pos
	# Scale UV coordinates through a single generated four-vertex surface.
	var arrays := mesh.get_mesh_arrays()
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	for i in range(uvs.size()):
		uvs[i] *= uv_scale
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	var tiled := ArrayMesh.new()
	tiled.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	result.mesh = tiled
	result.material_override = material
	world.add_child(result)
	return result

func make_prop(kind: String, pos: Vector2, size: Vector2, art_height: float, caption: String) -> StaticBody3D:
	var object := FP_PROP.new()
	object.kind = kind
	object.name = kind.capitalize()
	object.caption = caption
	object.footprint = size
	object.art_height = art_height
	object.distorted = distorted
	object.position = Vector3(pos.x * CELL, 0, pos.y * CELL)
	object.activated.connect(interact)
	objects.add_child(object)
	return object

func build_table(table: StaticBody3D) -> void:
	var wood := surface("wood")
	for spec in [[Vector3(0, 0.83, 0), Vector3(2.5, 0.17, 1.3)], [Vector3(-1, 0.4, -0.4), Vector3(0.16, 0.8, 0.16)], [Vector3(1, 0.4, -0.4), Vector3(0.16, 0.8, 0.16)], [Vector3(-1, 0.4, 0.4), Vector3(0.16, 0.8, 0.16)], [Vector3(1, 0.4, 0.4), Vector3(0.16, 0.8, 0.16)]]:
		var part := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = spec[1]
		part.mesh = box
		part.material_override = wood
		part.position = spec[0]
		table.add_child(part)
	var letter_mat := StandardMaterial3D.new()
	letter_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	letter_mat.albedo_texture = load("res://assets/first_person/letter.png")
	letter_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	letter_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	var letter := plane("Letter", table.position + Vector3(0, 0.922, 0), Vector2(0.65, 0.65), letter_mat, Vector2.ONE)
	letter.rotation.y = 0.2
	if distorted:
		table.rotation.z = 0.035

func guardian_spots() -> Array[Vector2]:
	return [Vector2(2.3, 10.4), Vector2(10.6, 7.0), Vector2(5.3, 3.7), Vector2(10.5, 3.3)]

func can_see(pos: Vector3) -> bool:
	var aim := pos + Vector3(0, 1.1, 0)
	var offset: Vector3 = aim - player.camera.global_position
	if (-player.global_transform.basis.z).dot(offset.normalized()) < 0.76:
		return false
	var query := PhysicsRayQueryParameters3D.create(player.camera.global_position, aim, 1)
	query.exclude = [player.get_rid(), guardian.get_rid()]
	return world.get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func update_status() -> void:
	var count: int = Story.completed_count()
	var complete: bool = Story.is_box_complete(room_id)
	UI.set_notes_count(Story.notes.size())
	sync_vitals()
	UI.status.text = Story.TITLES[room_id]
	var objective := ""
	if final_escape:
		objective = "All four memories heard. Reach the consultation doorway."
	elif unwinding:
		objective = "Turning music box %02d backward. Listen for the memory." % room_id
	elif complete:
		objective = "Memory %d / 4 recovered. Find the EXIT and press E." % room_id
		if room_id == 1:
			objective = "Memory 1 / 4 heard. Take the right passage beyond the table to the EXIT."
		elif room_id == 2:
			objective = "Memory 2 / 4 recovered. Follow the side aisle to the EXIT at the far end."
		elif room_id == 3:
			objective = "Memory 3 / 4 recovered. Turn around; the EXIT is where you entered."
		elif room_id == 4:
			objective = "4 / 4 memories heard. Cross the final door beyond the stage."
	else:
		match room_id:
			1: objective = "Follow the passage LEFT. Go around the table to MUSIC BOX 01. E to unwind."
			2: objective = "Find MUSIC BOX 02 at the near end of the long table. Press E to unwind."
			3: objective = "Find MUSIC BOX 03 behind the marked door. Press E to unwind." if memory_door_searched else "Find the door marked NOTHING HAPPENED HERE at the far end. Press E to search."
			4: objective = "Find MUSIC BOX 04 on the small stage, beside the Performer. Press E to unwind."
	UI.set_objective(objective, count)
	for note_id in note_props:
		if Story.notes.has(note_id):
			note_props[note_id].caption = "REREAD note / " + String(note_id).replace("_", " ")
	if is_instance_valid(exit_sign):
		exit_sign.text = "CONSULTATION ROOM" if final_escape else ("EXIT / CONTINUE" if complete else "EXIT / LOCKED\nUNWIND THIS ROOM'S MUSIC BOX")
		exit_sign.modulate = Color("dcff83") if complete else Color("c9aa95")
		dream_door.caption = "EXIT to the next room" if complete else "EXIT - the music box still holds this room"
	if is_instance_valid(box_sign):
		box_sign.text = "MEMORY %02d / HEARD" % room_id if complete else "MUSIC BOX %02d\nTURN THE KEY BACKWARD" % room_id

func _physics_process(delta: float) -> void:
	Game.set_chase_music(not failed and not transitioning and ((chase_remaining > 0.0 and not Game._silence_locked) or (final_escape and not ending_started)))
	var blocked := UI.busy or UI.menu_open or unwinding or scare_active or failed or UI._transition_phase != 0
	sync_vitals()
	reticle.visible = not blocked
	controls.visible = not blocked
	# Nearby players already have the E prompt; keep the close-up free of giant signage.
	box_sign.visible = not blocked and player.position.distance_to(box.position) > 3.0
	for material in materials:
		material.set_shader_parameter("floor_warp", bool(material.get_meta("floor_warp_enabled", false)) and not Game.reduced_effects and not UI.menu_open)
		material.set_shader_parameter("pulse", 0.0 if Game.reduced_effects or UI.menu_open else pulse)
		if Game.reduced_effects or UI.menu_open:
			material.set_shader_parameter("fold", 0.0)
	if UI.menu_open:
		return
	elapsed += delta
	pulse = move_toward(pulse, 0.0, delta * 0.18)
	if exploration_allowed():
		catch_grace = maxf(0.0, catch_grace - delta)
		damage_invulnerability = maxf(0.0, damage_invulnerability - delta)
		room_time_left = maxf(0.0, room_time_left - delta)
		if room_time_left <= 0:
			timeout_elapsed += delta
			if timeout_elapsed >= 5.0:
				timeout_elapsed -= 5.0
				apply_damage(15, "timeout")
		else:
			timeout_elapsed = 0.0
		if failed:
			return
		random_scare_cooldown = maxf(0.0, random_scare_cooldown - delta)
		chamber_alert_cooldown = maxf(0.0, chamber_alert_cooldown - delta)
		if room_id == 2 and chase_remaining <= 0 and chamber_alert_cooldown <= 0 and player.position.distance_to(witch.position) < 6.0 and not is_rue_protected():
			chase_remaining = 12.0
			witch.show()
			witch.animate("chomp")
			witch.actor_name.modulate = Color("ff9ccb")
			catch_grace = maxf(catch_grace, 1.0)
			Game.play_cue("rattle")
		if distraction_remaining > 0:
			distraction_remaining = maxf(0.0, distraction_remaining - delta)
			if distraction_remaining <= 0:
				guardian.animate("idle")
		if random_scare_cooldown <= 0 and random_scares_played == 0 and chase_remaining <= 0 and not Game.reduced_effects:
			trigger_scare("glimpse")
	if chase_remaining > 0 and not blocked and not transitioning and not failed:
		chase_remaining -= delta
		var chase_target: Vector3 = guardian.position if distraction_remaining > 0 else player.position
		var direction: Vector3 = chase_target - witch.position
		direction.y = 0
		if is_rue_protected():
			var away: Vector3 = witch.position - guardian.position
			away.y = 0.0
			if away.length() < 4.0:
				witch.position += away.normalized() * delta * 1.9
		elif direction.length() > 0.35:
			witch.position += direction.normalized() * delta * 1.9
		if distraction_remaining <= 0 and catch_grace <= 0 and witch.position.distance_to(player.position) < 1.1:
			trigger_scare("catch")
		if chase_remaining <= 0:
			if room_id == 2:
				witch.position = witch_home
				witch.animate("idle")
				chamber_alert_cooldown = 12.0
			else:
				witch.hide()
	if final_escape and not blocked:
		final_time += delta
		var pursuit: Vector3 = player.position - witch.position
		pursuit.y = 0
		if pursuit.length() > 0.8:
			witch.position += pursuit.normalized() * delta * 0.9
		var distance: float = player.position.distance_to(dream_door.position)
		if distance < 6.5:
			dream_door.position.z -= delta * 4.0
		for material in materials:
			material.set_shader_parameter("pulse", 0.0 if Game.reduced_effects else minf(1, final_time / 3))
			material.set_shader_parameter("fold", 0.0 if Game.reduced_effects else minf(1, final_time / 3))
		if final_time > 3 and not ending_started:
			ending_started = true
			Story.ending_choices(self)
	# Crossing a threshold requires E; moving close never consumes a room exit.

func interact(kind: String) -> void:
	if not exploration_allowed():
		return
	if kind.begins_with("note/"):
		Story.read_note(kind.trim_prefix("note/"), self)
	elif kind == "box":
		Story.activate_box(room_id, self)
	elif kind == "door":
		if Story.is_box_complete(room_id) and (room_id < 4 or Story.completed_count() == 4):
			transitioning = true
		Story.next_room(self)
	elif kind == "memory_door":
		memory_door_searched = true
		marked_door.hide()
		marked_door.collision_layer = 0
		marked_door.remove_from_group("dream_interactables")
		Game.play_cue("wind")
		update_status()
	elif kind == "animatronic":
		Game.play_cue("rattle")
		if room_id == 1 and not Story.met_performer:
			Story.performer_greeting()
		else:
			Story.performer_conversation(self)

func exploration_allowed() -> bool:
	return is_instance_valid(player) and not UI.busy and not UI.menu_open and UI._transition_phase == 0 and not unwinding and not transitioning and not final_escape and not scare_active and not failed

func is_rue_protected() -> bool:
	return is_instance_valid(player) and is_instance_valid(guardian) and player.position.distance_to(guardian.position) <= 3.0

func sync_vitals() -> void:
	var protected := is_rue_protected() and not failed and not final_escape
	UI.set_vitals(float(health), room_time_left, protected)
	if is_instance_valid(guardian):
		guardian.set_protecting(protected)

func apply_damage(amount: int, source: String = "timeout") -> bool:
	if amount <= 0 or not exploration_allowed() or is_rue_protected() or damage_invulnerability > 0:
		return false
	if source == "witch":
		return trigger_scare("catch")
	health = maxi(0, health - amount)
	damage_invulnerability = 4.0
	sync_vitals()
	if health <= 0:
		fail_room()
	return true

func fail_room() -> void:
	if failed:
		return
	failed = true
	player.input_locked = true
	player.target = null
	player.velocity = Vector3.ZERO
	UI.room_failed(Story.TITLES[room_id], retry_room)

func retry_room() -> void:
	health = 100
	room_time_left = 120.0
	timeout_elapsed = 0.0
	damage_invulnerability = 4.0
	catch_grace = 4.0
	failed = false
	scare_active = false
	transitioning = false
	chase_remaining = 0.0
	distraction_remaining = 0.0
	distract_used = false
	chamber_alert_cooldown = 8.0
	random_scare_cooldown = 30.0
	player.position = checkpoint
	player.rotation = Vector3.ZERO
	player.pitch = 0.0
	player.camera.rotation = Vector3.ZERO
	player.input_locked = false
	witch.position = witch_home
	witch.visible = room_id == 2
	witch.animate("idle")
	if room_id == 4 and Story.is_box_complete(4):
		guardian.freeze_actor()
	else:
		guardian.animate("idle")
	Story.room_unlocked = Story.is_box_complete(room_id)
	player.set_capture(true)
	update_status()

func trigger_scare(kind: String = "catch") -> bool:
	if not exploration_allowed() or (room_id == 4 and Story.is_box_complete(4)):
		return false
	if kind == "catch":
		if catch_grace > 0 or damage_invulnerability > 0 or distraction_remaining > 0 or is_rue_protected():
			return false
	elif kind == "glimpse":
		if Game.reduced_effects or random_scares_played >= 1 or random_scare_cooldown > 0:
			return false
		random_scares_played += 1
		random_scare_cooldown = 30.0
	else:
		return false
	scare_active = true
	player.input_locked = true
	player.target = null
	player.velocity = Vector3.ZERO
	UI.prompt.text = ""
	var started: bool = UI.jumpscare(kind, func(): finish_scare(kind))
	if started and kind == "catch":
		health = maxi(0, health - 25)
		damage_invulnerability = 4.0
		sync_vitals()
	if not started:
		scare_active = false
		player.input_locked = false
		if kind == "glimpse":
			random_scares_played -= 1
			random_scare_cooldown = 0.0
	return started

func finish_scare(kind: String) -> void:
	if not is_instance_valid(player):
		return
	if kind == "catch":
		catch_count += 1
		if health <= 0:
			scare_active = false
			fail_room()
			return
		player.position = checkpoint
		player.rotation = Vector3.ZERO
		player.pitch = 0.0
		player.camera.rotation = Vector3.ZERO
		witch.position = witch_home
		witch.visible = room_id == 2
		chase_remaining = 0.0
		catch_grace = 4.0
		damage_invulnerability = 4.0
		chamber_alert_cooldown = 8.0
		random_scare_cooldown = maxf(30.0, random_scare_cooldown)
	scare_active = false
	player.input_locked = false
	if not UI.menu_open and not UI.busy:
		player.set_capture(true)
	update_status()

func distract_witch() -> bool:
	if distract_used or Story.notes.is_empty() or scare_active or UI.menu_open or unwinding or transitioning or final_escape or (room_id == 4 and Story.is_box_complete(4)):
		return false
	distract_used = true
	distraction_remaining = 8.0
	catch_grace = maxf(catch_grace, 8.0)
	guardian.animate("frantic")
	Game.play_cue("rattle")
	return true

func run_unwind(_id: int) -> void:
	unwinding = true
	player.input_locked = true
	player.target = null
	player.velocity = Vector3.ZERO
	UI.prompt.text = ""
	box.begin_unwind()
	update_status()
	var saved_yaw: float = player.rotation.y
	var saved_pitch: float = player.pitch
	var saved_fov: float = player.camera.fov
	var direction: Vector3 = box.global_position - player.global_position
	player.rotation.y = atan2(-direction.x, -direction.z)
	player.camera.look_at(box.global_position + Vector3(0, 1.28, 0))
	player.pitch = player.camera.rotation.x
	var duration := 2.0
	var time := 0.0
	UI.set_unwind_progress(0.0, true)
	while time < duration:
		await get_tree().process_frame
		if UI.menu_open:
			continue
		time = minf(duration, time + get_process_delta_time())
		var progress := time / duration
		box.set_unwind_progress(progress)
		player.camera.fov = lerpf(saved_fov, 48.0, smoothstep(0.0, 0.25, progress))
		UI.set_unwind_progress(progress, true)
	box.set_unwind_progress(1.0)
	UI.set_unwind_progress(1.0, false)
	player.rotation.y = saved_yaw
	player.pitch = saved_pitch
	player.camera.rotation = Vector3(saved_pitch, 0, 0)
	player.camera.fov = saved_fov
	player.input_locked = false
	unwinding = false
	UI.set_objective("Listen to memory %d. The exit opens after the memory ends." % room_id, Story.completed_count())

func memory_changed(_id: int) -> void:
	pulse = 0.8
	for material in materials:
		material.set_shader_parameter("pulse", 0.0 if Game.reduced_effects else pulse)
	box.mark_complete()
	update_status()

func reveal_witch() -> void:
	witch.show()
	witch.animate("chomp")
	if room_id < 4:
		Game.play_cue("rattle")
	if room_id == 1 and chase_remaining <= 0:
		witch.position = player.position + Vector3(2.5, 0, -4.5)
		chase_remaining = 14.0
		catch_grace = maxf(catch_grace, 1.0)

func jerk_performer() -> void:
	guardian.animate("frantic")
	Game.play_cue("rattle")

func stop_performer() -> void:
	guardian.freeze_actor()

func silence_room() -> void:
	ambient.stop()
	stop_performer()

func face_plates() -> void:
	for plate in plates:
		plate.texture = load(V2 + "characters/ayush_grain_closed.png")
		plate.pixel_size = 0.5 / float(plate.texture.get_height())
		plate.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y

func begin_chase() -> void:
	reveal_witch()
	witch.position = player.position + Vector3(0, 0, -5)
	chase_remaining = 14.0
	catch_grace = maxf(catch_grace, 0.75)

func start_final_escape() -> void:
	final_escape = true
	final_barrier.collision_layer = 0
	plane("ImpossibleExitFloor", Vector3(8.5 * CELL, 0, -12), Vector2(3.6, 28), surface("wood"), Vector2(2, 14))
	plane("ImpossibleExitCeiling", Vector3(8.5 * CELL, HEIGHT, -12), Vector2(3.6, 28), surface("ceiling_dream"), Vector2(2, 14))
	Game.silence()
	reveal_witch()
	witch.position = player.position + Vector3(0, 0, 5)
	exit_sign.text = "CONSULTATION ROOM"
	# The destination is a separate live-looking office image inside the doorway.
	var window := Sprite3D.new()
	window.texture = load(KIT + "backgrounds/consultation_office_640x480.png")
	window.pixel_size = 0.003
	window.position = Vector3(0, 1.3, 0.15)
	window.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	dream_door.get_node("Billboard").hide()
	dream_door.add_child(window)
	update_status()

func swallow_screen() -> void:
	Game.silence()
	UI.busy = true
	UI.body.text = "The patient opens his eyes."
	var mouth := TextureRect.new()
	mouth.name = "WitchSwallowsScreen"
	mouth.texture = load(V2 + "characters/ayush_grain_open.png")
	mouth.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mouth.size = Vector2(1280, 720)
	mouth.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouth.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.add_child(mouth)
	mouth.pivot_offset = Vector2(640, 360)
	var cover := ColorRect.new()
	cover.size = Vector2(1280, 720)
	cover.color = Color.BLACK
	cover.modulate.a = 0
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.add_child(cover)
	var swallow_time := 0.0
	while swallow_time < 1.1:
		await get_tree().process_frame
		if UI.menu_open:
			continue
		swallow_time += get_process_delta_time()
		mouth.scale = Vector2.ONE * lerpf(1.0, 2.8, clampf(swallow_time / 1.1, 0, 1))
		cover.modulate.a = clampf((swallow_time - 0.7) / 0.4, 0, 1)
	mouth.queue_free()
	cover.queue_free()
	Story.finish_ending()
	Game.travel("res://scenes/Ending.tscn")

func block(parent: Node3D, node_name: String, pos: Vector3, size: Vector3, material: Material) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = node_name
	var cube := BoxMesh.new()
	cube.size = size
	mesh.mesh = cube
	mesh.material_override = material
	mesh.position = pos
	parent.add_child(mesh)

func build_box_table(box: StaticBody3D) -> void:
	var wood := surface("wood")
	block(box, "MusicBoxTable", Vector3(0, 0.78, 0), Vector3(1.1, 0.14, 0.8), wood)
	for x in [-0.42, 0.42]:
		for z in [-0.28, 0.28]:
			block(box, "Leg", Vector3(x, 0.36, z), Vector3(0.1, 0.72, 0.1), wood)

func build_altar(altar: StaticBody3D) -> void:
	var wood := surface("timber")
	block(altar, "AltarCabinet", Vector3(0, 0.42, 0), Vector3(1.2, 0.84, 0.65), wood)
	block(altar, "AltarTop", Vector3(0, 0.88, 0), Vector3(1.45, 0.12, 0.85), surface("wood"))
	for x in [-0.55, 0.55]:
		var wax := StandardMaterial3D.new()
		wax.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		wax.albedo_color = Color("c9ce79")
		block(altar, "Candle", Vector3(x, 1.15, 0.1), Vector3(0.07, 0.45, 0.07), wax)
		var flame := StandardMaterial3D.new()
		flame.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		flame.albedo_color = Color("f3b65e")
		block(altar, "Flame", Vector3(x, 1.43, 0.1), Vector3(0.045, 0.12, 0.045), flame)

func build_doorframe() -> void:
	var wood := surface("timber")
	for x in [-0.75, 0.75]:
		block(dream_door, "TimberFrame", Vector3(x, 1.35, 0.08), Vector3(0.16, 2.7, 0.25), wood)
	block(dream_door, "Lintel", Vector3(0, 2.65, 0.08), Vector3(1.65, 0.2, 0.25), wood)

func decorate_room() -> void:
	# Physical trim and separate supplied portrait/window art enrich the geometry.
	var trim := surface("timber")
	for x in [5.0, 11.9]:
		block(world, "RitualBeam", Vector3(x * CELL, HEIGHT - 0.1, 8.5 * CELL), Vector3(0.15, 0.2, 7.2), trim)
	for item in [[Vector3(3.7 * CELL, 1.55, 1.012 * CELL), "characters/ayush_grain_closed.png"], [Vector3(11.2 * CELL, 1.55, 1.012 * CELL), "characters/patient_grain_sad.png"]]:
		var frame := MeshInstance3D.new()
		frame.name = "StrangePortrait"
		var quad := QuadMesh.new()
		quad.size = Vector2(0.85, 1.15)
		frame.mesh = quad
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color("879053") if not distorted else Color("9f6a9b")
		mat.albedo_texture = load(V2 + item[1])
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		frame.material_override = mat
		frame.position = item[0]
		world.add_child(frame)
		block(world, "PortraitBack", frame.position - Vector3(0, 0, 0.025), Vector3(0.96, 1.26, 0.04), trim)

func _exit_tree() -> void:
	Game.set_chase_music(false)
	UI.set_unwind_progress(0.0, false)
	if is_instance_valid(reticle):
		reticle.queue_free()
	if is_instance_valid(controls):
		controls.queue_free()
	if is_instance_valid(ambient):
		ambient.stop()
		ambient.stream = null

func _draw() -> void:
	pass # Override the inherited top-down border; the viewport renders World.
