extends CanvasLayer
## Dialogue stays immediate and deterministic; recorded speech follows each line.

const PAPER := Color("deded4")
const INK := Color("282329")
const PINK := Color("d18aa5")
const ACID := Color("dce777")
const PIXEL_FONT = preload("res://assets/replacements_v2/ui/fonts/DotGothic16-Regular.ttf")
const CLINICAL_FONT = preload("res://assets/fonts/SpecialElite-Regular.ttf")
const TITLE_FONT = preload("res://assets/fonts/RubikGlitch-Regular.ttf")
const PANEL_TEXTURE = preload("res://assets/replacements_v2/ui/dialogue_panel.png")
const CHOICE_TEXTURE = preload("res://assets/replacements_v2/ui/choice_panel.png")
const DREAM_PATTERN = preload("res://assets/fever_dreams/textures/cabin/wallpaper_01.png")
const DREAM_RIPPLE = preload("res://assets/fever_dreams/textures/cabin/wallpaper_06.png")

var busy := false
var menu_open := false
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
var _speaker: Label
var _speaker_patch: ColorRect
var _signal: Label
var _options_panel: Panel
var _objective: Label
var _objective_count: Label
var _notes_count: Label
var _objective_text := ""
var _progress: ProgressBar
var _progress_text: Label
var _modal: Control
var _modal_page := ""
var _pause_context := false
var _menu_controls: Array[Control] = []
var _menu_selected := 0
var _jitter_time := 0.0
var _transition_generation := 0
var _transition_phase := 0
var _scare_active := false
var _scare_generation := 0
var _scare_overlay: Control
var _scare_callback := Callable()
var _scare_previous_busy := false
var _reading_note := false
var _vitals: Control
var _health_bar: ProgressBar
var _health_fill: StyleBoxFlat
var _health_text: Label
var _timer_text: Label
var _shield_text: Label
var _vitals_enabled := false
var _failure_active := false
var _failure_retry := Callable()
var _failure_room := ""

func _ready() -> void:
	layer = 10
	status = label(Vector2(28, 20), Vector2(830, 34), 19)
	status.add_theme_font_override("font", CLINICAL_FONT)
	status.add_theme_color_override("font_color", ACID)
	_notes_count = label(Vector2(28, 54), Vector2(740, 28), 17)
	_notes_count.add_theme_font_override("font", CLINICAL_FONT)
	_notes_count.add_theme_color_override("font_color", PINK)
	_notes_count.hide()
	prompt = label(Vector2(160, 598), Vector2(960, 54), 25)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_objective_count = label(Vector2(1044, 20), Vector2(208, 30), 20)
	_objective_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_objective_count.add_theme_color_override("font_color", PINK)
	_objective = label(Vector2(840, 52), Vector2(412, 96), 19)
	_objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_options_panel = _paper_panel(Vector2.ZERO, Vector2.ONE, CHOICE_TEXTURE)
	_options_panel.hide()
	panel = _paper_panel(Vector2(24, 486), Vector2(1232, 216), PANEL_TEXTURE)
	_speaker_patch = ColorRect.new()
	_speaker_patch.position = Vector2(48, 449)
	_speaker_patch.size = Vector2(270, 31)
	_speaker_patch.color = PINK
	_speaker_patch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_speaker_patch)
	_speaker = label(Vector2(59, 452), Vector2(252, 29), 20)
	_speaker.add_theme_font_override("font", CLINICAL_FONT)
	_ink_label(_speaker)
	_signal = label(Vector2(335, 454), Vector2(400, 26), 16)
	_signal.add_theme_color_override("font_color", ACID)
	body = label(Vector2(56, 516), Vector2(1168, 139), 26)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ink_label(body)
	body.add_theme_constant_override("line_spacing", 3)
	hint = label(Vector2(56, 666), Vector2(1168, 24), 17)
	hint.add_theme_font_override("font", CLINICAL_FONT)
	_ink_label(hint)
	hint.add_theme_color_override("font_color", Color("65505c"))
	_progress = ProgressBar.new()
	_progress.position = Vector2(420, 655)
	_progress.size = Vector2(440, 14)
	_progress.max_value = 1.0
	_progress.show_percentage = false
	_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_progress.add_theme_stylebox_override("background", _flat(Color("271e2e"), Color("8a7380"), 1))
	_progress.add_theme_stylebox_override("fill", _flat(ACID, ACID, 0))
	add_child(_progress)
	_progress_text = label(Vector2(320, 674), Vector2(640, 27), 18)
	_progress_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_progress_text.add_theme_color_override("font_color", ACID)
	_build_vitals()
	fade = ColorRect.new()
	fade.size = Vector2(1280, 720)
	fade.color = Color.BLACK
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.modulate.a = 0
	fade.z_index = 50
	add_child(fade)
	clear()
	set_objective("", 0)

