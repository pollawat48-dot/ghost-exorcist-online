extends SceneTree
## ทดสอบแบบ headless: godot --headless --path . --script res://tests/run_tests.gd

const Combat = preload("res://shared/combat/combat.gd")
const Progression = preload("res://shared/combat/progression.gd")

const STEP := 0.05

var failures := 0


func _initialize() -> void:
	_run_all()


func _run_all() -> void:
	print("== combat ==")
	_test_combat()
	print("== progression ==")
	_test_progression()
	print("== gameplay ==")
	await _test_gameplay()
	if failures == 0:
		print("ผ่านทั้งหมด")
	else:
		printerr("ล้มเหลว %d รายการ" % failures)
	quit(1 if failures > 0 else 0)


func check(cond: bool, name: String) -> void:
	if cond:
		print("  ok   ", name)
	else:
		failures += 1
		printerr("  FAIL ", name)


func _test_combat() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var neutral := 0
	var holy := 0
	for i in 200:
		neutral += Combat.damage(20, 2, "neutral", "spirit", rng)
		holy += Combat.damage(20, 2, "holy", "spirit", rng)
	check(holy > neutral * 2, "พลังศักดิ์สิทธิ์แรงกว่าตีธรรมดากับผีวิญญาณมาก")
	check(Combat.damage(1, 50, "neutral", "none", rng) == 1, "ดาเมจขั้นต่ำคือ 1")


func _test_progression() -> void:
	var state := {"level": 1, "exp": 0}
	check(Progression.add_exp(state, 19) == 0 and state["level"] == 1, "EXP ไม่พอยังไม่อัป")
	check(Progression.add_exp(state, 1) == 1 and state["level"] == 2 and state["exp"] == 0, "EXP ครบแล้วอัปเลเวล")
	check(Progression.add_exp(state, 1000) >= 2, "EXP เยอะอัปหลายเลเวลในครั้งเดียว")


func _test_gameplay() -> void:
	var main: Node2D = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	# ปิดเฟรมจริง แล้วขับเกมด้วย tick() เองเพื่อให้ผลแน่นอน
	main.set_process(false)
	var player: Node2D = main.player
	check(player != null, "โหลดฉากหลักได้")
	if player == null:
		return

	check(player.hp == player.stats["max_hp"], "ผู้เล่นเริ่มด้วย HP เต็ม")
	check(main.alive_ghosts().size() == 12, "ผีเกิดครบ 12 ตัว")

	var dest: Vector2 = player.position + Vector2(100, 0)
	player.command_move(dest)
	_run(main, 2.0)
	check(player.position.distance_to(dest) < 1.0, "คลิกแล้วเดินไปถึงจุดหมาย")

	var ghost: Node2D = main.alive_ghosts()[0]
	check(main.ghost_at(ghost.position + Vector2(5, 5)) == ghost, "คลิกโดนผีแล้วเลือกเป็นเป้าหมาย")

	# ล่าผีแบบที่ผู้เล่นทั่วไปทำ: ตีตัวที่ใกล้ที่สุด, ใช้สกิลตอนประชิด, กินยาตอนเลือดน้อย
	var time := 0.0
	var casts := 0
	while time < 900.0 and player.state["level"] < 3:
		if player.attack_target == null:
			player.command_attack(_nearest(main, player.position))
		elif player.position.distance_to(player.attack_target.position) < 50.0 and player.sp >= 20:
			if player.cast_holy_water():
				casts += 1
		if player.hp < player.stats["max_hp"] * 0.35:
			player.use_herb()
		main.tick(STEP)
		time += STEP
	check(player.state["level"] >= 3, "ล่าผีจนถึงเลเวล 3 (เวลาในเกม %d วินาที, ใช้สกิล %d ครั้ง)" % [time, casts])

	_run(main, 9.0)
	check(main.alive_ghosts().size() == 12, "ผีที่ตายแล้วเกิดใหม่ครบ")

	var drop: Node2D = null
	for d in main.drops.get_children():
		if not d.is_queued_for_deletion():
			drop = d
			break
	check(drop != null, "ผีดรอปไอเทม")
	if drop != null:
		var before := _item_count(player)
		player.command_move(drop.position)
		_run(main, 20.0)
		check(_item_count(player) > before, "เดินทับไอเทมแล้วเก็บเข้ากระเป๋า")

	var herbs: int = player.inventory.get("herb_potion", 0)
	player.hp = 10
	if herbs > 0:
		check(player.use_herb() and player.hp > 10, "ใช้ยาหอมสมุนไพรแล้ว HP เพิ่ม")

	player.take_damage(9999)
	check(player.hp == player.stats["max_hp"] and player.position == player.spawn_point, "สลบแล้วฟื้นที่วัดพร้อม HP เต็ม")
	main.free()


func _run(main: Node2D, seconds: float) -> void:
	var t := 0.0
	while t < seconds:
		main.tick(STEP)
		t += STEP


func _nearest(main: Node2D, pos: Vector2) -> Node2D:
	var best: Node2D = null
	for g in main.alive_ghosts():
		if best == null or pos.distance_to(g.position) < pos.distance_to(best.position):
			best = g
	return best


func _item_count(player: Node2D) -> int:
	var n := 0
	for id in player.inventory:
		n += player.inventory[id]
	return n
