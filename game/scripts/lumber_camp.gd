extends Node2D

const LUMBERJACK_WORKER_SCENE := preload("res://scenes/lumberjack_worker.tscn")

@export var chop_interval: float = 2.0
@export var chop_radius_tiles: int = 6

@onready var _storage = $StorageAreas
@onready var _tilemap: TileMap = get_parent() as TileMap

var _worker: Node2D

func _ready() -> void:
	CampRegistry.register_camp(self)
	call_deferred("_spawn_worker")

func _exit_tree() -> void:
	if is_instance_valid(_worker):
		_worker.queue_free()
	CampRegistry.unregister_camp(self)

func get_chop_duration() -> float:
	return chop_interval

func output_is_full() -> bool:
	return _storage.output_is_full()

func deposit_harvested_log(amount: int = 1) -> int:
	return _storage.output.try_add(amount)

func has_output_ready() -> bool:
	return get_output_log_count() > 0

func get_output_log_count() -> int:
	return _storage.output.current

func take_from_output(amount: int = 1) -> int:
	return _storage.output.try_remove(amount)

func get_log_pickup_position() -> Vector2:
	var pile := _storage.get_node_or_null("OutputPile") as Node2D
	if pile and _tilemap:
		return _tilemap.to_local(pile.global_position)
	if pile:
		return position + pile.position
	return position

func deposit_to_output(amount: int) -> int:
	return _storage.output.try_add(amount)

func find_nearest_tree() -> Node2D:
	var camp_tile := _tilemap.local_to_map(position)
	var nearest: Node2D = null
	var nearest_distance := chop_radius_tiles + 1

	for tree in TreeRegistry.get_active_trees():
		var tree_tile := _tilemap.local_to_map(tree.position)
		var distance := camp_tile.distance_to(tree_tile)
		if distance > chop_radius_tiles:
			continue
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = tree

	return nearest

func _spawn_worker() -> void:
	if _tilemap == null:
		return

	_worker = LUMBERJACK_WORKER_SCENE.instantiate()
	_worker.setup(self)
	_worker.position = position + Vector2(10, 38)
	_tilemap.add_child(_worker)
