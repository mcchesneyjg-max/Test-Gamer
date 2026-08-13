extends CanvasLayer

const LogStorageAreaScript := preload("res://scripts/log_storage_area.gd")
const LOG_STORAGE_AREA_SCENE := preload("res://scenes/log_storage_area.tscn")

@onready var _panel: PanelContainer = $Panel
@onready var _title_label: Label = $Panel/Margin/VBox/TitleLabel
@onready var _storage_label: Label = $Panel/Margin/VBox/StorageLabel
@onready var _status_label: Label = $Panel/Margin/VBox/StatusLabel
@onready var _draw_button: Button = $Panel/Margin/VBox/DrawStorageButton
@onready var _close_button: Button = $Panel/Margin/VBox/CloseButton
@onready var _hint_label: Label = $DrawHintLabel

var _tilemap: TileMap
var _zone_overlay: Node2D
var _selected_area: Node2D
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
		return _try_select_storage()
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_close_panel()
		return true
	return _panel.visible

func is_blocking_placement() -> bool:
	return _draw_mode or _panel.visible

func start_draw_mode() -> void:
	_selected_area = null
	_begin_draw_mode()

func _try_select_storage() -> bool:
	var area := _storage_at_mouse()
	if area == null:
		if _panel.visible:
			_close_panel()
		return _panel.visible
	_open_panel(area)
	return true

func _open_panel(area: Node2D) -> void:
	_selected_area = area
	_zone_overlay.clear_preview()
	_title_label.text = "Log Storage"
	_refresh_panel_labels()
	_panel.visible = true

func _close_panel() -> void:
	_panel.visible = false
	_cancel_draw_mode()
	_selected_area = null

func _refresh_panel_labels() -> void:
	if _selected_area != null and is_instance_valid(_selected_area):
		var slots: int = LogStorageAreaScript.pile_count_for_zone(_selected_area.get_zone())
		_storage_label.text = "Stored: %d / %d logs (%d pile slots)" % [
			_selected_area.get_stored_logs(),
			_selected_area.get_capacity(),
			slots,
		]
		_status_label.text = "Haulers spawn from and deliver logs here."
		_draw_button.text = "Redraw Storage Area"
	else:
		_storage_label.text = "No log storage area yet"
		_status_label.text = (
			"Draw a storage area (%d-%d pile slots wide) or Shift+right-click on the map."
			% [1, LogStorageAreaScript.MAX_PILE_SLOTS]
		)
		_draw_button.text = "Draw Log Storage Area"

func _on_draw_storage_pressed() -> void:
	_begin_draw_mode()

func _begin_draw_mode() -> void:
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
	if _selected_area != null and is_instance_valid(_selected_area):
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
	var zone := LogStorageAreaScript.snap_zone_from_tiles(_draw_anchor, _draw_current)
	var temp_area := LogStorageAreaScript.new()
	var error: String = temp_area.validate_zone(zone, _tilemap)
	temp_area.free()
	_zone_overlay.clear_preview()

	if not error.is_empty():
		_cancel_draw_mode()
		_status_label.text = error
		if _selected_area != null:
			_panel.visible = true
		return

	error = _assign_storage_zone(zone)
	_cancel_draw_mode()
	if error.is_empty():
		_status_label.text = "Log storage set! Haulers will spawn and deliver here."
	else:
		_status_label.text = error
	if _selected_area != null and is_instance_valid(_selected_area):
		_refresh_panel_labels()
		_panel.visible = true

func _assign_storage_zone(zone: Rect2i) -> String:
	if _tilemap == null:
		return "Map not ready."

	if _selected_area != null and is_instance_valid(_selected_area):
		var stored: int = _selected_area.get_stored_logs()
		_selected_area.queue_free()
		_selected_area = null
		var area: Node2D = _spawn_storage_area(zone)
		if area == null:
			return "Could not create log storage area."
		area.set_stored_logs(stored)
		_selected_area = area
		return ""

	for existing in LogStorageAreaRegistry.get_active_areas():
		if is_instance_valid(existing):
			existing.queue_free()

	var new_area: Node2D = _spawn_storage_area(zone)
	if new_area == null:
		return "Could not create log storage area."
	_selected_area = new_area
	return ""

func _spawn_storage_area(zone: Rect2i) -> Node2D:
	var area: Node2D = LOG_STORAGE_AREA_SCENE.instantiate()
	_tilemap.add_child(area)
	area.initialize_zone(zone)
	HaulerStationRegistry.notify_log_storage_available()
	return area

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

func _storage_at_mouse() -> Node2D:
	var click_tile := _mouse_tile()
	for area in LogStorageAreaRegistry.get_active_areas():
		if area.has_method("occupies_tile") and area.occupies_tile(click_tile):
			return area
	return null

func _on_close_pressed() -> void:
	_close_panel()
