extends SceneTree
## ภาพหน้าเมนู: godot --path . --script res://tests/title_shot.gd -- out.png [login|register|chars|create]

func _initialize() -> void:
	_shoot()


func _shoot() -> void:
	var args := OS.get_cmdline_user_args()
	var out := args[0] if args.size() > 0 else "title.png"
	var page := args[1] if args.size() > 1 else "login"
	var app: Node = load("res://app.tscn").instantiate()
	root.add_child(app)
	await process_frame
	var title: Control = app.title
	var chars := [{"name": "น้องมะลิ", "level": 57, "class": "ajarn_yant"}, {"name": "ขุนแผนจิ๋ว", "level": 104, "class": "khun_phaen"}]
	match page:
		"register":
			title.show_register()
		"chars":
			title.show_chars(chars, "ออนไลน์ · ไอดี malee01")
		"create":
			title.show_chars(chars, "ออนไลน์ · ไอดี malee01")
			title.show_create()
			title._name.text = "ผีน้อยใจดี"
			title.look = {"gender": "f", "hair": 3, "skin": 0}
			title.preview_changed.emit(title.look)
	for i in 40:
		await process_frame
	root.get_texture().get_image().save_png(out)
	print("saved ", out)
	quit()
