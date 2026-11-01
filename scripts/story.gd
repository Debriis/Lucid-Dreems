extends Node
## Canonical progression is stored here, never in scene-local copies.
var stage := 0
var boxes: Dictionary = {}
var notes: Dictionary = {}
var room_unlocked := false
var met_performer := false
var finished := false
var ending_phase := 0
var tutorial_seen := false
var sequence_generation := 0
var _ending_generation := 0
const ROOM_PATHS := ["", "res://scenes/WitchCabin.tscn", "res://scenes/DiningRoom.tscn", "res://scenes/SchoolHall.tscn", "res://scenes/Theatre.tscn"]
const TITLES := ["THE APPOINTMENT", "I / THE WITCH'S CABIN", "II / AYUSH'S CHAMBER", "III / THE HALL", "IV / THE LAST NOTE", "SOMEONE HEARD"]
const FINAL_CHOICE_SECONDS := 6.0

func reset() -> void:
	sequence_generation += 1
	_ending_generation += 1
	stage = 0
	boxes.clear()
	notes.clear()
	UI.set_notes_count(0)
	room_unlocked = false
	met_performer = false
	finished = false
	ending_phase = 0
	tutorial_seen = false

func completed_count() -> int:
	return boxes.values().count("complete")

func is_box_complete(id: int) -> bool:
	return boxes.get(id, "") == "complete"

func appointment() -> void:
	UI.status.text = "THE LAST LULLABY / THE APPOINTMENT"
	UI.say(["YOU ARE THE SLEEP DOCTOR. Tonight, you will enter a patient's recurring dream and stay with him until he can wake.", "Four music boxes hold the dream together. Unwind them, listen to the memories, and find a way through the witch's house. You cannot fight her. You will need Rue.", "The patient hasn't answered his friends in weeks. He tells them he's fine. Every night he returns to a witch's cabin and wakes before the music ends.", "DOCTOR: What happens when you close your eyes?"], appointment_choices)

func appointment_choices() -> void:
	UI.choose(["TELL ME ABOUT THE HOUSE.", "WHO ELSE IS THERE?", "WHAT WAKES YOU UP?"], appointment_answer, "DOCTOR: What happens when you close your eyes?")

func appointment_answer(index: int) -> void:
	var answers := ["PATIENT: It looks like a witch's cabin. But the rooms inside are rooms I know.", "PATIENT: Rue. A purple toy that used to play me to sleep. Now it dances even when nobody's watching.", "PATIENT: Ayush. She says she's keeping me safe. Then the face opens, and I wake up."]
	UI.say([answers[index], "PATIENT: My friend Maya keeps asking if I'm okay. I type 'I'm fine.' I can't even send that anymore.", "DOCTOR: You don't have to find the right answer. I'll stay with you while we look.", "The patient closes his eyes. The ticking clock becomes a music box."], enter_dream)

func enter_dream() -> void:
	stage = 1
	Game.play_music_box(false)
	Game.play_cue("dream")
	UI.sleep_into(ROOM_PATHS[1])

