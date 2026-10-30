extends Node
## Canonical progression is stored here, never in scene-local copies.
var stage := 0
var boxes: Dictionary = {}
var room_unlocked := false
var met_performer := false
var finished := false
var ending_phase := 0
const ROOM_PATHS := ["", "res://scenes/WitchCabin.tscn", "res://scenes/DiningRoom.tscn", "res://scenes/SchoolHall.tscn", "res://scenes/Theatre.tscn"]
const TITLES := ["THE APPOINTMENT", "I / THE PERFORMANCE", "II / THE TABLE", "III / THE HALL", "IV / THE LAST NOTE", "SOMEONE HEARD"]

func reset() -> void:
	stage = 0
	boxes.clear()
	room_unlocked = false
	met_performer = false
	finished = false
	ending_phase = 0

func appointment() -> void:
	UI.status.text = "THE LAST LULLABY / THE APPOINTMENT"
	UI.say(["The patient has not slept properly for weeks. Every night he returns to a witch's cabin. He always wakes before the music ends.", "DOCTOR: What happens when you close your eyes?"], appointment_choices)

func appointment_choices() -> void:
	UI.choose(["TELL ME ABOUT THE HOUSE.", "WHO ELSE IS THERE?", "WHAT WAKES YOU UP?"], appointment_answer, "DOCTOR: What happens when you close your eyes?")

func appointment_answer(index: int) -> void:
	var answers := ["PATIENT: It looks like a witch's cabin. But the rooms inside are rooms I know.", "PATIENT: There's a purple thing. It dances even when nobody's watching.", "PATIENT: There's someone else, too. I never see their mouth move. The whole face opens."]
	UI.say([answers[index], "PATIENT: I think something happened in that house. Every time I remember, the song starts again.", "DOCTOR: You don't have to explain everything at once. I'll stay with you.", "The patient closes his eyes. The ticking clock becomes a music box."], enter_dream)

func enter_dream() -> void:
	stage = 1
	Game.play_music_box(false)
	Game.play_cue("dream")
	UI.sleep_into(ROOM_PATHS[1])

func enter_room(id: int, room: Node) -> void:
	if stage == 0: # F6 supports testing a room directly.
		stage = id
	UI.status.text = TITLES[id] + "    /    BOXES %d / 4" % boxes.values().count("complete")
	if id == 1 and not met_performer:
		performer_greeting()
	elif id == 2:
		UI.say(["The dining room is longer than the house. The chairs face the walls. A knock comes from the wrong side of the room."], room.update_status)
	elif id == 3:
		UI.say(["A school corridor fits inside the cabin. The lockers have wooden doors. One reads: NOTHING HAPPENED HERE."], room.update_status)
	elif id == 4:
		room.stop_performer()
		UI.say(["PERFORMER: I kept the song going.", "DOCTOR: Why?", "PERFORMER: If he listened to me, he couldn't hear the house.", "The repeating song protected him from painful memories. It also kept him from feeling anything. The witch is the denial that punishes speaking.", "PERFORMER: I only knew one song."], room.update_status)

func performer_greeting() -> void:
	UI.say(["PERFORMER: Welcome back. You look happy."], func():
		UI.choose(["I'M NOT THE PATIENT.", "WHERE IS THE EXIT?", "STOP DANCING."], func(_index):
			UI.say(["PERFORMER: You look happy."], func():
				met_performer = true
				refresh()
			)
		, "The Performer keeps dancing.")
	)

func activate_box(id: int, room: Node) -> bool:
	if UI.busy or id != stage or boxes.has(id):
		return false
	boxes[id] = "unwinding"
	room_unlocked = false
	UI.say(["You wind the key backward. The melody slows, reverses, and stops."], func(): play_memory(id, room))
	Game.unwind_music(id)
	return true

func play_memory(id: int, room: Node) -> void:
	match id:
		1:
			room.jerk_performer()
			UI.say(["PATIENT VOICE: When I cried, she played this song. I wasn't allowed to leave until I smiled."], func():
				room.reveal_witch()
				finish_box(id, room)
			)
		2:
			UI.say(["PATIENT: My mother could hurt me, then sit down and ask how my day was. If I mentioned it, she said I was ruining dinner."], func():
				UI.choose(["WHAT HAPPENED NEXT?", "YOU DIDN'T DESERVE THAT."], func(_index):
					UI.say(["PATIENT: I learned to say nothing. After a while, I didn't know what I was feeling anymore.", "PERFORMER: See? Quiet is better.", "WITCH: We were having such a nice evening."], func():
						room.face_plates()
						room.begin_chase()
						finish_box(id, room)
					)
				, "The silence at the table deepens.")
			)
		3:
			UI.say(["PATIENT: Some people I trusted hurt me. When I told her, she asked what I'd done to make them angry.", "PATIENT: After that, I stopped telling anyone."], func():
				UI.choose(["I BELIEVE YOU.", "IT WASN'T YOUR FAULT.", "YOU CAN TAKE YOUR TIME."], func(index):
					UI.say(["DOCTOR: " + ["I BELIEVE YOU.", "IT WASN'T YOUR FAULT.", "YOU CAN TAKE YOUR TIME."][index], "PATIENT: Can you say that again?"], func():
						UI.say(["YOU MUST HAVE REMEMBERED IT WRONG."], func():
							room.begin_chase()
							finish_box(id, room)
						)
					)
				, "He waits for your answer.")
			)
		4:
			Game.silence()
			room.silence_room()
			UI.say(["The Performer becomes completely still. All music and ambience stop.", "PATIENT: I don't want to stay here."], func(): finish_box(id, room))

func finish_box(id: int, room: Node) -> void:
	boxes[id] = "complete"
	room_unlocked = true
	room.memory_changed(id)
	room.update_status()

func refresh() -> void:
	var room = get_tree().current_scene
	if is_instance_valid(room) and room.has_method("update_status"):
		room.update_status()

func next_room(room: Node) -> void:
	if UI.busy:
		return
	if not room_unlocked:
		UI.say(["The door will not open. The music box is still holding this room."], room.update_status)
		return
	if stage == 4:
		stage = 5
		room.start_final_escape()
	else:
		room_unlocked = false
		stage += 1
		Game.crossings += 1
		Game.play_cue("dream")
		UI.sleep_into(ROOM_PATHS[stage])

func ending_choices(room: Node) -> void:
	ending_phase = 1
	UI.choose(["I BELIEVE YOU.", "IT WASN'T YOUR FAULT.", "YOU DON'T HAVE TO STAY HERE."], func(_index): denial(room), "The consultation doorway recedes. The witch approaches.")
	await get_tree().create_timer(1.5).timeout
	if ending_phase == 1 and is_instance_valid(room):
		denial(room)

func denial(room: Node) -> void:
	if ending_phase != 1:
		return
	ending_phase = 2
	UI.choose(["I'M STILL LISTENING."], func(_index):
		ending_phase = 3
		room.swallow_screen()
	, "NOTHING HAPPENED.")

func finish_ending() -> void:
	finished = true
	Game.ending = "someone_heard"
