class_name DreamRoom
extends Control

const INK := Color("17112b")
const PAPER := Color("f3edce")
const FONT: Font = preload("res://assets/fonts/DotGothic16-Regular.ttf")
const PAPERS: Array[Texture2D] = [
	preload("res://assets/textures/wallpaper_01.png"),
	preload("res://assets/textures/wallpaper_02.png"),
	preload("res://assets/textures/wallpaper_03.png"),
	preload("res://assets/textures/wallpaper_04.png"),
	preload("res://assets/textures/wallpaper_05.png"),
	preload("res://assets/textures/wallpaper_06.png")
]
const WOOD: Texture2D = preload("res://assets/textures/kenney_floor_wood_planks.png")
const TILE: Texture2D = preload("res://assets/textures/kenney_floor_tiles_blue_large.png")
const TIMBER: Texture2D = preload("res://assets/textures/kenney_wall_timber_structure.png")
const WOOD_DOOR: Texture2D = preload("res://assets/textures/kenney_door_wood.png")
const DUNGEON_WALL: Texture2D = preload("res://assets/textures/dungeon_wall.png")
const DUNGEON_DOOR: Texture2D = preload("res://assets/textures/dungeon_door.png")
const DUNGEON_WINDOW: Texture2D = preload("res://assets/textures/dungeon_window.png")

var clock: float = 0.0
var room_index: int = 0
var scene_mode: String = "room"
var danger: float = 0.0
var gentle: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	custom_minimum_size = Vector2(640, 480)
	queue_redraw()


func set_room(index: int) -> void:
	room_index = clampi(index, 0, 3)
	queue_redraw()


func set_scene_mode(value: String) -> void:
	scene_mode = value
	queue_redraw()


func set_danger(value: float) -> void:
	danger = clampf(value, 0.0, 1.0)
	queue_redraw()


func set_gentle(value: bool) -> void:
	gentle = value
	queue_redraw()


func _process(delta: float) -> void:
	clock += delta
	if not gentle:
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 480), INK)
	match scene_mode:
		"clinic":
			_clinic()
		"corridor":
			_corridor()
		"final":
			_shell(3)
			_stage(true)
		_:
			_shell(room_index)
			match room_index:
				0: _cabin()
				1: _school()
				2: _dining()
				3: _stage(false)
	if danger > 0.01:
		_poly([Vector2.ZERO, Vector2(640, 0), Vector2(640, 22), Vector2(0, 6)], Color(0.95, 0.04, 0.35, danger * 0.32))
		_poly([Vector2(0, 480), Vector2(640, 480), Vector2(640, 461), Vector2(0, 472)], Color(0.95, 0.04, 0.35, danger * 0.32))
	_frame()


func _poly(points: Array, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array(points), color)


func _quad(points: Array, tex: Texture2D, repeats: Vector2 = Vector2.ONE, tint: Color = Color.WHITE) -> void:
	var uvs := PackedVector2Array([Vector2.ZERO, Vector2(repeats.x, 0), repeats, Vector2(0, repeats.y)])
	draw_polygon(PackedVector2Array(points), PackedColorArray([tint]), uvs, tex)


func _tex(tex: Texture2D, rect: Rect2, tint: Color = Color.WHITE) -> void:
	draw_texture_rect(tex, rect, false, tint)


func _outline(points: Array, color: Color = INK, width: float = 2.0) -> void:
	var path := PackedVector2Array(points)
	path.append(path[0])
	draw_polyline(path, color, width)


func _ellipse(rect: Rect2, color: Color) -> void:
	var points := PackedVector2Array()
	for n in range(32):
		var angle := float(n) * TAU / 32.0
		points.append(rect.get_center() + Vector2(cos(angle), sin(angle)) * rect.size * 0.5)
	draw_colored_polygon(points, color)


