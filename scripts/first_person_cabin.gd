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
	reticle = UI.label(Vector2(630, 342), Vector2(20, 32), 26)
	reticle.text = "+"
	reticle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls = UI.label(Vector2(32, 678), Vector2(1216, 32), 22)
	controls.text = "WASD move   MOUSE / Q C turn   E use   ESC cursor"
	controls.modulate = Color("b7a77d")
	ambient = AudioStreamPlayer.new()
	ambient.name = "DreamAmbience"
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
	sign.text = text
	sign.font_size = size
	sign.pixel_size = 0.008
	sign.position = pos
	sign.no_depth_test = false
	sign.modulate = Color("f7ed9c")
	world.add_child(sign)
	return sign

func build_story_objects() -> void:
	var box_spot := Vector2(8.3, 8.5)
	var performer_spot := Vector2(10.6, 7.0)
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
		performer_spot = Vector2(8.5, 7.3)
		exit_spot = Vector2(8.5, 2.0)
	box = make_prop("box", box_spot, Vector2(0.85, 0.65), 1.55, "Unwind music box %d" % room_id)
	box.box_id = room_id
	if room_id != 4:
		build_box_table(box)
	guardian = make_prop("animatronic", performer_spot, Vector2(0.7, 0.6), 2.2, "Speak to the Performer")
	witch = make_prop("witch", Vector2(8.5, 2.2), Vector2(0.6, 0.3), 1.7, "")
	witch.hide()
	witch.collision_layer = 0
	dream_door = make_prop("door", exit_spot, Vector2(1.2, 0.22), 2.65, "Open the exit")
	if room_id == 3:
		dream_door.rotation.y = PI
	build_doorframe()
	exit_sign = sign_at("PLEASE LEAVE AS YOU ARRIVED.", dream_door.position + Vector3(0, 2.78, 0.2), 24)
	if room_id == 1:
		var table := make_prop("table", Vector2(8.3, 10.2), Vector2(2.35, 1.1), 1, "")
		build_table(table)
		decorate_room()
	elif room_id == 2:
		build_dining_room()
	elif room_id == 3:
		build_school_hall()
	else:
		build_theatre()

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
			plate.texture = load(KIT + "props/music_box_cutout.png")
			plate.pixel_size = 0.35 / 1492.0
			plate.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
			plate.position = Vector3(x * CELL, 1.08, z * CELL)
			plate.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			world.add_child(plate)
			plates.append(plate)
	seat_performer()

func build_school_hall() -> void:
	marked_door = make_prop("memory_door", Vector2(8.5, 5.0), Vector2(1.2, 0.22), 2.65, "Open: NOTHING HAPPENED HERE")
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

func seat_performer() -> void:
	guardian.freeze_actor()
	var wood := surface("wood")
	block(guardian, "PerformerChair", Vector3(0, 0.5, 0), Vector3(0.8, 0.12, 0.65), wood)
	block(guardian, "ChairBack", Vector3(0, 0.9, -0.3), Vector3(0.8, 0.9, 0.1), wood)
	# The tabletop/stage hides the lower limbs; the stopped pose reads as seated.
	guardian.get_node("ModelPivot").position.y = -0.32

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
	UI.status.text = Story.TITLES[room_id] + "    BOXES %d / 4" % Story.boxes.values().count("complete")
	if is_instance_valid(exit_sign):
		if room_id == 1:
			exit_sign.text = "PLEASE LEAVE AS YOU ARE TOLD." if Story.boxes.has(1) and Story.boxes[1] == "complete" else "PLEASE LEAVE AS YOU ARRIVED."
		else:
			exit_sign.text = "EXIT / CONTINUE" if Story.room_unlocked else "THE SONG IS NOT FINISHED"