func enter_room(id: int, room: Node) -> void:
	if stage == 0: # F6 supports testing a room directly.
		stage = id
	room_unlocked = is_box_complete(id)
	Game.play_music_box(id > 1)
	room.update_status()
	if id == 1 and not tutorial_seen:
		tutorial_seen = true
		UI.say(["RUE / THE PERFORMER. The patient's childhood bunny, rebuilt by the dream from purple metal. He still remembers how to keep someone safe.", "RUE: Stay close to me and she can't hurt you. I'm bigger than I was when he carried me to bed.", "Each room gives you 120 seconds. Ayush's touch takes health. When time runs out, the house hurts you too. Your health and clock reset in the next room.", "WASD / arrows move. MOUSE / Q C look. E interacts. ESC pauses. Reading, talking and unwinding stop the clock. Stay near Rue for protection.", "Find this room's music box, unwind it, and hear its memory to unlock the exit. Three optional message scraps reveal what the patient couldn't say. Show Rue one to unlock a distraction.", "First: turn LEFT beyond Rue into the cabin. Find MUSIC BOX 01 on the small table. You can read the folded letter beside the entrance."], room.update_status)
	elif id == 2:
		UI.say(["AYUSH'S CHAMBER. A family table has become a throne. Every chair faces the wall. The witch has kept a place for him.", "AYUSH: My room. My rules. Here, nobody has to hear him say he's not okay.", "RUE: She won't let me take him out. But I can protect you while you open the way.", "MUSIC BOX 02 waits at the near end of the long table. After its memory, follow the side aisle to the exit at the far end."], room.update_status)
	elif id == 3:
		UI.say(["A school corridor fits inside the cabin. A telephone rings in a locked room. The door reads: NOTHING HAPPENED HERE.", "Search that marked door at the far end. MUSIC BOX 03 is behind it. Your exit is back where you entered."], room.update_status)
	elif id == 4:
		room.stop_performer()
		UI.say(["RUE: I kept the song going.", "DOCTOR: Even when he wanted to leave?", "RUE: He stopped crying when I played it. I thought that meant I was helping.", "AYUSH: Outside, they can stop loving him. In here, nothing changes.", "RUE: I only knew one song. This time, I'll keep her busy. You open the door."], room.update_status)

func performer_greeting() -> void:
	UI.say(["RUE: Welcome back. Stay close. I can keep her away."], func():
		UI.choose(["I'M NOT THE PATIENT.", "WHERE IS THE EXIT?", "STOP DANCING."], _greeting_answer, "Rue's smile stays on the beat.")
	)

func _greeting_answer(index: int) -> void:
	var replies: Array[String] = ["RUE: Then help me get him out. I'm Rue. He used to sleep with one hand around my ear.", "RUE: Every music box remembers a door. Turn the key backward. I'll keep Ayush off you while you're close to me.", "RUE: The dancing keeps her looking at me. I'd rather she watched me than him."]
	UI.say([replies[index]], func():
		met_performer = true
		refresh()
	)

func performer_conversation(room: Node) -> void:
	if UI.busy or UI.menu_open or not is_instance_valid(room):
		return
	if not met_performer:
		performer_greeting()
		return
	var options := ["WHY KEEP PLAYING?", "DO YOU KNOW AYUSH?", "KEEP HER BUSY." if not notes.is_empty() else "CAN YOU HELP ME?"]
	UI.choose(options, func(index: int):
		if not is_instance_valid(room):
			return
		match index:
			0:
				var reply := "RUE: I was a teddy with one loose ear. Every time he said 'I'm fine,' I played a little louder. I didn't notice he was trying to say something else."
				if notes.has("unsent_message"):
					reply = "RUE: That draft says he misses her. I've been playing over it for weeks. I thought silence was the thing hurting him."
				UI.say([reply], room.update_status)
			1:
				UI.say(["RUE: Ayush keeps the doors shut so nobody can disappoint him. She calls that safe. I think safe is supposed to have a way out."], room.update_status)
			2:
				if notes.is_empty():
					UI.say(["RUE: My shield works while you're close. Find a scrap of his message and I'll distract her too. Eight seconds for you to run. A different song, just once in each room."], room.update_status)
				elif room.distract_witch():
					UI.say(["RUE: Eight seconds. I'll sing the wrong words. She hates that. Go when I start."], room.update_status)
				else:
					UI.say(["RUE: She knows that trick now. I can only fool her once in each room. Keep moving."], room.update_status)
	, "Rue keeps time with an audience that isn't there.")

