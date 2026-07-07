extends Node

const MATURE_TREE_SCENE := preload("res://scenes/mature_tree.tscn")

func _ready() -> void:
	if "--screenshot-task2" in OS.get_cmdline_args():
		call_deferred("_capture_task2")
	elif "--screenshot-task3" in OS.get_cmdline_args():
		call_deferred("_capture_task3")
	elif "--screenshot-task4" in OS.get_cmdline_args():
		call_deferred("_capture_task4")
	elif "--screenshot-task5" in OS.get_cmdline_args():
		call_deferred("_capture_task5")
	elif "--screenshot-task6" in OS.get_cmdline_args():
		call_deferred("_capture_task6")
	elif "--screenshot-task7" in OS.get_cmdline_args():
		call_deferred("_capture_task7")
	elif "--screenshot-art-pass" in OS.get_cmdline_args():
		call_deferred("_capture_art_pass")
	elif "--screenshot-art-pass-v2" in OS.get_cmdline_args():
		call_deferred("_capture_art_pass_v2")
	elif "--screenshot-art-pass-v3" in OS.get_cmdline_args():
		call_deferred("_capture_art_pass_v3")
	elif "--screenshot-task8" in OS.get_cmdline_args():
		call_deferred("_capture_task8")
	elif "--screenshot-task9" in OS.get_cmdline_args():
		call_deferred("_capture_task9")
	elif "--screenshot-task10" in OS.get_cmdline_args():
		call_deferred("_capture_task10")

func _capture_task2() -> void:
	var tilemap: TileMap = get_parent().get_node("TileMap")
	var camera: Camera2D = get_parent().get_node("Camera2D")
	camera.position = Vector2(125, 125) * 32
	camera.zoom = Vector2(3, 3)

	var tree_coords := [
		Vector2i(120, 122),
		Vector2i(121, 123),
		Vector2i(122, 121),
		Vector2i(123, 124),
		Vector2i(124, 122),
		Vector2i(125, 125),
		Vector2i(126, 123),
		Vector2i(127, 126),
	]

	for coords in tree_coords:
		var tree := MATURE_TREE_SCENE.instantiate()
		tree.position = tilemap.map_to_local(coords)
		tilemap.add_child(tree)

	await get_tree().create_timer(0.5).timeout
	var output_dir := ProjectSettings.globalize_path("res://").path_join("screenshots")
	DirAccess.make_dir_absolute(output_dir)
	var output_path := output_dir.path_join("task2-trees.png")
	get_viewport().get_texture().get_image().save_png(output_path)
	get_tree().quit()

func _capture_task3() -> void:
	var tilemap: TileMap = get_parent().get_node("TileMap")
	var camera: Camera2D = get_parent().get_node("Camera2D")
	camera.position = Vector2(125, 125) * 32
	camera.zoom = Vector2(3, 3)

	var camp_coords := Vector2i(124, 124)
	var tree_coords := [
		Vector2i(122, 122),
		Vector2i(123, 123),
		Vector2i(125, 123),
		Vector2i(126, 125),
		Vector2i(127, 124),
		Vector2i(121, 125),
	]

	var camp_scene := preload("res://scenes/lumber_camp.tscn")
	var camp = camp_scene.instantiate()
	camp.position = tilemap.map_to_local(camp_coords)
	camp.chop_interval = 0.5
	tilemap.add_child(camp)

	for coords in tree_coords:
		var tree := MATURE_TREE_SCENE.instantiate()
		tree.position = tilemap.map_to_local(coords)
		tilemap.add_child(tree)

	await get_tree().create_timer(3.0).timeout
	var output_dir := ProjectSettings.globalize_path("res://").path_join("screenshots")
	DirAccess.make_dir_absolute(output_dir)
	var output_path := output_dir.path_join("task3-lumber-camp.png")
	get_viewport().get_texture().get_image().save_png(output_path)
	get_tree().quit()

