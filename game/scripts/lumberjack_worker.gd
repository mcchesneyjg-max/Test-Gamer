extends Node2D

enum State { IDLE, TO_TREE, CHOPPING, TO_CAMP }
enum FallWaitPhase { WALK_TO_LOG, CUT_LOG }

const ARRIVE_DISTANCE := 8.0
const WEST := Vector2(-1.0, 0.0)

@export var move_speed: float = 49.13
@export var standing_chop_east_offset: float = 6.0
@export var fallen_log_extra_west: float = 14.0
@export var fallen_log_second_pickup_extra_west: float = 8.0
@export var fall_animation_extra_west: float = 6.0
@export var fine_west_offset: float = 1.0

var _camp: Node2D
var _state: State = State.IDLE
var _target_tree: Node2D
var _cargo_amount: int = 0
var _idle_timer: float = 0.0
var _chop_timer: float = 0.0
var _chop_position := Vector2.ZERO
var _fallen_log_position := Vector2.ZERO
var _move_direction := Vector2.ZERO
var _last_move_offset := Vector2.ZERO
var _waiting_for_tree_fall: bool = false
var _fall_wait_phase: FallWaitPhase = FallWaitPhase.WALK_TO_LOG
var _target_is_log_pile: bool = false
var _awaiting_log_pickup_animation: bool = false
var _awaiting_bend_pickup: bool = false

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
	if _awaiting_bend_pickup:
		CharacterWalk.update_bending_down_pickup(_body, delta)
		if CharacterWalk.is_bending_down_pickup_finished(_body):
			_awaiting_bend_pickup = false
			_execute_log_pickup_from_pile()
		return

	if _state == State.CHOPPING and _waiting_for_tree_fall:
		match _fall_wait_phase:
			FallWaitPhase.WALK_TO_LOG:
				var walk_offset := _last_move_offset
				if walk_offset.length_squared() <= 0.001:
					walk_offset = WEST
				CharacterWalk.update_motion(_body, true, walk_offset, delta)
			FallWaitPhase.CUT_LOG:
				CharacterWalk.update_log_cutting(_body, delta)
		return

	if _state == State.CHOPPING:
		CharacterWalk.update_chopping(_body, delta)
		if _is_tree_valid() and CharacterWalk.poll_axe_strike_trigger(_body):
			_target_tree.begin_axe_strike()
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

	_target_is_log_pile = _tree_is_log_pile()
	var target_position := _get_tree_interaction_position()
	_move_toward(target_position, delta)
	if position.distance_to(target_position) > ARRIVE_DISTANCE:
		return

	position = target_position
	if _target_is_log_pile:
		_pickup_log_from_pile()
		return

	_chop_position = target_position
	CharacterWalk.reset_chopping(_body)
	_set_tree_chop_overlay(true)
	_state = State.CHOPPING
	_chop_timer = _camp.get_chop_duration() if _is_camp_valid() else 1.5
	_move_direction = Vector2.ZERO

func _process_chopping(delta: float) -> void:
	if _waiting_for_tree_fall:
		_process_fall_wait(delta)
		return

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

	if _target_tree.has_method("is_falling") and _target_tree.is_falling():
		_begin_fall_wait()
		_process_fall_wait(delta)
		return

	_chop_timer = _camp.get_chop_duration() if _is_camp_valid() else 1.5

func _process_fall_wait(delta: float) -> void:
	if not _is_tree_valid():
		_abort_fall_wait()
		return

	match _fall_wait_phase:
		FallWaitPhase.WALK_TO_LOG:
			if _is_at_fallen_log_position():
				position = _fallen_log_position
				_move_direction = Vector2.ZERO
				_begin_fallen_log_cutting()
				return
			_move_toward(_fallen_log_position, delta)
		FallWaitPhase.CUT_LOG:
			position = _fallen_log_position
			if _tree_is_log_pile():
				_pickup_log_from_pile()

func _begin_fall_wait() -> void:
	_set_tree_chop_overlay(false)
	_end_tree_axe_strike()
	CharacterWalk.reset_chopping(_body)
	_waiting_for_tree_fall = true
	_fallen_log_position = _get_fallen_log_walk_target() + Vector2(
		-(fall_animation_extra_west + fine_west_offset),
		0.0
	)
	_fall_wait_phase = FallWaitPhase.WALK_TO_LOG
	_move_direction = WEST
	_last_move_offset = WEST
	print(
		"LumberjackWorker: walking west to fallen log at %s"
		% _fallen_log_position
	)
	_connect_log_pickup_animation_signal()

func _begin_fallen_log_cutting() -> void:
	if _fall_wait_phase == FallWaitPhase.CUT_LOG:
		return
	CharacterWalk.reset_log_cutting(_body)
	_fall_wait_phase = FallWaitPhase.CUT_LOG
	print("LumberjackWorker: started log cutting animation at fallen tree")

func _connect_log_pickup_animation_signal() -> void:
	if not _is_tree_valid():
		return
	if not _target_tree.has_signal("log_pickup_animation_finished"):
		return
	if _target_tree.log_pickup_animation_finished.is_connected(_on_log_pickup_animation_finished):
		return
	_target_tree.log_pickup_animation_finished.connect(_on_log_pickup_animation_finished)

