extends CanvasLayer

const LogStorageAreaScript := preload("res://scripts/log_storage_area.gd")

@onready var _panel: PanelContainer = $Panel
@onready var _title_label: Label = $Panel/Margin/VBox/TitleLabel
@onready var _storage_label: Label = $Panel/Margin/VBox/StorageLabel
@onready var _status_label: Label = $Panel/Margin/VBox/StatusLabel
@onready var _draw_button: Button = $Panel/Margin/VBox/DrawStorageButton
@onready var _close_button: Button = $Panel/Margin/VBox/CloseButton
@onready var _hint_label: Label = $DrawHintLabel

var _tilemap: TileMap
var _zone_overlay: Node2D
var _selected_warehouse: Node2D
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
		return _try_select_warehouse()
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_close_panel()
		return true
	return _panel.visible

func is_blocking_placement() -> bool:
	return _draw_mode or _panel.visible

func _try_select_warehouse() -> bool:
	var warehouse := _warehouse_at_mouse()
	if warehouse == null:
		if _panel.visible:
			_close_panel()
		return _panel.visible
	_open_panel(warehouse)
	return true

func _open_panel(warehouse: Node2D) -> void:
	_selected_warehouse = warehouse
	_zone_overlay.clear_preview()
	_title_label.text = "Warehouse"
	_refresh_panel_labels()
	_panel.visible = true

func _close_panel() -> void:
	_panel.visible = false
	_cancel_draw_mode()
	_selected_warehouse = null

func _refresh_panel_labels() -> void:
	if _selected_warehouse == null or not is_instance_valid(_selected_warehouse):
		return

	if _selected_warehouse.has_method("has_log_storage_area") and _selected_warehouse.has_log_storage_area():
		var area: Node2D = _selected_warehouse.get_log_storage_area()
		var slots := LogStorageAreaScript.pile_count_for_zone(area.get_zone())
		_storage_label.text = "Log storage: %d / %d logs (%d pile slots)" % [
			area.get_stored_logs(),
			area.get_capacity(),
			slots,
		]
		_status_label.text = "Haulers spawn from and deliver logs to this storage area."
		_draw_button.text = "Redraw Log Storage Area"
	else:
		_storage_label.text = "No log storage area"
		_status_label.text = (
			"Draw a rectangular log storage area (%d-%d pile slots wide)."
			% [1, LogStorageAreaScript.MAX_PILE_SLOTS]
		)
		_draw_button.text = "Draw Log Storage Area"

func _on_draw_storage_pressed() -> void:
	if _selected_warehouse == null:
		return
	_draw_mode = true
	_draw_anchor = Vector2i(-999999, -999999)
	_panel.visible = false
	_hint_label.text = (
		"Draw log storage: drag horizontally for 1-%d pile slots (%dx%d tiles each). Esc to cancel."
		% [
			LogStorageAreaScript.MAX_PILE_SLOTS,
			LogStorageAreaScript.PILE_SLOT_TILES.x,
			LogStorageAreaScript.PILE_SLOT_TILES.y,
		]
	)
	_hint_label.visible = true

func _cancel_draw_mode() -> void:
	_draw_mode = false
	_draw_anchor = Vector2i(-999999, -999999)
	_hint_label.visible = false
	_zone_overlay.clear_preview()
	if _selected_warehouse != null and is_instance_valid(_selected_warehouse):
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

func _commit_draw_zone(_end_tile: Vector2i) -> void:
	if _selected_warehouse == null:
		_cancel_draw_mode()
		return

	var zone := LogStorageAreaScript.snap_zone_from_tiles(_draw_anchor, _draw_current)
	var temp_area := LogStorageAreaScript.new()
	var error: String = temp_area.validate_zone(zone, _tilemap)
	temp_area.free()
	_zone_overlay.clear_preview()

	if not error.is_empty():
		_cancel_draw_mode()
		_status_label.text = error
		_refresh_panel_labels()
		_panel.visible = true
		return

	if _selected_warehouse.has_method("assign_log_storage_zone"):
		error = _selected_warehouse.assign_log_storage_zone(zone)
	else:
		error = "Warehouse cannot assign log storage."

	_cancel_draw_mode()
	if error.is_empty():
		_status_label.text = "Log storage area set! Haulers will use it for drop-off."
	else:
		_status_label.text = error
	_refresh_panel_labels()
	_panel.visible = true

func _update_draw_preview() -> void:
	if _draw_anchor.x < -999999:
		return

	var zone := LogStorageAreaScript.snap_zone_from_tiles(_draw_anchor, _draw_current)
	var temp_area := LogStorageAreaScript.new()
	var validation_error: String = temp_area.validate_zone(zone, _tilemap)
	temp_area.free()
	var is_valid := validation_error.is_empty()
	var pile_count := LogStorageAreaScript.pile_count_for_zone(zone)

	if is_valid:
		_hint_label.text = (
			"Release to set storage (%d pile slot%s, capacity %d). Esc to cancel."
			% [pile_count, "s" if pile_count != 1 else "", pile_count * LogStorageAreaScript.STAGES_PER_PILE]
		)
	else:
		_hint_label.text = "%s — adjust outline. Esc to cancel." % validation_error

	_zone_overlay.set_preview_zone(zone, true, is_valid)

func _mouse_tile() -> Vector2i:
	return GridPlacement.mouse_tile_coords(_tilemap)

func _warehouse_at_mouse() -> Node2D:
	var click_tile := _mouse_tile()
	for warehouse in WarehouseRegistry.get_active_warehouses():
		if _tilemap.local_to_map(warehouse.position) == click_tile:
			return warehouse
	return null

func _on_close_pressed() -> void:
	_close_panel()
