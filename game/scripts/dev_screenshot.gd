extends Node

const MATURE_TREE_SCENE := preload("res://scenes/mature_tree.tscn")

func _ready() -> void:
	if "--screenshot-task2" in OS.get_cmdline_args():
		call_deferred("_capture_task2")
	elif "--screenshot-task3" in OS.get_cmdline_args():
		call_deferred("_capture_task3")

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