func _label(text: String, rect: Rect2, fg: Color = PAPER, bg: Color = INK, font_size: int = 12) -> void:
	draw_rect(rect, bg)
	draw_rect(rect.grow(2), fg, false, 1.0)
	draw_string(FONT, Vector2(rect.position.x + 5, rect.position.y + rect.size.y * 0.5 + font_size * 0.35), text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 10, font_size, fg)


func _frame() -> void:
	draw_rect(Rect2(0, 0, 640, 480), Color("110c1c"), false, 4.0)
	for x in [8, 632]:
		for y in [8, 472]:
			draw_line(Vector2(x - 4, y), Vector2(x + 4, y), PAPER, 1.0)
			draw_line(Vector2(x, y - 4), Vector2(x, y + 4), PAPER, 1.0)


func _shell(which: int) -> void:
	var left_tex: Texture2D = PAPERS[[0, 2, 3, 0][which]]
	var right_tex: Texture2D = PAPERS[[3, 0, 5, 2][which]]
	var back_tex: Texture2D = PAPERS[[1, 1, 4, 3][which]]
	var trim: Color = [Color("eaff21"), Color("f051c2"), Color("15edd0"), Color("eaff21")][which]
	_quad([Vector2(0, 0), Vector2(640, 0), Vector2(490, 65), Vector2(150, 65)], PAPERS[4], Vector2(5, 1), Color("b1a94f"))
	_quad([Vector2(0, 0), Vector2(150, 65), Vector2(150, 285), Vector2(0, 480)], left_tex, Vector2(2, 3))
	_quad([Vector2(490, 65), Vector2(640, 0), Vector2(640, 480), Vector2(490, 285)], right_tex, Vector2(2, 3))
	_quad([Vector2(150, 65), Vector2(490, 65), Vector2(490, 285), Vector2(150, 285)], back_tex, Vector2(3, 2), Color("eee7c8"))
	_quad([Vector2(150, 285), Vector2(490, 285), Vector2(640, 480), Vector2(0, 480)], TILE if which != 0 else WOOD, Vector2(5, 5), Color("f09fe7") if which != 0 else Color("c3c263"))
	_floor_grid(which)
	for pair in [[Vector2(0, 0), Vector2(150, 65)], [Vector2(640, 0), Vector2(490, 65)], [Vector2(150, 65), Vector2(150, 285)], [Vector2(490, 65), Vector2(490, 285)], [Vector2(0, 480), Vector2(150, 285)], [Vector2(640, 480), Vector2(490, 285)], [Vector2(150, 65), Vector2(490, 65)], [Vector2(150, 285), Vector2(490, 285)]]:
		draw_line(pair[0], pair[1], INK, 7.0)
		draw_line(pair[0], pair[1], trim, 3.0)
	# Timber bands make the location read as a cabin beneath its dream textures.
	for y in [98, 247]:
		_poly([Vector2(0, y - 20), Vector2(150, y), Vector2(150, y + 5), Vector2(0, y - 12)], trim)
		_poly([Vector2(490, y), Vector2(640, y - 20), Vector2(640, y - 12), Vector2(490, y + 5)], trim)
	for x in [150, 484]:
		_tex(TIMBER, Rect2(x, 65, 6, 220), trim)
	_back_door(which)
	_window(which)
	_case_poster(which)
	_ceiling_light(which)


