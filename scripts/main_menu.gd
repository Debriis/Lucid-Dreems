extends Control
## A photocopied case file, interrupted by the face from the dream.

const TITLE_FONT = preload("res://assets/fonts/RubikGlitch-Regular.ttf")
const CLINICAL_FONT = preload("res://assets/fonts/SpecialElite-Regular.ttf")
const PIXEL_FONT = preload("res://assets/replacements_v2/ui/fonts/DotGothic16-Regular.ttf")
const PAPER_TEXTURE = preload("res://assets/replacements_v2/ui/dialogue_panel.png")
const PATTERN = preload("res://assets/fever_dreams/textures/cabin/wallpaper_01.png")
const RIPPLE = preload("res://assets/fever_dreams/textures/cabin/wallpaper_06.png")
const RED_WAVE = preload("res://assets/fever_dreams/textures/cabin/wallpaper_04.png")
const PAPER := Color("e3e0c9")
const PINK := Color("d883a4")
const ACID := Color("e4e96b")

var _buttons: Array[Button] = []
var _selected := 0
var _head: Sprite2D
var _head_home := Vector2(1010, 390)
var _time := 0.0
var _note: Label

func _ready() -> void:
	Game.active_player = null
	UI.close_menu()
	UI.clear()
	UI.menu_open = true
	UI.status.text = ""
	UI.fade.modulate.a = 0.0
	UI.set_objective("", 0)
	UI.set_notes_count(0)
	UI.hide_vitals()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Game.play_menu_music()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_texture(PATTERN, Vector2.ZERO, Vector2(1280, 720), Color("6b327e"))
	_texture(RED_WAVE, Vector2(681, -35), Vector2(700, 790), Color("9f577f"), 0.05)
	_texture(RIPPLE, Vector2(-55, 355), Vector2(870, 400), Color("6d8951"), -0.035)
	_paper(Vector2(26, 58), Vector2(742, 280), Color("ed9ec4"), 0.013)
	_paper(Vector2(39, 64), Vector2(722, 270), PAPER, -0.018)
	_paper(Vector2(786, 161), Vector2(445, 426), Color("1f152c"), 0.025)
	_texture(PATTERN, Vector2(812, 180), Vector2(399, 384), Color("acbc4b"), -0.012)
	_paper(Vector2(30, 8), Vector2(1218, 43), Color("292034"))
	_label("DEPARTMENT OF IMPOSSIBLE SLEEP", Vector2(51, 18), Vector2(770, 28), 19, CLINICAL_FONT, ACID)
	_label("PATIENT FILE / 004", Vector2(970, 18), Vector2(300, 28), 18, CLINICAL_FONT, PINK)
	_label("THE LAST", Vector2(57, 78), Vector2(740, 110), 88, TITLE_FONT, Color("59203f"))
	_label("LULLABY", Vector2(49, 170), Vector2(750, 128), 100, TITLE_FONT, Color("211929"))
	var stamp := _label("DO NOT WIND\nFORWARD", Vector2(971, 80), Vector2(260, 86), 27, CLINICAL_FONT, ACID)
	stamp.rotation = -0.085
	_label("A SESSION IN FOUR BROKEN MOVEMENTS", Vector2(62, 295), Vector2(700, 32), 17, CLINICAL_FONT, Color("6d3256"))
	_head = Sprite2D.new()
	_head.texture = load("res://assets/replacements_v2/characters/purple_performer_head.png")
	_head.position = _head_home
	_head.scale = Vector2.ONE * (430.0 / float(_head.texture.get_width()))
	_head.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_head)
	_paper(Vector2(789, 580), Vector2(448, 83), Color("241a2e"), -0.018)
	_note = _label("HE KEPT YOU SAFE ONCE.\nLET HIM TRY AGAIN.", Vector2(806, 594), Vector2(420, 63), 21, CLINICAL_FONT, ACID)
	_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var entries := ["BEGIN SESSION", "HOW TO PLAY", "SETTINGS", "CREDITS", "RELOAD GAME" if OS.has_feature("web") else "QUIT"]
	var actions: Array[Callable] = [UI.begin_session, UI.show_help, UI.show_settings, UI.show_credits, _quit_game]
	for i in range(entries.size()):
		var button := Button.new()
		button.position = Vector2(47 + (i % 2) * 12, 353 + i * 56)
		button.size = Vector2(655 - (i % 3) * 15, 51)
		button.text = "   " + entries[i]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_override("font", PIXEL_FONT)
		button.add_theme_font_size_override("font_size", 26)
		for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			button.add_theme_color_override(key, PAPER)
		for state in ["normal", "hover", "pressed", "focus"]:
			var style := StyleBoxFlat.new()
			style.bg_color = Color.TRANSPARENT
			style.content_margin_left = 8
			button.add_theme_stylebox_override(state, style)
		button.pressed.connect(actions[i])
		button.mouse_entered.connect(_hover.bind(i))
		add_child(button)
		_buttons.append(button)
	_select(0)
	_paper(Vector2(30, 644), Vector2(680, 63), Color("241a2e"), -0.006)
	_label("FOUR ROOMS / 120 SECONDS / STAY CLOSE TO RUE", Vector2(51, 653), Vector2(660, 25), 16, CLINICAL_FONT, ACID)
	_label("W S / ARROWS : SELECT   E / ENTER / CLICK : CONFIRM", Vector2(51, 680), Vector2(1140, 28), 15, CLINICAL_FONT, PAPER)
	_label("SLEEP IS A PLACE.", Vector2(858, 681), Vector2(390, 28), 20, TITLE_FONT, ACID)
	queue_redraw()

