extends StaticBody3D
## PNG actors and a real rotating key, rendered inside the physical cabin.
const V2 := "res://assets/replacements_v2/"
var kind := ""
var caption := ""
var footprint := Vector2(0.8, 0.65)
var art_height := 1.8
var distorted := false
var box_id := 0
var completely_still := false
var interaction_enabled := true
var interaction_height := 1.15
var actor_animation := "idle"
var actor_clock := 0.0
var sprite: Sprite3D
var visual_pivot: Node3D
var winding_key: Node3D
var closed_texture: Texture2D
var open_texture: Texture2D
var sprite_home := Vector3.ZERO
var unwind_progress := 0.0
var unwinding := false
var opened := false
var note_id := ""
var actor_name: Label3D
var ears: Node3D
var ears_home := Vector3(0, 2.42, -0.035)
var body_rig: Node3D
var left_arm: Node3D
var right_arm: Node3D
var shield_ring: MeshInstance3D
var shielding := false
signal activated(kind: String)

func _ready() -> void:
	collision_layer = 1
	collision_mask = 2
	var shape := CollisionShape3D.new()
	shape.name = "CollisionShape3D"
	var bounds := BoxShape3D.new()
	bounds.size = Vector3(footprint.x, 1.0, footprint.y)
	shape.shape = bounds
	shape.position.y = 0.5
	add_child(shape)
	if not caption.is_empty():
		add_to_group("dream_interactables")
	if kind == "table":
		return
	visual_pivot = Node3D.new()
	visual_pivot.name = "ModelPivot"
	add_child(visual_pivot)
	sprite = Sprite3D.new()
	sprite.name = "Billboard"
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.alpha_scissor_threshold = 0.2
	sprite.shaded = false
	sprite.double_sided = true
	if kind in ["animatronic", "witch", "altar"]:
		var is_performer := kind == "animatronic"
		closed_texture = load(V2 + "characters/" + ("purple_performer_head.png" if is_performer else "ayush_grain_closed.png"))
		open_texture = closed_texture if is_performer else load(V2 + "characters/ayush_grain_open.png")
		sprite.texture = closed_texture
		var head_height := 1.3 if is_performer else (0.85 if kind == "altar" else 1.8)
		sprite.pixel_size = head_height / float(sprite.texture.get_height())
		sprite.position.y = 1.65 if is_performer else 1.55
		interaction_height = sprite.position.y
		sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		visual_pivot.add_child(sprite)
		build_actor_name("RUE" if is_performer else "AYUSH")
		if is_performer:
			build_teddy_body()
			build_bunny_ears()
	elif kind == "box":
		closed_texture = load(V2 + "props/music_box_closed.png")
		open_texture = load(V2 + "props/music_box_open.png")
		sprite.texture = closed_texture
		sprite.pixel_size = 1.12 / float(sprite.texture.get_height())
		sprite.position.y = 1.28
		interaction_height = 1.25
		visual_pivot.add_child(sprite)
		build_winding_key()
	elif kind == "note":
		sprite.texture = load("res://assets/first_person/letter.png")
		sprite.pixel_size = 0.5 / float(sprite.texture.get_height())
		sprite.position.y = 1.12
		interaction_height = 1.12
		sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		visual_pivot.add_child(sprite)
	else:
		sprite.texture = load("res://assets/fever_dreams/textures/cabin/kenney_door_wood.png")
		sprite.pixel_size = art_height / float(sprite.texture.get_height())
		sprite.position.y = art_height / 2.0
		add_child(sprite) # Final doorway overlay expects this direct child.
	sprite_home = sprite.position

func build_actor_name(display_name: String) -> void:
	actor_name = Label3D.new()
	actor_name.name = "ActorName"
	actor_name.text = display_name
	actor_name.font = load(V2 + "ui/fonts/DotGothic16-Regular.ttf")
	actor_name.font_size = 48
	actor_name.pixel_size = 0.008
	actor_name.outline_size = 2
	actor_name.position = Vector3(0, 0.8, 0.3) if kind == "animatronic" else Vector3(0, 0.45, 0)
	actor_name.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	actor_name.modulate = Color("e6dc91") if kind == "animatronic" else Color("e2a7e2")
	visual_pivot.add_child(actor_name)

