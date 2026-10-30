class_name DreamCharacter
extends SubViewportContainer
## A low-poly 3D character composited into the 2D dream interface.
## Call configure("performer"), configure("patient"), or configure("witch").

const FACE_PATH: String = "res://assets/characters/ayush_face.jpg"
const PHOTO_SIZE: Vector2 = Vector2(960.0, 1280.0)
const FACE_SCALE: float = 0.00315
const FACE_SPLIT_Y: float = 940.0

var _kind: String = "performer"
var _intensity: float = 0.0
var _mouth: float = 0.0
var _mouth_smooth: float = 0.0
var _gentle: bool = false
var _time: float = 0.0
var _view: SubViewport
var _world: Node3D
var _rig: Node3D
var _head: Node3D
var _jaw: Node3D
var _left_arm: Node3D
var _right_arm: Node3D
var _mouth_cavity: MeshInstance3D
var _jaw_rest: Vector3 = Vector3.ZERO
var _head_rest: Vector3 = Vector3.ZERO
var _rig_rest: Vector3 = Vector3.ZERO
var _materials: Dictionary = {}


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	stretch = true
	if size.x < 1.0 or size.y < 1.0:
		size = Vector2(256, 384)
	_build()


func configure(kind: String) -> void:
	var next_kind: String = kind if kind in ["performer", "patient", "witch"] else "performer"
	if next_kind == _kind and is_instance_valid(_view):
		return
	_kind = next_kind
	if is_inside_tree():
		_build()


func set_intensity(value: float) -> void:
	_intensity = clampf(value, 0.0, 1.0)


func set_mouth(value: float) -> void:
	_mouth = clampf(value, 0.0, 1.0)


func set_gentle(value: bool) -> void:
	_gentle = value


func _build() -> void:
	if is_instance_valid(_view):
		remove_child(_view)
		_view.queue_free()
	_head = null
	_jaw = null
	_left_arm = null
	_right_arm = null
	_mouth_cavity = null
	_materials.clear()
	_time = 0.0
	_mouth_smooth = 0.0
	_view = SubViewport.new()
	_view.name = "CharacterViewport"
	_view.size = Vector2i(256, 384)
	_view.own_world_3d = true
	_view.transparent_bg = true
	_view.handle_input_locally = false
	_view.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	_view.msaa_3d = Viewport.MSAA_DISABLED
	_view.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	add_child(_view)
	_world = Node3D.new()
	_world.name = "CharacterWorld"
	_view.add_child(_world)

	var environment_node: WorldEnvironment = WorldEnvironment.new()
	var environment: Environment = Environment.new()
	environment.background_mode = Environment.BG_CLEAR_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("c8bbdd")
	environment.ambient_light_energy = 0.65
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	environment_node.environment = environment
	_world.add_child(environment_node)

	var light: DirectionalLight3D = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-25, -25, 0)
	light.light_color = Color("fff0df")
	light.light_energy = 1.2
	light.shadow_enabled = false
	_world.add_child(light)
	var rim: DirectionalLight3D = DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-15, 150, 0)
	rim.light_color = Color("b19bff")
	rim.light_energy = 0.45
	_world.add_child(rim)

	_rig = Node3D.new()
	_rig.name = "CharacterRig"
	_world.add_child(_rig)
	match _kind:
		"witch":
			_build_witch()
		"patient":
			_build_patient()
		_:
			_build_performer()
	_rig_rest = _rig.position
	if is_instance_valid(_head):
		_head_rest = _head.position
	if is_instance_valid(_jaw):
		_jaw_rest = _jaw.position

	var camera: Camera3D = Camera3D.new()
	camera.name = "CharacterCamera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 4.40 if _kind != "witch" else 4.90
	camera.near = 0.05
	camera.far = 30.0
	_world.add_child(camera)
	camera.position = Vector3(0, 2.50 if _kind != "witch" else 1.65, 7)
	camera.look_at(Vector3(0, 1.75 if _kind != "witch" else 1.65, 0), Vector3.UP)
	camera.make_current()


func _mat(key: String, color: Color, unshaded: bool = false) -> StandardMaterial3D:
	if _materials.has(key):
		return _materials[key] as StandardMaterial3D
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	if unshaded:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_materials[key] = material
	return material