func _floor_grid(which: int) -> void:
	var cuts: Array[float] = [0.0, 0.045, 0.115, 0.22, 0.37, 0.57, 0.80, 1.0]
	var a: Color = [Color("dfd449"), Color("ff75ce"), Color("2cd5bd"), Color("d4e842")][which]
	var b: Color = [Color("4f595e"), Color("3a243b"), Color("984491"), Color("663099")][which]
	for row in range(cuts.size() - 1):
		var t0: float = cuts[row]
		var t1: float = cuts[row + 1]
		var left0: float = lerpf(150.0, 0.0, t0)
		var right0: float = lerpf(490.0, 640.0, t0)
		var left1: float = lerpf(150.0, 0.0, t1)
		var right1: float = lerpf(490.0, 640.0, t1)
		for col in range(10):
			var f0: float = col / 10.0
			var f1: float = (col + 1) / 10.0
			var color: Color = a if (row + col) % 2 == 0 else b
			color.a = 0.48 if which == 0 else 0.72
			_poly([Vector2(lerpf(left0, right0, f0), lerpf(285.0, 480.0, t0)), Vector2(lerpf(left0, right0, f1), lerpf(285.0, 480.0, t0)), Vector2(lerpf(left1, right1, f1), lerpf(285.0, 480.0, t1)), Vector2(lerpf(left1, right1, f0), lerpf(285.0, 480.0, t1))], color)


func _back_door(which: int) -> void:
	draw_rect(Rect2(266, 121, 108, 166), INK)
	draw_rect(Rect2(272, 127, 96, 158), Color("f4ea4c"))
	_tex(WOOD_DOOR, Rect2(277, 133, 86, 150), Color("f578d8") if which % 2 == 0 else Color("67e6b6"))
	draw_rect(Rect2(284, 144, 72, 127), Color(0.25, 0.02, 0.35, 0.28))
	draw_circle(Vector2(351, 216), 4, Color("faff77"))
	_label(["THE SAME DOOR", "AFTER SCHOOL", "COME HOME", "ONE MORE TURN"][which], Rect2(262, 99, 116, 17), INK, Color("ebef72"), 10)
	draw_line(Vector2(274, 285), Vector2(366, 285), Color("ff8bf3"), 4)


func _window(which: int) -> void:
	var rect := Rect2(158, 79, 99, 148)
	draw_rect(rect.grow(4), INK)
	draw_rect(rect, Color("00d8bb") if which % 2 == 0 else Color("ed0eac"))
	for i in range(4):
		var yy: float = 96 + i * 29
		_poly([Vector2(158, yy), Vector2(257, yy - 15), Vector2(257, yy - 5), Vector2(158, yy + 7)], Color("a6ed48") if which % 2 == 0 else Color("f9a9df"))
	_tex(DUNGEON_WINDOW, rect, Color("d7ef77") if which == 0 else Color("daa4fa"))
	_label("OUTSIDE", Rect2(176, 230, 65, 13), PAPER, INK, 9)


func _case_poster(which: int) -> void:
	draw_rect(Rect2(416, 94, 70, 104), INK)
	draw_rect(Rect2(420, 98, 62, 96), Color("e9e3b9"))
	var words: Array[String] = ["BE GOOD", "BE QUIET", "BE GRATEFUL", "BE STILL"]
	draw_string(FONT, Vector2(425, 116), words[which], HORIZONTAL_ALIGNMENT_CENTER, 52, 10, INK)
	for row in range(6):
		var length: float = 48.0 - float((row * 13 + which * 5) % 17)
		draw_rect(Rect2(427, 126 + row * 7, length, 2), INK)
	draw_rect(Rect2(433, 174, 37, 10), Color("ce2863"))
	draw_string(FONT, Vector2(434, 182), "CASE 04", HORIZONTAL_ALIGNMENT_CENTER, 34, 8, PAPER)


func _ceiling_light(which: int) -> void:
	draw_line(Vector2(320, 0), Vector2(320, 43), INK, 3)
	_poly([Vector2(301, 41), Vector2(339, 41), Vector2(348, 54), Vector2(292, 54)], INK)
	_poly([Vector2(304, 43), Vector2(336, 43), Vector2(343, 51), Vector2(297, 51)], Color("e8ef81"))
	_ellipse(Rect2(297, 47, 46, 10), Color("ffb2e0") if which == 3 else Color("effca5"))