func body_block(parent: Node3D, part_name: String, at: Vector3, dimensions: Vector3, material: Material) -> void:
	var part := MeshInstance3D.new()
	part.name = part_name
	var shape := BoxMesh.new()
	shape.size = dimensions
	part.mesh = shape
	part.position = at
	part.material_override = material
	parent.add_child(part)

func build_teddy_body() -> void:
	body_rig = Node3D.new()
	body_rig.name = "TeddyBody"
	visual_pivot.add_child(body_rig)
	var violet := StandardMaterial3D.new()
	violet.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	violet.albedo_color = Color("8820b9")
	var plum := StandardMaterial3D.new()
	plum.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	plum.albedo_color = Color("4c2463")
	var fabric := StandardMaterial3D.new()
	fabric.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fabric.albedo_color = Color("b995b5")
	body_block(body_rig, "SoftSquareChest", Vector3(0, 0.76, -0.06), Vector3(0.68, 0.62, 0.36), violet)
	body_block(body_rig, "MendedBelly", Vector3(0, 0.75, 0.131), Vector3(0.4, 0.37, 0.035), fabric)
	body_block(body_rig, "HipJoint", Vector3(0, 0.43, -0.04), Vector3(0.52, 0.17, 0.3), plum)
	for side in [-1.0, 1.0]:
		body_block(body_rig, "Leg", Vector3(side * 0.19, 0.26, -0.04), Vector3(0.22, 0.35, 0.24), violet)
		body_block(body_rig, "TeddyFoot", Vector3(side * 0.19, 0.08, 0.035), Vector3(0.3, 0.16, 0.4), plum)
		var arm := Node3D.new()
		arm.name = "LeftArm" if side < 0 else "RightArm"
		arm.position = Vector3(side * 0.44, 1.0, -0.04)
		body_rig.add_child(arm)
		body_block(arm, "Arm", Vector3(0, -0.22, 0), Vector3(0.2, 0.45, 0.26), violet)
		body_block(arm, "Paw", Vector3(0, -0.48, 0.02), Vector3(0.25, 0.21, 0.28), fabric)
		if side < 0:
			left_arm = arm
		else:
			right_arm = arm
	shield_ring = MeshInstance3D.new()
	shield_ring.name = "RueProtectionRing"
	var ring := TorusMesh.new()
	ring.inner_radius = 2.94
	ring.outer_radius = 3.0
	ring.rings = 24
	ring.ring_segments = 4
	shield_ring.mesh = ring
	shield_ring.position.y = 0.045
	var ward := StandardMaterial3D.new()
	ward.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ward.albedo_color = Color("d4b9ef")
	shield_ring.material_override = ward
	add_child(shield_ring)
	shield_ring.hide()

func set_protecting(value: bool) -> void:
	shielding = value
	if is_instance_valid(shield_ring):
		shield_ring.visible = value
	if is_instance_valid(actor_name) and kind == "animatronic":
		actor_name.modulate = Color("bfffd5") if value else Color("e6dc91")

func build_bunny_ears() -> void:
	ears = Node3D.new()
	ears.name = "BunnyEars"
	ears.position = ears_home
	visual_pivot.add_child(ears)
	var violet := StandardMaterial3D.new()
	violet.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	violet.albedo_color = Color("9d14c9")
	var inner := StandardMaterial3D.new()
	inner.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	inner.albedo_color = Color("ec64db")
	for side in [-1.0, 1.0]:
		var ear := MeshInstance3D.new()
		ear.name = "LeftEar" if side < 0 else "RightEar"
		var shell := CylinderMesh.new()
		shell.top_radius = 0.065
		shell.bottom_radius = 0.115
		shell.height = 0.58
		shell.radial_segments = 5
		shell.rings = 1
		ear.mesh = shell
		ear.position.x = side * 0.27
		ear.rotation.z = side * -0.17
		ear.material_override = violet
		ears.add_child(ear)
		var inset := MeshInstance3D.new()
		var center := BoxMesh.new()
		center.size = Vector3(0.065, 0.41, 0.025)
		inset.mesh = center
		inset.position.z = 0.10
		inset.material_override = inner
		ear.add_child(inset)

