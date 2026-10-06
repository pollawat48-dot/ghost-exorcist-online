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
	var main: Node3D = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	# ปิดเฟรมจริง แล้วขับเกมด้วย tick() เองเพื่อให้ผลแน่นอน
	main.set_process(false)
	var player: Node3D = main.player
	check(player != null, "โหลดฉากหลักได้")
	if player == null:
		return

	check(player.hp == player.stats["max_hp"], "ผู้เล่นเริ่มด้วย HP เต็ม")
	check(main.alive_ghosts().size() == 12, "ผีเกิดครบ 12 ตัว")

	var dest: Vector2 = player.pos + Vector2(100, 0)
	player.command_move(dest)
	_run(main, 2.0)
	check(player.pos.distance_to(dest) < 1.0, "คลิกแล้วเดินไปถึงจุดหมาย")

	var map: Node3D = main.map
	var canal_mid := Vector2(map.canal_center(500.0), 500.0)
	check(not map.is_walkable(canal_mid), "เดินลงคลองไม่ได้")
	check(map.is_walkable(Vector2(map.canal_center(1000.0), 1000.0)), "เดินบนสะพานได้")
	var route: PackedVector2Array = map.find_path(map.spawn_point, Vector2(1800, 500))
	var crossed_on_bridge := true
	var prev: Vector2 = map.spawn_point
	for p in route:
		if not map.is_walkable(p):
			crossed_on_bridge = false
		if (prev.x - map.canal_center(prev.y)) * (p.x - map.canal_center(p.y)) < 0.0 and absf(p.y - 1000.0) > 48.0:
			crossed_on_bridge = false
		prev = p
	check(route.size() > 0 and crossed_on_bridge, "หาทางจากหมู่บ้านไปทุ่งนาโดยข้ามทางสะพาน")
	player.command_move(Vector2(1800, 500))
	_run(main, 30.0)
	check(player.pos.distance_to(Vector2(1800, 500)) < 40.0, "เดินจากวัดข้ามสะพานไปถึงทุ่งนา")
	player.pos = map.spawn_point

	var ghost: Node3D = main.alive_ghosts()[0]
	check(main.ghost_at(ghost.pos + Vector2(5, 5)) == ghost, "คลิกโดนผีแล้วเลือกเป็นเป้าหมาย")

	# ล่าผีแบบที่ผู้เล่นทั่วไปทำ: ตีตัวที่ใกล้ที่สุด, ใช้สกิลตอนประชิด, กินยาตอนเลือดน้อย
	var time := 0.0
	var casts := 0
	while time < 900.0 and player.state["level"] < 3:
		if player.attack_target == null:
			player.command_attack(_nearest(main, player.pos))
		elif player.pos.distance_to(player.attack_target.pos) < 50.0 and player.sp >= 20:
			if player.cast_holy_water():
				casts += 1
		if player.hp < player.stats["max_hp"] * 0.35:
			player.use_herb()
		main.tick(STEP)
		time += STEP
	check(player.state["level"] >= 3, "ล่าผีจนถึงเลเวล 3 (เวลาในเกม %d วินาที, ใช้สกิล %d ครั้ง)" % [time, casts])

	_run(main, 9.0)
	check(main.alive_ghosts().size() == 12, "ผีที่ตายแล้วเกิดใหม่ครบ")

	var drop: Node3D = null
	for d in main.drops.get_children():
		if not d.is_queued_for_deletion():
			drop = d
			break
	check(drop != null, "ผีดรอปไอเทม")
	if drop != null:
		var before := _item_count(player)
		player.command_move(drop.pos)
		_run(main, 20.0)
		check(_item_count(player) > before, "เดินทับไอเทมแล้วเก็บเข้ากระเป๋า")

	var herbs: int = player.inventory.get("herb_potion", 0)
	player.hp = 10
	if herbs > 0:
		check(player.use_herb() and player.hp > 10, "ใช้ยาหอมสมุนไพรแล้ว HP เพิ่ม")

	player.take_damage(9999)
	check(player.hp == player.stats["max_hp"] and player.pos == player.spawn_point, "สลบแล้วฟื้นที่วัดพร้อม HP เต็ม")
	check(map.props_root.get_child_count() > 100, "สร้างฉาก 3D ครบ (สิ่งของ %d ชิ้น)" % map.props_root.get_child_count())

	# จอยบนจอ (มือถือ): ดันจอยแล้วเดินต่อเนื่อง และเดินลงคลองไม่ได้
	var start: Vector2 = player.pos
	player.stick = Vector2(0, 1)
	_run(main, 1.0)
	player.stick = Vector2.ZERO
	check(player.pos.y - start.y > player.SPEED * 0.8, "ดันจอยแล้วตัวละครเดินตาม")
	player.pos = Vector2(map.canal_center(600.0) - 120.0, 600.0)
	player.stick = Vector2(1, 0)
	_run(main, 3.0)
	player.stick = Vector2.ZERO
	check(not map.is_water(player.pos), "ดันจอยเข้าหาคลองแล้วไม่ตกน้ำ")

	# ปุ่มโจมตีบนจอ: เลือกผีที่ใกล้ที่สุดเป็นเป้าหมายเอง
	var near_ghost := _nearest(main, player.pos)
	player.pos = near_ghost.pos + Vector2(60, 0)
	main.do_action("attack")
	check(player.attack_target == near_ghost, "กดปุ่มโจมตีแล้วล็อกผีตัวที่ใกล้ที่สุด")
	main.free()


func _run(main: Node3D, seconds: float) -> void:
	var t := 0.0
	while t < seconds:
		main.tick(STEP)
		t += STEP


func _nearest(main: Node3D, pos: Vector2) -> Node3D:
	var best: Node3D = null
	for g in main.alive_ghosts():
		if best == null or pos.distance_to(g.pos) < pos.distance_to(best.pos):
			best = g
	return best


func _item_count(player: Node3D) -> int:
	var n := 0
	for id in player.inventory:
		n += player.inventory[id]
	return n