func _cabin() -> void:
	# Hanging herbs, shelves, cauldron, and a tiny table establish the witch's cabin.
	for n in range(6):
		var x: float = 22 + n * 20
		var yy: float = 51 + n * 8
		draw_line(Vector2(x, 0), Vector2(x, yy), INK, 2)
		for leaf in range(4):
			var ly: float = yy - 20 + leaf * 7
			_poly([Vector2(x, ly), Vector2(x - 9, ly + 3), Vector2(x - 3, ly + 13)], Color("b6df39"))
			_poly([Vector2(x, ly + 3), Vector2(x + 9, ly + 5), Vector2(x + 2, ly + 14)], Color("3caa78"))
	_poly([Vector2(15, 190), Vector2(125, 205), Vector2(125, 214), Vector2(15, 199)], INK)
	for n in range(5):
		var x: float = 23 + n * 19
		var y: float = 170 + n * 2.3
		var color: Color = [Color("faff54"), Color("e958a9"), Color("32e6b8")][n % 3]
		draw_rect(Rect2(x, y, 12, 24), color)
		draw_rect(Rect2(x + 2, y - 4, 8, 5), INK)
		draw_rect(Rect2(x + 2, y + 8, 8, 8), PAPER)
		draw_line(Vector2(x + 4, y + 12), Vector2(x + 8, y + 12), INK, 1)
	_cauldron(Vector2(70, 326))
	_small_table(Vector2(285, 340))
	_label("もう一度", Rect2(21, 233, 94, 23), Color("eaff21"), INK, 18)
	_clock(Vector2(550, 86), 25, false)
	# Paper clippings across the foreground resemble a badly assembled memory.
	_floor_paper(Vector2(70, 420), -0.10, "DON'T FORGET", Color("e9d9bc"))
	_floor_paper(Vector2(456, 427), 0.12, "PLEASE RETURN", Color("ff84bd"))


func _cauldron(center: Vector2) -> void:
	_poly([center + Vector2(-37, -5), center + Vector2(-31, 32), center + Vector2(-20, 46), center + Vector2(20, 46), center + Vector2(31, 32), center + Vector2(37, -5)], INK)
	_ellipse(Rect2(center + Vector2(-38, -16), Vector2(76, 26)), Color("4b3368"))
	_ellipse(Rect2(center + Vector2(-29, -10), Vector2(58, 14)), Color("b8f62d"))
	for n in range(5):
		var xx: float = center.x - 22 + n * 10
		var yy: float = center.y - 9 + float(n % 2) * 4
		draw_circle(Vector2(xx, yy), 2 + n % 3, Color("f6ff98"))
	for x in [-26, 26]:
		draw_line(center + Vector2(x, 35), center + Vector2(x * 1.25, 51), INK, 5)
	for n in range(3):
		var x: float = center.x - 17 + n * 16
		draw_polyline(PackedVector2Array([Vector2(x, center.y - 22), Vector2(x + 4, center.y - 35), Vector2(x - 3, center.y - 47)]), Color("f4b8de"), 3)


func _small_table(center: Vector2) -> void:
	_quad([center + Vector2(-65, -23), center + Vector2(50, -23), center + Vector2(73, 0), center + Vector2(-83, 0)], WOOD, Vector2(2, 1), Color("d794de"))
	_poly([center + Vector2(-83, 0), center + Vector2(73, 0), center + Vector2(73, 11), center + Vector2(-83, 11)], INK)
	for x in [-73, 63]:
		draw_line(center + Vector2(x, 9), center + Vector2(x, 75), INK, 7)
		draw_line(center + Vector2(x - 2, 10), center + Vector2(x - 2, 74), Color("bead50"), 2)


