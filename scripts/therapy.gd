extends Node2D

var ticks := 0
var clock: Timer
var consultation: Node2D

func _ready() -> void:
	UI.clear()
	UI.set_objective("", 0)
	Game.active_player = null
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	consultation = preload("res://scripts/consultation_set.gd").new()
	add_child(consultation)
	clock = Timer.new()
	clock.wait_time = 1.1
	clock.timeout.connect(clock_tick)
	add_child(clock)
	clock.start()
	Story.appointment()

func clock_tick() -> void:
	if UI.menu_open:
		return
	ticks += 1
	if not UI.fade.modulate.a > 0.1:
		Game.play_cue("tick")
		if ticks % 4 == 0:
			await get_tree().create_timer(0.13).timeout
			if is_instance_valid(clock) and not UI.menu_open:
				Game.play_cue("tick")
