extends SceneTree
## ถ่ายภาพหน้าจอเกม (ต้องมีหน้าจอ เช่น xvfb-run):
## godot --path . --script res://tests/screenshot.gd -- out.png [x y เวลา(0-1) ล่าผี(0/1)]

func _initialize() -> void:
	_shoot()


func _shoot() -> void:
	var out := "screenshot.png"
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	var main: Node2D = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.set_process(false)
	var player: Node2D = main.player
	player.position = Vector2(float(args[1]), float(args[2])) if args.size() > 2 else Vector2(1050, 700)
	if args.size() > 3:
		main.ambience.time_of_day = float(args[3])
		main.ambience.tick(0.0)
	var hunt := args.size() <= 4 or args[4] == "1"
	for i in (400 if hunt else 0):
		if player.attack_target == null:
			var best: Node2D = null
			for c in main.alive_ghosts():
				if best == null or player.position.distance_to(c.position) < player.position.distance_to(best.position):
					best = c
			player.command_attack(best)
		if i == 395:
			player.cast_holy_water()
		main.tick(0.05)
	main.set_process(true)
	for i in 30:
		await process_frame
	root.get_texture().get_image().save_png(out)
	print("saved ", out)
	quit()