func _school() -> void:
	# Impossible school lockers recede along both sides; no human figures are baked in.
	for n in range(5):
		var x: float = 8 + n * 28
		var top: float = 100 + n * 10
		var bottom: float = 366 - n * 19
		_poly([Vector2(x, top), Vector2(x + 25, top + 8), Vector2(x + 25, bottom - 14), Vector2(x, bottom)], Color("db8edb") if n % 2 == 0 else Color("49d6a9"))
		_outline([Vector2(x, top), Vector2(x + 25, top + 8), Vector2(x + 25, bottom - 14), Vector2(x, bottom)], INK, 3)
		for slit in range(3):
			draw_line(Vector2(x + 5, top + 18 + slit * 6), Vector2(x + 20, top + 23 + slit * 6), INK, 2)
		draw_rect(Rect2(x + 17, (top + bottom) * 0.5, 3, 12), INK)
		var rx: float = 640 - x
		_poly([Vector2(rx, top), Vector2(rx - 25, top + 8), Vector2(rx - 25, bottom - 14), Vector2(rx, bottom)], Color("e6e74d") if n % 2 == 0 else Color("a050b7"))
		_outline([Vector2(rx, top), Vector2(rx - 25, top + 8), Vector2(rx - 25, bottom - 14), Vector2(rx, bottom)], INK, 3)
		for slit in range(3):
			draw_line(Vector2(rx - 5, top + 18 + slit * 6), Vector2(rx - 20, top + 23 + slit * 6), INK, 2)
		_label(str(n + 1), Rect2(x + 5, top + 49, 16, 12), INK, PAPER, 6)
	_label("NO RUNNING / NO CRYING", Rect2(189, 68, 264, 17), Color("eff733"), INK, 12)
	_clock(Vector2(551, 78), 22, true)
	_floor_paper(Vector2(145, 406), 0.07, "ATTENDANCE", Color("ffff9a"))
	_floor_paper(Vector2(400, 443), -0.11, "ABSENT AGAIN", Color("fdbbdd"))
	_small_table(Vector2(285, 340))


func _dining() -> void:
	_label("A PLACE FOR EVERYONE", Rect2(188, 68, 268, 17), Color("f9ee6c"), INK, 12)
	for n in range(3):
		var yy: float = 292 + n * 54
		var spread: float = 105 + n * 37
		_chair(Vector2(320 - spread, yy), 0.75 + n * 0.20, Color("86e64e"))
		_chair(Vector2(320 + spread, yy), 0.75 + n * 0.20, Color("e958b8"))
	_quad([Vector2(266, 273), Vector2(374, 273), Vector2(490, 480), Vector2(150, 480)], WOOD, Vector2(3, 4), Color("ff83bf"))
	_outline([Vector2(266, 273), Vector2(374, 273), Vector2(490, 480), Vector2(150, 480)], INK, 4)
	_poly([Vector2(306, 273), Vector2(334, 273), Vector2(369, 480), Vector2(271, 480)], Color("b6f13c"))
	for n in range(3):
		var yy: float = 317 + n * 60
		var spread: float = 42 + n * 30
		for direction in [-1, 1]:
			var xx: float = 320 + spread * direction
			_ellipse(Rect2(xx - 21, yy - 7, 42, 18), INK)
			_ellipse(Rect2(xx - 18, yy - 6, 36, 14), PAPER)
			_ellipse(Rect2(xx - 13, yy - 4, 26, 10), Color("b46bb8"))
			draw_line(Vector2(xx + direction * 27, yy - 5), Vector2(xx + direction * 30, yy + 12), INK, 2)
	# Every empty setting has a folded name card.
	_label("MOTHER", Rect2(214, 350, 55, 11), INK, PAPER, 8)
	_label("NOBODY", Rect2(374, 350, 55, 11), INK, PAPER, 8)
	_clock(Vector2(548, 88), 23, false)
	_candelabra(Vector2(92, 264))
	_candelabra(Vector2(553, 267))


