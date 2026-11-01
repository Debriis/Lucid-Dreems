extends Node
## Editorial capture harness: uses shipping scenes, assets, dialogue and mechanics.
## Camera paths and scene cuts are staged for the trailer, not a continuous run.
const OUT := "D:/fever-dream/ItchRelease/Promo-v0.2.1/"
var frame := 0
var overlay: CanvasLayer

func _ready() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for i in range(count):
		await get_tree().process_frame
		frame += 1

func hold(seconds: float) -> void:
	await frames(roundi(seconds * 30.0))

func snapshot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT + "screenshots/" + name + ".png")

func caption(text: String, y: float, size: int, font: Font, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.position = Vector2(70, y)
	label.size = Vector2(1140, 180)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	overlay.add_child(label)
	return label

func card(title: String, subtitle: String, seconds: float, developers := false) -> void:
	Game.stop_voice()
	overlay = CanvasLayer.new()
	overlay.layer = 200
	add_child(overlay)
	var dark := ColorRect.new()
	dark.color = Color("120e18")
	dark.size = Vector2(1280,720)
	overlay.add_child(dark)
	var strip := ColorRect.new()
	strip.color = Color("d9e57b")
	strip.position = Vector2(70,108)
	strip.size = Vector2(1140,8)
	overlay.add_child(strip)
	caption(title, 203 if not developers else 137, 79 if not developers else 69, UI.TITLE_FONT, Color("eee6cf"))
	caption(subtitle, 451 if not developers else 345, 27, UI.PIXEL_FONT, Color("df92ba"))
	if developers:
		caption("Sreevalli pallapothu\nAyush (RA2411003010862)\nSamarth Ryan Edward", 442, 26, UI.PIXEL_FONT, Color("eee6cf"))
	await hold(seconds)
	overlay.queue_free()
	await frames(1)

func room(id: int) -> Node:
	UI.clear()
	UI.fade.modulate.a = 0
	Story.stage = id
	Story.tutorial_seen = true
	get_tree().change_scene_to_file(Story.ROOM_PATHS[id])
	await frames(3)
	var result: Node = get_tree().current_scene
	UI.clear()
	result.random_scare_cooldown = 999
	result.chamber_alert_cooldown = 999
	result.catch_grace = 999
	result.update_status()
	return result

func aim(r: Node, point: Vector3, target: Vector3) -> void:
	r.player.position = point
	r.player.rotation = Vector3.ZERO
	r.player.camera.look_at(target)
	r.player.pitch = r.player.camera.rotation.x

func glide(r: Node, start: Vector3, end: Vector3, target: Vector3, seconds: float) -> void:
	for i in range(roundi(seconds * 30)):
		aim(r, start.lerp(end, float(i) / (seconds*30.0)), target)
		await frames(1)

func run() -> void:
	seed(42)
	get_tree().current_scene = null
	# Capture voices and effects; the trailer receives the licensed music-box score in edit.
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), true)
	Game.start_session()
	await frames(4)
	await card("HE SAYS\nHE'S FINE.", "A SESSION INSIDE SOMEONE ELSE'S NIGHTMARE", 2.6)
	Story.appointment_answer(0)
	UI.advance()
	await hold(1.0)
	await snapshot("01-patient-confession")
	await hold(8.2)
	await card("THE HOUSE\nDISAGREES.", "ENTER THE DREAM.", 1.8)
	var r: Node = await room(1)
	UI.say(["RUE: Stay close to me and she can't hurt you. I'm bigger than I was when he carried me to bed."], r.update_status)
	await hold(0.6)
	await snapshot("02-rue-your-protector")
	await hold(3.1)
	UI.clear()
	aim(r, Vector3(15.0,0,21.0), Vector3(14.9,1.35,15.3))
	await glide(r, Vector3(15.0,0,21.0), Vector3(15.5,0,20.0), Vector3(14.9,1.35,15.3), 2.5)
	await snapshot("03-witch-cabin")
	aim(r, r.box.position + Vector3(0,0,1.65), r.box.position + Vector3(0,1.1,0))
	await frames(3)
	Story.activate_box(1,r)
	await hold(1.5)
	await snapshot("04-unwind-the-music-box")
	await hold(0.7)
	UI.clear()
	Story.read_note("unsent_message",r)
	await hold(0.3)
	await snapshot("05-unsent-message")
	await hold(2.3)
	UI.clear()
	r = await room(2)
	# A real camera move along the room's side aisle toward Ayush's throne.
	aim(r, Vector3(12.0,0,34.0), r.witch.position+Vector3(0,1.4,0))
	UI.say(["AYUSH: My room. My rules. Here, nobody has to hear him say he's not okay."],r.update_status)
	await glide(r,Vector3(12.0,0,34.0),Vector3(13.6,0,32.0),r.witch.position+Vector3(0,1.4,0),3.7)
	await snapshot("06-ayush-the-keeper")
	UI.clear()
	r = await room(3)
	aim(r,Vector3(15.3,0,24.0),Vector3(15.3,1.22,4.0))
	await glide(r,Vector3(15.3,0,24.0),Vector3(15.3,0,20.0),Vector3(15.3,1.22,4.0),2.2)
	await snapshot("07-the-school-hall")
	r.begin_chase()
	r.catch_grace = 0.8
	await glide(r,Vector3(15.3,0,20.0),Vector3(15.3,0,25.0),Vector3(15.3,1.5,13.0),3.0)
	await snapshot("08-ayush-pursuit")
	r.catch_grace = 0
	r.trigger_scare("catch")
	await hold(0.22)
	await snapshot("09-caught")
	await hold(0.6)
	r = await room(4)
	await glide(r,Vector3(15.3,0,22.5),Vector3(15.3,0,20.0),Vector3(16.0,1.3,13.0),2.2)
	await snapshot("10-the-last-performance")
	Game.silence()
	await card("THE LAST\nLULLABY", "UNWIND FOUR MUSIC BOXES. FIND A WAY TO WAKE.",3.0)
	await card("THE LAST LULLABY", "A GAME BY",4.0,true)
	print("TRAILER_END_FRAME=",frame)
	# These checks/captures are beyond the trailer's edit out-point.
	Game.return_to_menu()
	await frames(4)
	UI.show_credits()
	await frames(3)
	await snapshot("11-developer-credits")
	UI.close_menu()
	Game.travel("res://scenes/Ending.tscn")
	await frames(3)
	UI.clear()
	get_tree().current_scene.finish()
	await hold(1.0)
	await snapshot("12-ending-credits-review")
	Game.request_quit()
