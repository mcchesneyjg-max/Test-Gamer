extends Node2D

@onready var _tilemap: TileMap = $"../TileMap"

const MATURE_TREE_SCENE := preload("res://scenes/mature_tree.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_try_place_tree()

func _try_place_tree() -> void:
	var tile_coords := _tilemap.local_to_map(_tilemap.get_global_mouse_position())
	if not _is_valid_tree_tile(tile_coords):
		return

	var tree := MATURE_TREE_SCENE.instantiate()
	tree.position = _tilemap.map_to_local(tile_coords)
	_tilemap.add_child(tree)

func _is_valid_tree_tile(tile_coords: Vector2i) -> bool:
	if tile_coords.x < 0 or tile_coords.y < 0:
		return false
	if tile_coords.x >= 250 or tile_coords.y >= 250:
		return false
	if _tilemap.get_cell_source_id(0, tile_coords) == -1:
		return false
	return not _has_tree_at(tile_coords)

func _has_tree_at(tile_coords: Vector2i) -> bool:
	for tree in TreeRegistry.get_active_trees():
		if _tilemap.local_to_map(tree.position) == tile_coords:
			return true
	return false
