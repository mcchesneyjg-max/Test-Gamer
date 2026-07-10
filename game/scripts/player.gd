extends Node2D

const MAP_SIZE_TILES := Vector2i(250, 250)
const TILE_SIZE := 32

@export var move_speed: float = 140.0

var _move_direction := Vector2.ZERO

@onready var _body: AnimatedSprite2D = $Body

func _ready() -> void:
	add_to_group("player")
	var center_tile := MAP_SIZE_TILES / 2
	position = Vector2(center_tile) * TILE_SIZE + Vector2(TILE_SIZE, TILE_SIZE) * 0.5
	CharacterWalk.apply_shared(_body, 10.0)

func _process(delta: float) -> void:
	_move_direction = _get_input_direction()
	if _move_direction != Vector2.ZERO:
		position += _move_direction * move_speed * delta
		CharacterWalk.update_motion(_body, true, _move_direction)
	else:
		CharacterWalk.update_motion(_body, false, Vector2.ZERO)

func _get_input_direction() -> Vector2:
	var raw := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	return GridMovement.snap_eight_directions(raw)
