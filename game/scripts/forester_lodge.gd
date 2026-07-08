extends Node2D

const SAPLING_SCENE := preload("res://scenes/sapling.tscn")
const FORESTER_WORKER_SCENE := preload("res://scenes/forester_worker.tscn")

signal plant_zone_changed(zone: Rect2i)

@export var max_saplings: int = 6
@export var sapling_grow_time: float = 8.0
@export var max_zone_tiles: int = 64
@export var min_zone_tiles: int = 9
@export var vegetation_spacing_tiles: int = 2
@export var building_buffer_tiles: int = 2

@onready var _tilemap: TileMap = get_parent() as TileMap
@onready var _spawn_label: Label = $SpawnLabel

var _spawned_saplings: Array[Node2D] = []
var _worker: Node2D
var _plant_zone: Rect2i = Rect2i()
var _has_plant_zone: bool = false

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

func has_plant_zone() -> bool:
	return _has_plant_zone

func get_plant_zone() -> Rect2i:
	return _plant_zone

func get_lodge_tile() -> Vector2i:
	return _tilemap.local_to_map(position)

func get_zone_status_text() -> String:
	if not _has_plant_zone:
		return "No planting zone"
	return "Zone: %dx%d (%d tiles)" % [_plant_zone.size.x, _plant_zone.size.y, _plant_zone.size.x * _plant_zone.size.y]

func set_plant_zone(zone: Rect2i) -> String:
	var normalized := _normalize_zone(zone)
	var tile_count := normalized.size.x * normalized.size.y
	if tile_count < min_zone_tiles:
		return "Zone too small (min %d tiles)" % min_zone_tiles
	if tile_count > max_zone_tiles:
		return "Zone too large (max %d tiles)" % max_zone_tiles
	if not normalized.has_point(get_lodge_tile()):
		return "Zone must include the forester lodge"

	_plant_zone = normalized
	_has_plant_zone = true
	plant_zone_changed.emit(_plant_zone)
	_update_spawn_label()
	return ""

func clear_plant_zone() -> void:
	_has_plant_zone = false
	_plant_zone = Rect2i()
	plant_zone_changed.emit(_plant_zone)
	_update_spawn_label()

func get_active_sapling_count() -> int:
	_prune_invalid_saplings()
	return _spawned_saplings.size()

func can_plant_sapling() -> bool:
	_prune_invalid_saplings()
	return _has_plant_zone and _spawned_saplings.size() < max_saplings

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

func assign_default_plant_zone(half_size: int = 3) -> void:
	var center := get_lodge_tile()
	set_plant_zone(Rect2i(center.x - half_size, center.y - half_size, half_size * 2 + 1, half_size * 2 + 1))

func _spawn_worker() -> void:
	if _tilemap == null:
		return

	_worker = FORESTER_WORKER_SCENE.instantiate()
	_worker.setup(self)
	_worker.position = position + Vector2(10, 38)
	_tilemap.add_child(_worker)

func _find_spawn_tile() -> Vector2i:
	if not _has_plant_zone:
		return Vector2i(-1, -1)

	var candidates: Array[Vector2i] = []
	var lodge_tile := get_lodge_tile()

	for y in range(_plant_zone.position.y, _plant_zone.position.y + _plant_zone.size.y):
		for x in range(_plant_zone.position.x, _plant_zone.position.x + _plant_zone.size.x):
			var tile_coords := Vector2i(x, y)
			if tile_coords == lodge_tile:
				continue
			if _is_valid_spawn_tile(tile_coords):
				candidates.append(tile_coords)

	if candidates.is_empty():
		return Vector2i(-1, -1)

	return candidates[randi() % candidates.size()]

func _is_valid_spawn_tile(tile_coords: Vector2i) -> bool:
	if not _has_plant_zone or not _plant_zone.has_point(tile_coords):
		return false
	if tile_coords.x < 0 or tile_coords.y < 0:
		return false
	if tile_coords.x >= 250 or tile_coords.y >= 250:
		return false
	if _tilemap.get_cell_source_id(0, tile_coords) == -1:
		return false
	if _is_tile_occupied(tile_coords):
		return false
	if _is_too_close_to_vegetation(tile_coords):
		return false
	if _is_too_close_to_building(tile_coords):
		return false
	return true

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

func _is_too_close_to_vegetation(tile_coords: Vector2i) -> bool:
	for tree in TreeRegistry.get_active_trees():
		if _chebyshev_distance(tile_coords, _tilemap.local_to_map(tree.position)) < vegetation_spacing_tiles:
			return true
	for sapling in SaplingRegistry.get_active_saplings():
		if _chebyshev_distance(tile_coords, _tilemap.local_to_map(sapling.position)) < vegetation_spacing_tiles:
			return true
	return false

func _is_too_close_to_building(tile_coords: Vector2i) -> bool:
	for camp in CampRegistry.get_active_camps():
		if _chebyshev_distance(tile_coords, _tilemap.local_to_map(camp.position)) < building_buffer_tiles:
			return true
	for warehouse in WarehouseRegistry.get_active_warehouses():
		if _chebyshev_distance(tile_coords, _tilemap.local_to_map(warehouse.position)) < building_buffer_tiles:
			return true
	for station in HaulerStationRegistry.get_active_stations():
		if _chebyshev_distance(tile_coords, _tilemap.local_to_map(station.position)) < building_buffer_tiles:
			return true
	for lodge in ForesterLodgeRegistry.get_active_lodges():
		if _chebyshev_distance(tile_coords, _tilemap.local_to_map(lodge.position)) < building_buffer_tiles:
			return true
	return false

func _chebyshev_distance(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))

func _normalize_zone(zone: Rect2i) -> Rect2i:
	var x0 := mini(zone.position.x, zone.position.x + zone.size.x - 1)
	var y0 := mini(zone.position.y, zone.position.y + zone.size.y - 1)
	var x1 := maxi(zone.position.x, zone.position.x + zone.size.x - 1)
	var y1 := maxi(zone.position.y, zone.position.y + zone.size.y - 1)
	return Rect2i(x0, y0, x1 - x0 + 1, y1 - y0 + 1)

func _prune_invalid_saplings() -> void:
	for i in range(_spawned_saplings.size() - 1, -1, -1):
		if not is_instance_valid(_spawned_saplings[i]):
			_spawned_saplings.remove_at(i)
	_update_spawn_label()

func _update_spawn_label() -> void:
	var zone_text := "Set zone" if not _has_plant_zone else "%dx%d" % [_plant_zone.size.x, _plant_zone.size.y]
	_spawn_label.text = "Saplings: %d/%d | %s" % [_spawned_saplings.size(), max_saplings, zone_text]
