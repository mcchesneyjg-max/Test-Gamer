extends Node2D

enum State { IDLE, TO_SITE, PLANTING, TO_HOME }

const ARRIVE_DISTANCE := 8.0
const PLANT_DURATION := 0.9
const WALK_SHEET := preload("res://assets/sprites/hauler_worker_walk.png")
const FRAME_SIZE := 32
const WALK_FRAMES := 4

@export var move_speed: float = 85.0

var _lodge: Node2D
var _state: State = State.IDLE
var _plant_site: Vector2 = Vector2.ZERO
var _idle_timer: float = 0.0
var _action_timer: float = 0.0

@onready var _body: AnimatedSprite2D = $Body

func setup(lodge: Node2D) -> void:
	_lodge = lodge

func _ready() -> void:
	add_to_group("forester_worker")
	_setup_walk_animation()
	_body.modulate = Color(0.5, 0.82, 0.45, 1)

func _setup_walk_animation() -> void:
	var frames := SpriteFrames.new()
	frames.add_animation(&"walk")
	frames.set_animation_loop(&"walk", true)
	frames.set_animation_speed(&"walk", 6.0)
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
	_update_animation()
	match _state:
		State.IDLE:
			_process_idle(delta)
		State.TO_SITE:
			_process_to_site(delta)
		State.PLANTING:
			_process_planting(delta)
		State.TO_HOME:
			_process_to_home(delta)

func _update_animation() -> void:
	if _state == State.PLANTING:
		if _body.animation != &"idle":
			_body.play(&"idle")
	elif _state == State.IDLE:
		if _body.animation != &"idle":
			_body.play(&"idle")
	else:
		if _body.animation != &"walk":
			_body.play(&"walk")

func _process_idle(delta: float) -> void:
	if _is_lodge_valid() and position.distance_to(_lodge.position) > 14.0:
		_move_toward(_lodge.position, delta * 0.6)

	_idle_timer -= delta
	if _idle_timer > 0.0:
		return
	_idle_timer = 0.45
	_try_start_job()

func _process_to_site(delta: float) -> void:
	_move_toward(_plant_site, delta)
	if position.distance_to(_plant_site) <= ARRIVE_DISTANCE:
		_state = State.PLANTING
		_action_timer = PLANT_DURATION

func _process_planting(delta: float) -> void:
	_action_timer -= delta
	if _action_timer > 0.0:
		return

	if _is_lodge_valid():
		_lodge.plant_sapling_at_world_pos(_plant_site)
	_state = State.TO_HOME

func _process_to_home(delta: float) -> void:
	if not _is_lodge_valid():
		_return_idle()
		return

	_move_toward(_lodge.position, delta)
	if position.distance_to(_lodge.position) <= ARRIVE_DISTANCE:
		_return_idle()

func _try_start_job() -> void:
	if not _is_lodge_valid():
		return
	if not _lodge.can_plant_sapling():
		return

	var site: Vector2 = _lodge.find_plant_site()
	if site == Vector2.ZERO:
		return

	_plant_site = site
	_state = State.TO_SITE

func _return_idle() -> void:
	_plant_site = Vector2.ZERO
	_state = State.IDLE
	_idle_timer = 0.25

func _move_toward(target_position: Vector2, delta: float) -> void:
	var offset := target_position - position
	if offset.length_squared() <= 0.001:
		return
	position += offset.normalized() * move_speed * delta

func _is_lodge_valid() -> bool:
	return _lodge != null and is_instance_valid(_lodge) and _lodge.has_method("can_plant_sapling")
