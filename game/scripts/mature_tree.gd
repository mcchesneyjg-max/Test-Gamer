extends Node2D

## Depletable wood source for future lumber camps.
@export var harvest_remaining: int = 10
@export var chop_stand_distance: float = 20.0
@export var chop_stand_north_offset: float = -32.0

var _chopper: Node = null

@onready var _sprite: Sprite2D = $Sprite
@onready var _foreground_sprite: Sprite2D = $ForegroundSprite

func _ready() -> void:
	TreeRegistry.register_tree(self)
	_setup_chop_foreground_sprite()

func _exit_tree() -> void:
	_chopper = null
	TreeRegistry.unregister_tree(self)

func is_available_to(chopper: Node) -> bool:
	_clear_stale_chopper()
	if _chopper == null:
		return true
	return _chopper == chopper

func try_reserve(chopper: Node) -> bool:
	_clear_stale_chopper()
	if _chopper != null and _chopper != chopper:
		return false
	_chopper = chopper
	_update_chop_foreground()
	return true

func release_reservation(chopper: Node) -> void:
	if _chopper == chopper:
		_chopper = null
		_update_chop_foreground()

func get_chop_position() -> Vector2:
	var texture_size := Vector2.ZERO
	if _sprite.texture:
		texture_size = _sprite.texture.get_size()

	var trunk_base := position + _sprite.position + Vector2(texture_size.x * 0.5, texture_size.y)
	return trunk_base + Vector2(chop_stand_distance, chop_stand_north_offset)

func is_depleted() -> bool:
	return harvest_remaining <= 0

func harvest(amount: int = 1, chopper: Node = null) -> int:
	if chopper != null and _chopper != chopper:
		return 0
	if harvest_remaining <= 0:
		return 0
	var taken := mini(amount, harvest_remaining)
	harvest_remaining -= taken
	if harvest_remaining <= 0:
		queue_free()
	return taken

func _clear_stale_chopper() -> void:
	if _chopper != null and not is_instance_valid(_chopper):
		_chopper = null
		_update_chop_foreground()

func _setup_chop_foreground_sprite() -> void:
	_foreground_sprite.texture = _sprite.texture
	_foreground_sprite.position = _sprite.position
	_foreground_sprite.centered = _sprite.centered
	_foreground_sprite.texture_filter = _sprite.texture_filter
	_foreground_sprite.z_as_relative = false
	_foreground_sprite.z_index = 4
	_foreground_sprite.visible = false

func _update_chop_foreground() -> void:
	_clear_stale_chopper()
	_foreground_sprite.visible = _chopper != null
