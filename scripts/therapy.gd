extends Node2D

var ticks := 0
var clock: Timer

func _ready() -> void:
	UI.clear()
	Game.active_player = null
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var background := Sprite2D.new()
	background.name = "ConsultationOffice"
	background.texture = load("res://assets/fever_dreams/backgrounds/consultation_office_640x480.png")
	background.centered = false
	background.scale = Vector2(2.0, 1.5)
	background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(background)
	var patient := Sprite2D.new()
	patient.name = "Patient"
	patient.texture = load("res://assets/fever_dreams/characters/patient/patient_idle.png")
	patient.position = Vector2(920, 360)
	patient.scale = Vector2(0.4, 0.4)
	patient.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(patient)
	clock = Timer.new()
	clock.wait_time = 1.1
	clock.timeout.connect(clock_tick)
	add_child(clock)
	clock.start()
	Story.appointment()

func clock_tick() -> void:
	ticks += 1
	if not UI.fade.modulate.a > 0.1:
		Game.play_cue("tick")
		if ticks % 4 == 0:
			await get_tree().create_timer(0.13).timeout
			if is_instance_valid(clock):
				Game.play_cue("tick")
