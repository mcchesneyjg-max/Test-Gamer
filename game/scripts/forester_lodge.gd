extends Node2D

const SAPLING_SCENE := preload("res://scenes/sapling.tscn")
const FORESTER_WORKER_SCENE := preload("res://scenes/forester_worker.tscn")
const FOOTPRINT_TILES := Vector2i(4, 4)
const SPRITE_OFFSET := Vector2(-64, -128)

const LEVEL_TEXTURES := {
	1: preload("res://assets/sprites/forester_lodge_l1.png"),
	2: preload("res://assets/sprites/forester_lodge_l2.png"),
	3: preload("res://assets/sprites/forester_lodge_l3.png"),
}

signal plant_zone_changed(zone: Rect2i)
signal level_changed(level: int)

@export var level: int = 1:
	set(value):
		var clamped := clampi(value, 1, 3)
		if _level == clamped:
			return
		_level = clamped
		if is_node_ready():
			_apply_level_visual()
	get:
		return _level

@export var max_saplings: int = 6
@export var sapling_grow_time: float = 8.0
@export var max_zone_tiles: int = 64
@export var min_zone_tiles: int = 9
@export var vegetation_spacing_tiles: int = 2
@export var building_buffer_tiles: int = 2

@onready var _tilemap: TileMap = get_parent() as TileMap
@onready var _sprite: Sprite2D = $Sprite
@onready var _spawn_label: Label = $SpawnLabel

var _spawned_saplings: Array[Node2D] = []
var _worker: Node2D
var _pending_zone_wake: bool = false
var _plant_zone: Rect2i = Rect2i()
var _has_plant_zone: bool = false
var _footprint_top_left: Vector2i = Vector2i.ZERO
var _footprint_initialized: bool = false
var _level: int = 1

static func get_footprint_size() -> Vector2i:
	return FOOTPRINT_TILES

static func top_left_from_center(center_tile: Vector2i) -> Vector2i:
	return center_tile - Vector2i(1, 1)

static func footprint_world_position(tilemap: TileMap, top_left: Vector2i) -> Vector2:
	return tilemap.map_to_local(top_left) + Vector2(48, 96)

func _ready() -> void:
	_level = clampi(level, 1, 3)
	if _footprint_initialized:
		_apply_placement_position()
	_apply_level_visual()
	ForesterLodgeRegistry.register_lodge(self)
	_update_spawn_label()
	call_deferred("_spawn_worker")
	YSortDepth.apply_to_entity(self)

func _exit_tree() -> void:
	if is_instance_valid(_worker):
		_worker.queue_free()
	ForesterLodgeRegistry.unregister_lodge(self)

func _process(_delta: float) -> void:
	_prune_invalid_saplings()

func initialize_placement(top_left: Vector2i) -> void:
	_footprint_top_left = top_left
	_footprint_initialized = true
	_apply_placement_position()

func get_min_zone_tile_count() -> int:
	return min_zone_tiles

func get_max_zone_tile_count() -> int:
	return max_zone_tiles

func get_level_name() -> String:
	match _level:
		1:
			return "Basic Forester Lodge"
		2:
			return "Experienced Forester Lodge"
		3:
			return "Master Forester Lodge"
		_:
			return "Forester Lodge"

func can_upgrade() -> bool:
	return _level < 3

func upgrade_level() -> bool:
	if not can_upgrade():
		return false
	level = _level + 1
	level_changed.emit(_level)
	_update_spawn_label()
	return true

func get_footprint_rect() -> Rect2i:
	return Rect2i(_footprint_top_left, FOOTPRINT_TILES)

func get_footprint_tiles() -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for y in range(FOOTPRINT_TILES.y):
		for x in range(FOOTPRINT_TILES.x):
			tiles.append(_footprint_top_left + Vector2i(x, y))
	return tiles

func occupies_tile(tile_coords: Vector2i) -> bool:
	return get_footprint_rect().has_point(tile_coords)

func has_plant_zone() -> bool:
	return _has_plant_zone

func get_plant_zone() -> Rect2i:
	return _plant_zone