func read_note(id: String, room: Node) -> bool:
	if UI.busy or UI.menu_open or not is_instance_valid(room):
		return false
	var title := ""
	var text := ""
	var reply := ""
	match id:
		"unsent_message":
			title = "DRAFT 01 / UNSENT"
			text = "Hey, Maya. Sorry I disappeared. I'm not busy. I just keep thinking you deserve an answer from someone who's doing better than this."
			reply = "PATIENT: I wrote that on the bus. Then I sent a picture of a dog instead. She laughed. I felt worse."
		"birthday_ticket":
			title = "DRAFT 02 / THE TICKET"
			text = "I kept your birthday ticket. I got as far as the bus stop, then went home. You said you missed me. I read it like you were angry."
			reply = "PATIENT: She saved me a slice of cake. I let it become another thing I had to apologise for."
		"last_note":
			title = "DRAFT 03 / NOT FINISHED"
			text = "I don't need you to fix this. Could you sit with me for a bit? We don't have to talk. I don't know why that is the hardest part to send."
			reply = "PATIENT: That's what I wanted to ask. I thought needing someone would make them leave."
		_:
			return false
	var first_read := not notes.has(id)
	notes[id] = true
	UI.set_notes_count(notes.size())
	UI.read_note(title, text, func():
		if not is_instance_valid(room):
			return
		if first_read:
			UI.say([reply], room.update_status)
		else:
			room.update_status()
	)
	return true

func ending_extra_line() -> String:
	if notes.size() == 3:
		return "PATIENT: I think I'll send it. Just: I'm not fine. Could you sit with me?"
	if not notes.is_empty():
		return "PATIENT: I want to answer Maya. I don't have the words yet. But I want to."
	return ""

func activate_box(id: int, room: Node) -> bool:
	if UI.busy or UI.menu_open or id < 1 or id > 4 or id != stage or boxes.has(id) or not is_instance_valid(room):
		return false
	# Reserve synchronously: another E press cannot start a duplicate coroutine.
	boxes[id] = "unwinding"
	room_unlocked = false
	complete_unwind(id, room, sequence_generation)
	return true

func complete_unwind(id: int, room: Node, generation: int) -> void:
	Game.unwind_music(id)
	await room.run_unwind(id)
	if generation != sequence_generation or not is_instance_valid(room) or stage != id or boxes.get(id, "") != "unwinding":
		return
	boxes[id] = "remembering"
	play_memory(id, room)

func play_memory(id: int, room: Node) -> void:
	match id:
		1:
			room.jerk_performer()
			UI.say(["PATIENT: Rue used to play when I couldn't sleep. Later I played the song before answering anyone. Just until I felt normal.", "PATIENT: I kept waiting. The messages kept arriving."], func():
				room.reveal_witch()
				finish_box(id, room)
			)
		2:
			UI.say(["PATIENT: At dinner, Mum asked for good news. If I didn't have any, I was ruining the evening. 'I'm fine' let everyone finish eating."], func():
				UI.choose(["WHAT DID YOU WANT TO SAY?", "YOU DON'T HAVE TO PERFORM."], func(index: int):
					var replies: Array[String] = ["PATIENT: That I was scared. That nothing felt like anything. I kept waiting for a version of me they would want at the table.", "PATIENT: I don't know what I look like when I'm not making it easier for everyone else. I'm afraid there's nothing underneath."]
					UI.say([replies[index], "RUE: Quiet sounds so much like peace. Until you listen.", "AYUSH: I'm keeping you safe. Nobody can reject you here."], func():
						room.face_plates()
						room.begin_chase()
						finish_box(id, room)
					)
				, "The silence at the table deepens.")
			)
		3:
			UI.say(["PATIENT: They read my message out in the corridor. Everyone laughed. I started deleting things before anyone could see them.", "PATIENT: Maya isn't like them. I know that. My hands don't."], func():
				UI.choose(["I BELIEVE YOU.", "IT WASN'T YOUR FAULT.", "YOU CAN TAKE YOUR TIME."], func(index):
					var replies: Array[String] = ["PATIENT: I thought you'd need proof. I've spent so long trying to make it sound bad enough to count.", "PATIENT: I keep rewriting the message. As if the right words could have made them kinder.", "PATIENT: Thank you. People usually fill the silence before I find the words."]
					UI.say(["DOCTOR: " + ["I BELIEVE YOU.", "IT WASN'T YOUR FAULT.", "YOU CAN TAKE YOUR TIME."][index], replies[index]], func():
						UI.say(["YOU MUST HAVE REMEMBERED IT WRONG."], func():
							room.face_plates()
							room.begin_chase()
							finish_box(id, room)
						)
					)
				, "He waits for your answer.")
			)
		4:
			Game.silence()
			room.silence_room()
			var extra := "PATIENT: I don't know what comes after the door. I'd like to find out."
			if notes.size() == 3:
				extra = "PATIENT: I don't need a perfect message. I could start with: I'm not fine. Are you there?"
			elif not notes.is_empty():
				extra = "PATIENT: There's someone I want to answer. I don't know what to say yet."
			UI.say(["Rue becomes completely still. All music and ambience stop.", "PATIENT: I don't want to stay here.", extra], func(): finish_box(id, room))