func _texture(texture: Texture2D, pos: Vector2, dimensions: Vector2, tint: Color, angle: float = 0.0) -> TextureRect:
	var result := TextureRect.new()
	result.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	result.texture = texture
	result.stretch_mode = TextureRect.STRETCH_TILE
	result.position = pos
	result.size = dimensions
	result.rotation = angle
	result.modulate = tint
	result.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(result)
	return result

func _paper(pos: Vector2, dimensions: Vector2, tint: Color, angle: float = 0.0) -> Panel:
	var result := Panel.new()
	result.position = pos
	result.size = dimensions
	result.rotation = angle
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxTexture.new()
	style.texture = PAPER_TEXTURE
	style.set_texture_margin_all(12)
	style.modulate_color = tint
	result.add_theme_stylebox_override("panel", style)
	add_child(result)
	return result

func _label(text: String, pos: Vector2, dimensions: Vector2, font_size: int, font: Font, color: Color) -> Label:
	var result := Label.new()
	result.text = text
	result.position = pos
	result.size = dimensions
	result.add_theme_font_override("font", font)
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", color)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(result)
	return result

func _hover(index: int) -> void:
	if not UI.has_open_modal():
		_select(index)

func _select(index: int) -> void:
	_selected = index
	var entries := ["BEGIN SESSION", "HOW TO PLAY", "SETTINGS", "CREDITS", "RELOAD GAME" if OS.has_feature("web") else "QUIT"]
	for i in range(_buttons.size()):
		_buttons[i].text = (">  " if i == index else "   ") + entries[i]
		var color := Color("201820")
		for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			_buttons[i].add_theme_color_override(key, color)
		var style := StyleBoxTexture.new()
		style.texture = PAPER_TEXTURE
		style.set_texture_margin_all(12)
		style.content_margin_left = 15
		style.modulate_color = PINK if i == index else PAPER
		for state in ["normal", "hover", "focus", "pressed"]:
			_buttons[i].add_theme_stylebox_override(state, style)

func _unhandled_input(event: InputEvent) -> void:
	if UI.has_open_modal() or event.is_echo():
		return
	if event.is_action_pressed("up") or event.is_action_pressed("ui_up"):
		_select(posmod(_selected - 1, _buttons.size()))
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("down") or event.is_action_pressed("ui_down"):
		_select((_selected + 1) % _buttons.size())
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_buttons[_selected].pressed.emit()

func _process(delta: float) -> void:
	_time += delta
	if is_instance_valid(_head):
		_head.position = _head_home if Game.reduced_effects else _head_home + Vector2(sin(_time * 0.34) * 2.0, sin(_time * 0.62) * 7.0)

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color("140e1b"))
	# Stationary toner streaks, not flashing noise. No text receives a shader.
	for i in range(90):
		var y := float((i * 139) % 720)
		var x := float((i * 313) % 1280)
		draw_line(Vector2(x, y), Vector2(x + 11 + i % 27, y), Color("5c435b30"), 1)
	for i in range(8):
		draw_line(Vector2(773 + i * 3, 78), Vector2(762 + i * 3, 645), Color("80797b0b"), 1)

func _quit_game() -> void:
	Game.request_quit()
