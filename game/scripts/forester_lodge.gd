extends Node2D

const SAPLING_SCENE := preload("res://scenes/sapling.tscn")

@export var spawn_interval: float = 4.0
@export var spawn_radius_tiles: int = 5
@export var max_saplings: int = 6
@export var sapling_grow_time: float = 8.0

@onready var _tilemap: TileMap = get_parent() as TileMap
@onready var _spawn_label: Label = $SpawnLabel

var _spawn_timer: float = 0.0
var _spawned_saplings: Array[Node2D] = []

func _ready() -> void:
	ForesterLodgeRegistry.register_lodge(self)
	_update_spawn_label()

func _exit_tree() -> void:
	ForesterLodgeRegistry.unregister_lodge(self)

func _process(delta: float) -> void:
	_prune_invalid_saplings()
	if _spawned_saplings.size() >= max_saplings:
		return

	_spawn_timer += delta
	if _spawn_timer < spawn_interval:
		return
	_spawn_timer = 0.0
	_try_spawn_sapling()

func get_active_sapling_count() -> int:
	_prune_invalid_saplings()
	return _spawned_saplings.size()

func _try_spawn_sapling() -> void:
	var tile_coords := _find_spawn_tile()
	if tile_coords.x < 0:
		return

	var sapling := SAPLING_SCENE.instantiate()
	sapling.grow_time = sapling_grow_time
	sapling.position = _tilemap.map_to_local(tile_coords)
	_tilemap.add_child(sapling)
	_spawned_saplings.append(sapling)
	_update_spawn_label()

func _find_spawn_tile() -> Vector2i:
	var lodge_tile := _tilemap.local_to_map(position)
	var candidates: Array[Vector2i] = []

	for dy in range(-spawn_radius_tiles, spawn_radius_tiles + 1):
		for dx in range(-spawn_radius_tiles, spawn_radius_tiles + 1):
			if dx == 0 and dy == 0:
				continue
			var tile_coords := lodge_tile + Vector2i(dx, dy)
			if _is_valid_spawn_tile(tile_coords):
				candidates.append(tile_coords)

	if candidates.is_empty():
		return Vector2i(-1, -1)

	return candidates[randi() % candidates.size()]

func _is_valid_spawn_tile(tile_coords: Vector2i) -> bool:
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
	for sapling in SaplingRegistry.get_active_saplings():
		if _tilemap.local_to_map(sapling.position) == tile_coords:
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
		if _tilemap.local_to_map(lodge.position) == tile_coords:
			return true
	return false

func _prune_invalid_saplings() -> void:
	for i in range(_spawned_saplings.size() - 1, -1, -1):
		if not is_instance_valid(_spawned_saplings[i]):
			_spawned_saplings.remove_at(i)
	_update_spawn_label()

func _update_spawn_label() -> void:
	_spawn_label.text = "Saplings: %d/%d" % [_spawned_saplings.size(), max_saplings]