func get_lodge_tile() -> Vector2i:
	if _footprint_initialized:
		return _footprint_top_left + Vector2i(1, 1)
	if _tilemap != null:
		return _tilemap.local_to_map(position)
	return _footprint_top_left

func get_zone_status_text() -> String:
	if not _has_plant_zone:
		return "No planting zone"
	return "Zone: %dx%d (%d tiles)" % [_plant_zone.size.x, _plant_zone.size.y, _plant_zone.size.x * _plant_zone.size.y]

func validate_plant_zone(zone: Rect2i) -> String:
	var normalized := _normalize_zone(zone)
	var tile_count := normalized.size.x * normalized.size.y
	if tile_count < min_zone_tiles:
		return "Zone too small (min %d tiles)" % min_zone_tiles
	if tile_count > max_zone_tiles:
		return "Zone too large (max %d tiles)" % max_zone_tiles
	if not normalized.has_point(get_lodge_tile()):
		return "Zone must include the forester lodge"
	return ""

func set_plant_zone(zone: Rect2i) -> String:
	var error := validate_plant_zone(zone)
	if not error.is_empty():
		return error

	var normalized := _normalize_zone(zone)
	_plant_zone = normalized
	_has_plant_zone = true
	plant_zone_changed.emit(_plant_zone)
	_update_spawn_label()
	_notify_worker_zone_ready()
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

func has_work_in_zone(for_worker: Node2D = null) -> bool:
	if not _has_plant_zone:
		return false
	if _has_stump_in_zone(for_worker):
		return true
	if can_plant_sapling() and find_plant_site() != Vector2.ZERO:
		return true
	return false