func _paper_panel(pos: Vector2, dimensions: Vector2, texture: Texture2D) -> Panel:
	var result := Panel.new()
	result.position = pos
	result.size = dimensions
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.set_texture_margin_all(12)
	result.add_theme_stylebox_override("panel", style)
	add_child(result)
	return result

func _flat(fill: Color, border: Color, width: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.content_margin_left = 12
	style.content_margin_right = 12
	return style

func label(pos: Vector2, dimensions: Vector2, font_size: int) -> Label:
	var result := Label.new()
	result.position = pos
	result.size = dimensions
	result.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	result.add_theme_font_override("font", PIXEL_FONT)
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", PAPER)
	result.add_theme_color_override("font_shadow_color", Color.BLACK)
	result.add_theme_constant_override("shadow_offset_x", 1)
	result.add_theme_constant_override("shadow_offset_y", 1)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(result)
	return result

func _ink_label(item: Label) -> void:
	item.add_theme_color_override("font_color", INK)
	item.add_theme_color_override("font_shadow_color", Color("28232966"))
	item.add_theme_constant_override("shadow_offset_x", 1)
	item.add_theme_constant_override("shadow_offset_y", 0)

func clear() -> void:
	_cancel_scare()
	_reading_note = false
	# Clearing the outgoing conversation cancels its pending room transition.
	# A newly entered room may clear dialogue while its own fade-in continues.
	if _transition_phase == 1:
		_cancel_transition()
	Game.stop_voice()
	busy = false
	lines.clear()
	choices.clear()
	completion = Callable()
	choice_callback = Callable()
	for button in buttons:
		button.hide()
		button.queue_free()
	buttons.clear()
	panel.hide()
	body.hide()
	hint.hide()
	_speaker.hide()
	_speaker_patch.hide()
	_signal.hide()
	_options_panel.hide()
	prompt.text = ""
	set_unwind_progress(0.0, false)
	if is_instance_valid(Game.active_player) and not menu_open:
		Game.active_player.set_capture(true)

func show_panel() -> void:
	busy = true
	prompt.text = ""
	panel.show()
	body.show()
	hint.show()
	_speaker.show()
	_speaker_patch.show()
	_signal.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if is_instance_valid(Game.active_player):
		Game.active_player.set_capture(false)

func say(texts: Array[String], after: Callable = Callable()) -> void:
	clear()
	lines.assign(texts)
	completion = after
	if lines.is_empty():
		advance()
		return
	show_panel()
	set_text(lines.pop_front())
	hint.text = "E / ENTER / LEFT CLICK  :  CONTINUE                         ESC : PAUSE"

func set_text(text: String) -> void:
	Game.stop_voice()
	body.text = text
	history.append(text)
	var speaker_name := "SESSION TRANSCRIPT"
	var colon := text.find(":")
	if colon > 0 and colon < 22:
		speaker_name = text.substr(0, colon)
	if speaker_name in ["RUE", "PERFORMER"]:
		speaker_name = "RUE / THE PERFORMER"
	elif speaker_name in ["AYUSH", "WITCH"] or text in ["YOU MUST HAVE REMEMBERED IT WRONG.", "NOTHING HAPPENED."]:
		speaker_name = "AYUSH / THE KEEPER"
	_speaker.text = speaker_name
	_speaker_patch.color = PINK if speaker_name in ["AYUSH / THE KEEPER", "RUE / THE PERFORMER"] else PAPER
	_signal.text = "[ THE LINE IS STILL OPEN ]"
	Game.play_dialogue(text)

func choose(options: Array = [], after: Callable = Callable(), question: String = "Choose your response.") -> void:
	clear()
	choices = options.duplicate()
	choice_callback = after
	selected = 0
	show_panel()
	set_text(question)
	hint.text = "W / S / ARROWS : SELECT     E / ENTER / CLICK : RESPOND     ESC : PAUSE"
	if choices.is_empty():
		return
	var row_height := 64.0
	var top := 470.0 - options.size() * row_height - 16.0
	_options_panel.position = Vector2(810, top)
	_options_panel.size = Vector2(430, options.size() * row_height + 16)
	_options_panel.show()
	for i in range(options.size()):
		var button := Button.new()
		button.position = Vector2(824, top + 8 + i * row_height)
		button.size = Vector2(402, row_height)
		button.text = "  " + str(options[i])
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_override("font", PIXEL_FONT)
		button.add_theme_font_size_override("font_size", 22)
		for state in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
			button.add_theme_color_override(state, INK)
		button.add_theme_color_override("font_shadow_color", Color("28232955"))
		button.add_theme_constant_override("shadow_offset_x", 1)
		button.add_theme_constant_override("shadow_offset_y", 0)
		for state in ["normal", "hover", "focus", "pressed"]:
			button.add_theme_stylebox_override(state, _flat(Color.TRANSPARENT if state == "normal" else PINK, Color.TRANSPARENT, 0))
		button.pressed.connect(select_choice.bind(i))
		button.mouse_entered.connect(_select_hover.bind(i))
		add_child(button)
		buttons.append(button)
	_update_choice_selection()

func _select_hover(index: int) -> void:
	if menu_open:
		return
	selected = index
	_update_choice_selection()

func _update_choice_selection() -> void:
	for i in range(buttons.size()):
		buttons[i].add_theme_stylebox_override("normal", _flat(PINK if i == selected else Color.TRANSPARENT, Color.TRANSPARENT, 0))
		buttons[i].text = ("> " if i == selected else "  ") + str(choices[i])

func select_choice(index: int) -> void:
	if menu_open or _scare_active or _transition_phase != 0 or choices.is_empty() or index < 0 or index >= choices.size():
		return
	var callback := choice_callback
	history.append(str(choices[index]))
	Game.play_cue("click")
	clear()
	if callback.is_valid():
		callback.call(index)

func advance() -> void:
	if menu_open or _scare_active or _transition_phase != 0:
		return
	if not lines.is_empty():
		set_text(lines.pop_front())
	else:
		var callback := completion
		clear()
		if callback.is_valid():
			callback.call()

func set_objective(text: String, completed: int = 0) -> void:
	_objective_text = text
	_objective.text = text
	_objective_count.text = "MEMORIES  %d / 4" % clampi(completed, 0, 4) if not text.is_empty() else ""
	if text.is_empty():
		_notes_count.hide()
		hide_vitals()

func _build_vitals() -> void:
	_vitals = Control.new()
	_vitals.position = Vector2(28, 94)
	_vitals.size = Vector2(336, 105)
	_vitals.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_vitals)
	var backing := Panel.new()
	backing.size = Vector2(336, 76)
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxTexture.new()
	style.texture = PANEL_TEXTURE
	style.set_texture_margin_all(12)
	style.modulate_color = Color("302539")
	backing.add_theme_stylebox_override("panel", style)
	_vitals.add_child(backing)
	_health_text = _vitals_label("HEALTH 100", Vector2(15, 12), Vector2(190, 27), 18, PAPER)
	_timer_text = _vitals_label("02:00", Vector2(228, 15), Vector2(98, 46), 28, ACID)
	_timer_text.add_theme_font_override("font", CLINICAL_FONT)
	_health_bar = ProgressBar.new()
	_health_bar.position = Vector2(16, 47)
	_health_bar.size = Vector2(185, 12)
	_health_bar.max_value = 100.0
	_health_bar.show_percentage = false
	_health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_health_bar.add_theme_stylebox_override("background", _flat(Color("17101c"), Color("8e6f86"), 1))
	_health_fill = _flat(ACID, Color.TRANSPARENT, 0)
	_health_fill.content_margin_left = 0.0
	_health_fill.content_margin_right = 0.0
	_health_fill.content_margin_top = 0.0
	_health_fill.content_margin_bottom = 0.0
	_health_bar.add_theme_stylebox_override("fill", _health_fill)
	_vitals.add_child(_health_bar)
	_shield_text = _vitals_label("RUE SHIELD / STAY CLOSE", Vector2(10, 78), Vector2(330, 27), 17, ACID)
	_vitals.hide()