func _capture_task4() -> void:
	var tilemap: TileMap = get_parent().get_node("TileMap")
	var camera: Camera2D = get_parent().get_node("Camera2D")
	camera.position = Vector2(125, 125) * 32
	camera.zoom = Vector2(3, 3)

	var camp_coords := Vector2i(124, 124)
	var tree_coords := [
		Vector2i(122, 122),
		Vector2i(123, 123),
		Vector2i(125, 123),
		Vector2i(126, 125),
		Vector2i(127, 124),
		Vector2i(121, 125),
	]

	var camp_scene := preload("res://scenes/lumber_camp.tscn")
	var camp = camp_scene.instantiate()
	camp.position = tilemap.map_to_local(camp_coords)
	camp.chop_interval = 0.5
	tilemap.add_child(camp)

	for coords in tree_coords:
		var tree := MATURE_TREE_SCENE.instantiate()
		tree.position = tilemap.map_to_local(coords)
		tilemap.add_child(tree)

	await get_tree().create_timer(3.0).timeout
	var output_dir := ProjectSettings.globalize_path("res://").path_join("screenshots")
	DirAccess.make_dir_absolute(output_dir)
	var output_path := output_dir.path_join("task4-building-storage.png")
	get_viewport().get_texture().get_image().save_png(output_path)
	get_tree().quit()

func _capture_task5() -> void:
	var tilemap: TileMap = get_parent().get_node("TileMap")
	var camera: Camera2D = get_parent().get_node("Camera2D")
	camera.position = Vector2(125, 125) * 32
	camera.zoom = Vector2(3, 3)

	var warehouse_scene := preload("res://scenes/warehouse_building.tscn")
	var warehouse = warehouse_scene.instantiate()
	warehouse.position = tilemap.map_to_local(Vector2i(124, 124))
	tilemap.add_child(warehouse)
	await get_tree().process_frame
	warehouse.deposit_logs(12)

	await get_tree().create_timer(0.5).timeout
	var output_dir := ProjectSettings.globalize_path("res://").path_join("screenshots")
	DirAccess.make_dir_absolute(output_dir)
	var output_path := output_dir.path_join("task5-warehouse.png")
	get_viewport().get_texture().get_image().save_png(output_path)
	get_tree().quit()

func _capture_task6() -> void:
	var tilemap: TileMap = get_parent().get_node("TileMap")
	var camera: Camera2D = get_parent().get_node("Camera2D")
	camera.position = Vector2(125, 125) * 32
	camera.zoom = Vector2(3, 3)

	var station_scene := preload("res://scenes/hauler_station.tscn")
	var station = station_scene.instantiate()
	station.position = tilemap.map_to_local(Vector2i(124, 124))
	station.hauler_count = 2
	tilemap.add_child(station)

	await get_tree().create_timer(0.5).timeout
	var output_dir := ProjectSettings.globalize_path("res://").path_join("screenshots")
	DirAccess.make_dir_absolute(output_dir)
	var output_path := output_dir.path_join("task6-hauler-station.png")
	get_viewport().get_texture().get_image().save_png(output_path)
	get_tree().quit()

func _capture_task7() -> void:
	var tilemap: TileMap = get_parent().get_node("TileMap")
	var camera: Camera2D = get_parent().get_node("Camera2D")
	camera.position = Vector2(125, 124) * 32
	camera.zoom = Vector2(3, 3)

	var camp_scene := preload("res://scenes/lumber_camp.tscn")
	var camp = camp_scene.instantiate()
	camp.position = tilemap.map_to_local(Vector2i(118, 124))
	tilemap.add_child(camp)
	await get_tree().process_frame
	camp.deposit_to_output(4)

	var warehouse_scene := preload("res://scenes/warehouse_building.tscn")
	var warehouse = warehouse_scene.instantiate()
	warehouse.position = tilemap.map_to_local(Vector2i(132, 124))
	tilemap.add_child(warehouse)

	var station_scene := preload("res://scenes/hauler_station.tscn")
	var station = station_scene.instantiate()
	station.position = tilemap.map_to_local(Vector2i(125, 127))
	station.hauler_count = 1
	tilemap.add_child(station)

	await get_tree().create_timer(0.3).timeout
	for worker in get_tree().get_nodes_in_group("hauler_worker"):
		worker.move_speed = 220.0

	await get_tree().create_timer(1.1).timeout
	var output_dir := ProjectSettings.globalize_path("res://").path_join("screenshots")
	DirAccess.make_dir_absolute(output_dir)
	var output_path := output_dir.path_join("task7-hauler-ai.png")
	get_viewport().get_texture().get_image().save_png(output_path)
	get_tree().quit()

