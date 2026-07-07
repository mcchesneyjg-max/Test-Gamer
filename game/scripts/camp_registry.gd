extends Node

signal camp_count_changed(count: int)

var _camps: Array[Node2D] = []

func register_camp(camp: Node2D) -> void:
	if camp in _camps:
		return
	_camps.append(camp)
	camp_count_changed.emit(_camps.size())

func unregister_camp(camp: Node2D) -> void:
	if camp not in _camps:
		return
	_camps.erase(camp)
	camp_count_changed.emit(_camps.size())

func get_camp_count() -> int:
	return _camps.size()

func get_active_camps() -> Array[Node2D]:
	return _camps.duplicate()