func finish_box(id: int, room: Node) -> void:
	if id != stage or boxes.get(id, "") != "remembering" or not is_instance_valid(room):
		return
	boxes[id] = "complete"
	room_unlocked = true
	room.memory_changed(id)
	room.update_status()

func refresh() -> void:
	var room = get_tree().current_scene
	if is_instance_valid(room) and room.has_method("update_status"):
		room.update_status()

func next_room(room: Node) -> void:
	if UI.busy or UI.menu_open or stage < 1 or stage > 4:
		return
	if not room_unlocked or not is_box_complete(stage):
		UI.say(["The door will not open. The music box is still holding this room."], room.update_status)
		return
	if stage == 4:
		if completed_count() != 4:
			UI.say(["Four music boxes hold this dream. Every memory must be heard before the final door opens."], room.update_status)
			return
		stage = 5
		room_unlocked = false
		room.start_final_escape()
	else:
		room_unlocked = false
		stage += 1
		Game.crossings += 1
		Game.play_cue("dream")
		UI.sleep_into(ROOM_PATHS[stage])

func ending_choices(room: Node) -> void:
	_ending_generation += 1
	var generation := _ending_generation
	ending_phase = 1
	UI.choose(["I BELIEVE YOU.", "IT WASN'T YOUR FAULT.", "YOU DON'T HAVE TO STAY HERE."], func(index: int): _ending_reply(index, room, generation), "The consultation doorway recedes. Ayush approaches.")
	var waiting := 0.0
	while waiting < FINAL_CHOICE_SECONDS and generation == _ending_generation and ending_phase == 1 and is_instance_valid(room):
		await get_tree().process_frame
		if not UI.menu_open:
			waiting += get_process_delta_time()
	if generation == _ending_generation and ending_phase == 1 and is_instance_valid(room):
		denial(room)

func _ending_reply(index: int, room: Node, generation: int) -> void:
	if generation != _ending_generation or ending_phase != 1 or not is_instance_valid(room):
		return
	# Claim the choice before showing its answer: the old timeout cannot erase it.
	ending_phase = 4
	var replies: Array[String] = ["AYUSH: Believe him, then. See how long you stay when he stops smiling.", "AYUSH: Blame is not the point. If he never tries again, he can never fail again.", "AYUSH: Out there, he has to be someone they can love. I keep that perfect little version safe."]
	UI.say([replies[index]], func():
		if generation == _ending_generation and ending_phase == 4 and is_instance_valid(room):
			denial(room)
	)

func denial(room: Node) -> void:
	if ending_phase not in [1, 4] or not is_instance_valid(room):
		return
	ending_phase = 2
	UI.choose(["I'M STILL LISTENING."], func(_index):
		ending_phase = 3
		room.swallow_screen()
	, "NOTHING HAPPENED.")

func finish_ending() -> void:
	finished = true
	Game.ending = "someone_heard"
