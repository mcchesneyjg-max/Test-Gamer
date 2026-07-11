extends Node2D

signal fall_animation_finished

## Depletable wood source for future lumber camps.
@export var harvest_remaining: int = 10
@export var chop_stand_distance: float = 20.0
@export var chop_stand_north_offset: float = -32.0

const AXE_STRIKE_ROOT_CANDIDATES: Array[String] = [
	"res://assets/sprites/summer_tree_animation/summer_tree_1/axe_strike_animation",
	"res://assets/sprites/Summer_tree_animation/summer_tree_1/axe_strike_animation",
]
const FALL_ANIMATION_ROOT_CANDIDATES: Array[String] = [
	"res://assets/sprites/summer_tree_animation/summer_tree_1/fall_animation",
	"res://assets/sprites/Summer_tree_animation/summer_tree_1/fall_animation",
]
const AXE_STRIKE_PREFIXES: Array[String] = [
	"axe_strike",
	"axe_strike_animation",
	"summer_tree_axe_frame",
	"summer_tree_axe",
]
const FALL_ANIMATION_PREFIXES: Array[String] = [
	"fall",
	"fall_animation",
	"summer_tree_fall",
	"tree_fall",
]
const AXE_STRIKE_PLAY_SPEED := 10.0
const FALL_ANIMATION_PLAY_SPEED := 10.0

var _chopper: Node = null
var _static_texture: Texture2D
var _axe_strike_frames: Array[Texture2D] = []
var _fall_frames: Array[Texture2D] = []
var _axe_strike_active: bool = false
var _fall_active: bool = false
var _axe_strike_elapsed: float = 0.0
var _fall_elapsed: float = 0.0

@onready var _sprite: Sprite2D = $Sprite
@onready var _foreground_sprite: Sprite2D = $ForegroundSprite

func _ready() -> void:
	TreeRegistry.register_tree(self)
	_load_axe_strike_frames()
	_setup_chop_foreground_sprite()

func _process(delta: float) -> void:
	if _fall_active:
		_advance_fall_animation(delta)
		return

	if not _axe_strike_active or _axe_strike_frames.is_empty():
		return

	_axe_strike_elapsed += delta
	var frame_index := int(_axe_strike_elapsed * AXE_STRIKE_PLAY_SPEED) % _axe_strike_frames.size()
	_set_tree_texture(_axe_strike_frames[frame_index])

func _exit_tree() -> void:
	_chopper = null
	TreeRegistry.unregister_tree(self)

func is_available_to(chopper: Node) -> bool:
	_clear_stale_chopper()
	if _fall_active:
		return false
	if _chopper == null:
		return true
	return _chopper == chopper

func try_reserve(chopper: Node) -> bool:
	_clear_stale_chopper()
	if _fall_active:
		return false
	if _chopper != null and _chopper != chopper:
		return false
	_chopper = chopper
	_update_chop_foreground()
	return true

func release_reservation(chopper: Node) -> void:
	if _chopper == chopper:
		_chopper = null
		if not _fall_active:
			end_axe_strike()
		_update_chop_foreground()

func is_falling() -> bool:
	return _fall_active

func begin_axe_strike() -> void:
	if _fall_active:
		return
	_load_axe_strike_frames()
	if _axe_strike_frames.is_empty():
		push_warning("MatureTree: cannot play axe strike — no frames loaded")
		return
	_axe_strike_active = true
	_axe_strike_elapsed = 0.0
	_set_tree_texture(_axe_strike_frames[0])
	print("MatureTree: started axe strike animation (%d frames)" % _axe_strike_frames.size())

func end_axe_strike() -> void:
	if not _axe_strike_active:
		return
	_axe_strike_active = false
	_axe_strike_elapsed = 0.0
	_set_tree_texture(_static_texture)

func begin_fall_animation() -> void:
	_axe_strike_active = false
	_load_fall_frames()
	if _fall_frames.is_empty():
		push_warning("MatureTree: no fall frames found — removing tree immediately")
		queue_free()
		return

	_fall_active = true
	_fall_elapsed = 0.0
	_set_tree_texture(_fall_frames[0])
	_update_chop_foreground()
	print("MatureTree: started fall animation (%d frames)" % _fall_frames.size())

func get_chop_position() -> Vector2:
	var texture_size := Vector2.ZERO
	if _sprite.texture:
		texture_size = _sprite.texture.get_size()

	var trunk_base := position + _sprite.position + Vector2(0.0, texture_size.y * 0.5)
	return trunk_base + Vector2(chop_stand_distance, chop_stand_north_offset)

func is_depleted() -> bool:
	return harvest_remaining <= 0

func harvest(amount: int = 1, chopper: Node = null) -> int:
	if chopper != null and _chopper != chopper:
		return 0
	if harvest_remaining <= 0:
		return 0
	var taken := mini(amount, harvest_remaining)
	harvest_remaining -= taken
	if harvest_remaining <= 0:
		begin_fall_animation()
	return taken

func _load_axe_strike_frames() -> void:
	_axe_strike_frames = CharacterWalk.load_png_sequence_from_candidates(
		AXE_STRIKE_ROOT_CANDIDATES,
		AXE_STRIKE_PREFIXES,
		true
	)
	if _axe_strike_frames.is_empty():
		push_warning(
			"MatureTree: no axe strike frames found. Checked: %s"
			% ", ".join(AXE_STRIKE_ROOT_CANDIDATES)
		)
		_static_texture = _sprite.texture
		return

	_static_texture = _axe_strike_frames[0]
	if not _axe_strike_active and not _fall_active:
		_set_tree_texture(_static_texture)

func _load_fall_frames() -> void:
	_fall_frames = CharacterWalk.load_png_sequence_from_candidates(
		FALL_ANIMATION_ROOT_CANDIDATES,
		FALL_ANIMATION_PREFIXES,
		true
	)
	if _fall_frames.is_empty():
		push_warning(
			"MatureTree: no fall frames found. Checked: %s"
			% ", ".join(FALL_ANIMATION_ROOT_CANDIDATES)
		)

func _advance_fall_animation(delta: float) -> void:
	if _fall_frames.is_empty():
		_finish_fall_animation()
		return

	_fall_elapsed += delta
	var frame_index := int(_fall_elapsed * FALL_ANIMATION_PLAY_SPEED)
	if frame_index >= _fall_frames.size():
		_finish_fall_animation()
		return
	_set_tree_texture(_fall_frames[frame_index])

func _finish_fall_animation() -> void:
	if not _fall_active:
		return
	_fall_active = false
	fall_animation_finished.emit()
	queue_free()

func _clear_stale_chopper() -> void:
	if _chopper != null and not is_instance_valid(_chopper):
		_chopper = null
		if not _fall_active:
			end_axe_strike()
		_update_chop_foreground()

func _setup_chop_foreground_sprite() -> void:
	_foreground_sprite.texture = _sprite.texture
	_foreground_sprite.position = _sprite.position
	_foreground_sprite.centered = _sprite.centered
	_foreground_sprite.texture_filter = _sprite.texture_filter
	_foreground_sprite.z_as_relative = false
	_foreground_sprite.z_index = 4
	_foreground_sprite.visible = false

func _update_chop_foreground() -> void:
	_clear_stale_chopper()
	_foreground_sprite.visible = _chopper != null and not _fall_active

func _set_tree_texture(texture: Texture2D) -> void:
	_sprite.texture = texture
	if not _fall_active:
		_foreground_sprite.texture = texture
