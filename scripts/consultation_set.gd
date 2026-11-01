extends Node2D
## Shared seated first-person appointment and waking-room composition.
var ending_mode := false
var patient: Sprite2D
var elapsed := 0.0
var speech_energy := 0.0
const HEAD_HOME := Vector2(600, 226)
const HEAD_SCALE := Vector2(0.255, 0.255)
const FACE = preload("res://assets/replacements_v2/characters/patient_grain_sad.png")
const LABEL_FONT = preload("res://assets/replacements_v2/ui/fonts/DotGothic16-Regular.ttf")

func _ready() -> void:
	name = "ConsultationSet"
	var office := Sprite2D.new()
	office.name = "OfficeBackground"
	office.texture = load("res://assets/fever_dreams/backgrounds/consultation_office_640x480.png")
	office.centered = false
	office.scale = Vector2(2, 1.5)
	office.modulate = Color("a5a5bc") if not ending_mode else Color("a9b7b0")
	office.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	office.z_index = -5
	add_child(office)
	patient = Sprite2D.new()
	patient.name = "SeatedPatientHead"
	patient.texture = FACE
	patient.position = HEAD_HOME
	patient.scale = HEAD_SCALE
	patient.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	patient.z_index = 2
	add_child(patient)
	var foreground := Node2D.new()
	foreground.name = "PsychiatristDesk"
	foreground.z_index = 3
	foreground.draw.connect(_draw_foreground.bind(foreground))
	add_child(foreground)

func _process(delta: float) -> void:
	if UI.menu_open:
		return
	elapsed += delta
	speech_energy = lerpf(speech_energy, Game.voice_level(), minf(delta * 15.0, 1.0))
	var quiet := Game.reduced_effects
	var breath := 0.0 if quiet else sin(elapsed * 0.8) * 1.8
	patient.position = HEAD_HOME + Vector2(0, breath - speech_energy * 2.5)
	patient.rotation = 0.0 if quiet else sin(elapsed * 0.37) * 0.012
	patient.scale = HEAD_SCALE * Vector2(1.0, 1.0 + speech_energy * 0.012)
	queue_redraw()

func poly(points: Array, color: String) -> void:
	draw_colored_polygon(PackedVector2Array(points), Color(color))

func _draw() -> void:
	# Narrow chair + angular dark suit, with an intentionally oversized PNG head.
	poly([Vector2(438,292),Vector2(464,272),Vector2(734,272),Vector2(766,297),Vector2(757,463),Vector2(438,463)], "262231")
	poly([Vector2(453,300),Vector2(478,288),Vector2(722,288),Vector2(748,305),Vector2(740,446),Vector2(457,446)], "4d484f")
	poly([Vector2(472,318),Vector2(512,314),Vector2(521,454),Vector2(464,454)], "665765")
	poly([Vector2(708,314),Vector2(740,323),Vector2(735,454),Vector2(691,454)], "383545")
	poly([Vector2(538,341),Vector2(660,341),Vector2(690,373),Vector2(679,455),Vector2(519,455),Vector2(512,373)], "222b2d")
	poly([Vector2(541,345),Vector2(584,355),Vector2(567,422),Vector2(521,391)], "3a4846")
	poly([Vector2(656,345),Vector2(610,356),Vector2(637,429),Vector2(683,389)], "30353d")
	poly([Vector2(576,349),Vector2(619,349),Vector2(606,395),Vector2(591,399)], "8d9890")
	poly([Vector2(540,442),Vector2(596,440),Vector2(589,516),Vector2(526,516)], "1c222b")
	poly([Vector2(608,440),Vector2(666,444),Vector2(680,514),Vector2(617,514)], "272630")
	poly([Vector2(516,367),Vector2(541,380),Vector2(535,418),Vector2(578,430),Vector2(571,448),Vector2(501,433)], "303d3c")
	poly([Vector2(681,365),Vector2(659,379),Vector2(663,418),Vector2(622,432),Vector2(629,447),Vector2(697,430)], "34373f")
	poly([Vector2(571,428),Vector2(593,430),Vector2(607,442),Vector2(575,449)], "919f81")
	poly([Vector2(630,429),Vector2(608,433),Vector2(601,445),Vector2(628,448)], "768f86")
	draw_rect(Rect2(123,302,236,139), Color("282431"))
	draw_rect(Rect2(135,314,210,105), Color("192c2c"))
	var line := PackedVector2Array()
	for i in range(82):
		var wave := 0.0
		if not ending_mode:
			var beat := fposmod(float(i) / 82.0 * 3.0 - elapsed * 0.65, 1.0)
			wave = sin(beat * TAU) * 2.0 + (19.0 if beat > 0.44 and beat < 0.49 else 0.0) - (9.0 if beat > 0.49 and beat < 0.54 else 0.0)
		line.append(Vector2(143 + i * 2.35, 362 - wave))
	draw_polyline(line, Color("d2e591"), 2.0)
	draw_string(LABEL_FONT, Vector2(143,404), "LINK LOST" if ending_mode else "DREAM LINK // 02", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("c7cfb6"))
	draw_circle(Vector2(333,430), 3, Color("d18594") if ending_mode else Color("cedc76"))
	for i in range(25):
		var x := 462.0 + fposmod(i * 23.7, 271.0)
		var y := 300.0 + fposmod(i * 31.3, 142.0)
		draw_line(Vector2(x,y), Vector2(x+6,y+1), Color(0.7,0.62,0.67,0.08), 1.0)

func _draw_foreground(canvas: Node2D) -> void:
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(168,470),Vector2(1074,470),Vector2(1260,720),Vector2(12,720)]),Color("302a36"))
	canvas.draw_line(Vector2(168,470), Vector2(1074,470), Color("79705f"), 5.0)
	for i in range(12):
		canvas.draw_line(Vector2(180+i*72,474),Vector2(15+i*110,720),Color("4a4148"),2.0)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(175,504),Vector2(203,476),Vector2(288,467),Vector2(316,490),Vector2(260,525)]),Color("b8bba6"))
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(282,468),Vector2(324,462),Vector2(350,474),Vector2(331,489),Vector2(306,491)]),Color("9f8881"))
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(1085,510),Vector2(1057,478),Vector2(970,467),Vector2(938,490),Vector2(996,527)]),Color("a8aa9e"))
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(973,469),Vector2(932,461),Vector2(904,475),Vector2(926,491),Vector2(948,491)]),Color("847a7d"))
