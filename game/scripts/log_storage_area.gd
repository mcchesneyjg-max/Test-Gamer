extends Node2D

signal storage_changed(current_amount: int, capacity_amount: int)

const TILE_SIZE := 32
const STAGES_PER_PILE := 18
const MAX_PILE_SLOTS := 5
const PILE_SLOT_TILES := Vector2i(3, 2)
const LOG_PILE_ROOT := "res://assets/sprites/stacked_resources/logs"
const LOG_PILE_PREFIXES: Array[String] = ["log_pile"]

@onready var _pile_slots: Node2D = $PileSlots
@onready var _tilemap: TileMap = get_parent() as TileMap

var _zone: Rect2i = Rect2i()
var _pile_slot_count: int = 1
var _delivery_count: int = 0
var _pile_textures: Array[Texture2D] = []
var _pile_sprites: Array[Sprite2D] = []
var _owner_warehouse: Node2D
var _registered: bool = false

static func get_pile_slot_tiles() -> Vector2i:
	return PILE_SLOT_TILES

static func get_min_zone_size() -> Vector2i:
	return PILE_SLOT_TILES

static func get_max_zone_size() -> Vector2i:
	return Vector2i(PILE_SLOT_TILES.x * MAX_PILE_SLOTS, PILE_SLOT_TILES.y)

static func pile_count_for_zone(zone: Rect2i) -> int:
	if zone.size.y != PILE_SLOT_TILES.y:
		return 0
	if zone.size.x % PILE_SLOT_TILES.x != 0:
		return 0
	var count := zone.size.x / PILE_SLOT_TILES.x
	if count < 1 or count > MAX_PILE_SLOTS:
		return 0
	return count

static func snap_zone_from_tiles(anchor: Vector2i, current: Vector2i) -> Rect2i:
	var raw_width := absi(current.x - anchor.x) + 1
	var pile_count := clampi(
		ceili(float(raw_width) / float(PILE_SLOT_TILES.x)),
		1,
		MAX_PILE_SLOTS
	)
	var snapped_width := pile_count * PILE_SLOT_TILES.x
	var snapped_height := PILE_SLOT_TILES.y

	var left_x := anchor.x
	if current.x < anchor.x:
		left_x = anchor.x - snapped_width + 1

	var top_y := anchor.y
	if current.y < anchor.y:
		top_y = anchor.y - snapped_height + 1

	return Rect2i(left_x, top_y, snapped_width, snapped_height)

func _ready() -> void:
	_load_pile_textures()
	YSortDepth.apply_to_entity(self)

func _exit_tree() -> void:
	if _registered:
		LogStorageAreaRegistry.unregister_area(self)

func initialize_zone(zone: Rect2i, owner_warehouse: Node2D = null) -> void:
	_zone = zone
	_pile_slot_count = pile_count_for_zone(zone)
	_owner_warehouse = owner_warehouse
	_apply_zone_position()
	_build_pile_sprites()
	_refresh_pile_visuals()
	if not _registered:
		LogStorageAreaRegistry.register_area(self)
		_registered = true

func get_zone() -> Rect2i:
	return _zone

func get_owner_warehouse() -> Node2D:
	return _owner_warehouse

func occupies_tile(tile_coords: Vector2i) -> bool:
	return _zone.has_point(tile_coords)

func get_stored_logs() -> int:
	return _delivery_count

func get_capacity() -> int:
	return _pile_slot_count * STAGES_PER_PILE

func can_accept_logs() -> bool:
	return _delivery_count < get_capacity()

func deposit_logs(amount: int) -> int:
	if amount <= 0 or not can_accept_logs():
		return 0
	var added := mini(amount, get_capacity() - _delivery_count)
	if added <= 0:
		return 0
	_delivery_count += added
	_refresh_pile_visuals()
	storage_changed.emit(_delivery_count, get_capacity())
	LogStorageAreaRegistry.notify_storage_changed()
	return added

func set_stored_logs(amount: int) -> void:
	_delivery_count = clampi(amount, 0, get_capacity())
	_refresh_pile_visuals()
	storage_changed.emit(_delivery_count, get_capacity())
	LogStorageAreaRegistry.notify_storage_changed()

func get_delivery_position() -> Vector2:
	var center_x := _zone.size.x * TILE_SIZE * 0.5
	var south_y := _zone.size.y * TILE_SIZE + 14.0
	return position + Vector2(center_x, south_y)

func get_spawn_position(index: int) -> Vector2:
	var delivery := get_delivery_position()
	var spacing := 10.0
	return delivery + Vector2(-16.0 + index * spacing, 10.0)

