extends SceneTree
## วัดภาระการวาดของฉากเกม (จำนวน draw call / วัตถุ / เหลี่ยม) ต้องมีหน้าจอ เช่น xvfb-run
## godot --path . --rendering-driver opengl3 --rendering-method gl_compatibility --script res://tests/perf_probe.gd -- [ระดับกราฟิก] [map:<id>]

func _initialize() -> void:
	_run()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var G = load("res://client/graphics.gd")
	G.config_path = "user://perf_probe.cfg"
	if args.size() > 0:
		G.set_level(null, args[0])
	var main: Node3D = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	for a in args:
		if a.begins_with("map:"):
			main.load_map(a.substr(4))
	for i in 60:
		await process_frame
	var meshes := 0
	var outlined := 0
	for n in root.find_children("*", "MeshInstance3D", true, false):
		if n.is_visible_in_tree():
			meshes += 1
			var m: Material = n.material_override
			if m != null and m.next_pass != null:
				outlined += 1
	var t0 := Time.get_ticks_usec()
	for i in 60:
		await process_frame
	var ms := (Time.get_ticks_usec() - t0) / 60000.0
	print("PERF level=%s meshes=%d outlined=%d draw_calls=%d objects=%d prims=%d frame_ms=%.1f nodes=%d" % [G.level(), meshes, outlined,
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME), ms, Performance.get_monitor(Performance.OBJECT_NODE_COUNT)])
	quit()
