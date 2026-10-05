extends SceneTree
## ถ่ายภาพหน้าจอเกม (ต้องมีหน้าจอ เช่น xvfb-run): godot --path . --script res://tests/screenshot.gd -- out.png

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
	player.position = Vector2(1050, 700)
	for i in 400:
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