func _vitals_label(text: String, pos: Vector2, dimensions: Vector2, font_size: int, color: Color) -> Label:
	var item := Label.new()
	item.text = text
	item.position = pos
	item.size = dimensions
	item.add_theme_font_override("font", PIXEL_FONT)
	item.add_theme_font_size_override("font_size", font_size)
	item.add_theme_color_override("font_color", color)
	item.add_theme_color_override("font_shadow_color", INK)
	item.add_theme_constant_override("shadow_offset_x", 1)
	item.add_theme_constant_override("shadow_offset_y", 1)
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vitals.add_child(item)
	return item

func set_vitals(health: float, seconds: float, protected: bool) -> void:
	_vitals_enabled = true
	_health_bar.value = clampf(health, 0.0, 100.0)
	_health_text.text = "HEALTH %03d" % int(ceilf(clampf(health, 0.0, 100.0)))
	var remaining := maxi(0, int(ceilf(seconds)))
	_timer_text.text = "%02d:%02d" % [floori(remaining / 60.0), remaining % 60]
	_timer_text.add_theme_color_override("font_color", PINK if seconds <= 15.0 else ACID)
	_health_fill.bg_color = PINK if health <= 25.0 else ACID
	_shield_text.visible = protected or seconds <= 0.0
	_shield_text.text = "RUE SHIELD / STAY CLOSE" if protected else "TIME'S UP / FIND RUE"
	_shield_text.add_theme_color_override("font_color", ACID if protected else PINK)
	_update_vitals_visibility()

