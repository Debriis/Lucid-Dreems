extends StaticBody2D

var kind := "table"
var caption := ""
var distorted := false
var solid_size := Vector2(24, 12)
signal activated(kind: String)

func _ready() -> void:
	collision_layer = 1
	collision_mask = 2
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape := RectangleShape2D.new()
	shape.size = solid_size
	collision.shape = shape
	collision.position.y = -solid_size.y / 2.0
	add_child(collision)
	if not caption.is_empty():
		add_to_group("interactables")
	queue_redraw()

func interact() -> void:
	activated.emit(kind)

func block(rect: Rect2, color: String) -> void:
	draw_rect(rect, Color(color))

func _draw() -> void:
	draw_rect(Rect2(-solid_size.x / 2.0 - 3, -3, solid_size.x + 7, 5), Color(0, 0, 0, 0.4))
	var wood := "624143" if distorted else "715133"
	var edge := "bb788e" if distorted else "b19a55"
	match kind:
		"table", "desk":
			block(Rect2(-27, -13, 5, 17), "332632")
			block(Rect2(22, -13, 5, 17), "332632")
			block(Rect2(-30, -31, 60, 27), wood)
			block(Rect2(-29, -31, 58, 2), edge)
			for x in range(-26, 29, 9):
				draw_line(Vector2(x, -28), Vector2(x + 2, -6), Color("463431"))
			block(Rect2(-10, -25, 15, 11), "c1b788")
			for y in range(-23, -15, 3):
				block(Rect2(-8, y, 10, 1), "675b64")
			block(Rect2(14, -21, 6, 5), "302635")
		"altar":
			block(Rect2(-18, -22, 36, 22), wood)
			block(Rect2(-20, -25, 40, 5), edge)
			block(Rect2(-11, -36, 3, 11), "ddd2a1")
			block(Rect2(9, -36, 3, 11), "ddd2a1")
			block(Rect2(-11, -39, 2, 3), "edaf63")
			block(Rect2(9, -39, 2, 3), "edaf63")
			draw_colored_polygon(PackedVector2Array([Vector2(-6,-25), Vector2(0,-40), Vector2(7,-25)]), Color("93678a"))
		"box":
			block(Rect2(-13, -13, 26, 13), "49303c")
			block(Rect2(-14, -20, 28, 9), edge)
			block(Rect2(-10, -18, 20, 5), "674558")
			block(Rect2(-2, -9, 4, 4), "e3c77b")
			block(Rect2(13, -10, 5, 2), "c9bd8a")
		"animatronic":
			block(Rect2(-11, -8, 8, 9), "443e41")
			block(Rect2(4, -8, 8, 9), "443e41")
			block(Rect2(-11, -32, 23, 24), "8a8851" if not distorted else "956184")
			block(Rect2(-16, -30, 5, 21), wood)
			block(Rect2(12, -30, 5, 21), wood)
			block(Rect2(-13, -48, 26, 17), "b1a56c")
			block(Rect2(-11, -57, 5, 12), "8a8851")
			block(Rect2(7, -61, 5, 16), "8a8851")
			block(Rect2(-9, -43, 7, 5), "252332")
			block(Rect2(4, -43, 7, 5), "252332")
			block(Rect2(-6, -42, 2, 2), "e47a9a")
			block(Rect2(6, -42, 2, 2), "e47a9a")
			block(Rect2(-7, -35, 15, 2), "302635")
			for x in range(-5, 9, 4):
				block(Rect2(x, -35, 1, 2), "e8d4a1")
			block(Rect2(-2, -27, 4, 4), "4b3b43")
		"door":
			block(Rect2(-17, -42, 34, 43), "302335")
			block(Rect2(-14, -39, 28, 38), "837147" if not distorted else "826080")
			block(Rect2(-11, -36, 22, 33), "403448")
			block(Rect2(7, -17, 3, 3), "e6bc79")
			for y in range(-34, -3, 5):
				block(Rect2(-9, y, 2, 2), "b07b90")
		"patient":
			draw_texture_rect(preload("res://assets/fever_dreams/characters/patient/patient_idle.png"), Rect2(-17, -48, 34, 51), false)
