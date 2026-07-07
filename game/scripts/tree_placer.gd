extends Node2D

@onready var _tilemap: TileMap = $"../TileMap"

const MATURE_TREE_SCENE := preload("res://scenes/mature_tree.tscn")
const LUMBER_CAMP_SCENE := preload("res://scenes/lumber_camp.tscn")
const WAREHOUSE_SCENE := preload("res://scenes/warehouse_building.tscn")
const HAULER_STATION_SCENE := preload("res://scenes/hauler_station.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_try_place_tree()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if event.ctrl_pressed:
				_try_place_hauler_station()
			elif event.shift_pressed:
				_try_place_warehouse()
			else:
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

func _try_place_warehouse() -> void:
	var tile_coords := _tilemap.local_to_map(_tilemap.get_global_mouse_position())
	if not _is_valid_placement_tile(tile_coords):
		return

	var warehouse := WAREHOUSE_SCENE.instantiate()
	warehouse.position = _tilemap.map_to_local(tile_coords)
	_tilemap.add_child(warehouse)

func _try_place_hauler_station() -> void:
	var tile_coords := _tilemap.local_to_map(_tilemap.get_global_mouse_position())
	if not _is_valid_placement_tile(tile_coords):
		return

	var station := HAULER_STATION_SCENE.instantiate()
	station.position = _tilemap.map_to_local(tile_coords)
	_tilemap.add_child(station)

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
	for warehouse in WarehouseRegistry.get_active_warehouses():
		if _tilemap.local_to_map(warehouse.position) == tile_coords:
			return true
	for station in HaulerStationRegistry.get_active_stations():
		if _tilemap.local_to_map(station.position) == tile_coords:
			return true
	return false