func hide_vitals() -> void:
	_vitals_enabled = false
	if is_instance_valid(_vitals):
		_vitals.hide()

func _update_vitals_visibility() -> void:
	var scene := get_tree().current_scene
	var exploring := is_instance_valid(scene) and scene.has_method("run_unwind")
	if exploring:
		exploring = not bool(scene.get("final_escape"))
	_vitals.visible = _vitals_enabled and exploring and not busy and not menu_open and not _scare_active and _transition_phase == 0

func set_notes_count(count: int) -> void:
	_notes_count.text = "UNSENT MESSAGE  /  %d OF 3 SCRAPS" % clampi(count, 0, 3)
	_notes_count.visible = count > 0

func read_note(title: String, text: String, after: Callable = Callable()) -> void:
	var note_text: Array[String] = [text]
	say(note_text, after)
	_reading_note = true
	_speaker.text = title
	_speaker_patch.color = ACID
	_signal.text = "[ A MESSAGE IN HIS OWN WORDS ]"
	hint.text = "E / ENTER / LEFT CLICK : FOLD THE NOTE                         ESC : PAUSE"

func set_unwind_progress(progress: float, active: bool) -> void:
	_progress.value = clampf(progress, 0.0, 1.0)
	_progress.visible = active
	_progress_text.visible = active
	_progress_text.text = "UNWINDING  /  LET THE SPRING RUN BACKWARD  /  %d%%" % int(progress * 100.0)

func _process(delta: float) -> void:
	_jitter_time += delta
	if busy and not menu_open and not _reading_note:
		_signal.text = "[ RECEIVING %s VOICE ]" % Game.dialogue_speaker if Game.voice_is_playing() else "[ THE LINE IS STILL OPEN ]"
	_update_vitals_visibility()
	if _jitter_time >= 2.4:
		_jitter_time = 0.0
		_speaker.position.x = 59.0 if Game.reduced_effects or menu_open else 59.0 + float(randi_range(-1, 1))

func _input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if is_instance_valid(_modal):
			_modal_back()
		elif not _is_title_screen():
			open_pause_menu()
		return
	if is_instance_valid(_modal):
		_menu_input(event)
		return
	if menu_open:
		return
	# Do not let the key which closed the old conversation clear its room fade,
	# or consume the next room's opening line before that room becomes visible.
	# Escape and modal controls are handled above this guard.
	if _transition_phase != 0 or _scare_active:
		get_viewport().set_input_as_handled()
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
		elif event.is_action_pressed("up") or event.is_action_pressed("left") or event.is_action_pressed("ui_up") or event.is_action_pressed("ui_left"):
			selected = posmod(selected - 1, choices.size())
			_update_choice_selection()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("down") or event.is_action_pressed("right") or event.is_action_pressed("ui_down") or event.is_action_pressed("ui_right"):
			selected = (selected + 1) % choices.size()
			_update_choice_selection()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
			get_viewport().set_input_as_handled()
			select_choice(selected)
	elif event.is_action_pressed("interact") or event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		get_viewport().set_input_as_handled()
		advance()

func _is_title_screen() -> bool:
	return is_instance_valid(get_tree().current_scene) and get_tree().current_scene.name == "MainMenu"

func has_open_modal() -> bool:
	return is_instance_valid(_modal)

