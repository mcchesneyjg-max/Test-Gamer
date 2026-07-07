extends Node2D

const SAPLING_SCENE := preload("res://scenes/sapling.tscn")
const FORESTER_WORKER_SCENE := preload("res://scenes/forester_worker.tscn")

@export var spawn_radius_tiles: int = 5
@export var max_saplings: int = 6
@export var sapling_grow_time: float = 8.0

@onready var _tilemap: TileMap = get_parent() as TileMap
@onready var _spawn_label: Label = $SpawnLabel

var _spawned_saplings: Array[Node2D] = []
var _worker: Node2D

func _ready() -> void:
	ForesterLodgeRegistry.register_lodge(self)
	_update_spawn_label()
	call_deferred("_spawn_worker")

func _exit_tree() -> void:
	if is_instance_valid(_worker):
		_worker.queue_free()
	ForesterLodgeRegistry.unregister_lodge(self)

func _process(_delta: float) -> void:
	_prune_invalid_saplings()

func get_active_sapling_count() -> int:
	_prune_invalid_saplings()
	return _spawned_saplings.size()

func can_plant_sapling() -> bool:
	_prune_invalid_saplings()
	return _spawned_saplings.size() < max_saplings

func find_plant_site() -> Vector2:
	var tile_coords := _find_spawn_tile()
	if tile_coords.x < 0:
		return Vector2.ZERO
	return _tilemap.map_to_local(tile_coords)

func plant_sapling_at_world_pos(world_pos: Vector2) -> bool:
	if not can_plant_sapling():
		return false

	var sapling := SAPLING_SCENE.instantiate()
	sapling.grow_time = sapling_grow_time
	sapling.position = world_pos
	_tilemap.add_child(sapling)
	_spawned_saplings.append(sapling)
	_update_spawn_label()
	return true

func _spawn_worker() -> void:
	if _tilemap == null:
		return

	_worker = FORESTER_WORKER_SCENE.instantiate()
	_worker.setup(self)
	_worker.position = position + Vector2(10, 38)
	_tilemap.add_child(_worker)

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
