extends Node2D

@export var chop_interval: float = 2.0
@export var chop_radius_tiles: int = 4

@onready var _storage = $StorageAreas
@onready var _tilemap: TileMap = get_parent() as TileMap

var _chop_timer: float = 0.0

func _ready() -> void:
	CampRegistry.register_camp(self)

func _exit_tree() -> void:
	CampRegistry.unregister_camp(self)

func _process(delta: float) -> void:
	if _storage.output_is_full():
		return

	_chop_timer += delta
	if _chop_timer < chop_interval:
		return
	_chop_timer = 0.0
	_try_chop_nearby_tree()

func _try_chop_nearby_tree() -> void:
	if _storage.output_is_full():
		return

	var tree := _find_nearest_tree()
	if tree == null:
		return

	var harvested: int = tree.harvest(1)
	if harvested <= 0:
		return

	_storage.output.try_add(harvested)

func _find_nearest_tree() -> Node2D:
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
