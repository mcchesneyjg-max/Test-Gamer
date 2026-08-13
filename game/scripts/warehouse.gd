extends Node

signal wood_logs_changed(new_total: int)

## Global wood total — sum of all log storage area deliveries.
var wood_logs: int = 0

func _ready() -> void:
	LogStorageAreaRegistry.storage_changed.connect(_refresh_total)

func _refresh_total() -> void:
	var total := 0
	for area in LogStorageAreaRegistry.get_active_areas():
		if area.has_method("get_stored_logs"):
			total += area.get_stored_logs()

	if total == wood_logs:
		return

	wood_logs = total
	wood_logs_changed.emit(wood_logs)

func add_wood_logs(amount: int = 1) -> void:
	## Debug helper: deposit into the first log storage area.
	var area := LogStorageAreaRegistry.get_first_area()
	if area != null and area.has_method("deposit_logs"):
		area.deposit_logs(amount)

func set_wood_logs(amount: int) -> void:
	var area := LogStorageAreaRegistry.get_first_area()
	if area != null and area.has_method("set_stored_logs"):
		area.set_stored_logs(amount)
