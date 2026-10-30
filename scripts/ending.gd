extends Node2D

var end_labels: Array[Label] = []
var complete := false

func _ready() -> void:
	UI.clear()
	UI.status.text = "SOMEONE HEARD"
	Game.silence()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Game.active_player = null
	UI.set_objective("", 4)
	var consultation := preload("res://scripts/consultation_set.gd").new()
	consultation.ending_mode = true
	add_child(consultation)
	Game.play_cue("flatline")
	var closing_lines: Array[String] = ["The patient is awake. The doctor is motionless. The dream monitor flatlines."]
	var personal_line: String = Story.ending_extra_line()
	if not personal_line.is_empty():
		closing_lines.append(personal_line)
	closing_lines.append("PATIENT: You heard me.")
	UI.say(closing_lines, finish)

func finish() -> void:
	Game.stop_cues()
	var tween := create_tween()
	tween.tween_property(UI.fade, "modulate:a", 1.0, 0.7)
	await tween.finished
	Game.play_cue("click")
	var title := UI.label(Vector2(520, 320), Vector2(240, 70), 40)
	title.text = "END."
	title.z_index = 60
	title.add_theme_font_override("font", UI.TITLE_FONT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_labels.append(title)
	var restart := UI.label(Vector2(420, 410), Vector2(440, 40), 24)
	restart.text = "R / BEGIN ANOTHER SESSION"
	restart.z_index = 60
	restart.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_labels.append(restart)
	complete = true

func _unhandled_input(event: InputEvent) -> void:
	if complete and not UI.menu_open and event.is_action_pressed("restart") and not event.is_echo():
		UI.fade.modulate.a = 0
		Game.reset()

func _exit_tree() -> void:
	for label in end_labels:
		label.queue_free()
