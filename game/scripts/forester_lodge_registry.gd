extends Node

signal lodge_count_changed(count: int)

var _lodges: Array[Node2D] = []

func register_lodge(lodge: Node2D) -> void:
	if lodge in _lodges:
		return
	_lodges.append(lodge)
	lodge_count_changed.emit(_lodges.size())

func unregister_lodge(lodge: Node2D) -> void:
	if lodge not in _lodges:
		return
	_lodges.erase(lodge)
	lodge_count_changed.emit(_lodges.size())

func get_lodge_count() -> int:
	return _lodges.size()

func get_active_lodges() -> Array[Node2D]:
	return _lodges.duplicate()
