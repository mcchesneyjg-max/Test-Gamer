extends Node2D

enum State { IDLE, TO_SOURCE, TO_DEST }

const ARRIVE_DISTANCE := 18.0

@export var move_speed: float = 52.02

var _station: Node2D
var _state: State = State.IDLE
var _source: Node2D
var _destination: Node2D
var _cargo_amount: int = 0
var _idle_timer: float = 0.0
var _move_direction := Vector2.ZERO
var _last_move_offset := Vector2.ZERO
var _travel_target := Vector2.ZERO
var _awaiting_bend_pickup: bool = false

@onready var _body: AnimatedSprite2D = $Body
@onready var _cargo: Sprite2D = $Cargo

func setup(station: Node2D, _body_color: Color = Color.WHITE) -> void:
	_station = station

func _ready() -> void:
	add_to_group("hauler_worker")
	CharacterWalk.apply_shared(_body, 10.0)
	_cargo.visible = false

func _process(delta: float) -> void:
	_last_move_offset = Vector2.ZERO
	match _state:
		State.IDLE:
			_process_idle(delta)
		State.TO_SOURCE:
			_process_to_source(delta)
		State.TO_DEST:
			_process_to_dest(delta)
	_update_animation(delta)

func _update_animation(delta: float) -> void:
	if _awaiting_bend_pickup:
		CharacterWalk.update_bending_down_pickup(_body, delta)
		if CharacterWalk.is_bending_down_pickup_finished(_body):
			_awaiting_bend_pickup = false
			_execute_cargo_pickup()
		return

	var is_walking := _last_move_offset.length_squared() > 0.001
	CharacterWalk.update_motion(_body, is_walking, _last_move_offset, delta)

func _process_idle(delta: float) -> void:
	if _station != null and is_instance_valid(_station):
		if position.distance_to(_station.position) > 14.0:
			_move_toward(_station.position, delta * 0.6)

	_idle_timer -= delta
	if _idle_timer > 0.0:
		return
	_idle_timer = 0.35
	_try_start_job()

func _process_to_source(delta: float) -> void:
	if not _is_source_reachable():
		_return_idle()
		return

	var pickup_position := _travel_target
	if pickup_position == Vector2.ZERO:
		pickup_position = _get_nearest_pickup_position(_source)
		_travel_target = pickup_position
	_move_toward(pickup_position, delta)
	if _is_near_pickup(_source):
		_pickup_cargo()

func _process_to_dest(delta: float) -> void:
	if _cargo_amount <= 0:
		_return_idle()
		return

	if not _is_destination_valid():
		_return_idle()
		return

	var delivery_position := _travel_target
	if delivery_position == Vector2.ZERO:
		delivery_position = _get_destination_position(_destination)
		_travel_target = delivery_position
	_move_toward(delivery_position, delta)
	if position.distance_to(delivery_position) <= ARRIVE_DISTANCE:
		_deliver_cargo()

func _try_start_job() -> bool:
	if _cargo_amount > 0:
		var destination := _find_best_destination()
		if destination == null:
			return false
		_destination = destination
		_state = State.TO_DEST
		_move_direction = Vector2.ZERO
		_travel_target = _get_destination_position(destination)
		return true

	var source := _find_best_source()
	if source == null:
		return false

	var dest := _find_best_destination()
	if dest == null:
		return false

	_source = source
	_destination = dest
	_state = State.TO_SOURCE
	_move_direction = Vector2.ZERO
	_travel_target = _get_nearest_pickup_position(source)
	return true

func _find_best_source() -> Node2D:
	var best: Node2D = null
	var best_distance := INF

	for camp in CampRegistry.get_active_camps():
		if not camp.has_method("has_output_ready") or not camp.has_output_ready():
			continue
		var distance := position.distance_to(_get_nearest_pickup_position(camp))
		if distance < best_distance:
			best_distance = distance
			best = camp

	return best

