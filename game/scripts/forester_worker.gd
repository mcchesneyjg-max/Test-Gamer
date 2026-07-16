extends Node2D

enum State { IDLE, TO_STUMP, REMOVING_STUMP, TO_SITE, PLANTING, TO_HOME }

const ARRIVE_DISTANCE := 8.0
const PLANT_DURATION := 0.9
const STUMP_REMOVAL_FALLBACK_DURATION := 1.2

@export var move_speed: float = 49.13
@export var stump_removal_east_offset: float = 10.0

var _lodge: Node2D
var _state: State = State.IDLE
var _plant_site: Vector2 = Vector2.ZERO
var _work_site: Vector2 = Vector2.ZERO
var _target_stump: Node2D
var _idle_timer: float = 0.0
var _action_timer: float = 0.0
var _move_direction := Vector2.ZERO
var _last_move_offset := Vector2.ZERO
var _using_log_cut_fallback: bool = false
var _using_stump_sprite_animation: bool = false

@onready var _body: AnimatedSprite2D = $Body

func setup(lodge: Node2D) -> void:
	_lodge = lodge

func on_plant_zone_ready() -> void:
	_idle_timer = 0.0
	if _state == State.TO_HOME and _is_lodge_valid() and position.distance_to(_lodge.position) <= ARRIVE_DISTANCE:
		_return_idle()
	if _state == State.IDLE:
		_try_start_job()

func _ready() -> void:
	add_to_group("forester_worker")
	CharacterWalk.apply_shared(_body, 10.0)

func _process(delta: float) -> void:
	_last_move_offset = Vector2.ZERO
	match _state:
		State.IDLE:
			_process_idle(delta)
		State.TO_STUMP:
			_process_to_stump(delta)
		State.REMOVING_STUMP:
			_process_removing_stump(delta)
		State.TO_SITE:
			_process_to_site(delta)
		State.PLANTING:
			_process_planting(delta)
		State.TO_HOME:
			_process_to_home(delta)
	_update_animation(delta)

func _update_animation(delta: float) -> void:
	if _state == State.REMOVING_STUMP and not _using_log_cut_fallback:
		CharacterWalk.update_log_cutting(_body, delta)
		return

	var is_walking := _last_move_offset.length_squared() > 0.001
	CharacterWalk.update_motion(_body, is_walking, _last_move_offset, delta)

func _process_idle(delta: float) -> void:
	if _is_lodge_valid() and position.distance_to(_lodge.position) > 14.0:
		_move_toward(_lodge.position, delta * 0.6)

	_idle_timer -= delta
	if _idle_timer > 0.0:
		return
	_idle_timer = 0.45
	_try_start_job()

func _process_to_stump(delta: float) -> void:
	if not _is_stump_valid():
		_return_idle()
		return

	_move_toward(_work_site, delta)
	if position.distance_to(_work_site) > ARRIVE_DISTANCE:
		return

	position = _work_site
	_begin_stump_removal()

func _process_removing_stump(delta: float) -> void:
	if _using_stump_sprite_animation:
		position = _work_site
		return

	if not _is_stump_valid():
		_return_idle()
		return

	position = _work_site

	if _using_log_cut_fallback:
		_action_timer -= delta
		if _action_timer > 0.0:
			return
		_finish_stump_removal()
		return

	if CharacterWalk.poll_log_cutting_intro_finished(_body):
		_finish_stump_removal()

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
	_move_direction = Vector2.ZERO

func _process_to_home(delta: float) -> void:
	if not _is_lodge_valid():
		_return_idle()
		return

	_move_toward(_lodge.position, delta)
	if position.distance_to(_lodge.position) <= ARRIVE_DISTANCE:
		_return_idle()

func _try_start_job() -> void:
	if not _is_lodge_valid() or not _lodge.has_plant_zone():
		return
	if _lodge.has_method("has_work_in_zone") and not _lodge.has_work_in_zone(self):
		return

	var stump: Node2D = _lodge.find_stump_in_zone(position, self)
	if stump != null:
		_target_stump = stump
		_work_site = _lodge.get_stump_work_position(stump) + Vector2(stump_removal_east_offset, 0.0)
		_plant_site = Vector2.ZERO
		_state = State.TO_STUMP
		_move_direction = Vector2.ZERO
		return

	if not _lodge.can_plant_sapling():
		return

	var site: Vector2 = _lodge.find_plant_site()
	if site == Vector2.ZERO:
		return

	_release_stump_reservation()
	_target_stump = null
	_plant_site = site
	_work_site = Vector2.ZERO
	_state = State.TO_SITE
	_move_direction = Vector2.ZERO

func _begin_stump_removal() -> void:
	_using_stump_sprite_animation = false
	_using_log_cut_fallback = _body.sprite_frames == null or not _body.sprite_frames.has_animation(&"log_cutting")
	if _using_log_cut_fallback:
		_action_timer = STUMP_REMOVAL_FALLBACK_DURATION
	else:
		CharacterWalk.reset_log_cutting(_body)

	if _is_stump_valid() and _target_stump.has_method("begin_stump_cutting_animation"):
		if _target_stump.begin_stump_cutting_animation():
			_using_stump_sprite_animation = true
			_connect_stump_cutting_finished_signal()

	_state = State.REMOVING_STUMP
	_move_direction = Vector2.ZERO

func _connect_stump_cutting_finished_signal() -> void:
	if not _is_stump_valid():
		return
	if not _target_stump.has_signal("stump_cutting_finished"):
		return
	if _target_stump.stump_cutting_finished.is_connected(_on_stump_cutting_finished):
		_target_stump.stump_cutting_finished.disconnect(_on_stump_cutting_finished)
	_target_stump.stump_cutting_finished.connect(_on_stump_cutting_finished, CONNECT_ONE_SHOT)

func _on_stump_cutting_finished() -> void:
	_using_stump_sprite_animation = false
	_target_stump = null
	_work_site = Vector2.ZERO
	_using_log_cut_fallback = false
	_state = State.TO_HOME
	_move_direction = Vector2.ZERO

func _finish_stump_removal() -> void:
	if _is_stump_valid() and _target_stump.has_method("remove_stump"):
		_target_stump.remove_stump()
	_target_stump = null
	_work_site = Vector2.ZERO
	_using_log_cut_fallback = false
	_using_stump_sprite_animation = false
	_state = State.TO_HOME
	_move_direction = Vector2.ZERO

func _return_idle() -> void:
	_release_stump_reservation()
	_plant_site = Vector2.ZERO
	_work_site = Vector2.ZERO
	_target_stump = null
	_using_log_cut_fallback = false
	_using_stump_sprite_animation = false
	_state = State.IDLE
	_idle_timer = 0.25
	_move_direction = Vector2.ZERO

func _release_stump_reservation() -> void:
	if _is_stump_valid() and _target_stump.has_method("release_stump_reservation"):
		_target_stump.release_stump_reservation(self)

func _is_stump_valid() -> bool:
	return _target_stump != null and is_instance_valid(_target_stump) and _target_stump.has_method("is_depleted_stump")

func _move_toward(target_position: Vector2, delta: float) -> void:
	var movement := GridMovement.step_toward(position, target_position, move_speed, delta, _move_direction)
	_move_direction = movement.direction
	if movement.step == Vector2.ZERO:
		_move_direction = Vector2.ZERO
		_last_move_offset = Vector2.ZERO
		return
	position += movement.step
	_last_move_offset = movement.direction

func _is_lodge_valid() -> bool:
	return (
		_lodge != null
		and is_instance_valid(_lodge)
		and _lodge.has_method("has_plant_zone")
		and _lodge.has_plant_zone()
	)