func validate_zone(zone: Rect2i, tilemap: TileMap) -> String:
	var pile_count := pile_count_for_zone(zone)
	if pile_count <= 0:
		return (
			"Storage area must be %dx%d tiles per pile slot (1-%d slots wide)."
			% [PILE_SLOT_TILES.x, PILE_SLOT_TILES.y, MAX_PILE_SLOTS]
		)

	for tile_coords in GridPlacement.footprint_tiles(zone.position, zone.size):
		if not GridPlacement.is_cardinal_tile_in_bounds(tile_coords):
			return "Storage area must stay inside the map."
		if tilemap.get_cell_source_id(0, tile_coords) == -1:
			return "Storage area must be placed on ground tiles."
		if _is_foreign_tile_blocked(tile_coords, tilemap):
			return "Storage area overlaps another building or zone."

	return ""

func _is_foreign_tile_blocked(tile_coords: Vector2i, tilemap: TileMap) -> bool:
	for area in LogStorageAreaRegistry.get_active_areas():
		if area == self:
			continue
		if area.has_method("occupies_tile") and area.occupies_tile(tile_coords):
			return true
	for tree in TreeRegistry.get_active_trees():
		if tilemap.local_to_map(tree.position) == tile_coords:
			return true
	for camp in CampRegistry.get_active_camps():
		if tilemap.local_to_map(camp.position) == tile_coords:
			return true
	for warehouse in WarehouseRegistry.get_active_warehouses():
		if warehouse != _owner_warehouse and tilemap.local_to_map(warehouse.position) == tile_coords:
			return true
	for station in HaulerStationRegistry.get_active_stations():
		if tilemap.local_to_map(station.position) == tile_coords:
			return true
	for lodge in ForesterLodgeRegistry.get_active_lodges():
		if lodge.has_method("occupies_tile") and lodge.occupies_tile(tile_coords):
			return true
	for sapling in SaplingRegistry.get_active_saplings():
		if tilemap.local_to_map(sapling.position) == tile_coords:
			return true
	return false

func _apply_zone_position() -> void:
	if _tilemap == null:
		return
	var top_left := _tilemap.map_to_local(_zone.position) - Vector2(TILE_SIZE, TILE_SIZE) * 0.5
	position = top_left

func _load_pile_textures() -> void:
	if not _pile_textures.is_empty():
		return
	var roots: Array[String] = [LOG_PILE_ROOT]
	_pile_textures = CharacterWalk.load_png_sequence_from_candidates(
		roots,
		LOG_PILE_PREFIXES,
		true
	)
	if _pile_textures.is_empty():
		push_warning(
			"LogStorageArea: no log pile sprites found in %s (expected log_pile_1..18)"
			% LOG_PILE_ROOT
		)

func _build_pile_sprites() -> void:
	if _pile_slots == null:
		return

	for child in _pile_slots.get_children():
		child.queue_free()
	_pile_sprites.clear()

	for slot_index in _pile_slot_count:
		var sprite := Sprite2D.new()
		sprite.name = "PileSlot%d" % (slot_index + 1)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.centered = false
		sprite.position = _slot_sprite_position(slot_index)
		_pile_slots.add_child(sprite)
		_pile_sprites.append(sprite)

func _slot_sprite_position(slot_index: int) -> Vector2:
	var slot_offset_x := slot_index * PILE_SLOT_TILES.x * TILE_SIZE
	var slot_width := PILE_SLOT_TILES.x * TILE_SIZE
	var slot_height := PILE_SLOT_TILES.y * TILE_SIZE
	var x := slot_offset_x + slot_width * 0.5
	var y := slot_height
	return Vector2(x, y)

func _refresh_pile_visuals() -> void:
	for slot_index in _pile_sprites.size():
		var sprite := _pile_sprites[slot_index]
		var stage := _stage_for_slot(slot_index)
		if stage <= 0:
			sprite.visible = false
			continue

		var texture := _texture_for_stage(stage)
		if texture == null:
			sprite.visible = false
			continue

		sprite.texture = texture
		sprite.visible = true
		sprite.offset = Vector2(-texture.get_width() * 0.5, -texture.get_height())

func _stage_for_slot(slot_index: int) -> int:
	var slot_start := slot_index * STAGES_PER_PILE
	if _delivery_count <= slot_start:
		return 0
	var deliveries_in_slot := _delivery_count - slot_start
	return clampi(deliveries_in_slot, 1, STAGES_PER_PILE)

func _texture_for_stage(stage: int) -> Texture2D:
	if stage <= 0:
		return null
	if not _pile_textures.is_empty():
		var index := clampi(stage - 1, 0, _pile_textures.size() - 1)
		return _pile_textures[index]
	return preload("res://assets/sprites/wood_log.png")
