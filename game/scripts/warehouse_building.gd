extends Node2D

const LOG_STORAGE_AREA_SCENE := preload("res://scenes/log_storage_area.tscn")

@onready var _storage = $StorageAreas

var _log_storage_area: Node2D

func _ready() -> void:
	WarehouseRegistry.register_warehouse(self)
	_storage.input.changed.connect(_on_input_changed)
	YSortDepth.apply_to_entity(self)

func _exit_tree() -> void:
	if is_instance_valid(_log_storage_area):
		_log_storage_area.queue_free()
	_log_storage_area = null
	WarehouseRegistry.unregister_warehouse(self)

func _on_input_changed(_current: int, _capacity: int) -> void:
	WarehouseRegistry.notify_storage_changed()

func has_log_storage_area() -> bool:
	return is_instance_valid(_log_storage_area)

func get_log_storage_area() -> Node2D:
	return _log_storage_area

func assign_log_storage_zone(zone: Rect2i) -> String:
	var tilemap := get_parent() as TileMap
	if tilemap == null:
		return "Warehouse must be placed on the map."

	if is_instance_valid(_log_storage_area):
		_log_storage_area.queue_free()
		_log_storage_area = null

	var area := LOG_STORAGE_AREA_SCENE.instantiate()
	tilemap.add_child(area)
	area.initialize_zone(zone, self)
	_log_storage_area = area
	HaulerStationRegistry.notify_log_storage_available()
	return ""

func get_stored_logs() -> int:
	if has_log_storage_area():
		return _log_storage_area.get_stored_logs()
	return _storage.input.current

func deposit_logs(amount: int) -> int:
	if has_log_storage_area():
		return _log_storage_area.deposit_logs(amount)
	var added: int = _storage.input.try_add(amount)
	if added > 0:
		WarehouseRegistry.notify_storage_changed()
	return added

func can_accept_logs() -> bool:
	if has_log_storage_area():
		return _log_storage_area.can_accept_logs()
	return not _storage.input.is_full()

func get_delivery_position() -> Vector2:
	if has_log_storage_area():
		return _log_storage_area.get_delivery_position()
	var tilemap := get_parent() as TileMap
	if tilemap:
		return tilemap.to_local(global_position + Vector2(32, 44))
	return position + Vector2(32, 44)

func set_stored_logs(amount: int) -> void:
	if has_log_storage_area():
		_log_storage_area.set_stored_logs(amount)
		return
	_storage.input.current = clampi(amount, 0, _storage.input.capacity)
	_storage.input.changed.emit(_storage.input.current, _storage.input.capacity)
	WarehouseRegistry.notify_storage_changed()
