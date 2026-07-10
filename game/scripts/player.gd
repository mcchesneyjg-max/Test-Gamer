extends Node2D

const WALK_SHEET := preload("res://assets/sprites/player_walk.png")
const MAP_SIZE_TILES := Vector2i(250, 250)
const TILE_SIZE := 32

@export var move_speed: float = 140.0

var _move_direction := Vector2.ZERO

@onready var _body: AnimatedSprite2D = $Body

func _ready() -> void:
	add_to_group("player")
	position = Vector2(MAP_SIZE_TILES) * TILE_SIZE * 0.5
	CharacterWalk.apply(_body, WALK_SHEET, 8.0)

func _process(delta: float) -> void:
	_move_direction = _get_input_direction()
	if _move_direction != Vector2.ZERO:
		position += _move_direction * move_speed * delta
		CharacterWalk.update_motion(_body, true, _move_direction)
	else:
		CharacterWalk.update_motion(_body, false, Vector2.ZERO)

func _get_input_direction() -> Vector2:
	var raw := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if raw.length_squared() < 0.01:
		return Vector2.ZERO
	var angle := snappedf(raw.angle(), PI / 4.0)
	return Vector2.from_angle(angle)
