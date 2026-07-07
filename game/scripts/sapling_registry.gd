extends Node

signal sapling_count_changed(count: int)

var _saplings: Array[Node2D] = []

func register_sapling(sapling: Node2D) -> void:
	if sapling in _saplings:
		return
	_saplings.append(sapling)
	sapling_count_changed.emit(_saplings.size())

func unregister_sapling(sapling: Node2D) -> void:
	if sapling not in _saplings:
		return
	_saplings.erase(sapling)
	sapling_count_changed.emit(_saplings.size())

func get_sapling_count() -> int:
	return _saplings.size()

func get_active_saplings() -> Array[Node2D]:
	return _saplings.duplicate()
