extends Node2D

signal output_logs_changed(count: int)

@export var chop_interval: float = 2.0
@export var chop_radius_tiles: int = 4
@export var output_capacity: int = 20

var output_logs: int = 0

@onready var _output_label: Label = $OutputLabel
@onready var _tilemap: TileMap = get_parent() as TileMap

var _chop_timer: float = 0.0

func _ready() -> void:
	CampRegistry.register_camp(self)
	_update_output_label()

func _exit_tree() -> void:
	CampRegistry.unregister_camp(self)

func _process(delta: float) -> void:
	if output_logs >= output_capacity:
		return

	_chop_timer += delta
	if _chop_timer < chop_interval:
		return
	_chop_timer = 0.0
	_try_chop_nearby_tree()

func _try_chop_nearby_tree() -> void:
	var tree := _find_nearest_tree()
	if tree == null:
		return

	var harvested: int = tree.harvest(1)
	if harvested <= 0:
		return

	output_logs = mini(output_logs + harvested, output_capacity)
	output_logs_changed.emit(output_logs)
	_update_output_label()

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

func _update_output_label() -> void:
	_output_label.text = "Out: %d/%d" % [output_logs, output_capacity]