func _capture_art_pass() -> void:
	var tilemap: TileMap = get_parent().get_node("TileMap")
	var camera: Camera2D = get_parent().get_node("Camera2D")
	camera.position = Vector2(125, 124) * 32
	camera.zoom = Vector2(3, 3)

	var tree_coords := [Vector2i(116, 122), Vector2i(117, 125), Vector2i(119, 121)]
	for coords in tree_coords:
		var tree := MATURE_TREE_SCENE.instantiate()
		tree.position = tilemap.map_to_local(coords)
		tilemap.add_child(tree)

	var camp_scene := preload("res://scenes/lumber_camp.tscn")
	var camp = camp_scene.instantiate()
	camp.position = tilemap.map_to_local(Vector2i(118, 124))
	tilemap.add_child(camp)
	await get_tree().process_frame
	camp.deposit_to_output(3)

	var warehouse_scene := preload("res://scenes/warehouse_building.tscn")
	var warehouse = warehouse_scene.instantiate()
	warehouse.position = tilemap.map_to_local(Vector2i(132, 124))
	tilemap.add_child(warehouse)

	var station_scene := preload("res://scenes/hauler_station.tscn")
	var station = station_scene.instantiate()
	station.position = tilemap.map_to_local(Vector2i(125, 127))
	station.hauler_count = 1
	tilemap.add_child(station)

	await get_tree().create_timer(0.3).timeout
	for worker in get_tree().get_nodes_in_group("hauler_worker"):
		worker.move_speed = 220.0

	await get_tree().create_timer(1.0).timeout
	var output_dir := ProjectSettings.globalize_path("res://").path_join("screenshots")
	DirAccess.make_dir_absolute(output_dir)
	var output_path := output_dir.path_join("art-pass-after.png")
	get_viewport().get_texture().get_image().save_png(output_path)
	get_tree().quit()

func _capture_art_pass_v2() -> void:
	var tilemap: TileMap = get_parent().get_node("TileMap")
	var camera: Camera2D = get_parent().get_node("Camera2D")
	camera.position = Vector2(125, 124) * 32
	camera.zoom = Vector2(3, 3)

	var tree_coords := [Vector2i(116, 122), Vector2i(117, 125), Vector2i(119, 121)]
	for coords in tree_coords:
		var tree := MATURE_TREE_SCENE.instantiate()
		tree.position = tilemap.map_to_local(coords)
		tilemap.add_child(tree)

	var camp_scene := preload("res://scenes/lumber_camp.tscn")
	var camp = camp_scene.instantiate()
	camp.position = tilemap.map_to_local(Vector2i(118, 124))
	tilemap.add_child(camp)
	await get_tree().process_frame
	camp.deposit_to_output(3)

	var warehouse_scene := preload("res://scenes/warehouse_building.tscn")
	var warehouse = warehouse_scene.instantiate()
	warehouse.position = tilemap.map_to_local(Vector2i(132, 124))
	tilemap.add_child(warehouse)

	var station_scene := preload("res://scenes/hauler_station.tscn")
	var station = station_scene.instantiate()
	station.position = tilemap.map_to_local(Vector2i(125, 127))
	station.hauler_count = 1
	tilemap.add_child(station)

	await get_tree().create_timer(0.3).timeout
	for worker in get_tree().get_nodes_in_group("hauler_worker"):
		worker.move_speed = 220.0

	await get_tree().create_timer(1.0).timeout
	var output_dir := ProjectSettings.globalize_path("res://").path_join("screenshots")
	DirAccess.make_dir_absolute(output_dir)
	var output_path := output_dir.path_join("art-pass-v2-after.png")
	get_viewport().get_texture().get_image().save_png(output_path)
	get_tree().quit()

func _capture_art_pass_v3() -> void:
	var tilemap: TileMap = get_parent().get_node("TileMap")
	var camera: Camera2D = get_parent().get_node("Camera2D")
	camera.position = Vector2(125, 124) * 32
	camera.zoom = Vector2(3, 3)

	var tree_coords := [Vector2i(116, 122), Vector2i(117, 125), Vector2i(119, 121)]
	for coords in tree_coords:
		var tree := MATURE_TREE_SCENE.instantiate()
		tree.position = tilemap.map_to_local(coords)
		tilemap.add_child(tree)

	var camp_scene := preload("res://scenes/lumber_camp.tscn")
	var camp = camp_scene.instantiate()
	camp.position = tilemap.map_to_local(Vector2i(118, 124))
	tilemap.add_child(camp)
	await get_tree().process_frame
	camp.deposit_to_output(3)

	var warehouse_scene := preload("res://scenes/warehouse_building.tscn")
	var warehouse = warehouse_scene.instantiate()
	warehouse.position = tilemap.map_to_local(Vector2i(132, 124))
	tilemap.add_child(warehouse)

	var station_scene := preload("res://scenes/hauler_station.tscn")
	var station = station_scene.instantiate()
	station.position = tilemap.map_to_local(Vector2i(125, 127))
	station.hauler_count = 1
	tilemap.add_child(station)

	await get_tree().create_timer(0.3).timeout
	for worker in get_tree().get_nodes_in_group("hauler_worker"):
		worker.move_speed = 220.0

	await get_tree().create_timer(1.0).timeout
	var output_dir := ProjectSettings.globalize_path("res://").path_join("screenshots")
	DirAccess.make_dir_absolute(output_dir)
	var output_path := output_dir.path_join("art-pass-v3-after.png")
	get_viewport().get_texture().get_image().save_png(output_path)
	get_tree().quit()

