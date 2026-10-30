extends StaticBody3D

var kind := ""
var caption := ""
var footprint := Vector2(0.8, 0.65)
var art_height := 1.8
var distorted := false
var box_id := 0
var completely_still := false
signal activated(kind: String)

func _ready() -> void:
	collision_layer = 1
	collision_mask = 2
	var shape := CollisionShape3D.new()
	shape.name = "CollisionShape3D"
	var box := BoxShape3D.new()
	box.size = Vector3(footprint.x, 1.0, footprint.y)
	shape.shape = box
	shape.position.y = 0.5
	add_child(shape)
	if not caption.is_empty():
		add_to_group("dream_interactables")
	if kind == "animatronic":
		install_model("performer", art_height, 0.0)
	elif kind == "altar":
		install_model("ayush_witch", 0.85, 1.15)
	elif kind == "witch":
		install_model("ayush_witch", 1.7, 0.7)
	elif kind != "table":
		var sprite := Sprite3D.new()
		sprite.name = "Billboard"
		sprite.texture = load("res://assets/fever_dreams/props/music_box_cutout.png" if kind == "box" else "res://assets/fever_dreams/textures/cabin/kenney_door_wood.png")
		var visible_height := 0.85 if kind == "box" else art_height
		sprite.pixel_size = visible_height / float(sprite.texture.get_height())
		sprite.position.y = 0.85 + visible_height / 2.0 if kind == "box" else visible_height / 2.0
		sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y if kind == "box" else BaseMaterial3D.BILLBOARD_DISABLED
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		sprite.no_depth_test = false
		sprite.shaded = false
		if distorted:
			sprite.modulate = Color(1.0, 0.7, 0.94)
		add_child(sprite)

func install_model(model_name: String, height: float, base_y: float) -> void:
	var pivot := Node3D.new()
	pivot.name = "ModelPivot"
	add_child(pivot)
	var packed: PackedScene = load("res://assets/fever_dreams/characters/models/" + model_name + ".glb")
	var model: Node3D = packed.instantiate()
	model.name = "SuppliedModel"
	pivot.add_child(model)
	var bounds := AABB()
	var first := true
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh_node: MeshInstance3D = node
		var relative: Transform3D = model.global_transform.affine_inverse() * mesh_node.global_transform
		var mesh_bounds: AABB = relative * mesh_node.get_aabb()
		bounds = mesh_bounds if first else bounds.merge(mesh_bounds)
		first = false
		for index in range(mesh_node.mesh.get_surface_count()):
			var material = mesh_node.get_active_material(index)
			if material is StandardMaterial3D:
				material = material.duplicate()
				material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
				mesh_node.set_surface_override_material(index, material)
	var factor := height / maxf(bounds.size.y, 0.01)
	model.scale = Vector3.ONE * factor
	model.position = Vector3(-bounds.get_center().x * factor, base_y - bounds.position.y * factor, -bounds.get_center().z * factor)
	for animator in model.find_children("*", "AnimationPlayer", true, false):
		if animator.has_animation("idle"):
			animator.get_animation("idle").loop_mode = Animation.LOOP_LINEAR
			animator.play("idle")

func _process(_delta: float) -> void:
	if kind in ["animatronic", "witch"] and not completely_still and has_node("ModelPivot"):
		var camera := get_viewport().get_camera_3d()
		if is_instance_valid(camera):
			var direction := camera.global_position - global_position
			get_node("ModelPivot").rotation.y = atan2(direction.x, direction.z)

func interact() -> void:
	activated.emit(kind)

func animate(animation_name: String) -> void:
	completely_still = false
	for animator in find_children("*", "AnimationPlayer", true, false):
		if animator.has_animation(animation_name):
			if animation_name == "chomp":
				animator.get_animation(animation_name).loop_mode = Animation.LOOP_LINEAR
			animator.play(animation_name)

func freeze_actor() -> void:
	completely_still = true
	for animator in find_children("*", "AnimationPlayer", true, false):
		animator.pause()
