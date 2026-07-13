extends Node2D

const MATURE_TREE_SCENE := preload("res://scenes/mature_tree.tscn")

@export var grow_time: float = 8.0

@onready var _sprite: Sprite2D = $Sprite

var _grow_timer: float = 0.0
var _has_matured: bool = false

func _ready() -> void:
	SaplingRegistry.register_sapling(self)
	call_deferred("_apply_sort_depth")

func _apply_sort_depth() -> void:
	YSortDepth.apply_to_entity(self)

func _exit_tree() -> void:
	SaplingRegistry.unregister_sapling(self)

func _process(delta: float) -> void:
	if _has_matured:
		return

	_grow_timer += delta
	var progress := clampf(_grow_timer / grow_time, 0.0, 1.0)
	_sprite.scale = Vector2.ONE * lerpf(0.65, 1.0, progress)

	if _grow_timer >= grow_time:
		_mature_into_tree()

func _mature_into_tree() -> void:
	if _has_matured:
		return
	_has_matured = true
	set_process(false)

	var parent_node := get_parent()
	var tree_position := position
	if parent_node == null:
		queue_free()
		return

	var tree := MATURE_TREE_SCENE.instantiate()
	tree.position = tree_position
	parent_node.add_child(tree)
	queue_free()