func _capture_task8() -> void:
	var tilemap: TileMap = get_parent().get_node("TileMap")
	var camera: Camera2D = get_parent().get_node("Camera2D")
	camera.position = Vector2(125, 124) * 32
	camera.zoom = Vector2(3, 3)

	var lodge_scene := preload("res://scenes/forester_lodge.tscn")
	var lodge = lodge_scene.instantiate()
	lodge.position = tilemap.map_to_local(Vector2i(124, 124))
	lodge.spawn_interval = 1.0
	tilemap.add_child(lodge)

	await get_tree().create_timer(5.0).timeout
	var output_dir := ProjectSettings.globalize_path("res://").path_join("screenshots")
	DirAccess.make_dir_absolute(output_dir)
	var output_path := output_dir.path_join("task8-forester-lodge.png")
	get_viewport().get_texture().get_image().save_png(output_path)
	get_tree().quit()

func _capture_task9() -> void:
	var tilemap: TileMap = get_parent().get_node("TileMap")
	var camera: Camera2D = get_parent().get_node("Camera2D")
	camera.position = Vector2(125, 124) * 32
	camera.zoom = Vector2(3, 3)

	var lodge_scene := preload("res://scenes/forester_lodge.tscn")
	var lodge = lodge_scene.instantiate()
	lodge.position = tilemap.map_to_local(Vector2i(124, 124))
	lodge.spawn_interval = 1.0
	lodge.sapling_grow_time = 2.0
	lodge.max_saplings = 4
	tilemap.add_child(lodge)

	await get_tree().create_timer(6.0).timeout
	var output_dir := ProjectSettings.globalize_path("res://").path_join("screenshots")
	DirAccess.make_dir_absolute(output_dir)
	var output_path := output_dir.path_join("task9-sapling-growth.png")
	get_viewport().get_texture().get_image().save_png(output_path)
	get_tree().quit()

func _capture_task10() -> void:
	var tilemap: TileMap = get_parent().get_node("TileMap")
	var camera: Camera2D = get_parent().get_node("Camera2D")
	camera.position = Vector2(125, 124) * 32
	camera.zoom = Vector2(3, 3)

	var lodge_scene := preload("res://scenes/forester_lodge.tscn")
	var lodge = lodge_scene.instantiate()
	lodge.position = tilemap.map_to_local(Vector2i(120, 124))
	lodge.spawn_interval = 2.0
	lodge.sapling_grow_time = 4.0
	lodge.max_saplings = 6
	tilemap.add_child(lodge)

	var camp_scene := preload("res://scenes/lumber_camp.tscn")
	var camp = camp_scene.instantiate()
	camp.position = tilemap.map_to_local(Vector2i(124, 124))
	camp.chop_interval = 1.0
	camp.chop_radius_tiles = 5
	tilemap.add_child(camp)

	var warehouse_scene := preload("res://scenes/warehouse_building.tscn")
	var warehouse = warehouse_scene.instantiate()
	warehouse.position = tilemap.map_to_local(Vector2i(132, 124))
	tilemap.add_child(warehouse)

	var station_scene := preload("res://scenes/hauler_station.tscn")
	var station = station_scene.instantiate()
	station.position = tilemap.map_to_local(Vector2i(126, 127))
	station.hauler_count = 2
	tilemap.add_child(station)

	await get_tree().create_timer(0.3).timeout
	for worker in get_tree().get_nodes_in_group("hauler_worker"):
		worker.move_speed = 180.0

	await get_tree().create_timer(28.0).timeout

	if Warehouse.wood_logs <= 0:
		push_error("Closed loop verification failed: warehouse has no logs after 28s")

	var output_dir := ProjectSettings.globalize_path("res://").path_join("screenshots")
	DirAccess.make_dir_absolute(output_dir)
	var output_path := output_dir.path_join("task10-closed-loop.png")
	get_viewport().get_texture().get_image().save_png(output_path)
	get_tree().quit()
