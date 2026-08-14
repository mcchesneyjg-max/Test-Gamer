extends Node2D

signal storage_changed(current_amount: int, capacity_amount: int)

const TILE_SIZE := 32
const STAGES_PER_PILE := 18
const MAX_PILE_SLOTS := 5
const MIN_ZONE_WIDTH_TILES := 2
const MAX_ZONE_WIDTH_TILES := 6
const ZONE_HEIGHT_TILES := 2
const PILE_SLOT_STEP_TILES := 1
const LOG_PILE_ROOT := "res://assets/sprites/stacked_resources/logs"
const LOG_PILE_PREFIXES: Array[String] = ["log_pile"]

@onready var _pile_slots: Node2D = $PileSlots
@onready var _tilemap: TileMap = get_parent() as TileMap

var _zone: Rect2i = Rect2i()
var _pile_slot_count: int = 1
var _delivery_count: int = 0
var _pile_textures: Array[Texture2D] = []
var _pile_sprites: Array[Sprite2D] = []
var _registered: bool = false

static func zone_width_for_pile_count(pile_count: int) -> int:
	var count: int = clampi(pile_count, 1, MAX_PILE_SLOTS)
	return count + 1

static func snap_width_tiles(raw_width_tiles: int) -> int:
	var raw: int = clampi(maxi(raw_width_tiles, 1), 1, MAX_ZONE_WIDTH_TILES)
	var best_width: int = MIN_ZONE_WIDTH_TILES
	var best_distance: int = absi(raw - MIN_ZONE_WIDTH_TILES)
	for width in range(MIN_ZONE_WIDTH_TILES + 1, MAX_ZONE_WIDTH_TILES + 1):
		var distance: int = absi(raw - width)
		if distance < best_distance:
			best_distance = distance
			best_width = width
	return best_width

static func pile_count_from_width(width_tiles: int) -> int:
	return clampi(width_tiles - 1, 1, MAX_PILE_SLOTS)

static func zone_size_for_pile_count(pile_count: int) -> Vector2i:
	var width_tiles: int = zone_width_for_pile_count(pile_count)
	return Vector2i(width_tiles, ZONE_HEIGHT_TILES)

static func pile_count_from_drag_width(raw_width_tiles: int) -> int:
	return pile_count_from_width(snap_width_tiles(raw_width_tiles))

static func get_pile_slot_tiles() -> Vector2i:
	return zone_size_for_pile_count(1)

static func get_min_zone_size() -> Vector2i:
	return zone_size_for_pile_count(1)

static func get_max_zone_size() -> Vector2i:
	return zone_size_for_pile_count(MAX_PILE_SLOTS)

static func pile_count_for_zone(zone: Rect2i) -> int:
	if zone.size.y != ZONE_HEIGHT_TILES:
		return 0
	for pile_count in range(1, MAX_PILE_SLOTS + 1):
		if zone.size == zone_size_for_pile_count(pile_count):
			return pile_count
	return 0

static func snap_zone_from_tiles(anchor: Vector2i, current: Vector2i) -> Rect2i:
	var raw_width_tiles: int = absi(current.x - anchor.x) + 1
	var pile_count: int = pile_count_from_drag_width(raw_width_tiles)
	var zone_size: Vector2i = zone_size_for_pile_count(pile_count)

	var left_x: int = anchor.x
	if current.x < anchor.x:
		left_x = anchor.x - zone_size.x + 1

	return Rect2i(left_x, anchor.y, zone_size.x, zone_size.y)

func _ready() -> void:
	_load_pile_textures()

func _exit_tree() -> void:
	if _registered:
		LogStorageAreaRegistry.unregister_area(self)

func initialize_zone(zone: Rect2i) -> void:
	_zone = zone
	_pile_slot_count = pile_count_for_zone(zone)
	_apply_zone_position()
	_build_pile_sprites()
	_refresh_pile_visuals()
	_refresh_sort_depth()
	if not _registered:
		LogStorageAreaRegistry.register_area(self)
		_registered = true

func get_zone() -> Rect2i:
	return _zone

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
	var added: int = mini(amount, get_capacity() - _delivery_count)
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
	var center_x: float = _zone.size.x * TILE_SIZE * 0.5
	return position + Vector2(center_x, 14.0)

func get_spawn_position(index: int) -> Vector2:
	var delivery: Vector2 = get_delivery_position()
	var spacing: float = 10.0
	return delivery + Vector2(-16.0 + index * spacing, 10.0)

func validate_zone(zone: Rect2i, tilemap: TileMap) -> String:
	var pile_count: int = pile_count_for_zone(zone)
	if pile_count <= 0:
		return (
			"Storage area must fit %d-%d pile slots (2x2 up to 2x6 tiles)."
			% [1, MAX_PILE_SLOTS]
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
	var zone_size_px := Vector2(_zone.size) * TILE_SIZE
	position = top_left + Vector2(0.0, zone_size_px.y)

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
	var slot_step_px: float = float(PILE_SLOT_STEP_TILES) * TILE_SIZE
	var slot_span_px: float = float(TILE_SIZE * 2)
	var x: float = float(slot_index) * slot_step_px + slot_span_px * 0.5
	return Vector2(x, 0.0)

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

	_refresh_sort_depth()

func _refresh_sort_depth() -> void:
	var textures: Array[Texture2D] = []
	for texture in _pile_textures:
		if texture != null:
			textures.append(texture)
	set_meta("_y_sort_extra_textures", textures)
	YSortDepth.apply_to_entity(self, true)

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