func _open_modal(page: String, title: String, subtitle: String) -> void:
	if not is_instance_valid(_modal):
		_pause_context = not _is_title_screen()
		if _pause_context:
			Game.set_audio_paused(true)
	else:
		_modal.hide()
		_modal.queue_free()
	menu_open = true
	_modal_page = page
	_menu_controls.clear()
	_menu_selected = 0
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if is_instance_valid(Game.active_player):
		Game.active_player.set_capture(false)
	_modal = Control.new()
	_modal.size = Vector2(1280, 720)
	_modal.z_index = 100
	add_child(_modal)
	var dim := ColorRect.new()
	dim.size = Vector2(1280, 720)
	dim.color = Color("100b19e8")
	_modal.add_child(dim)
	_modal_pattern(DREAM_PATTERN, Vector2(-30, 74), Vector2(270, 570), Color("eb7eba"), -0.09)
	_modal_pattern(DREAM_RIPPLE, Vector2(1080, 23), Vector2(250, 680), Color("c3d552"), 0.10)
	var offset_frame := ColorRect.new()
	offset_frame.position = Vector2(251, 89)
	offset_frame.size = Vector2(768, 582)
	offset_frame.color = Color("8b306f")
	offset_frame.rotation = -0.016
	_modal.add_child(offset_frame)
	var sheet := Panel.new()
	sheet.position = Vector2(266, 72)
	sheet.size = Vector2(748, 584)
	var style := StyleBoxTexture.new()
	style.texture = PANEL_TEXTURE
	style.set_texture_margin_all(12)
	sheet.add_theme_stylebox_override("panel", style)
	_modal.add_child(sheet)
	var heading_tape := ColorRect.new()
	heading_tape.position = Vector2(290, 96)
	heading_tape.size = Vector2(692, 66)
	heading_tape.color = ACID
	heading_tape.rotation = -0.006
	_modal.add_child(heading_tape)
	_modal_label(title, Vector2(306, 103), Vector2(670, 55), 37, TITLE_FONT, INK)
	_modal_label(subtitle, Vector2(310, 167), Vector2(660, 45), 18, CLINICAL_FONT, Color("6d4559"))
	_modal_label("DREAM LINK / HOLD", Vector2(29, 28), Vector2(240, 25), 17, CLINICAL_FONT, ACID)
	_modal_label("THE HOUSE IS STILL HERE", Vector2(1003, 686), Vector2(260, 24), 15, CLINICAL_FONT, PINK)

func _modal_pattern(texture: Texture2D, pos: Vector2, dimensions: Vector2, tint: Color, angle: float) -> void:
	var pattern := TextureRect.new()
	pattern.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pattern.texture = texture
	pattern.stretch_mode = TextureRect.STRETCH_TILE
	pattern.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pattern.position = pos
	pattern.size = dimensions
	pattern.modulate = tint
	pattern.rotation = angle
	pattern.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_modal.add_child(pattern)

func _modal_label(text: String, pos: Vector2, dimensions: Vector2, font_size: int = 23, font: Font = PIXEL_FONT, color: Color = INK) -> Label:
	var item := Label.new()
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item.add_theme_font_override("font", font)
	item.add_theme_font_size_override("font_size", font_size)
	item.add_theme_color_override("font_color", color)
	item.text = text
	item.position = pos
	item.size = dimensions
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_modal.add_child(item)
	return item

func _menu_button(text: String, pos: Vector2, dimensions: Vector2, action: Callable, font_size: int = 24) -> Button:
	var button := Button.new()
	button.text = text
	button.position = pos
	button.size = dimensions
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_override("font", PIXEL_FONT)
	button.add_theme_font_size_override("font_size", font_size)
	for state in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
		button.add_theme_color_override(state, INK)
	for state in ["normal", "hover", "focus", "pressed"]:
		button.add_theme_stylebox_override(state, _flat(Color.TRANSPARENT if state == "normal" else PINK, Color.TRANSPARENT, 0))
	if action.is_valid():
		button.pressed.connect(action)
	_modal.add_child(button)
	_menu_controls.append(button)
	return button

func _focus_first() -> void:
	if not _menu_controls.is_empty():
		_menu_controls[0].grab_focus()