func _find_best_destination() -> Node2D:
	var best: Node2D = null
	var best_distance := INF

	for warehouse in WarehouseRegistry.get_active_warehouses():
		if not warehouse.has_method("can_accept_logs") or not warehouse.can_accept_logs():
			continue
		var distance := position.distance_to(_get_destination_position(warehouse))
		if distance < best_distance:
			best_distance = distance
			best = warehouse

	return best

func _pickup_cargo() -> void:
	if _awaiting_bend_pickup:
		return
	if not _is_source_reachable():
		_return_idle()
		return
	if not _source.has_output_ready():
		_return_idle()
		return
	if CharacterWalk.begin_bending_down_pickup(_body):
		_awaiting_bend_pickup = true
		return
	_execute_cargo_pickup()

func _execute_cargo_pickup() -> void:
	if not _is_source_reachable():
		_return_idle()
		return
	if not _source.has_output_ready():
		_return_idle()
		return

	var taken: int = _source.take_from_output(1)
	if taken <= 0:
		_return_idle()
		return

	_cargo_amount = taken
	_sync_cargo_visual()
	_state = State.TO_DEST
	_move_direction = Vector2.ZERO
	_travel_target = _get_destination_position(_destination)

func _deliver_cargo() -> void:
	if _cargo_amount <= 0:
		_return_idle()
		return

	if _is_destination_valid():
		var delivered: int = _destination.deposit_logs(_cargo_amount)
		_cargo_amount -= delivered

	if _cargo_amount <= 0:
		_sync_cargo_visual()
		_return_idle()
	elif _find_best_destination() != null:
		_state = State.TO_DEST
		_move_direction = Vector2.ZERO
		_travel_target = _get_destination_position(_destination)
	else:
		_idle_timer = 0.2

func _return_idle() -> void:
	_source = null
	_destination = null
	_awaiting_bend_pickup = false
	_state = State.IDLE
	_idle_timer = 0.2
	_move_direction = Vector2.ZERO
	_travel_target = Vector2.ZERO

func _get_pickup_positions(source: Node2D) -> Array[Vector2]:
	var points: Array[Vector2] = [source.position]
	if source.has_method("get_log_pickup_position"):
		points.append(source.get_log_pickup_position())
	return points

func _get_nearest_pickup_position(source: Node2D) -> Vector2:
	var points := _get_pickup_positions(source)
	var best := points[0]
	var best_distance := position.distance_to(best)
	for i in range(1, points.size()):
		var distance := position.distance_to(points[i])
		if distance < best_distance:
			best_distance = distance
			best = points[i]
	return best

func _is_near_pickup(source: Node2D) -> bool:
	for point in _get_pickup_positions(source):
		if position.distance_to(point) <= ARRIVE_DISTANCE:
			return true
	return false

func _get_destination_position(destination: Node2D) -> Vector2:
	if destination.has_method("get_delivery_position"):
		return destination.get_delivery_position()
	return destination.position

func _move_toward(target_position: Vector2, delta: float) -> void:
	var movement := GridMovement.step_toward(position, target_position, move_speed, delta, _move_direction)
	_move_direction = movement.direction
	if movement.step == Vector2.ZERO:
		_move_direction = Vector2.ZERO
		_last_move_offset = Vector2.ZERO
		return
	position += movement.step
	_last_move_offset = movement.direction

func _is_source_reachable() -> bool:
	return _source != null and is_instance_valid(_source) and _source.has_method("take_from_output")

func _is_destination_valid() -> bool:
	return (
		_destination != null
		and is_instance_valid(_destination)
		and _destination.has_method("can_accept_logs")
		and _destination.can_accept_logs()
	)

func _sync_cargo_visual() -> void:
	var carrying := _cargo_amount > 0
	CharacterWalk.set_carrying_log(_body, carrying)
	if CharacterWalk.has_walk_with_log_animations(_body):
		_cargo.visible = false
	else:
		_cargo.visible = carrying
