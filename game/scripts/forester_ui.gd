extends CanvasLayer

const TILE_SIZE := 32

@onready var _panel: PanelContainer = $Panel
@onready var _title_label: Label = $Panel/Margin/VBox/TitleLabel
@onready var _zone_label: Label = $Panel/Margin/VBox/ZoneLabel
@onready var _status_label: Label = $Panel/Margin/VBox/StatusLabel
@onready var _draw_button: Button = $Panel/Margin/VBox/DrawZoneButton
@onready var _upgrade_button: Button = $Panel/Margin/VBox/UpgradeButton
@onready var _close_button: Button = $Panel/Margin/VBox/CloseButton
@onready var _hint_label: Label = $DrawHintLabel

var _tilemap: TileMap
var _zone_overlay: Node2D
var _selected_lodge: Node2D
var _draw_mode: bool = false
var _draw_anchor: Vector2i = Vector2i(-999999, -999999)
var _draw_current: Vector2i = Vector2i.ZERO

func setup(tilemap: TileMap, zone_overlay: Node2D) -> void:
	_tilemap = tilemap
	_zone_overlay = zone_overlay
	_panel.visible = false
	_hint_label.visible = false

func handle_input(event: InputEvent) -> bool:
	if _draw_mode:
		return _handle_draw_input(event)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		return _try_select_lodge()
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_close_panel()
		return true
	return _panel.visible

func is_blocking_placement() -> bool:
	return _draw_mode or _panel.visible

func _try_select_lodge() -> bool:
	var lodge := _lodge_at_mouse()
	if lodge == null:
		if _panel.visible:
			_close_panel()
		return _panel.visible
	_open_panel(lodge)
	return true

func _open_panel(lodge: Node2D) -> void:
	_selected_lodge = lodge
	_zone_overlay.clear_preview()
	_title_label.text = _selected_lodge.get_level_name()
	_refresh_panel_labels()
	_upgrade_button.disabled = not _selected_lodge.can_upgrade()
	_panel.visible = true

func _close_panel() -> void:
	_panel.visible = false
	_cancel_draw_mode()
	_selected_lodge = null

func _refresh_panel_labels() -> void:
	if _selected_lodge == null or not is_instance_valid(_selected_lodge):
		return
	_zone_label.text = _selected_lodge.get_zone_status_text()
	if _selected_lodge.has_plant_zone():
		_status_label.text = "Workers clear stumps and plant saplings inside the drawn zone."
	else:
		_status_label.text = "Draw a zone (max %d tiles). Lodge must be inside." % _selected_lodge.max_zone_tiles

func _on_draw_zone_pressed() -> void:
	if _selected_lodge == null:
		return
	_draw_mode = true
	_draw_anchor = Vector2i(-999999, -999999)
	_panel.visible = false
	_hint_label.text = "Draw planting zone: green = valid size, red = too large (max %d tiles). Lodge must be inside. Esc to cancel." % _selected_lodge.max_zone_tiles
	_hint_label.visible = true

func _cancel_draw_mode() -> void:
	_draw_mode = false
	_draw_anchor = Vector2i(-999999, -999999)
	_hint_label.visible = false
	_zone_overlay.clear_preview()
	if _selected_lodge != null and is_instance_valid(_selected_lodge):
		_panel.visible = true

func _handle_draw_input(event: InputEvent) -> bool:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_cancel_draw_mode()
		return true

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var tile := _mouse_tile()
		if event.pressed:
			_draw_anchor = tile
			_draw_current = tile
			_update_draw_preview()
			return true
		if _draw_anchor.x > -999999:
			_commit_draw_zone(tile)
			return true

	if event is InputEventMouseMotion and _draw_anchor.x > -999999:
		_draw_current = _mouse_tile()
		_update_draw_preview()
		return true

	return true

func _commit_draw_zone(end_tile: Vector2i) -> void:
	if _selected_lodge == null:
		_cancel_draw_mode()
		return

	var zone := _rect_from_tiles(_draw_anchor, end_tile)
	_zone_overlay.clear_preview()
	var error: String = _selected_lodge.set_plant_zone(zone)
	_cancel_draw_mode()
	if error.is_empty():
		_status_label.text = "Zone set! Workers will plant inside it."
	else:
		_status_label.text = error
	_refresh_panel_labels()
	_panel.visible = true

func _update_draw_preview() -> void:
	if _draw_anchor.x < -999999:
		return
	var zone := _rect_from_tiles(_draw_anchor, _draw_current)
	var tile_count := zone.size.x * zone.size.y
	var within_limit: bool = tile_count <= _selected_lodge.max_zone_tiles
	_zone_overlay.set_preview_zone(zone, true, within_limit)

func _rect_from_tiles(a: Vector2i, b: Vector2i) -> Rect2i:
	return GridPlacement.cardinal_rect_from_tiles(a, b)

func _mouse_tile() -> Vector2i:
	return GridPlacement.mouse_tile_coords(_tilemap)

func _lodge_at_mouse() -> Node2D:
	var click_tile := _mouse_tile()
	for lodge in ForesterLodgeRegistry.get_active_lodges():
		if lodge.has_method("occupies_tile") and lodge.occupies_tile(click_tile):
			return lodge
	return null

func _on_upgrade_pressed() -> void:
	if _selected_lodge == null or not is_instance_valid(_selected_lodge):
		return
	if _selected_lodge.upgrade_level():
		_title_label.text = _selected_lodge.get_level_name()
		_status_label.text = "Lodge upgraded! Same footprint, larger building."
		_upgrade_button.disabled = not _selected_lodge.can_upgrade()

func _on_close_pressed() -> void:
	_close_panel()

func register_new_lodge(_lodge: Node2D) -> void:
	pass