func open_pause_menu() -> void:
	if _failure_active:
		_show_room_failure()
		return
	_open_modal("pause", "SESSION INTERRUPTED", "The house will wait. Your place in the conversation is kept.")
	var entries := ["RESUME SESSION", "HOW TO PLAY", "SETTINGS", "RESTART SESSION", "MAIN MENU"]
	var actions: Array[Callable] = [close_menu, show_help, show_settings, begin_session, return_to_menu]
	for i in range(entries.size()):
		_menu_button(entries[i], Vector2(310, 225 + 65 * i), Vector2(660, 56), actions[i])
	_modal_label("ESC : RESUME    /    W S OR ARROWS : SELECT    /    E : CONFIRM", Vector2(310, 599), Vector2(660, 28), 16, CLINICAL_FONT)
	_focus_first()

func show_help() -> void:
	_open_modal("help", "HOW TO STAY AWAKE", "You are the sleep doctor. Unwind four boxes and reach the patient.")
	var keys := ["W A S D / ARROWS", "MOUSE", "E", "E AT A MUSIC BOX", "ESC"]
	var instructions := ["Move through the dream", "Look around", "Inspect / talk / read / use", "Unwind its spring backward", "Pause / sound / reduced effects"]
	for i in range(keys.size()):
		_modal_label(keys[i], Vector2(310, 224 + i * 34), Vector2(230, 33), 20)
		_modal_label(instructions[i], Vector2(552, 224 + i * 34), Vector2(430, 33), 20)
	_modal_label("120 seconds per room. Start at 100 health.\nAyush hits for 25. Overtime costs 15 every 5 seconds.\nStay within 3 metres of Rue for a protective shield.\nPause menus stop the room clock.\nOptional scraps unlock Rue's one-use distraction.", Vector2(310, 411), Vector2(665, 148), 18, CLINICAL_FONT)
	_menu_button("<  BACK", Vector2(310, 577), Vector2(660, 48), _modal_back)
	_focus_first()

func show_settings() -> void:
	_open_modal("settings", "ADJUST THE SIGNAL", "Sound levels are saved. Reduced effects quiets visual distortion.")
	var settings := Game.get_settings()
	var channels := ["master", "voice", "music", "sfx"]
	var names := ["MASTER", "PATIENT VOICE", "MUSIC BOX", "ROOM / EFFECTS"]
	for i in range(channels.size()):
		var y := 235.0 + i * 66.0
		var channel: String = channels[i]
		_modal_label(names[i], Vector2(310, y + 5), Vector2(218, 33), 20)
		var slider := HSlider.new()
		slider.position = Vector2(535, y)
		slider.size = Vector2(270, 40)
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.05
		slider.value = float(settings[channel + "_volume"])
		slider.add_theme_stylebox_override("slider", _flat(Color("857a80"), INK, 1))
		slider.add_theme_stylebox_override("grabber_area", _flat(Color("7d3f65"), INK, 0))
		slider.add_theme_stylebox_override("grabber_area_highlight", _flat(Color("a74176"), INK, 0))
		_modal.add_child(slider)
		_menu_controls.append(slider)
		var value_label := _modal_label("%d%%" % int(slider.value * 100), Vector2(815, y + 7), Vector2(67, 34), 18)
		slider.value_changed.connect(func(value: float):
			Game.set_setting(channel + "_volume", value)
			value_label.text = "%d%%" % roundi(value * 100)
		)
		if channel != "master":
			var mute := _menu_button("MUTED" if bool(settings[channel + "_muted"]) else "ON", Vector2(890, y), Vector2(84, 40), Callable(), 18)
			mute.toggle_mode = true
			mute.button_pressed = bool(settings[channel + "_muted"])
			mute.toggled.connect(func(value: bool):
				Game.set_setting(channel + "_muted", value)
				mute.text = "MUTED" if value else "ON"
			)
	var reduced := _menu_button("", Vector2(310, 510), Vector2(660, 42), Callable(), 21)
	reduced.toggle_mode = true
	reduced.button_pressed = bool(settings["reduced_effects"])
	reduced.text = "[X] REDUCED EFFECTS" if reduced.button_pressed else "[ ] REDUCED EFFECTS"
	reduced.toggled.connect(func(value: bool):
		Game.set_setting("reduced_effects", value)
		reduced.text = "[X] REDUCED EFFECTS" if value else "[ ] REDUCED EFFECTS"
	)
	_menu_button("<  BACK", Vector2(310, 577), Vector2(660, 48), _modal_back)
	_focus_first()