func build_winding_key() -> void:
	winding_key = Node3D.new()
	winding_key.name = "BackwardWindingKey"
	winding_key.position = Vector3(0.44, 1.17, 0.035)
	visual_pivot.add_child(winding_key)
	var brass := StandardMaterial3D.new()
	brass.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	brass.albedo_color = Color("e7c855")
	for offset in [-0.09, 0.09]:
		var loop := MeshInstance3D.new()
		loop.name = "KeyLoop"
		var ring := TorusMesh.new()
		ring.inner_radius = 0.035
		ring.outer_radius = 0.075
		ring.rings = 8
		ring.ring_segments = 4
		loop.mesh = ring
		loop.rotation.x = PI / 2.0
		loop.position.y = offset
		loop.material_override = brass
		winding_key.add_child(loop)
	var shaft := MeshInstance3D.new()
	shaft.name = "KeyShaft"
	var rod := BoxMesh.new()
	rod.size = Vector3(0.035, 0.18, 0.04)
	shaft.mesh = rod
	shaft.material_override = brass
	winding_key.add_child(shaft)
	winding_key.hide()

func _process(delta: float) -> void:
	if UI.menu_open or not is_instance_valid(sprite):
		return
	if kind in ["box", "animatronic"]:
		var camera := get_viewport().get_camera_3d()
		if is_instance_valid(camera):
			var direction := camera.global_position - global_position
			visual_pivot.rotation.y = atan2(direction.x, direction.z)
		if kind == "box":
			return
	if kind not in ["animatronic", "witch", "altar"] or completely_still:
		return
	actor_clock += delta
	var frantic := actor_animation == "frantic"
	var amplitude := 0.16 if frantic else 0.055
	var speed := 21.0 if frantic else 2.1
	if Game.reduced_effects:
		amplitude *= 0.15
		speed = 2.1
	sprite.position = sprite_home + Vector3(sin(actor_clock * speed * 0.7) * amplitude, sin(actor_clock * speed) * amplitude, 0)
	sprite.rotation.z = sin(actor_clock * speed * 0.85) * (0.0 if Game.reduced_effects else (0.18 if frantic else 0.035))
	var squash := 1.0 + sin(actor_clock * speed * 1.4) * (0.0 if Game.reduced_effects else (0.09 if frantic else 0.015))
	sprite.scale = Vector3(1.0 / squash, squash, 1.0)
	if is_instance_valid(ears):
		ears.position = ears_home + sprite.position - sprite_home
		ears.rotation.z = sprite.rotation.z
	if is_instance_valid(left_arm):
		left_arm.rotation.z = -0.15 + sin(actor_clock * speed) * (0.35 if frantic else 0.06)
		right_arm.rotation.z = 0.15 - sin(actor_clock * speed + 0.6) * (0.35 if frantic else 0.06)
	if actor_animation == "chomp":
		sprite.texture = open_texture if fmod(actor_clock, 0.72) < 0.37 else closed_texture
		sprite.scale.y *= 1.08 if sprite.texture == open_texture else 1.0

func begin_unwind() -> void:
	unwinding = true
	interaction_enabled = false
	caption = "Unwinding..."
	winding_key.show()
	set_unwind_progress(0.0)

func set_unwind_progress(value: float) -> void:
	unwind_progress = clampf(value, 0.0, 1.0)
	# Backward revolutions slow toward the final note.
	winding_key.rotation.z = TAU * 4.0 * (1.0 - pow(1.0 - unwind_progress, 1.6))
	sprite.texture = open_texture if unwind_progress > 0.12 else closed_texture
	sprite.position = sprite_home + Vector3(sin(unwind_progress * 48.0) * 0.012 * (1.0 - unwind_progress), 0, 0)
	if unwind_progress >= 1.0:
		unwinding = false
		opened = true
		sprite.position = sprite_home
		winding_key.hide()

func mark_complete() -> void:
	opened = true
	interaction_enabled = false
	sprite.texture = open_texture
	caption = "Memory recovered"
	remove_from_group("dream_interactables")

func interact() -> void:
	if interaction_enabled and not UI.busy and not UI.menu_open:
		activated.emit("note/" + note_id if kind == "note" else kind)

func animate(animation_name: String) -> void:
	actor_animation = animation_name
	actor_clock = 0.0
	completely_still = false

func freeze_actor() -> void:
	completely_still = true
