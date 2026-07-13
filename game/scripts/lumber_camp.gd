extends Node2D
class_name LumberCamp

const LUMBERJACK_WORKER_SCENE := preload("res://scenes/lumberjack_worker.tscn")
const MAX_WORKERS := 6
const WORKER_OFFSETS: Array[Vector2] = [
	Vector2(6, 38),
	Vector2(16, 38),
	Vector2(26, 38),
	Vector2(-4, 42),
	Vector2(10, 42),
	Vector2(22, 42),
]

@export var chop_interval: float = 8.0
@export var chop_radius_tiles: int = 6

@onready var _storage = $StorageAreas
@onready var _tilemap: TileMap = get_parent() as TileMap

var _workers: Array[Node2D] = []
var _assigned_count: int = 0

func _ready() -> void:
	CampRegistry.register_camp(self)
	YSortDepth.apply_to_entity(self)
	call_deferred("_assign_initial_worker")

func _assign_initial_worker() -> void:
	if _assigned_count == 0:
		add_worker()

func _exit_tree() -> void:
	_release_all_workers_to_pool()
	_despawn_all_workers()
	CampRegistry.unregister_camp(self)

func get_max_workers() -> int:
	return MAX_WORKERS

func get_assigned_worker_count() -> int:
	return _assigned_count

func can_add_worker() -> bool:
	return _assigned_count < MAX_WORKERS and WorkerPool.get_available() > 0

func can_remove_worker() -> bool:
	return _assigned_count > 0

func add_worker() -> bool:
	if not can_add_worker():
		return false
	if not WorkerPool.try_assign(1):
		return false
	_assigned_count += 1
	_spawn_worker_at(_assigned_count - 1)
	return true

func remove_worker() -> bool:
	if not can_remove_worker():
		return false
	WorkerPool.release(1)
	_assigned_count -= 1
	if _workers.size() > _assigned_count:
		var worker: Node2D = _workers.pop_back()
		if is_instance_valid(worker):
			worker.queue_free()
	return true

func occupies_tile(tile: Vector2i) -> bool:
	if _tilemap == null:
		return false
	return _tilemap.local_to_map(position) == tile

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

func find_nearest_tree(for_worker: Node = null) -> Node2D:
	var camp_tile := _tilemap.local_to_map(position)
	var nearest: Node2D = null
	var nearest_distance := chop_radius_tiles + 1

	for tree in TreeRegistry.get_active_trees():
		if for_worker != null and tree.has_method("is_available_to"):
			if not tree.is_available_to(for_worker):
				continue
		var tree_tile := _tilemap.local_to_map(tree.position)
		var distance := camp_tile.distance_to(tree_tile)
		if distance > chop_radius_tiles:
			continue
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = tree

	if nearest != null and for_worker != null and nearest.has_method("try_reserve"):
		if not nearest.try_reserve(for_worker):
			return null

	return nearest

func _release_all_workers_to_pool() -> void:
	if _assigned_count > 0:
		WorkerPool.release(_assigned_count)
		_assigned_count = 0

func _despawn_all_workers() -> void:
	for worker in _workers:
		if is_instance_valid(worker):
			worker.queue_free()
	_workers.clear()

func _spawn_worker_at(index: int) -> void:
	if _tilemap == null:
		return

	var worker := LUMBERJACK_WORKER_SCENE.instantiate()
	worker.setup(self)
	var offset: Vector2 = WORKER_OFFSETS[index % WORKER_OFFSETS.size()]
	worker.position = position + offset
	_tilemap.add_child(worker)
	_workers.append(worker)