func show_credits() -> void:
	_open_modal("credits", "THE PEOPLE OUTSIDE", "THE LAST LULLABY / a short fever dream")
	_modal_label("Created by the jam team.\nBuilt in Godot. Patient: synthetic Microsoft David voice.\n\nTextures: Screaming Brain Studios / Kenney\nMusic box tracks: Aureolus_Omicron / OpenGameArt\nV2 heads, music box and UI supplied by the jam team.\n\nDotGothic16: Fontworks / SIL Open Font License\nRubik Glitch: NaN / SIL Open Font License\nSpecial Elite: Astigmatic / Apache License 2.0\n\nFull asset sources and licenses are included with the project.", Vector2(310, 228), Vector2(665, 340), 20)
	_menu_button("<  BACK", Vector2(310, 577), Vector2(660, 48), _modal_back)
	_focus_first()

func _menu_input(event: InputEvent) -> void:
	if _menu_controls.is_empty():
		return
	var focused := get_viewport().gui_get_focus_owner()
	var focused_index := _menu_controls.find(focused)
	if focused_index >= 0:
		_menu_selected = focused_index
	var moving_up := event.is_action_pressed("up") or event.is_action_pressed("ui_up")
	var moving_down := event.is_action_pressed("down") or event.is_action_pressed("ui_down")
	if moving_up or moving_down:
		_menu_selected = posmod(_menu_selected + (-1 if moving_up else 1), _menu_controls.size())
		_menu_controls[_menu_selected].grab_focus()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		if focused is Button:
			if focused.toggle_mode:
				focused.button_pressed = not focused.button_pressed
			focused.pressed.emit()
		get_viewport().set_input_as_handled()

func _modal_back() -> void:
	if _failure_active:
		if _modal_page != "failure":
			_show_room_failure()
		return
	if _pause_context and _modal_page != "pause":
		open_pause_menu()
	else:
		close_menu()

func close_menu() -> void:
	if is_instance_valid(_modal):
		_modal.hide()
		_modal.queue_free()
	_modal = null
	_modal_page = ""
	_menu_controls.clear()
	menu_open = false
	_pause_context = false
	_failure_active = false
	_failure_retry = Callable()
	Game.set_audio_paused(false)
	if is_instance_valid(Game.active_player) and not busy:
		Game.active_player.set_capture(true)
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func begin_session() -> void:
	_cancel_scare()
	_cancel_transition()
	close_menu()
	fade.modulate.a = 0.0
	set_objective("", 0)
	set_notes_count(0)
	hide_vitals()
	Game.start_session()

func return_to_menu() -> void:
	_cancel_scare()
	_cancel_transition()
	close_menu()
	clear()
	set_objective("", 0)
	set_notes_count(0)
	hide_vitals()
	status.text = ""
	fade.modulate.a = 0.0
	Game.return_to_menu()

func room_failed(roomname: String, retry: Callable) -> void:
	if _failure_active:
		return
	_cancel_scare()
	_cancel_transition()
	clear()
	hide_vitals()
	_failure_active = true
	_failure_room = roomname
	_failure_retry = retry
	_show_room_failure()

func _show_room_failure() -> void:
	_open_modal("failure", "CONNECTION LOST", _failure_room + " / THE DREAM HAS PUSHED YOU OUT")
	_modal_label("The link broke. The room is still here.", Vector2(310, 242), Vector2(660, 48), 25)
	_modal_label("Take a breath. Re-enter this room with a fresh connection. Your recovered message scraps stay with you.", Vector2(310, 308), Vector2(660, 112), 23)
	_menu_button(">  RETRY ROOM", Vector2(310, 465), Vector2(660, 61), _retry_failed_room, 27)
	_menu_button("MAIN MENU", Vector2(310, 540), Vector2(660, 61), return_to_menu, 25)
	_modal_label("W / S / ARROWS : SELECT    E / ENTER : CONFIRM", Vector2(310, 615), Vector2(660, 24), 16, CLINICAL_FONT)
	_focus_first()

func _retry_failed_room() -> void:
	if not _failure_active:
		return
	var retry := _failure_retry
	close_menu()
	clear()
	if retry.is_valid():
		retry.call()
	else:
		return_to_menu()

func sleep_into(path: String) -> void:
	_cancel_transition()
	var generation := _transition_generation
	var origin := get_tree().current_scene
	_transition_phase = 1
	busy = true
	Game.stop_voice()
	if not await _transition_fade(generation, origin, 0.0, 1.0, 0.6):
		return
	_transition_phase = 2
	Game.travel(path)
	# Scene changes are deferred until the end of the frame.
	await get_tree().process_frame
	while get_tree().current_scene == null and generation == _transition_generation:
		await get_tree().process_frame
	if generation != _transition_generation:
		return
	var destination := get_tree().current_scene
	if destination.scene_file_path != path:
		_cancel_transition()
		return
	_transition_phase = 3
	if await _transition_fade(generation, destination, 1.0, 0.0, 0.7):
		_transition_phase = 0