func _part(parent: Node3D, mesh: Mesh, material: Material, at: Vector3, scale_value: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var part: MeshInstance3D = MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = material
	part.position = at
	part.scale = scale_value
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(part)
	return part


func _box(parent: Node3D, material: Material, at: Vector3, dimensions: Vector3) -> MeshInstance3D:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = dimensions
	return _part(parent, mesh, material, at)


func _ball(parent: Node3D, material: Material, at: Vector3, dimensions: Vector3) -> MeshInstance3D:
	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 10
	mesh.rings = 4
	return _part(parent, mesh, material, at, dimensions)


func _round_segment(parent: Node3D, material: Material, at: Vector3, dimensions: Vector3) -> MeshInstance3D:
	var mesh: CapsuleMesh = CapsuleMesh.new()
	mesh.radius = 0.5
	mesh.height = 2.0
	mesh.radial_segments = 8
	mesh.rings = 2
	return _part(parent, mesh, material, at, Vector3(dimensions.x, dimensions.y / 2.0, dimensions.z))


func _disk(parent: Node3D, material: Material, at: Vector3, radius: float, depth: float = 0.035) -> MeshInstance3D:
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = depth
	mesh.radial_segments = 12
	var disk: MeshInstance3D = _part(parent, mesh, material, at)
	disk.rotation.x = PI / 2.0
	return disk


func _pivot(parent: Node3D, at: Vector3, part_name: String) -> Node3D:
	var pivot: Node3D = Node3D.new()
	pivot.name = part_name
	pivot.position = at
	parent.add_child(pivot)
	return pivot


func _build_performer() -> void:
	var violet: StandardMaterial3D = _mat("violet", Color("a53cfa"))
	var lavender: StandardMaterial3D = _mat("lavender", Color("c683ff"))
	var dark: StandardMaterial3D = _mat("joint", Color("24132c"))
	var black: StandardMaterial3D = _mat("black", Color("07030a"), true)
	var silver: StandardMaterial3D = _mat("silver", Color("9699aa"))
	var tooth: StandardMaterial3D = _mat("tooth", Color("d4c9e6"))

	_round_segment(_rig, violet, Vector3(0, 1.91, 0), Vector3(1.0, 1.18, 0.62))
	_box(_rig, lavender, Vector3(0, 1.95, 0.30), Vector3(0.77, 0.70, 0.10))
	_box(_rig, dark, Vector3(0, 1.49, 0.02), Vector3(0.54, 0.20, 0.35))
	_round_segment(_rig, violet, Vector3(0, 1.26, 0), Vector3(0.78, 0.42, 0.53))
	_disk(_rig, silver, Vector3(0, 1.95, 0.37), 0.14)
	for side: float in [-1.0, 1.0]:
		_ball(_rig, dark, Vector3(side * 0.27, 1.08, 0), Vector3.ONE * 0.25)
		_round_segment(_rig, violet, Vector3(side * 0.29, 0.80, 0), Vector3(0.36, 0.58, 0.37))
		_ball(_rig, silver, Vector3(side * 0.29, 0.50, 0.04), Vector3.ONE * 0.20)
		_round_segment(_rig, violet, Vector3(side * 0.29, 0.30, 0), Vector3(0.32, 0.38, 0.36))
		_box(_rig, lavender, Vector3(side * 0.29, 0.10, 0.25), Vector3(0.46, 0.22, 0.82))
		_box(_rig, dark, Vector3(side * 0.29, 0.025, 0.25), Vector3(0.47, 0.05, 0.83))

	_left_arm = _robot_arm(-1.0, violet, lavender, dark, silver)
	_right_arm = _robot_arm(1.0, violet, lavender, dark, silver)
	_round_segment(_rig, silver, Vector3(0, 2.53, 0), Vector3(0.23, 0.24, 0.23))
	_head = _pivot(_rig, Vector3(0, 2.98, 0), "RobotHead")
	_ball(_head, violet, Vector3.ZERO, Vector3(1.02, 1.05, 0.82))
	_box(_head, violet, Vector3(0, 0.02, 0.23), Vector3(0.87, 0.65, 0.34))
	for x: float in [-0.245, 0.245]:
		_disk(_head, black, Vector3(x, 0.13, 0.424), 0.155, 0.03)
		_disk(_head, tooth, Vector3(x - 0.025, 0.165, 0.445), 0.024, 0.01)
		_disk(_head, silver, Vector3(x * 1.8, -0.15, 0.34), 0.04)
	_box(_head, black, Vector3(0, -0.21, 0.432), Vector3(0.73, 0.12, 0.03))
	_jaw = _pivot(_head, Vector3(0, -0.26, 0.13), "RobotJaw")
	_round_segment(_jaw, violet, Vector3(0, -0.11, 0.12), Vector3(0.86, 0.28, 0.50))
	_box(_jaw, lavender, Vector3(0, -0.07, 0.30), Vector3(0.65, 0.13, 0.10))
	for x: float in [-0.22, -0.075, 0.075, 0.22]:
		_box(_jaw, tooth, Vector3(x, 0.005, 0.32), Vector3(0.11, 0.055, 0.05))


func _robot_arm(side: float, violet: Material, lavender: Material, dark: Material, silver: Material) -> Node3D:
	var arm: Node3D = _pivot(_rig, Vector3(side * 0.62, 2.27, 0), "LeftArm" if side < 0.0 else "RightArm")
	_ball(arm, dark, Vector3.ZERO, Vector3.ONE * 0.27)
	_round_segment(arm, violet, Vector3(side * 0.035, -0.28, 0), Vector3(0.32, 0.51, 0.34))
	_ball(arm, silver, Vector3(side * 0.04, -0.57, 0), Vector3.ONE * 0.20)
	_round_segment(arm, violet, Vector3(side * 0.05, -0.82, 0), Vector3(0.28, 0.48, 0.31))
	_box(arm, lavender, Vector3(side * 0.05, -1.12, 0.04), Vector3(0.26, 0.26, 0.31))
	for finger: int in range(3):
		_box(arm, violet, Vector3(side * 0.05 + (float(finger) - 1.0) * 0.085, -1.28, 0.055), Vector3(0.07, 0.15, 0.20))
	return arm


func _build_patient() -> void:
	var skin: StandardMaterial3D = _mat("skin", Color("c9a58a"))
	var dark_skin: StandardMaterial3D = _mat("skin_shadow", Color("aa806e"))
	var hair: StandardMaterial3D = _mat("hair", Color("201d23"))
	var olive: StandardMaterial3D = _mat("jacket", Color("2b2e34"))
	var shirt: StandardMaterial3D = _mat("shirt", Color("d0c8b2"))
	var trousers: StandardMaterial3D = _mat("trousers", Color("373b46"))
	var wood: StandardMaterial3D = _mat("chair", Color("493c3c"))
	var black: StandardMaterial3D = _mat("black", Color("17111a"), true)
	_box(_rig, wood, Vector3(0, 1.05, -0.12), Vector3(1.11, 0.15, 0.87))
	_box(_rig, wood, Vector3(0, 1.64, -0.48), Vector3(1.08, 1.10, 0.13))
	for x: float in [-0.44, 0.44]:
		for z: float in [-0.43, 0.33]:
			_box(_rig, wood, Vector3(x, 0.51, z), Vector3(0.12, 1.02, 0.12))
	_round_segment(_rig, olive, Vector3(0, 1.68, -0.03), Vector3(0.98, 1.14, 0.53))
	_box(_rig, shirt, Vector3(0, 1.86, 0.255), Vector3(0.25, 0.69, 0.035))
	for y: float in [1.58, 1.78, 1.98]:
		_disk(_rig, wood, Vector3(0.20, y, 0.30), 0.032)
	for side: float in [-1.0, 1.0]:
		var thigh: MeshInstance3D = _round_segment(_rig, trousers, Vector3(side * 0.28, 1.02, 0.25), Vector3(0.37, 0.75, 0.38))
		thigh.rotation.x = PI / 2.0
		_round_segment(_rig, trousers, Vector3(side * 0.28, 0.58, 0.58), Vector3(0.32, 0.87, 0.33))
		_box(_rig, black, Vector3(side * 0.28, 0.14, 0.72), Vector3(0.36, 0.22, 0.58))
		var arm: Node3D = _pivot(_rig, Vector3(side * 0.54, 2.01, 0.0), "PatientArm")
		_round_segment(arm, olive, Vector3(0, -0.31, 0.07), Vector3(0.28, 0.67, 0.31))
		var sleeve: MeshInstance3D = _round_segment(arm, olive, Vector3(-side * 0.09, -0.63, 0.28), Vector3(0.25, 0.55, 0.28))
		sleeve.rotation.x = -0.75
		_ball(arm, skin, Vector3(-side * 0.13, -0.82, 0.45), Vector3(0.23, 0.25, 0.28))
		if side < 0.0:
			_left_arm = arm
		else:
			_right_arm = arm
	_round_segment(_rig, skin, Vector3(0, 2.27, 0), Vector3(0.24, 0.30, 0.25))
	_head = _pivot(_rig, Vector3(0, 2.80, 0.02), "PatientPhotoHead")
	var patient_material: StandardMaterial3D = _mat("patient_photo", Color.WHITE, true)
	patient_material.albedo_texture = load("res://assets/characters/patient_face.jpg") as Texture2D
	patient_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var photo_center: Vector2 = Vector2(375, 765)
	var photo_scale: float = 0.00112
	var upper: PackedVector2Array = PackedVector2Array([
		Vector2(83, 1065), Vector2(78, 870), Vector2(82, 750),
		Vector2(48, 650), Vector2(25, 534), Vector2(28, 430),
		Vector2(102, 350), Vector2(175, 305), Vector2(250, 256),
		Vector2(344, 238), Vector2(452, 265), Vector2(560, 327),
		Vector2(620, 405), Vector2(695, 450), Vector2(724, 544),
		Vector2(697, 650), Vector2(666, 754), Vector2(668, 909), Vector2(660, 1065),
	])
	var lower: PackedVector2Array = PackedVector2Array([
		Vector2(83, 1065), Vector2(660, 1065), Vector2(620, 1170),
		Vector2(570, 1248), Vector2(512, 1275), Vector2(225, 1275),
		Vector2(148, 1211), Vector2(110, 1140),
	])
	_build_photo_piece(_head, upper, patient_material, hair, dark_skin, Vector2.ZERO, photo_scale, photo_center, 0.18, 0.34)
	_jaw = _pivot(_head, _map_photo(Vector2(375, 1065), photo_scale, photo_center, 0.18), "PatientPhotoJaw")
	_build_photo_piece(_jaw, lower, patient_material, dark_skin, dark_skin, Vector2(375, 1065), photo_scale, photo_center, 0.18, 0.34)


func _build_witch() -> void:
	_head = _pivot(_rig, Vector3(0, 1.85, 0), "PhotoHead")
	var face_texture: Texture2D = load(FACE_PATH) as Texture2D
	var face_material: StandardMaterial3D = _mat("photo", Color.WHITE, true)
	face_material.albedo_texture = face_texture
	face_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var hair: StandardMaterial3D = _mat("photo_hair", Color("19171d"))
	var skin: StandardMaterial3D = _mat("photo_side", Color("a75e58"))
	var black: StandardMaterial3D = _mat("mouth_inside", Color("08000d"), true)
	var upper: PackedVector2Array = PackedVector2Array([
		Vector2(255, 940), Vector2(225, 815), Vector2(224, 667),
		Vector2(200, 565), Vector2(150, 469), Vector2(192, 350),
		Vector2(280, 245), Vector2(390, 178), Vector2(507, 142),
		Vector2(650, 145), Vector2(775, 220), Vector2(860, 345),
		Vector2(888, 470), Vector2(870, 575), Vector2(825, 670),
		Vector2(809, 813), Vector2(790, 940),
	])
	# Correct cheek cut: upper head and lower jaw share the same photo edge.
	upper[0] = Vector2(255, FACE_SPLIT_Y)
	var lower: PackedVector2Array = PackedVector2Array([
		Vector2(255, FACE_SPLIT_Y), Vector2(790, FACE_SPLIT_Y),
		Vector2(760, 1018), Vector2(680, 1096), Vector2(564, 1142),
		Vector2(433, 1142), Vector2(335, 1080), Vector2(285, 1010),
	])
	_build_photo_piece(_head, upper, face_material, hair, skin, Vector2.ZERO)
	var split_local: Vector3 = _photo_point(Vector2(480, FACE_SPLIT_Y))
	_jaw = _pivot(_head, split_local, "HingedPhotoJaw")
	_build_photo_piece(_jaw, lower, face_material, skin, skin, Vector2(480, FACE_SPLIT_Y))
	_mouth_cavity = _box(_head, black, split_local + Vector3(0, -0.40, -0.55), Vector3(1.65, 0.80, 0.50))
	_mouth_cavity.visible = false


func _photo_point(point: Vector2) -> Vector3:
	return _map_photo(point, FACE_SCALE, Vector2(480, 650), 0.33)


func _map_photo(point: Vector2, factor: float, center: Vector2, depth: float) -> Vector3:
	return Vector3((point.x - center.x) * factor, (center.y - point.y) * factor, depth)


func _build_photo_piece(parent: Node3D, polygon: PackedVector2Array, photo: Material, upper_side: Material, lower_side: Material, photo_pivot: Vector2, factor: float = FACE_SCALE, center: Vector2 = Vector2(480, 650), front_depth: float = 0.33, thickness: float = 0.68) -> void:
	var positions: PackedVector3Array = PackedVector3Array()
	var uvs: PackedVector2Array = PackedVector2Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var origin: Vector3 = Vector3.ZERO if photo_pivot == Vector2.ZERO else _map_photo(photo_pivot, factor, center, front_depth)
	for point: Vector2 in polygon:
		positions.append(_map_photo(point, factor, center, front_depth) - origin)
		uvs.append(point / PHOTO_SIZE)
		normals.append(Vector3.FORWARD)
	var indices: PackedInt32Array = Geometry2D.triangulate_polygon(polygon)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = positions
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_part(parent, mesh, photo, Vector3.ZERO)
	# Side faces give the photograph an actual thick, faceted 3D silhouette.
	for i: int in range(polygon.size()):
		var next: int = (i + 1) % polygon.size()
		var front_a: Vector3 = positions[i]
		var front_b: Vector3 = positions[next]
		var back_a: Vector3 = front_a - Vector3(0, 0, thickness)
		var back_b: Vector3 = front_b - Vector3(0, 0, thickness)
		var side_arrays: Array = []
		side_arrays.resize(Mesh.ARRAY_MAX)
		side_arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([front_a, front_b, back_b, front_a, back_b, back_a])
		var side_normal: Vector3 = (front_b - front_a).cross(back_a - front_a).normalized()
		side_arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array([side_normal, side_normal, side_normal, side_normal, side_normal, side_normal])
		var side_mesh: ArrayMesh = ArrayMesh.new()
		side_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, side_arrays)
		var side_mat: Material = upper_side if (polygon[i].y + polygon[next].y) * 0.5 < 590.0 else lower_side
		_part(parent, side_mesh, side_mat, Vector3.ZERO)
	# A back plate closes the silhouette even during head turns.
	var back_positions: PackedVector3Array = PackedVector3Array()
	for point: Vector3 in positions:
		back_positions.append(point - Vector3(0, 0, thickness))
	var back_arrays: Array = []
	back_arrays.resize(Mesh.ARRAY_MAX)
	back_arrays[Mesh.ARRAY_VERTEX] = back_positions
	back_arrays[Mesh.ARRAY_INDEX] = indices
	var back_mesh: ArrayMesh = ArrayMesh.new()
	back_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, back_arrays)
	_part(parent, back_mesh, upper_side, Vector3.ZERO)


