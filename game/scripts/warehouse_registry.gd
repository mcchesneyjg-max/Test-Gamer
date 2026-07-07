extends Node

signal warehouse_count_changed(count: int)
signal storage_changed()

var _warehouses: Array[Node2D] = []

func register_warehouse(warehouse: Node2D) -> void:
	if warehouse in _warehouses:
		return
	_warehouses.append(warehouse)
	warehouse_count_changed.emit(_warehouses.size())
	storage_changed.emit()

func unregister_warehouse(warehouse: Node2D) -> void:
	if warehouse not in _warehouses:
		return
	_warehouses.erase(warehouse)
	warehouse_count_changed.emit(_warehouses.size())
	storage_changed.emit()

func notify_storage_changed() -> void:
	storage_changed.emit()

func get_warehouse_count() -> int:
	return _warehouses.size()

func get_active_warehouses() -> Array[Node2D]:
	return _warehouses.duplicate()

func get_first_warehouse() -> Node2D:
	if _warehouses.is_empty():
		return null
	return _warehouses[0]
