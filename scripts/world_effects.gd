extends ColorRect

func _process(_delta: float) -> void:
	visible = not Game.reduced_effects and not UI.menu_open
