extends Node2D

@export_range(1, 8, 1) var hauler_count: int = 2

const HAULER_WORKER_SCENE := preload("res://scenes/hauler_worker.tscn")
const HAULER_COLORS := [
	Color(0.9, 0.55, 0.25, 1),
	Color(0.35, 0.65, 0.95, 1),
	Color(0.55, 0.85, 0.45, 1),
	Color(0.85, 0.45, 0.75, 1),
]

@onready var _hauler_label: Label = $HaulerLabel
@onready var _idle_haulers: Node2D = $IdleHaulers

var _spawned_workers: Array[Node2D] = []

func _ready() -> void:
	HaulerStationRegistry.register_station(self)
	_update_hauler_label()
	call_deferred("_spawn_workers")

func _exit_tree() -> void:
	for worker in _spawned_workers:
		if is_instance_valid(worker):
			worker.queue_free()
	_spawned_workers.clear()
	HaulerStationRegistry.unregister_station(self)

func get_hauler_count() -> int:
	return hauler_count

func _spawn_workers() -> void:
	var tilemap := get_parent() as TileMap
	if tilemap == null:
		_refresh_idle_hauler_markers()
		return

	if _idle_haulers:
		_idle_haulers.visible = false

	for i in hauler_count:
		var worker := HAULER_WORKER_SCENE.instantiate()
		worker.setup(self, HAULER_COLORS[i % HAULER_COLORS.size()])
		worker.position = position + Vector2(6 + i * 10, 38)
		tilemap.add_child(worker)
		_spawned_workers.append(worker)

	_update_hauler_label()

func _update_hauler_label() -> void:
	_hauler_label.text = "Haulers: %d" % hauler_count

func _refresh_idle_hauler_markers() -> void:
	if _idle_haulers == null:
		return

	var slots := _idle_haulers.get_child_count()
	for i in slots:
		var marker := _idle_haulers.get_child(i) as ColorRect
		if marker:
			marker.visible = i < hauler_count
