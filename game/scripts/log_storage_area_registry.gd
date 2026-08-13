extends Node

signal area_count_changed(count: int)
signal storage_changed()

var _areas: Array[Node2D] = []

func register_area(area: Node2D) -> void:
	if area in _areas:
		return
	_areas.append(area)
	area_count_changed.emit(_areas.size())
	storage_changed.emit()

func unregister_area(area: Node2D) -> void:
	if area not in _areas:
		return
	_areas.erase(area)
	area_count_changed.emit(_areas.size())
	storage_changed.emit()

func notify_storage_changed() -> void:
	storage_changed.emit()

func get_area_count() -> int:
	return _areas.size()

func get_active_areas() -> Array[Node2D]:
	return _areas.duplicate()

func get_first_area() -> Node2D:
	if _areas.is_empty():
		return null
	return _areas[0]

func get_nearest_area(from_position: Vector2) -> Node2D:
	var best: Node2D = null
	var best_distance := INF
	for area in _areas:
		if not is_instance_valid(area):
			continue
		var distance := from_position.distance_to(area.global_position)
		if distance < best_distance:
			best_distance = distance
			best = area
	return best
