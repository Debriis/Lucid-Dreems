extends CanvasLayer

var busy := false
var lines: Array[String] = []
var completion := Callable()
var choices: Array = []
var choice_callback := Callable()
var selected := 0
var panel: Panel
var body: Label
var hint: Label
var prompt: Label
var status: Label
var fade: ColorRect
var buttons: Array[Button] = []
var history: Array[String] = []

func _ready() -> void:
	layer = 10
	status = label(Vector2(32, 20), Vector2(1216, 40), 24)
	prompt = label(Vector2(160, 565), Vector2(960, 40), 25)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel = Panel.new()
	panel.position = Vector2(40, 440)
	panel.size = Vector2(1200, 248)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxTexture.new()
	style.texture = load("res://assets/fever_dreams/ui/dialogue_panel.png")
	style.set_texture_margin_all(12)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	body = label(Vector2(76, 466), Vector2(1128, 160), 26)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_color_override("font_color", Color("29222e"))
	body.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	hint = label(Vector2(76, 644), Vector2(1128, 32), 22)
	hint.add_theme_color_override("font_color", Color("5b3b52"))
	hint.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	fade = ColorRect.new()
	fade.size = Vector2(1280, 720)
	fade.color = Color.BLACK
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.modulate.a = 0
	add_child(fade)
	clear()

func label(pos: Vector2, dimensions: Vector2, font_size: int) -> Label:
	var result := Label.new()
	result.position = pos
	result.size = dimensions
	result.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", Color("ede3b2"))
	result.add_theme_color_override("font_shadow_color", Color.BLACK)
	result.add_theme_constant_override("shadow_offset_x", 1)
	result.add_theme_constant_override("shadow_offset_y", 1)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(result)
	return result

func clear() -> void:
	busy = false
	lines.clear()
	choices.clear()
	completion = Callable()
	choice_callback = Callable()
	for button in buttons:
		button.queue_free()
	buttons.clear()
	panel.hide()
	body.hide()
	hint.hide()
	prompt.text = ""
	if is_instance_valid(Game.active_player):
		Game.active_player.set_capture(true)

func show_panel() -> void:
	busy = true
	prompt.text = ""
	panel.show()
	body.show()
	hint.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if is_instance_valid(Game.active_player):
		Game.active_player.set_capture(false)

func say(texts: Array[String], after: Callable = Callable()) -> void:
	clear()
	lines.assign(texts)
	completion = after
	show_panel()
	set_text(lines.pop_front())
	hint.text = "E / ENTER / LEFT CLICK  ·  continue"

func set_text(text: String) -> void:
	body.text = text
	history.append(text)

func choose(options: Array = [], after: Callable = Callable(), question: String = "Choose your response.") -> void:
	clear()
	choices = options.duplicate()
	choice_callback = after
	selected = 0
	show_panel()
	set_text(question)
	hint.text = "W / S or ARROWS · select     E / ENTER or CLICK · respond"
	for i in range(options.size()):
		var button := Button.new()
		button.position = Vector2(76, 420 - options.size() * 62 + i * 62)
		button.size = Vector2(1128, 54)
		button.text = options[i]
		button.add_theme_font_size_override("font_size", 25)
		button.add_theme_color_override("font_color", Color("241e29"))
		button.add_theme_color_override("font_hover_color", Color("241e29"))
		button.add_theme_color_override("font_focus_color", Color("241e29"))
		for state in ["normal", "hover", "focus", "pressed"]:
			var style := StyleBoxFlat.new()
			style.bg_color = Color("e8dcc0") if state == "normal" else Color("d6a4b7")
			style.border_color = Color("453044")
			style.set_border_width_all(3)
			button.add_theme_stylebox_override(state, style)
		button.pressed.connect(select_choice.bind(i))
		add_child(button)
		buttons.append(button)
	buttons[0].grab_focus()

func select_choice(index: int) -> void:
	if choices.is_empty() or index < 0 or index >= choices.size():
		return
	var callback := choice_callback
	history.append(choices[index])
	clear()
	if callback.is_valid():
		callback.call(index)

func advance() -> void:
	if not lines.is_empty():
		set_text(lines.pop_front())
	else:
		var callback := completion
		clear()
		if callback.is_valid():
			callback.call()

func _input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if not busy:
		if is_instance_valid(Game.active_player):
			Game.active_player.handle_input(event)
			Game.active_player.use_input(event)
		return
	if not choices.is_empty():
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			for i in range(buttons.size()):
				if buttons[i].get_global_rect().has_point(event.position):
					get_viewport().set_input_as_handled()
					select_choice(i)
					return
		elif event.is_action_pressed("up") or event.is_action_pressed("left"):
			selected = posmod(selected - 1, choices.size())
			buttons[selected].grab_focus()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("down") or event.is_action_pressed("right"):
			selected = (selected + 1) % choices.size()
			buttons[selected].grab_focus()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("interact"):
			get_viewport().set_input_as_handled()
			select_choice(selected)
	elif event.is_action_pressed("interact") or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		get_viewport().set_input_as_handled()
		advance()

func sleep_into(path: String) -> void:
	busy = true
	var tween := create_tween()
	tween.tween_property(fade, "modulate:a", 1.0, 0.6)
	await tween.finished
	Game.travel(path)
	tween = create_tween()
	tween.tween_property(fade, "modulate:a", 0.0, 0.7)
