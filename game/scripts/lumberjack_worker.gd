extends Node2D

enum State { IDLE, TO_TREE, CHOPPING, TO_CAMP }

const ARRIVE_DISTANCE := 8.0

@export var move_speed: float = 72.25

var _camp: Node2D
var _state: State = State.IDLE
var _target_tree: Node2D
var _cargo_amount: int = 0
var _idle_timer: float = 0.0
var _chop_timer: float = 0.0
var _move_direction := Vector2.ZERO
var _last_move_offset := Vector2.ZERO

@onready var _body: AnimatedSprite2D = $Body
@onready var _cargo: Sprite2D = $Cargo

func setup(camp: Node2D) -> void:
	_camp = camp

func _ready() -> void:
	add_to_group("lumberjack_worker")
	CharacterWalk.apply_shared(_body, 10.0)
	_cargo.visible = false

func _process(delta: float) -> void:
	_last_move_offset = Vector2.ZERO
	match _state:
		State.IDLE:
			_process_idle(delta)
		State.TO_TREE:
			_process_to_tree(delta)
		State.CHOPPING:
			_process_chopping(delta)
		State.TO_CAMP:
			_process_to_camp(delta)
	_update_animation()

func _update_animation() -> void:
	var is_walking := _last_move_offset.length_squared() > 0.001
	CharacterWalk.update_motion(_body, is_walking, _last_move_offset)

func _process_idle(delta: float) -> void:
	if _is_camp_valid() and position.distance_to(_camp.position) > 14.0:
		_move_toward(_camp.position, delta * 0.6)

	_idle_timer -= delta
	if _idle_timer > 0.0:
		return
	_idle_timer = 0.45
	_try_start_job()

func _process_to_tree(delta: float) -> void:
	if not _is_tree_valid():
		_return_idle()
		return

	_move_toward(_target_tree.position, delta)
	if position.distance_to(_target_tree.position) <= ARRIVE_DISTANCE:
		_state = State.CHOPPING
		_chop_timer = _camp.get_chop_duration() if _is_camp_valid() else 1.5

func _process_chopping(delta: float) -> void:
	_chop_timer -= delta
	if _chop_timer > 0.0:
		return

	if not _is_tree_valid():
		_return_idle()
		return

	var harvested: int = _target_tree.harvest(1)
	if harvested <= 0:
		_return_idle()
		return

	_cargo_amount = harvested
	_cargo.visible = true
	_target_tree = null
	_state = State.TO_CAMP
	_move_direction = Vector2.ZERO

func _process_to_camp(delta: float) -> void:
	if not _is_camp_valid():
		_return_idle()
		return

	_move_toward(_camp.position, delta)
	if position.distance_to(_camp.position) <= ARRIVE_DISTANCE:
		_deliver_log()

func _try_start_job() -> void:
	if _cargo_amount > 0:
		return
	if not _is_camp_valid():
		return
	if _camp.output_is_full():
		return

	_target_tree = _camp.find_nearest_tree()
	if _target_tree == null:
		return

	_state = State.TO_TREE
	_move_direction = Vector2.ZERO

func _deliver_log() -> void:
	if _cargo_amount <= 0:
		_return_idle()
		return

	if _is_camp_valid():
		var deposited: int = _camp.deposit_harvested_log(_cargo_amount)
		_cargo_amount -= deposited

	if _cargo_amount <= 0:
		_cargo.visible = false
	_return_idle()

func _return_idle() -> void:
	_target_tree = null
	_state = State.IDLE
	_idle_timer = 0.25
	_move_direction = Vector2.ZERO

func _move_toward(target_position: Vector2, delta: float) -> void:
	var movement := GridMovement.step_toward(position, target_position, move_speed, delta, _move_direction)
	_move_direction = movement.direction
	if movement.step == Vector2.ZERO:
		_move_direction = Vector2.ZERO
		_last_move_offset = Vector2.ZERO
		return
	position += movement.step
	_last_move_offset = movement.step

func _is_camp_valid() -> bool:
	return _camp != null and is_instance_valid(_camp) and _camp.has_method("find_nearest_tree")

func _is_tree_valid() -> bool:
	return _target_tree != null and is_instance_valid(_target_tree) and _target_tree.has_method("harvest")