func find_stump_in_zone(from_world_pos: Vector2, for_worker: Node2D = null) -> Node2D:
	if not _has_plant_zone or _tilemap == null:
		return null

	var worker := for_worker if for_worker != null else _worker
	var nearest: Node2D = null
	var nearest_distance := INF

	for tree in TreeRegistry.get_active_trees():
		if not tree.has_method("is_stump_available_to"):
			continue
		if worker != null and not tree.is_stump_available_to(worker):
			continue
		if not _tree_is_in_plant_zone(tree):
			continue
		var distance := from_world_pos.distance_squared_to(tree.position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = tree

	if nearest != null and worker != null and nearest.has_method("try_reserve_stump_removal"):
		if not nearest.try_reserve_stump_removal(worker):
			return null

	return nearest

func get_stump_work_position(stump: Node2D) -> Vector2:
	if stump != null and stump.has_method("get_fallen_log_chop_position"):
		return stump.get_fallen_log_chop_position()
	if stump != null:
		return stump.position
	return Vector2.ZERO

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

func _apply_level_visual() -> void:
	_sprite.texture = LEVEL_TEXTURES[_level]
	_sprite.position = SPRITE_OFFSET
	_spawn_label.offset_top = -22.0 - float(_level - 1) * 10.0
	_spawn_label.offset_bottom = _spawn_label.offset_top + 16.0
	YSortDepth.apply_to_entity(self, true)

func _spawn_worker() -> void:
	if _tilemap == null:
		return

	_worker = FORESTER_WORKER_SCENE.instantiate()
	_worker.setup(self)
	_worker.position = position + Vector2(0, -6)
	_tilemap.add_child(_worker)
	if not plant_zone_changed.is_connected(_notify_worker_zone_ready):
		plant_zone_changed.connect(_notify_worker_zone_ready)
	if _has_plant_zone or _pending_zone_wake:
		_notify_worker_zone_ready()

func _notify_worker_zone_ready() -> void:
	if not is_instance_valid(_worker):
		_pending_zone_wake = true
		return
	_pending_zone_wake = false
	if _worker.has_method("on_plant_zone_ready"):
		_worker.on_plant_zone_ready()

func _has_stump_in_zone(for_worker: Node2D = null) -> bool:
	if not _has_plant_zone or _tilemap == null:
		return false

	var worker := for_worker if for_worker != null else _worker
	for tree in TreeRegistry.get_active_trees():
		if not tree.has_method("is_stump_available_to"):
			continue
		if worker != null and not tree.is_stump_available_to(worker):
			continue
		if not _tree_is_in_plant_zone(tree):
			continue
		return true
	return false

func _tree_is_in_plant_zone(tree: Node2D) -> bool:
	if _tilemap == null or tree == null:
		return false

	var trunk_tile := _tilemap.local_to_map(tree.position)
	if _plant_zone.has_point(trunk_tile):
		return true
	if tree.has_method("get_fallen_log_chop_position"):
		var log_tile := _tilemap.local_to_map(tree.get_fallen_log_chop_position())
		if _plant_zone.has_point(log_tile):
			return true
	return false

func _find_spawn_tile() -> Vector2i:
	if not _has_plant_zone:
		return Vector2i(-1, -1)

	var footprint := get_footprint_tiles()
	var candidates: Array[Vector2i] = []

	for y in range(_plant_zone.position.y, _plant_zone.position.y + _plant_zone.size.y):
		for x in range(_plant_zone.position.x, _plant_zone.position.x + _plant_zone.size.x):
			var tile_coords := Vector2i(x, y)
			if tile_coords in footprint:
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
		if lodge != self and lodge.has_method("occupies_tile") and lodge.occupies_tile(tile_coords):
			return true
	return false

func _is_too_close_to_vegetation(tile_coords: Vector2i) -> bool:
	for tree in TreeRegistry.get_active_trees():
		if tree.has_method("is_depleted_stump") and tree.is_depleted_stump():
			continue
		var tree_tile := _tilemap.local_to_map(tree.position)
		if not _plant_zone.has_point(tree_tile):
			continue
		if _chebyshev_distance(tile_coords, tree_tile) < vegetation_spacing_tiles:
			return true
	for sapling in SaplingRegistry.get_active_saplings():
		var sapling_tile := _tilemap.local_to_map(sapling.position)
		if not _plant_zone.has_point(sapling_tile):
			continue
		if _chebyshev_distance(tile_coords, sapling_tile) < vegetation_spacing_tiles:
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
		if lodge == self:
			continue
		if lodge.has_method("get_footprint_rect"):
			if _rect_chebyshev_distance(tile_coords, lodge.get_footprint_rect()) < building_buffer_tiles:
				return true
		elif _chebyshev_distance(tile_coords, _tilemap.local_to_map(lodge.position)) < building_buffer_tiles:
			return true
	return false

func _rect_chebyshev_distance(tile: Vector2i, rect: Rect2i) -> int:
	var dx := 0
	if tile.x < rect.position.x:
		dx = rect.position.x - tile.x
	elif tile.x >= rect.position.x + rect.size.x:
		dx = tile.x - (rect.position.x + rect.size.x - 1)

	var dy := 0
	if tile.y < rect.position.y:
		dy = rect.position.y - tile.y
	elif tile.y >= rect.position.y + rect.size.y:
		dy = tile.y - (rect.position.y + rect.size.y - 1)

	return maxi(dx, dy)

func _chebyshev_distance(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))

func _normalize_zone(zone: Rect2i) -> Rect2i:
	var x0 := mini(zone.position.x, zone.position.x + zone.size.x - 1)
	var y0 := mini(zone.position.y, zone.position.y + zone.size.y - 1)
	var x1 := maxi(zone.position.x, zone.position.x + zone.size.x - 1)
	var y1 := maxi(zone.position.y, zone.position.y + zone.size.y - 1)
	return Rect2i(x0, y0, x1 - x0 + 1, y1 - y0 + 1)

func _apply_placement_position() -> void:
	var tilemap := _tilemap if _tilemap != null else get_parent() as TileMap
	if tilemap == null:
		return
	position = footprint_world_position(tilemap, _footprint_top_left)

func _prune_invalid_saplings() -> void:
	for i in range(_spawned_saplings.size() - 1, -1, -1):
		if not is_instance_valid(_spawned_saplings[i]):
			_spawned_saplings.remove_at(i)
	_update_spawn_label()

func _update_spawn_label() -> void:
	var zone_text := "Set zone" if not _has_plant_zone else "%dx%d" % [_plant_zone.size.x, _plant_zone.size.y]
	_spawn_label.text = "Lv%d | Saplings: %d/%d | %s" % [_level, _spawned_saplings.size(), max_saplings, zone_text]