func _physics_process(delta: float) -> void:
	elapsed += delta
	reticle.visible = not UI.busy
	controls.visible = not UI.busy
	if chase_remaining > 0 and not UI.busy:
		chase_remaining -= delta
		var direction: Vector3 = player.position - witch.position
		direction.y = 0
		if direction.length() > 1.5:
			witch.position += direction.normalized() * delta * 1.1
		if chase_remaining <= 0:
			witch.hide()
	if final_escape:
		final_time += delta
		var pursuit: Vector3 = player.position - witch.position
		pursuit.y = 0
		if pursuit.length() > 0.8:
			witch.position += pursuit.normalized() * delta * 0.9
		var distance: float = player.position.distance_to(dream_door.position)
		if distance < 6.5:
			dream_door.position.z -= delta * 4.0
		for material in materials:
			material.set_shader_parameter("pulse", minf(1, final_time / 3))
			material.set_shader_parameter("fold", minf(1, final_time / 3))
		if final_time > 3 and not ending_started:
			ending_started = true
			Story.ending_choices(self)
	elif not UI.busy and not transitioning and elapsed > 2 and player.position.distance_to(dream_door.position) < 1.15 and Story.room_unlocked:
		interact("door")

func interact(kind: String) -> void:
	if kind == "box":
		Story.activate_box(room_id, self)
	elif kind == "door":
		if not transitioning:
			if Story.room_unlocked:
				transitioning = true
			Story.next_room(self)
	elif kind == "memory_door":
		marked_door.hide()
		marked_door.collision_layer = 0
		marked_door.remove_from_group("dream_interactables")
	elif kind == "animatronic":
		Game.play_cue("rattle")
		if room_id == 1 and not Story.met_performer:
			Story.performer_greeting()
		else:
			UI.say(["PERFORMER: I only knew one song." if room_id == 4 else "PERFORMER: You look happy."], update_status)

func memory_changed(_id: int) -> void:
	pulse = 0.8
	for material in materials:
		material.set_shader_parameter("pulse", pulse)
	box.caption = "The music box is unwound"
	update_status()

func reveal_witch() -> void:
	witch.show()
	witch.animate("chomp")
	Game.play_cue("rattle")

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
		plate.texture = load(KIT + "characters/ayush_witch/witch_closed.png")

func begin_chase() -> void:
	reveal_witch()
	witch.position = player.position + Vector3(0, 0, -5)
	chase_remaining = 8.0

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

func swallow_screen() -> void:
	Game.silence()
	UI.busy = true
	UI.body.text = "The patient opens his eyes."
	var mouth := TextureRect.new()
	mouth.name = "WitchSwallowsScreen"
	mouth.texture = load(KIT + "characters/ayush_witch/witch_open.png")
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
	var swallow := create_tween().set_parallel(true)
	swallow.tween_property(mouth, "scale", Vector2.ONE * 2.8, 1.1)
	swallow.tween_property(cover, "modulate:a", 1.0, 0.4).set_delay(0.7)
	await swallow.finished
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
	for item in [[Vector3(3.7 * CELL, 1.55, 1.012 * CELL), "characters/ayush_witch/witch_closed.png"], [Vector3(11.2 * CELL, 1.55, 1.012 * CELL), "characters/patient/patient_idle.png"]]:
		var frame := MeshInstance3D.new()
		frame.name = "StrangePortrait"
		var quad := QuadMesh.new()
		quad.size = Vector2(0.85, 1.15)
		frame.mesh = quad
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color("879053") if not distorted else Color("9f6a9b")
		mat.albedo_texture = load(KIT + item[1])
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		frame.material_override = mat
		frame.position = item[0]
		world.add_child(frame)
		block(world, "PortraitBack", frame.position - Vector3(0, 0, 0.025), Vector3(0.96, 1.26, 0.04), trim)

func _exit_tree() -> void:
	if is_instance_valid(reticle):
		reticle.queue_free()
	if is_instance_valid(controls):
		controls.queue_free()
	if is_instance_valid(ambient):
		ambient.stop()
		ambient.stream = null

func _draw() -> void:
	pass # Override the inherited top-down border; the viewport renders World.
