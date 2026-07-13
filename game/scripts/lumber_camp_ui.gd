extends CanvasLayer

@onready var _panel: PanelContainer = $Panel
@onready var _title_label: Label = $Panel/Margin/VBox/TitleLabel
@onready var _workers_label: Label = $Panel/Margin/VBox/WorkersLabel
@onready var _pool_label: Label = $Panel/Margin/VBox/PoolLabel
@onready var _add_button: Button = $Panel/Margin/VBox/WorkerControls/AddButton
@onready var _remove_button: Button = $Panel/Margin/VBox/WorkerControls/RemoveButton
@onready var _close_button: Button = $Panel/Margin/VBox/CloseButton

var _tilemap: TileMap
var _selected_camp: LumberCamp

func setup(tilemap: TileMap) -> void:
	_tilemap = tilemap
	_panel.visible = false
	WorkerPool.pool_changed.connect(_on_pool_changed)

func handle_input(event: InputEvent) -> bool:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		return _try_select_camp()
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_close_panel()
		return true
	return _panel.visible

func is_blocking_placement() -> bool:
	return _panel.visible

func _try_select_camp() -> bool:
	var camp := _camp_at_mouse()
	if camp == null:
		if _panel.visible:
			_close_panel()
		return _panel.visible
	_open_panel(camp)
	return true

func _open_panel(camp: LumberCamp) -> void:
	_selected_camp = camp
	_title_label.text = "Lumber Camp"
	_refresh_panel_labels()
	_panel.visible = true

func _close_panel() -> void:
	_panel.visible = false
	_selected_camp = null

func _refresh_panel_labels() -> void:
	if _selected_camp == null or not is_instance_valid(_selected_camp):
		return
	var assigned := _selected_camp.get_assigned_worker_count()
	var max_workers := _selected_camp.get_max_workers()
	_workers_label.text = "Workers: %d / %d" % [assigned, max_workers]
	_pool_label.text = "Available in pool: %d" % WorkerPool.get_available()
	_add_button.disabled = not _selected_camp.can_add_worker()
	_remove_button.disabled = not _selected_camp.can_remove_worker()

func _on_add_pressed() -> void:
	if _selected_camp == null or not is_instance_valid(_selected_camp):
		return
	if _selected_camp.add_worker():
		_refresh_panel_labels()

func _on_remove_pressed() -> void:
	if _selected_camp == null or not is_instance_valid(_selected_camp):
		return
	if _selected_camp.remove_worker():
		_refresh_panel_labels()

func _on_close_pressed() -> void:
	_close_panel()

func _on_pool_changed(_available: int, _assigned: int, _total: int) -> void:
	if _panel.visible:
		_refresh_panel_labels()

func _camp_at_mouse() -> LumberCamp:
	var click_tile := GridPlacement.mouse_tile_coords(_tilemap)
	for camp in CampRegistry.get_active_camps():
		if camp is LumberCamp and camp.occupies_tile(click_tile):
			return camp
	return null
