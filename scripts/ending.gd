extends Node2D

var end_labels: Array[Label] = []
var complete := false

func _ready() -> void:
	UI.clear()
	UI.status.text = "SOMEONE HEARD"
	Game.silence()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var office := Sprite2D.new()
	office.texture = load("res://assets/fever_dreams/backgrounds/consultation_office_640x480.png")
	office.centered = false
	office.scale = Vector2(2, 1.5)
	office.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(office)
	var patient := Sprite2D.new()
	patient.texture = load("res://assets/fever_dreams/characters/patient/patient_idle.png")
	patient.position = Vector2(920, 350)
	patient.scale = Vector2.ONE * 0.4
	patient.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(patient)
	var doctor := preload("res://scripts/player.gd").new()
	doctor.position = Vector2(350, 410)
	doctor.scale = Vector2.ONE * 5
	add_child(doctor)
	doctor.get_node("Camera2D").enabled = false
	doctor.set_physics_process(false)
	doctor.set_process_unhandled_input(false)
	var monitor := Node2D.new()
	monitor.name = "FlatlineMonitor"
	monitor.draw.connect(func():
		monitor.draw_rect(Rect2(50, 180, 240, 110), Color("171c20"))
		monitor.draw_rect(Rect2(58, 188, 224, 94), Color("273b34"))
		monitor.draw_line(Vector2(66, 236), Vector2(274, 236), Color("91cd8b"), 3)
	)
	add_child(monitor)
	Game.play_cue("flatline")
	UI.say(["The patient is awake. The doctor is motionless. The dream monitor flatlines.", "PATIENT: You heard me."], finish)

func finish() -> void:
	Game.stop_cues()
	var tween := create_tween()
	tween.tween_property(UI.fade, "modulate:a", 1.0, 0.7)
	await tween.finished
	Game.play_cue("click")
	var title := UI.label(Vector2(520, 320), Vector2(240, 70), 40)
	title.text = "END."
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_labels.append(title)
	var restart := UI.label(Vector2(420, 410), Vector2(440, 40), 24)
	restart.text = "R / BEGIN ANOTHER SESSION"
	restart.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_labels.append(restart)
	complete = true

func _unhandled_input(event: InputEvent) -> void:
	if complete and event.is_action_pressed("restart") and not event.is_echo():
		UI.fade.modulate.a = 0
		Game.reset()

func _exit_tree() -> void:
	for label in end_labels:
		label.queue_free()
