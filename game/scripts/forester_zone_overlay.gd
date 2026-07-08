extends Node2D

const TILE_SIZE := 32

var _tilemap: TileMap
var _preview_zone: Rect2i = Rect2i()
var _show_preview: bool = false
var _preview_within_limit: bool = true
var _tracked_lodges: Array[Node2D] = []

func setup(tilemap: TileMap) -> void:
	_tilemap = tilemap

func set_preview_zone(zone: Rect2i, visible: bool, within_limit: bool = true) -> void:
	_preview_zone = zone
	_show_preview = visible
	_preview_within_limit = within_limit
	queue_redraw()

func track_lodge(lodge: Node2D) -> void:
	if lodge not in _tracked_lodges:
		_tracked_lodges.append(lodge)
		if lodge.has_signal("plant_zone_changed"):
			lodge.plant_zone_changed.connect(func(_z): queue_redraw())
	queue_redraw()

func untrack_lodge(lodge: Node2D) -> void:
	_tracked_lodges.erase(lodge)
	queue_redraw()

func _draw() -> void:
	if _tilemap == null:
		return

	for lodge in _tracked_lodges:
		if not is_instance_valid(lodge):
			continue
		if lodge.has_method("has_plant_zone") and lodge.has_plant_zone():
			_draw_zone(lodge.get_plant_zone(), Color(0.35, 0.78, 0.42, 0.18), Color(0.35, 0.78, 0.42, 0.75))

	if _show_preview and _preview_zone.size != Vector2i.ZERO:
		if _preview_within_limit:
			_draw_zone(_preview_zone, Color(0.35, 0.78, 0.42, 0.2), Color(0.35, 0.78, 0.42, 0.9))
		else:
			_draw_zone(_preview_zone, Color(0.9, 0.25, 0.25, 0.2), Color(0.95, 0.2, 0.2, 0.95))

func _draw_zone(zone: Rect2i, fill_color: Color, border_color: Color) -> void:
	var pixel_rect := _tile_zone_to_rect(zone)
	draw_rect(pixel_rect, fill_color, true)
	draw_rect(pixel_rect, border_color, false, 2.0)

func _tile_zone_to_rect(zone: Rect2i) -> Rect2:
	var top_left := _tilemap.map_to_local(zone.position) - Vector2(TILE_SIZE, TILE_SIZE) * 0.5
	return Rect2(top_left, Vector2(zone.size) * TILE_SIZE)