func _on_log_pickup_animation_finished() -> void:
	_awaiting_log_pickup_animation = false
	_complete_log_pickup()

func _pickup_log_from_pile() -> void:
	if _awaiting_bend_pickup:
		return
	if CharacterWalk.begin_bending_down_pickup(_body):
		_awaiting_bend_pickup = true
		return
	_execute_log_pickup_from_pile()

func _execute_log_pickup_from_pile() -> void:
	if not _is_tree_valid():
		_return_idle()
		return
	if _awaiting_log_pickup_animation:
		return
	if _target_tree.has_method("is_log_pickup_animating") and _target_tree.is_log_pickup_animating():
		_awaiting_log_pickup_animation = true
		return

	_connect_log_pickup_animation_signal()
	var pickup_started := false
	if _target_tree.has_method("try_begin_log_pickup"):
		pickup_started = _target_tree.try_begin_log_pickup(self)
	elif _target_tree.has_method("harvest"):
		pickup_started = _target_tree.harvest(1, self) > 0

	if not pickup_started:
		if not (_target_tree.has_method("is_log_pickup_animating") and _target_tree.is_log_pickup_animating()):
			_return_idle()
		return

	if _target_tree.has_method("is_log_pickup_animating") and _target_tree.is_log_pickup_animating():
		_awaiting_log_pickup_animation = true
		return

	_complete_log_pickup()

func _complete_log_pickup() -> void:
	_waiting_for_tree_fall = false
	_fall_wait_phase = FallWaitPhase.WALK_TO_LOG
	_set_tree_chop_overlay(false)
	_end_tree_axe_strike()
	_cargo_amount = 1
	_cargo.visible = true
	_release_tree_reservation()
	_target_tree = null
	_target_is_log_pile = false
	_awaiting_log_pickup_animation = false
	_awaiting_bend_pickup = false
	_state = State.TO_CAMP
	_move_direction = Vector2.ZERO

func _abort_fall_wait() -> void:
	_waiting_for_tree_fall = false
	_fall_wait_phase = FallWaitPhase.WALK_TO_LOG
	_awaiting_log_pickup_animation = false
	_awaiting_bend_pickup = false
	_release_tree_reservation()
	_target_tree = null
	_target_is_log_pile = false
	_return_idle()

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

	_target_is_log_pile = _tree_is_log_pile()
	_awaiting_log_pickup_animation = false
	_awaiting_bend_pickup = false
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

func _end_tree_axe_strike() -> void:
	if _is_tree_valid() and _target_tree.has_method("end_axe_strike"):
		_target_tree.end_axe_strike()

func _return_idle() -> void:
	_waiting_for_tree_fall = false
	_fall_wait_phase = FallWaitPhase.WALK_TO_LOG
	_set_tree_chop_overlay(false)
	_end_tree_axe_strike()
	_release_tree_reservation()
	_target_tree = null
	_target_is_log_pile = false
	_awaiting_log_pickup_animation = false
	_awaiting_bend_pickup = false
	_state = State.IDLE
	_idle_timer = 0.25
	_move_direction = Vector2.ZERO
	_chop_position = Vector2.ZERO
	_fallen_log_position = Vector2.ZERO

func _release_tree_reservation() -> void:
	if _target_tree != null and is_instance_valid(_target_tree) and _target_tree.has_method("release_reservation"):
		_target_tree.release_reservation(self)

func _set_tree_chop_overlay(active: bool) -> void:
	if _is_tree_valid() and _target_tree.has_method("set_chopper_draws_behind_tree"):
		_target_tree.set_chopper_draws_behind_tree(active)

func _tree_is_log_pile() -> bool:
	return _is_tree_valid() and _target_tree.has_method("is_log_pile") and _target_tree.is_log_pile()

func _get_tree_interaction_position() -> Vector2:
	if _tree_is_log_pile():
		return _get_fallen_log_walk_target()
	return _get_chop_position()

func _get_chop_position() -> Vector2:
	var base_position := Vector2.ZERO
	if _is_tree_valid() and _target_tree.has_method("get_chop_position"):
		base_position = _target_tree.get_chop_position()
	elif _is_tree_valid():
		base_position = _target_tree.position
	return base_position + Vector2(standing_chop_east_offset - fine_west_offset, 0.0)

func _get_fallen_log_walk_target() -> Vector2:
	var base_position := _get_fallen_log_chop_position()
	return base_position + Vector2(-_get_log_pile_west_offset(), 0.0)

func _get_log_pile_west_offset() -> float:
	var remaining := _get_log_pile_pickups_remaining()
	if remaining == 2:
		return fallen_log_extra_west + fallen_log_second_pickup_extra_west
	return fallen_log_extra_west

func _get_log_pile_pickups_remaining() -> int:
	if _is_tree_valid() and _target_tree.has_method("get_log_pile_pickups_remaining"):
		return _target_tree.get_log_pile_pickups_remaining()
	return 3

func _get_fallen_log_chop_position() -> Vector2:
	if _is_tree_valid() and _target_tree.has_method("get_fallen_log_chop_position"):
		return _target_tree.get_fallen_log_chop_position()
	if _is_tree_valid():
		return _target_tree.position
	return Vector2.ZERO

func _is_at_fallen_log_position() -> bool:
	return position.distance_to(_fallen_log_position) <= ARRIVE_DISTANCE

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
