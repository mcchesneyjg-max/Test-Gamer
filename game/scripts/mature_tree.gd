extends Node2D

## Depletable wood source for future lumber camps.
@export var harvest_remaining: int = 10

func _ready() -> void:
	TreeRegistry.register_tree(self)

func _exit_tree() -> void:
	TreeRegistry.unregister_tree(self)

func is_depleted() -> bool:
	return harvest_remaining <= 0

func harvest(amount: int = 1) -> int:
	if harvest_remaining <= 0:
		return 0
	var taken := mini(amount, harvest_remaining)
	harvest_remaining -= taken
	if harvest_remaining <= 0:
		queue_free()
	return taken