func _chair(pos: Vector2, factor: float, color: Color) -> void:
	draw_set_transform(pos, 0.0, Vector2(factor, factor))
	draw_rect(Rect2(-21, -46, 42, 45), INK)
	draw_rect(Rect2(-17, -42, 34, 35), color)
	for x in [-10, 0, 10]:
		draw_line(Vector2(x, -39), Vector2(x, -10), INK, 2)
	_poly([Vector2(-21, -1), Vector2(21, -1), Vector2(27, 12), Vector2(-27, 12)], color)
	for x in [-21, 21]:
		draw_line(Vector2(x, 12), Vector2(x, 43), INK, 5)
	draw_set_transform(Vector2.ZERO)


func _candelabra(pos: Vector2) -> void:
	draw_line(pos, pos + Vector2(0, -62), INK, 5)
	for dx in [-17, 0, 17]:
		draw_line(pos + Vector2(0, -35), pos + Vector2(dx, -48), INK, 4)
		draw_rect(Rect2(pos + Vector2(dx - 3, -68), Vector2(6, 20)), Color("d9eb6a"))
		_poly([pos + Vector2(dx, -83), pos + Vector2(dx + 4, -71), pos + Vector2(dx - 4, -71)], Color("ff95d9"))
	_ellipse(Rect2(pos + Vector2(-16, -2), Vector2(32, 7)), INK)


func _stage(final_scene: bool) -> void:
	# Theatre curtains, nursery alphabet, and a raised empty stage.
	for direction in [-1, 1]:
		for n in range(6):
			var x: float = n * 24.0 if direction < 0 else 640.0 - n * 24.0 - 24.0
			var low: float = 286 - n * 21
			var color: Color = Color("a623b9") if n % 2 == 0 else Color("e64da6")
			_poly([Vector2(x, 0), Vector2(x + 26, 0), Vector2(x + 21, low), Vector2(x + 7, low + 15)], color)
			draw_line(Vector2(x + 5, 3), Vector2(x + 12, low), INK, 2)
	_poly([Vector2(0, 0), Vector2(640, 0), Vector2(640, 30), Vector2(544, 52), Vector2(450, 31), Vector2(320, 49), Vector2(191, 31), Vector2(94, 52), Vector2(0, 30)], Color("760f79"))
	for n in range(15):
		draw_circle(Vector2(12 + n * 44, 25 + (n % 2) * 8), 3, Color("e9ef3b"))
	_quad([Vector2(154, 292), Vector2(486, 292), Vector2(569, 391), Vector2(71, 391)], WOOD, Vector2(5, 2), Color("d88bea"))
	_poly([Vector2(71, 391), Vector2(569, 391), Vector2(569, 411), Vector2(71, 411)], INK)
	draw_line(Vector2(71, 391), Vector2(569, 391), Color("f7e950"), 4)
	for n in range(15):
		draw_circle(Vector2(87 + n * 33, 401), 3, Color("e0ff62"))
	_label("THE LAST PERFORMANCE" if final_scene else "THE GOOD CHILDREN'S SHOW", Rect2(166, 68, 309, 19), Color("ecf648"), INK, 12)
	for n in range(5):
		var x: float = 77 + n * 34
		var y: float = 430 + (n % 2) * 7
		draw_rect(Rect2(x, y, 28, 28), [Color("d3ed24"), Color("43d8d1"), Color("ed62b0")][n % 3])
		draw_rect(Rect2(x, y, 28, 28), INK, false, 2)
		draw_string(FONT, Vector2(x + 5, y + 21), ["A", "B", "C", "A", "A"][n], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, INK)
	_small_table(Vector2(285, 340))
	if final_scene:
		_label("NO ENCORE", Rect2(281, 224, 78, 21), PAPER, INK, 12)


