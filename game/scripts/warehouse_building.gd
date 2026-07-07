extends Node2D

@onready var _storage = $StorageAreas

func _ready() -> void:
	WarehouseRegistry.register_warehouse(self)
	_storage.input.changed.connect(_on_input_changed)

func _exit_tree() -> void:
	WarehouseRegistry.unregister_warehouse(self)

func _on_input_changed(_current: int, _capacity: int) -> void:
	WarehouseRegistry.notify_storage_changed()

func get_stored_logs() -> int:
	return _storage.input.current

func deposit_logs(amount: int) -> int:
	var added: int = _storage.input.try_add(amount)
	if added > 0:
		WarehouseRegistry.notify_storage_changed()
	return added

func can_accept_logs() -> bool:
	return not _storage.input.is_full()

func set_stored_logs(amount: int) -> void:
	_storage.input.current = clampi(amount, 0, _storage.input.capacity)
	_storage.input.changed.emit(_storage.input.current, _storage.input.capacity)
	WarehouseRegistry.notify_storage_changed()