func _transition_fade(generation: int, scene: Node, from_alpha: float, to_alpha: float, duration: float) -> bool:
	var elapsed := 0.0
	while elapsed < duration:
		await get_tree().process_frame
		if generation != _transition_generation:
			return false
		if not is_instance_valid(scene) or get_tree().current_scene != scene:
			_cancel_transition()
			return false
		if menu_open:
			continue
		elapsed += get_process_delta_time()
		fade.modulate.a = lerpf(from_alpha, to_alpha, minf(elapsed / duration, 1.0))
	return true

func _cancel_transition() -> void:
	_transition_generation += 1
	_transition_phase = 0
	if is_instance_valid(fade):
		fade.modulate.a = 0.0

func jumpscare(kind: String, after: Callable = Callable()) -> bool:
	if _scare_active or busy or menu_open or _transition_phase != 0:
		return false
	_scare_generation += 1
	var generation := _scare_generation
	_scare_active = true
	_scare_previous_busy = busy
	_scare_callback = after
	busy = true
	prompt.text = ""
	if is_instance_valid(Game.active_player):
		Game.active_player.set_capture(false)
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	_scare_overlay = Control.new()
	_scare_overlay.name = "AyushScare"
	_scare_overlay.size = Vector2(1280, 720)
	_scare_overlay.z_index = 80
	add_child(_scare_overlay)
	var darkness := ColorRect.new()
	darkness.size = Vector2(1280, 720)
	darkness.color = Color("110b15")
	_scare_overlay.add_child(darkness)
	var face := Sprite2D.new()
	face.texture = load("res://assets/replacements_v2/characters/ayush_grain_open.png")
	face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	face.position = Vector2(640, 180)
	face.scale = Vector2.ONE * (1450.0 / float(face.texture.get_width()))
	_scare_overlay.add_child(face)
	var nameplate := Label.new()
	nameplate.text = "AYUSH / THE KEEPER"
	nameplate.position = Vector2(40, 656)
	nameplate.size = Vector2(1200, 48)
	nameplate.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nameplate.add_theme_font_override("font", TITLE_FONT)
	nameplate.add_theme_font_size_override("font_size", 31)
	nameplate.add_theme_color_override("font_color", ACID)
	nameplate.add_theme_color_override("font_outline_color", INK)
	nameplate.add_theme_constant_override("outline_size", 6)
	_scare_overlay.add_child(nameplate)
	Game.play_scare(kind)
	_run_scare(generation, get_tree().current_scene, face, 0.35 if kind == "glimpse" else 0.7)
	return true

func _run_scare(generation: int, origin: Node, face: Sprite2D, duration: float) -> void:
	var elapsed := 0.0
	var original_scale := face.scale
	while elapsed < duration:
		await get_tree().process_frame
		if generation != _scare_generation:
			return
		if not is_instance_valid(origin) or get_tree().current_scene != origin:
			_cancel_scare()
			return
		if menu_open:
			continue
		elapsed += get_process_delta_time()
		if Game.reduced_effects:
			face.position = Vector2(640, 180)
			face.scale = original_scale
		else:
			face.position = Vector2(640 + sin(elapsed * 61.0) * 3.0, 180 + cos(elapsed * 43.0) * 2.0)
			face.scale = original_scale * (1.0 + 0.06 * minf(elapsed / duration, 1.0))
	var callback := _scare_callback
	_scare_callback = Callable()
	_scare_active = false
	busy = _scare_previous_busy
	if is_instance_valid(_scare_overlay):
		_scare_overlay.hide()
		_scare_overlay.queue_free()
	_scare_overlay = null
	if callback.is_valid():
		callback.call()
	if is_instance_valid(Game.active_player) and not busy and not menu_open:
		Game.active_player.set_capture(true)
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _cancel_scare() -> void:
	_scare_generation += 1
	_scare_callback = Callable()
	if _scare_active:
		busy = _scare_previous_busy
	_scare_active = false
	if is_instance_valid(_scare_overlay):
		_scare_overlay.hide()
		_scare_overlay.queue_free()
	_scare_overlay = null