func _clock(center: Vector2, radius: float, broken: bool) -> void:
	draw_circle(center, radius + 4, INK)
	draw_circle(center, radius, PAPER)
	for n in range(12):
		var a: float = float(n) * TAU / 12.0
		var p: Vector2 = center + Vector2(sin(a), -cos(a)) * (radius - 4)
		draw_circle(p, 1.2, INK)
	draw_line(center, center + Vector2(0, -radius * 0.66), INK, 2)
	draw_line(center, center + Vector2(radius * 0.50, radius * 0.23), INK, 3)
	if broken:
		draw_polyline(PackedVector2Array([center + Vector2(-9, -radius), center + Vector2(2, -5), center + Vector2(-6, 4), center + Vector2(11, radius)]), Color("c22e68"), 2)


func _floor_paper(pos: Vector2, angle: float, caption: String, color: Color) -> void:
	draw_set_transform(pos, angle)
	draw_rect(Rect2(-46, -18, 92, 38), color)
	draw_string(FONT, Vector2(-40, -5), caption, HORIZONTAL_ALIGNMENT_CENTER, 80, 9, INK)
	for n in range(3):
		draw_rect(Rect2(-38, 2 + n * 5, 76 - (n % 2) * 14, 1), INK)
	draw_set_transform(Vector2.ZERO)


func _clinic() -> void:
	var wall := Color("9ab4ab")
	_poly([Vector2(0, 0), Vector2(150, 65), Vector2(150, 285), Vector2(0, 480)], wall.darkened(0.16))
	_poly([Vector2(490, 65), Vector2(640, 0), Vector2(640, 480), Vector2(490, 285)], wall.darkened(0.24))
	draw_rect(Rect2(150, 65, 340, 220), wall)
	_poly([Vector2(0, 0), Vector2(640, 0), Vector2(490, 65), Vector2(150, 65)], Color("c9cfbb"))
	_quad([Vector2(150, 285), Vector2(490, 285), Vector2(640, 480), Vector2(0, 480)], WOOD, Vector2(6, 5), Color("858277"))
	for pair in [[Vector2(0, 0), Vector2(150, 65)], [Vector2(640, 0), Vector2(490, 65)], [Vector2(150, 65), Vector2(490, 65)], [Vector2(150, 285), Vector2(490, 285)], [Vector2(150, 65), Vector2(150, 285)], [Vector2(490, 65), Vector2(490, 285)]]:
		draw_line(pair[0], pair[1], Color("4f665f"), 4)
	# A muted window and curtains, no portrait baked into the consultation view.
	draw_rect(Rect2(169, 95, 101, 121), Color("365b61"))
	draw_rect(Rect2(175, 101, 89, 109), Color("c5d4bf"))
	for x in [193, 218, 243]:
		draw_line(Vector2(x, 102), Vector2(x, 210), Color("698c87"), 2)
	draw_line(Vector2(175, 151), Vector2(264, 151), Color("698c87"), 3)
	for x in [164, 253]:
		draw_rect(Rect2(x, 91, 19, 134), Color("758f89"))
		for offset in [3, 8, 13]:
			draw_line(Vector2(x + offset, 95), Vector2(x + offset, 220), Color("526c68"), 1)
	_tex(WOOD_DOOR, Rect2(293, 128, 81, 157), Color("b6b6a1"))
	draw_rect(Rect2(289, 124, 89, 165), Color("344d49"), false, 4)
	_label("DREAM CONSULTATION", Rect2(281, 96, 131, 18), Color("dce0c7"), Color("344d49"), 10)
	draw_rect(Rect2(411, 113, 58, 77), Color("344d49"))
	draw_rect(Rect2(416, 118, 48, 67), Color("dedcc2"))
	draw_string(FONT, Vector2(421, 132), "CERTIFICATE", HORIZONTAL_ALIGNMENT_CENTER, 38, 6, Color("344d49"))
	for n in range(5):
		draw_line(Vector2(424, 141 + n * 5), Vector2(456, 141 + n * 5), Color("899886"), 1)
	draw_circle(Vector2(440, 174), 5, Color("9f8967"))
	_clock(Vector2(550, 86), 22, false)
	# Bookshelf at left and plant at right leave the central patient area unobstructed.
	_poly([Vector2(18, 226), Vector2(119, 245), Vector2(119, 340), Vector2(18, 366)], Color("43504a"))
	for shelf in range(2):
		for n in range(8):
			var xx: float = 25 + n * 11
			var yy: float = 234 + shelf * 52 + n * 1.9
			draw_rect(Rect2(xx, yy, 8, 32 - n % 3 * 4), [Color("9da696"), Color("8d7775"), Color("bfba96")][n % 3])
		_poly([Vector2(18, 276 + shelf * 51), Vector2(119, 280 + shelf * 45), Vector2(119, 286 + shelf * 45), Vector2(18, 282 + shelf * 51)], INK)
	_poly([Vector2(544, 326), Vector2(587, 326), Vector2(578, 370), Vector2(554, 370)], Color("9e7965"))
	for n in range(5):
		var tip := Vector2(536 + n * 14, 258 - (n % 2) * 26)
		draw_line(Vector2(564, 332), tip, Color("3b6052"), 3)
		_ellipse(Rect2(tip - Vector2(8, 14), Vector2(17, 30)), Color("487e5e"))
	_quad([Vector2(179, 355), Vector2(420, 355), Vector2(502, 465), Vector2(107, 465)], WOOD, Vector2(4, 2), Color("b5a991"))
	_outline([Vector2(179, 355), Vector2(420, 355), Vector2(502, 465), Vector2(107, 465)], Color("344d49"), 4)
	draw_rect(Rect2(107, 465, 395, 15), Color("344d49"))
	_floor_paper(Vector2(231, 402), -0.04, "SESSION 04", Color("e1dec6"))
	_label("TAKE YOUR TIME", Rect2(429, 226, 97, 15), Color("e1dec6"), Color("344d49"), 10)


