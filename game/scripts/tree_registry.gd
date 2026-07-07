extends Node

signal tree_count_changed(count: int)

var _trees: Array[Node2D] = []

func register_tree(tree: Node2D) -> void:
	if tree in _trees:
		return
	_trees.append(tree)
	tree_count_changed.emit(_trees.size())

func unregister_tree(tree: Node2D) -> void:
	if tree not in _trees:
		return
	_trees.erase(tree)
	tree_count_changed.emit(_trees.size())

func get_tree_count() -> int:
	return _trees.size()

func get_active_trees() -> Array[Node2D]:
	return _trees.duplicate()