func _process(delta: float) -> void:
	if not is_instance_valid(_rig) or not is_instance_valid(_head):
		return
	_time += delta
	var movement: float = 0.0 if _gentle else 1.0
	var agitation: float = _intensity * movement
	var speech: float = _mouth
	if _kind == "performer":
		speech = maxf(speech, absf(sin(_time * 18.0)) * agitation * 0.78)
	_mouth_smooth = move_toward(_mouth_smooth, speech, delta * 6.0)
	match _kind:
		"witch":
			_rig.position = _rig_rest + Vector3(sin(_time * 0.8) * 0.05, sin(_time * 1.1) * 0.08, 0) * movement
			_head.rotation = Vector3(sin(_time * 1.3) * 0.025, sin(_time * 0.7) * (0.09 + agitation * 0.08), sin(_time * 1.4) * 0.03) * movement
			_jaw.position = _jaw_rest + Vector3(0, -_mouth_smooth * 0.52, _mouth_smooth * 0.10)
			_jaw.rotation.x = -_mouth_smooth * 0.72
			_mouth_cavity.visible = _mouth_smooth > 0.025
			_mouth_cavity.scale.y = maxf(0.05, _mouth_smooth)
		"patient":
			_rig.position = _rig_rest + Vector3(0, sin(_time * 1.3) * 0.008 * movement, 0)
			_head.rotation = Vector3(0.045, sin(_time * 0.32) * 0.05 * movement, -0.035)
			_jaw.rotation.x = -_mouth_smooth * 0.08
			_jaw.position = _jaw_rest + Vector3(0, -_mouth_smooth * 0.018, 0)
		_:
			var tick: float = floorf(_time * 13.0) / 13.0
			_rig.position = _rig_rest + Vector3(sin(tick * 53.0) * agitation * 0.04, absf(sin(_time * 9.0)) * agitation * 0.08, 0)
			_rig.rotation.z = sin(tick * 19.0) * agitation * 0.035
			_head.rotation = Vector3(sin(tick * 21.0) * agitation * 0.15, sin(_time * 0.6) * 0.06 * movement + sin(tick * 17.0) * agitation * 0.20, sin(tick * 29.0) * agitation * 0.09)
			_left_arm.rotation = Vector3(-0.10 - absf(sin(tick * 12.0)) * agitation * 1.35, 0, 0.10 + sin(tick * 9.0) * agitation * 0.45)
			_right_arm.rotation = Vector3(-0.10 - absf(cos(tick * 11.0)) * agitation * 1.35, 0, -0.10 + cos(tick * 13.0) * agitation * 0.45)
			_jaw.position = _jaw_rest + Vector3(0, -_mouth_smooth * 0.12, 0)
			_jaw.rotation.x = -_mouth_smooth * 0.65
