extends Node

signal pool_changed(available: int, assigned: int, total: int)

@export var pool_size: int = 12

var _assigned: int = 0

func _ready() -> void:
	pool_changed.emit(get_available(), _assigned, pool_size)

func get_available() -> int:
	return pool_size - _assigned

func get_assigned() -> int:
	return _assigned

func get_total() -> int:
	return pool_size

func try_assign(amount: int = 1) -> bool:
	if amount <= 0:
		return false
	if _assigned + amount > pool_size:
		return false
	_assigned += amount
	pool_changed.emit(get_available(), _assigned, pool_size)
	return true

func release(amount: int = 1) -> void:
	if amount <= 0:
		return
	_assigned = maxi(0, _assigned - amount)
	pool_changed.emit(get_available(), _assigned, pool_size)
