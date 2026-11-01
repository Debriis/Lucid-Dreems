extends Node

func _ready() -> void:
	var menu: Node = load("res://scenes/MainMenu.tscn").instantiate()
	get_tree().root.add_child.call_deferred(menu)
	await get_tree().process_frame
	get_tree().current_scene = menu
	await get_tree().create_timer(0.25).timeout
	assert(Game.music.playing)
	var args := OS.get_cmdline_user_args()
	if "--window-close" in args:
		print("AUDIO_QUIT_SMOKE: root window close_requested")
		get_tree().root.close_requested.emit()
	elif "--request" in args:
		print("AUDIO_QUIT_SMOKE: Game.request_quit")
		Game.call("request_quit")
	else:
		print("AUDIO_QUIT_SMOKE: actual MainMenu._quit_game")
		menu.call("_quit_game")
