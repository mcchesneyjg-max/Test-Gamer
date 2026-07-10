extends Node2D

@onready var _tilemap: TileMap = $"../TileMap"
@onready var _forester_ui: CanvasLayer = $"../ForesterUi"

const MATURE_TREE_SCENE := preload("res://scenes/mature_tree.tscn")
const LUMBER_CAMP_SCENE := preload("res://scenes/lumber_camp.tscn")
const WAREHOUSE_SCENE := preload("res://scenes/warehouse_building.tscn")
const HAULER_STATION_SCENE := preload("res://scenes/hauler_station.tscn")
const FORESTER_LODGE_SCENE := preload("res://scenes/forester_lodge.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if _forester_ui and _forester_ui.handle_input(event):
		return
	if _forester_ui and _forester_ui.is_blocking_placement():
		return

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_try_place_tree()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if event.alt_pressed:
				_try_place_forester_lodge()
			elif event.ctrl_pressed:
				_try_place_hauler_station()
			elif event.shift_pressed:
				_try_place_warehouse()
			else:
				_try_place_lumber_camp()

func _try_place_tree() -> void:
	if ForesterLodgeRegistry.get_lodge_count() > 0:
		return
	var tile_coords := GridPlacement.mouse_tile_coords(_tilemap)
	if not _is_valid_placement_tile(tile_coords):
		return

	var tree := MATURE_TREE_SCENE.instantiate()
	tree.position = GridPlacement.tile_to_world(_tilemap, tile_coords)
	_tilemap.add_child(tree)

func _try_place_lumber_camp() -> void:
	var tile_coords := GridPlacement.mouse_tile_coords(_tilemap)
	if not _is_valid_placement_tile(tile_coords):
		return

	var camp := LUMBER_CAMP_SCENE.instantiate()
	camp.position = GridPlacement.tile_to_world(_tilemap, tile_coords)
	_tilemap.add_child(camp)

func _try_place_warehouse() -> void:
	var tile_coords := GridPlacement.mouse_tile_coords(_tilemap)
	if not _is_valid_placement_tile(tile_coords):
		return

	var warehouse := WAREHOUSE_SCENE.instantiate()
	warehouse.position = GridPlacement.tile_to_world(_tilemap, tile_coords)
	_tilemap.add_child(warehouse)

func _try_place_hauler_station() -> void:
	var tile_coords := GridPlacement.mouse_tile_coords(_tilemap)
	if not _is_valid_placement_tile(tile_coords):
		return

	var station := HAULER_STATION_SCENE.instantiate()
	station.position = GridPlacement.tile_to_world(_tilemap, tile_coords)
	_tilemap.add_child(station)

func _try_place_forester_lodge() -> void:
	var center_tile := GridPlacement.mouse_tile_coords(_tilemap)
	var top_left := center_tile - Vector2i(1, 1)
	if not _is_valid_forester_footprint(top_left):
		return

	var lodge := FORESTER_LODGE_SCENE.instantiate()
	_tilemap.add_child(lodge)
	lodge.initialize_placement(top_left)
	if _forester_ui:
		_forester_ui.register_new_lodge(lodge)

func _is_valid_forester_footprint(top_left: Vector2i) -> bool:
	var footprint_size: Vector2i = Vector2i(4, 4)
	for tile_coords in GridPlacement.footprint_tiles(top_left, footprint_size):
		if not _is_valid_placement_tile(tile_coords):
			return false
		if _is_tile_occupied(tile_coords):
			return false
	return true

func _is_valid_placement_tile(tile_coords: Vector2i) -> bool:
	if not GridPlacement.is_cardinal_tile_in_bounds(tile_coords):
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
	for lodge in ForesterLodgeRegistry.get_active_lodges():
		if lodge.has_method("occupies_tile") and lodge.occupies_tile(tile_coords):
			return true
	for sapling in SaplingRegistry.get_active_saplings():
		if _tilemap.local_to_map(sapling.position) == tile_coords:
			return true
	return false
