extends Node

signal wood_logs_changed(new_total: int)

## Global warehouse stockpile. UI and buildings read/write totals here.
var wood_logs: int = 0

func add_wood_logs(amount: int = 1) -> void:
	wood_logs += amount
	wood_logs_changed.emit(wood_logs)

func set_wood_logs(amount: int) -> void:
	wood_logs = max(amount, 0)
	wood_logs_changed.emit(wood_logs)
