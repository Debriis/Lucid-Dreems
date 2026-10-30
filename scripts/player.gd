extends CharacterBody2D

const SPEED := 90.0
var facing := Vector2.DOWN
var stride := 0.0
var target: Node2D

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(9, 6)
	shape.shape = rectangle
	shape.position = Vector2(0, -3)
	add_child(shape)
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.position = Vector2(0, -12)
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 320
	camera.limit_bottom = 240
	add_child(camera)

func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("left", "right", "up", "down") if not UI.busy else Vector2.ZERO
	velocity = direction * SPEED
	if direction != Vector2.ZERO:
		facing = direction
		stride += delta * 12.0
	move_and_slide()
	queue_redraw()
	target = null
	var closest := 29.0
	for object in get_tree().get_nodes_in_group("interactables"):
		var distance: float = global_position.distance_to(object.global_position)
		if distance < closest:
			closest = distance
			target = object
	if not UI.busy:
		UI.prompt.text = "[E] " + target.caption if is_instance_valid(target) else ""
		if is_instance_valid(target):
			var screen_pos: Vector2 = target.get_global_transform_with_canvas().origin
			UI.prompt.size.x = 220
			UI.prompt.position = Vector2(clampf(screen_pos.x - 110, 3, 97), clampf(screen_pos.y + 6, 24, 151))

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not event.is_echo() and not UI.busy and is_instance_valid(target):
		target.interact()
		get_viewport().set_input_as_handled()

func _draw() -> void:
	draw_set_transform(Vector2(0, -2), 0, Vector2(1, 0.4))
	draw_circle(Vector2.ZERO, 8, Color(0.02, 0.01, 0.025, 0.5))
	draw_set_transform(Vector2.ZERO)
	var step := int(sin(stride) * 2.0) if velocity.length() > 0.0 else 0
	draw_rect(Rect2(-5, -7, 4, 6 + step), Color("30273d"))
	draw_rect(Rect2(1, -7, 4, 6 - step), Color("30273d"))
	draw_rect(Rect2(-6, -18, 12, 12), Color("afa584"))
	draw_rect(Rect2(-3, -17, 2, 10), Color("ded3ac"))
	draw_rect(Rect2(2, -17, 1, 10), Color("625a60"))
	draw_rect(Rect2(-4, -25, 8, 8), Color("cfb082"))
	draw_rect(Rect2(-5, -27, 10, 4), Color("33283a"))
	if facing.y >= 0:
		draw_rect(Rect2(-3 if facing.x <= 0 else 1, -22, 2, 2), Color("211b2a"))
