extends Node

signal station_count_changed(count: int)
signal hauler_workforce_changed(total_haulers: int)

var _stations: Array[Node2D] = []

func register_station(station: Node2D) -> void:
	if station in _stations:
		return
	_stations.append(station)
	_emit_counts()

func unregister_station(station: Node2D) -> void:
	if station not in _stations:
		return
	_stations.erase(station)
	_emit_counts()

func get_station_count() -> int:
	return _stations.size()

func get_active_stations() -> Array[Node2D]:
	return _stations.duplicate()

func get_total_haulers() -> int:
	var total := 0
	for station in _stations:
		if station.has_method("get_hauler_count"):
			total += station.get_hauler_count()
	return total

func _emit_counts() -> void:
	station_count_changed.emit(_stations.size())
	hauler_workforce_changed.emit(get_total_haulers())

func notify_log_storage_available() -> void:
	for station in _stations:
		if station.has_method("_reposition_workers_to_storage"):
			station._reposition_workers_to_storage()
