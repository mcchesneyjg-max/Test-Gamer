extends Node2D

## Depletable wood source for future lumber camps.
@export var harvest_remaining: int = 10
@export var chop_stand_distance: float = 20.0

@onready var _sprite: Sprite2D = $Sprite

func _ready() -> void:
	TreeRegistry.register_tree(self)

func _exit_tree() -> void:
	TreeRegistry.unregister_tree(self)

func get_chop_position(from_position: Vector2 = position) -> Vector2:
	var texture_size := Vector2.ZERO
	if _sprite.texture:
		texture_size = _sprite.texture.get_size()

	var trunk_base := position + _sprite.position + Vector2(texture_size.x * 0.5, texture_size.y)
	var stand_side := chop_stand_distance
	if from_position.x < position.x:
		stand_side = -chop_stand_distance
	return trunk_base + Vector2(stand_side, 0.0)

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
