extends Node2D

@onready var _tilemap: TileMap = $"../TileMap"

const MATURE_TREE_SCENE := preload("res://scenes/mature_tree.tscn")
const LUMBER_CAMP_SCENE := preload("res://scenes/lumber_camp.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or not event.pressed:
		return

	if event.button_index == MOUSE_BUTTON_LEFT:
		_try_place_tree()
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		_try_place_lumber_camp()

func _try_place_tree() -> void:
	var tile_coords := _tilemap.local_to_map(_tilemap.get_global_mouse_position())
	if not _is_valid_placement_tile(tile_coords):
		return

	var tree := MATURE_TREE_SCENE.instantiate()
	tree.position = _tilemap.map_to_local(tile_coords)
	_tilemap.add_child(tree)

func _try_place_lumber_camp() -> void:
	var tile_coords := _tilemap.local_to_map(_tilemap.get_global_mouse_position())
	if not _is_valid_placement_tile(tile_coords):
		return

	var camp := LUMBER_CAMP_SCENE.instantiate()
	camp.position = _tilemap.map_to_local(tile_coords)
	_tilemap.add_child(camp)

func _is_valid_placement_tile(tile_coords: Vector2i) -> bool:
	if tile_coords.x < 0 or tile_coords.y < 0:
		return false
	if tile_coords.x >= 250 or tile_coords.y >= 250:
		return false
	if _tilemap.get_cell_source_id(0, tile_coords) == -1:
		return false
	return not _is_tile_occupied(tile_coords)

func _is_tile_occupied(tile_coords: Vector2i) -> bool:
	for tree in TreeRegistry.get_active_trees():
		if _tilemap.local_to_map(tree.position) == tile_coords:
			return true
	for camp in CampRegistry.get_active_camps():
		if _tilemap.local_to_map(camp.position) == tile_coords:
			return true
	return false
