extends Node2D

const WALK_SHEET := preload("res://assets/sprites/hauler_worker_walk.png")
const FRAME_SIZE := 32
const WALK_FRAMES := 4
const MAP_SIZE_TILES := Vector2i(250, 250)
const TILE_SIZE := 32

@export var move_speed: float = 140.0

var _move_direction := Vector2.ZERO

@onready var _body: AnimatedSprite2D = $Body

func _ready() -> void:
	add_to_group("player")
	position = Vector2(MAP_SIZE_TILES) * TILE_SIZE * 0.5
	_setup_walk_animation()
	_body.modulate = Color(0.45, 0.68, 0.95, 1)

func _setup_walk_animation() -> void:
	var frames := SpriteFrames.new()
	frames.add_animation(&"walk")
	frames.set_animation_loop(&"walk", true)
	frames.set_animation_speed(&"walk", 8.0)
	frames.add_animation(&"idle")
	frames.set_animation_loop(&"idle", true)
	frames.set_animation_speed(&"idle", 1.0)

	for i in WALK_FRAMES:
		var atlas := AtlasTexture.new()
		atlas.atlas = WALK_SHEET
		atlas.region = Rect2(i * FRAME_SIZE, 0, FRAME_SIZE, FRAME_SIZE)
		frames.add_frame(&"walk", atlas)

	var idle_atlas := AtlasTexture.new()
	idle_atlas.atlas = WALK_SHEET
	idle_atlas.region = Rect2(0, 0, FRAME_SIZE, FRAME_SIZE)
	frames.add_frame(&"idle", idle_atlas)

	_body.sprite_frames = frames
	_body.play(&"idle")

func _process(delta: float) -> void:
	_move_direction = _get_input_direction()
	if _move_direction != Vector2.ZERO:
		position += _move_direction * move_speed * delta
		_update_facing()
		if _body.animation != &"walk":
			_body.play(&"walk")
	else:
		if _body.animation != &"idle":
			_body.play(&"idle")

func _get_input_direction() -> Vector2:
	var raw := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if raw.length_squared() < 0.01:
		return Vector2.ZERO
	var angle := snappedf(raw.angle(), PI / 4.0)
	return Vector2.from_angle(angle)

func _update_facing() -> void:
	if _move_direction.x < -0.01:
		_body.flip_h = true
	elif _move_direction.x > 0.01:
		_body.flip_h = false
