extends Node

signal wood_logs_changed(new_total: int)

## Global wood total — sum of all warehouse building input storage.
var wood_logs: int = 0

func _ready() -> void:
	WarehouseRegistry.storage_changed.connect(_refresh_total)

func _refresh_total() -> void:
	var total := 0
	for warehouse in WarehouseRegistry.get_active_warehouses():
		if warehouse.has_method("get_stored_logs"):
			total += warehouse.get_stored_logs()

	if total == wood_logs:
		return

	wood_logs = total
	wood_logs_changed.emit(wood_logs)

func add_wood_logs(amount: int = 1) -> void:
	## Debug helper: deposit into the first warehouse input storage.
	var warehouse := WarehouseRegistry.get_first_warehouse()
	if warehouse == null or not warehouse.has_method("deposit_logs"):
		return
	warehouse.deposit_logs(amount)

func set_wood_logs(amount: int) -> void:
	var warehouse := WarehouseRegistry.get_first_warehouse()
	if warehouse == null or not warehouse.has_method("set_stored_logs"):
		return
	warehouse.set_stored_logs(amount)
