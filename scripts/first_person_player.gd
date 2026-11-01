extends CharacterBody3D

const SPEED := 3.1
const TURN_SPEED := 1.8
var camera: Camera3D
var target: Node3D
var footsteps := 0.0
var mouse_captured := true
@export var mouse_sensitivity := 0.0028
var pitch := 0.0
var input_locked := false

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.24
	capsule.height = 1.5
	collision.shape = capsule
	collision.position.y = 0.75
	add_child(collision)
	camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.position.y = 1.22
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	# Godot's KEEP_HEIGHT keeps horizontal FOV, even at a widescreen aspect.
	camera.fov = 70.0
	camera.near = 0.05
	camera.far = 55.0
	add_child(camera)
	camera.current = true
	Game.active_player = self
	set_capture(true)

func set_capture(captured: bool) -> void:
	mouse_captured = captured and not UI.menu_open
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if mouse_captured else Input.MOUSE_MODE_VISIBLE

func input_blocked() -> bool:
	return UI.busy or UI.menu_open or input_locked or UI._transition_phase != 0

func _exit_tree() -> void:
	if Game.active_player == self:
		Game.active_player = null
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func handle_input(event: InputEvent) -> void:
	if input_blocked():
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and not event.echo:
		set_capture(false)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		set_capture(true)
	elif event is InputEventMouseMotion and mouse_captured:
		rotate_y(-event.relative.x * mouse_sensitivity)
		pitch = clampf(pitch - event.relative.y * mouse_sensitivity, deg_to_rad(-80.0), deg_to_rad(80.0))
		camera.rotation = Vector3(pitch, 0, 0)

func _physics_process(delta: float) -> void:
	velocity = Vector3.ZERO
	if input_blocked():
		target = null
		UI.prompt.text = ""
		return
	if mouse_captured:
		var axes := Input.get_vector("strafe_left", "strafe_right", "forward", "back")
		velocity = (transform.basis * Vector3(axes.x, 0.0, axes.y)) * SPEED
		var turn := float(Input.is_physical_key_pressed(KEY_Q)) - float(Input.is_physical_key_pressed(KEY_C))
		if Input.is_physical_key_pressed(KEY_LEFT):
			turn += 1.0
		if Input.is_physical_key_pressed(KEY_RIGHT):
			turn -= 1.0
		rotate_y(turn * TURN_SPEED * delta)
	move_and_slide()
	if velocity.length() > 0.1:
		footsteps += delta * 9.0
	camera.position.y = 1.22 + (sin(footsteps) * 0.018 if velocity.length() > 0.1 else 0.0)
	find_target()

func find_target() -> void:
	target = null
	if input_blocked() or not mouse_captured:
		UI.prompt.text = ""
		return
	var best := 2.65
	var forward := -camera.global_transform.basis.z
	for object in get_tree().get_nodes_in_group("dream_interactables"):
		if not object is Node3D or not object.is_visible_in_tree() or not object.interaction_enabled:
			continue
		var aim: Vector3 = object.global_position + Vector3.UP * object.interaction_height
		var offset: Vector3 = aim - camera.global_position
		var distance := offset.length()
		if distance < best and distance > 0.05 and forward.dot(offset / distance) > 0.82:
			var query := PhysicsRayQueryParameters3D.create(camera.global_position, aim, 1)
			query.exclude = [get_rid()]
			var hit := get_world_3d().direct_space_state.intersect_ray(query)
			if hit.is_empty() or hit.collider == object:
				target = object
				best = distance
	UI.prompt.text = "[E] " + target.caption if is_instance_valid(target) else ""

func use_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not event.is_echo() and not input_blocked() and mouse_captured and is_instance_valid(target):
		target.interact()
		get_viewport().set_input_as_handled()
