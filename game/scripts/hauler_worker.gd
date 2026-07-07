extends Node2D

enum State { IDLE, TO_SOURCE, TO_DEST }

const ARRIVE_DISTANCE := 8.0
const WALK_SHEET := preload("res://assets/sprites/hauler_worker_walk.png")

@export var move_speed: float = 90.0

var _station: Node2D
var _pending_color: Color = Color(0.9, 0.55, 0.25, 1)
var _state: State = State.IDLE
var _source: Node2D
var _destination: Node2D
var _cargo_amount: int = 0
var _idle_timer: float = 0.0

@onready var _body: AnimatedSprite2D = $Body
@onready var _cargo: Sprite2D = $Cargo

func setup(station: Node2D, body_color: Color) -> void:
	_station = station
	_pending_color = body_color

func _ready() -> void:
	add_to_group("hauler_worker")
	_setup_walk_animation()
	_body.modulate = _pending_color
	_cargo.visible = false

func _setup_walk_animation() -> void:
	var frames := SpriteFrames.new()
	frames.add_animation(&"walk")
	frames.set_animation_loop(&"walk", true)
	frames.set_animation_speed(&"walk", 6.0)
	frames.add_animation(&"idle")
	frames.set_animation_loop(&"idle", true)
	frames.set_animation_speed(&"idle", 1.0)

	for i in 2:
		var atlas := AtlasTexture.new()
		atlas.atlas = WALK_SHEET
		atlas.region = Rect2(i * 16, 0, 16, 16)
		frames.add_frame(&"walk", atlas)

	var idle_atlas := AtlasTexture.new()
	idle_atlas.atlas = WALK_SHEET
	idle_atlas.region = Rect2(0, 0, 16, 16)
	frames.add_frame(&"idle", idle_atlas)

	_body.sprite_frames = frames
	_body.play(&"idle")

func _process(delta: float) -> void:
	_update_animation()
	match _state:
		State.IDLE:
			_process_idle(delta)
		State.TO_SOURCE:
			_process_to_source(delta)
		State.TO_DEST:
			_process_to_dest(delta)

func _update_animation() -> void:
	if _state == State.IDLE:
		if _body.animation != &"idle":
			_body.play(&"idle")
	else:
		if _body.animation != &"walk":
			_body.play(&"walk")

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
	if not _is_source_valid():
		_return_idle()
		return

	_move_toward(_source.position, delta)
	if position.distance_to(_source.position) <= ARRIVE_DISTANCE:
		_pickup_cargo()

func _process_to_dest(delta: float) -> void:
	if not _is_destination_valid():
		_return_idle()
		return

	_move_toward(_destination.position, delta)
	if position.distance_to(_destination.position) <= ARRIVE_DISTANCE:
		_deliver_cargo()

func _try_start_job() -> bool:
	if _cargo_amount > 0:
		return false

	var source := _find_best_source()
	if source == null:
		return false

	var destination := _find_best_destination()
	if destination == null:
		return false

	_source = source
	_destination = destination
	_state = State.TO_SOURCE
	return true

func _find_best_source() -> Node2D:
	var best: Node2D = null
	var best_distance := INF

	for camp in CampRegistry.get_active_camps():
		if not camp.has_method("has_output_ready") or not camp.has_output_ready():
			continue
		var distance := position.distance_to(camp.position)
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
		var distance := position.distance_to(warehouse.position)
		if distance < best_distance:
			best_distance = distance
			best = warehouse

	return best

func _pickup_cargo() -> void:
	if not _is_source_valid():
		_return_idle()
		return

	var taken: int = _source.take_from_output(1)
	if taken <= 0:
		_return_idle()
		return

	_cargo_amount = taken
	_cargo.visible = true
	_state = State.TO_DEST

func _deliver_cargo() -> void:
	if _cargo_amount <= 0:
		_return_idle()
		return

	if _is_destination_valid():
		var delivered: int = _destination.deposit_logs(_cargo_amount)
		_cargo_amount -= delivered

	if _cargo_amount <= 0:
		_cargo.visible = false
	_return_idle()

func _return_idle() -> void:
	_source = null
	_destination = null
	_state = State.IDLE
	_idle_timer = 0.2

func _move_toward(target_position: Vector2, delta: float) -> void:
	var offset := target_position - position
	if offset.length_squared() <= 0.001:
		return
	position += offset.normalized() * move_speed * delta

func _is_source_valid() -> bool:
	return _source != null and is_instance_valid(_source) and _source.has_method("has_output_ready")

func _is_destination_valid() -> bool:
	return _destination != null and is_instance_valid(_destination) and _destination.has_method("can_accept_logs")
