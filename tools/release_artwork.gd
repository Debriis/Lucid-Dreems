extends Control
const OUT := "D:/fever-dream/ItchRelease/page-assets/"
func texture(path: String, at: Vector2, dimensions: Vector2, tint := Color.WHITE) -> void:
	var item := Sprite2D.new()
	item.texture = load(path)
	item.position = at
	item.centered = false
	item.scale = dimensions / item.texture.get_size()
	item.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	item.modulate = tint
	add_child(item)
func words(value: String, at: Vector2, dimensions: Vector2, size_px: int, font: Font, tint: Color) -> void:
	var label := Label.new()
	label.text = value
	label.position = at
	label.size = dimensions
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size_px)
	label.add_theme_color_override("font_color", tint)
	add_child(label)
func _ready() -> void:
	UI.hide()
	get_window().size = Vector2i(630, 500)
	get_window().content_scale_size = Vector2i(630, 500)
	texture("res://assets/fever_dreams/textures/cabin/wallpaper_03.png", Vector2.ZERO, Vector2(630, 500), Color("774b6e"))
	texture("res://assets/replacements_v2/ui/dialogue_panel.png", Vector2(18, 18), Vector2(594, 168), Color("e1e88a"))
	words("THE LAST", Vector2(33, 26), Vector2(560, 75), 61, UI.TITLE_FONT, Color("321c37"))
	words("LULLABY", Vector2(32, 91), Vector2(560, 88), 73, UI.TITLE_FONT, Color("211925"))
	texture("res://assets/replacements_v2/characters/purple_performer_head.png", Vector2(300, 198), Vector2(290, 252))
	words("YOU ARE THE\nSLEEP DOCTOR.", Vector2(30, 219), Vector2(294, 90), 27, UI.CLINICAL_FONT, Color("e4e96b"))
	words("Four music boxes.\nOne way out.\nStay close to Rue.", Vector2(31, 333), Vector2(300, 100), 21, UI.PIXEL_FONT, Color("f0e9de"))
	texture("res://assets/replacements_v2/ui/selected_row.png", Vector2(17, 461), Vector2(598, 28))
	words("A SHORT PSYCHEDELIC HORROR GAME", Vector2(35, 463), Vector2(580, 28), 18, UI.PIXEL_FONT, Color("271c28"))
	for i in range(6):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(OUT)
	get_viewport().get_texture().get_image().save_png(OUT + "cover-630x500.png")
	print("ITCH COVER SAVED")
	Game.request_quit()
