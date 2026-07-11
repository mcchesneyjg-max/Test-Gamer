extends Node2D

enum State { IDLE, TO_TREE, CHOPPING, TO_CAMP }

const ARRIVE_DISTANCE := 8.0

@export var move_speed: float = 49.13

var _camp: Node2D
var _state: State = State.IDLE
var _target_tree: Node2D
var _cargo_amount: int = 0
var _idle_timer: float = 0.0
var _chop_timer: float = 0.0
var _chop_position := Vector2.ZERO
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
	_update_animation(delta)

func _update_animation(delta: float) -> void:
	if _state == State.CHOPPING:
		CharacterWalk.update_chopping(_body, delta)
		return

	var is_walking := _last_move_offset.length_squared() > 0.001
	CharacterWalk.update_motion(_body, is_walking, _last_move_offset, delta)

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

	var chop_position := _get_chop_position()
	_move_toward(chop_position, delta)
	if position.distance_to(chop_position) <= ARRIVE_DISTANCE:
		position = chop_position
		_chop_position = chop_position
		_state = State.CHOPPING
		_chop_timer = _camp.get_chop_duration() if _is_camp_valid() else 1.5
		_move_direction = Vector2.ZERO

func _process_chopping(delta: float) -> void:
	position = _chop_position
	_chop_timer -= delta
	if _chop_timer > 0.0:
		return

	if not _is_tree_valid():
		_return_idle()
		return

	var harvested: int = _target_tree.harvest(1, self)
	if harvested <= 0:
		_return_idle()
		return

	_cargo_amount = harvested
	_cargo.visible = true
	_release_tree_reservation()
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

	_target_tree = _camp.find_nearest_tree(self)
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
	_release_tree_reservation()
	_target_tree = null
	_state = State.IDLE
	_idle_timer = 0.25
	_move_direction = Vector2.ZERO
	_chop_position = Vector2.ZERO

func _release_tree_reservation() -> void:
	if _target_tree != null and is_instance_valid(_target_tree) and _target_tree.has_method("release_reservation"):
		_target_tree.release_reservation(self)

func _get_chop_position() -> Vector2:
	if _is_tree_valid() and _target_tree.has_method("get_chop_position"):
		return _target_tree.get_chop_position(position)
	if _is_tree_valid():
		return _target_tree.position
	return Vector2.ZERO

func _move_toward(target_position: Vector2, delta: float) -> void:
	var movement := GridMovement.step_toward(position, target_position, move_speed, delta, _move_direction)
	_move_direction = movement.direction
	if movement.step == Vector2.ZERO:
		_move_direction = Vector2.ZERO
		_last_move_offset = Vector2.ZERO
		return
	position += movement.step
	_last_move_offset = movement.direction

func _exit_tree() -> void:
	_release_tree_reservation()

func _is_camp_valid() -> bool:
	return _camp != null and is_instance_valid(_camp) and _camp.has_method("find_nearest_tree")

func _is_tree_valid() -> bool:
	return _target_tree != null and is_instance_valid(_target_tree) and _target_tree.has_method("harvest")