func _corridor() -> void:
	_quad([Vector2(0, 0), Vector2(640, 0), Vector2(640, 324), Vector2(0, 324)], PAPERS[0], Vector2(6, 3), Color("e9bce5"))
	_quad([Vector2(0, 324), Vector2(640, 324), Vector2(640, 480), Vector2(0, 480)], PAPERS[1], Vector2(5, 2))
	_poly([Vector2(0, 0), Vector2(640, 0), Vector2(564, 63), Vector2(76, 63)], Color("251b36"))
	for x in [0, 160, 320, 480, 640]:
		draw_line(Vector2(320, 324), Vector2(x, 480), INK, 4)
	for y in [335, 356, 391, 441]:
		draw_line(Vector2(0, y), Vector2(640, y), INK, 4)
	for x in [27, 203, 422, 598]:
		_tex(DUNGEON_WALL, Rect2(x, 61, 16, 266), Color("ceef70"))
	for n in range(3):
		var x: float = [60.0, 270.0, 480.0][n]
		var y: float = [150.0, 125.0, 150.0][n]
		draw_rect(Rect2(x - 8, y - 10, 116, 194), INK)
		draw_rect(Rect2(x - 4, y - 6, 108, 186), Color("e9f652"))
		_tex(DUNGEON_DOOR, Rect2(x, y, 100, 180), [Color("eb87d9"), Color("8cf4cd"), Color("f7cf69")][n])
		_label(["LEFT", "FORWARD", "RIGHT"][n], Rect2(x - 3, y - 35, 106, 19), INK, Color("eff667"), 14)
		_label(["01", "02", "03"][n], Rect2(x + 37, y + 43, 26, 18), PAPER, INK, 12)
	_label("THE HALL RETURNS WHAT IT TAKES", Rect2(159, 21, 322, 25), Color("ecfa39"), INK, 13)
	_label("もう一度", Rect2(266, 66, 108, 28), Color("fa58c5"), INK, 19)
	_label("LISTEN. THEN CHOOSE.", Rect2(215, 431, 210, 21), PAPER, INK, 12)
