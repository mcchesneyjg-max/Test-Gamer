extends Node2D

signal fall_animation_finished

## Depletable wood source for future lumber camps.
@export var harvest_remaining: int = 10
@export var chop_stand_distance: float = 14.0
@export var chop_stand_north_offset: float = 0.0

const TREE_VARIANT_NAMES: Array[String] = [
	"summer_tree_1",
	"summer_tree_2",
	"summer_tree_3",
]
const ANIMATION_BASE_CANDIDATES: Array[String] = [
	"res://assets/sprites/summer_tree_animation",
	"res://assets/sprites/Summer_tree_animation",
]
const AXE_STRIKE_PREFIXES: Array[String] = [
	"axe_strike",
	"axe_strike_animation",
	"summer_tree_axe_frame",
	"summer_tree_axe",
]
const FALL_ANIMATION_PREFIXES: Array[String] = [
	"summer_tree_fall_frame",
	"summer_tree_fall",
	"fall_animation",
	"fall",
	"tree_fall",
]
const AXE_STRIKE_PLAY_SPEED := 10.0
const FALL_ANIMATION_PLAY_SPEED := 10.0
var _chopper: Node = null
var _tree_variant: String = ""
var _axe_strike_root_candidates: Array[String] = []
var _fall_animation_root_candidates: Array[String] = []
var _static_texture: Texture2D
var _axe_strike_frames: Array[Texture2D] = []
var _fall_frames: Array[Texture2D] = []
var _trunk_anchor_cache: Dictionary = {}
var _planted_root: Vector2 = Vector2.ZERO
var _planted_root_initialized: bool = false
var _axe_strike_active: bool = false
var _fall_active: bool = false
var _axe_strike_elapsed: float = 0.0
var _fall_elapsed: float = 0.0

@onready var _sprite: Sprite2D = $Sprite
@onready var _foreground_sprite: Sprite2D = $ForegroundSprite

func _ready() -> void:
	_pick_random_variant()
	TreeRegistry.register_tree(self)
	_load_axe_strike_frames()
	_setup_chop_foreground_sprite()

func _process(delta: float) -> void:
	if _fall_active:
		_advance_fall_animation(delta)
	elif _axe_strike_active and not _axe_strike_frames.is_empty():
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
	if _fall_active or _axe_strike_frames.is_empty():
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
	# Tree position is the planted trunk base; lumberjack position is their feet.
	return position + Vector2(chop_stand_distance, chop_stand_north_offset)

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
	if not _axe_strike_frames.is_empty():
		return

	_axe_strike_frames = CharacterWalk.load_png_sequence_from_candidates(
		_axe_strike_root_candidates,
		AXE_STRIKE_PREFIXES,
		true
	)
	if _axe_strike_frames.is_empty():
		if _tree_variant != TREE_VARIANT_NAMES[0]:
			push_warning(
				"MatureTree: no axe strike frames for %s — falling back to %s"
				% [_tree_variant, TREE_VARIANT_NAMES[0]]
			)
			_set_variant_paths(TREE_VARIANT_NAMES[0])
			_axe_strike_frames = CharacterWalk.load_png_sequence_from_candidates(
				_axe_strike_root_candidates,
				AXE_STRIKE_PREFIXES,
				true
			)

	if _axe_strike_frames.is_empty():
		push_warning(
			"MatureTree: no axe strike frames found. Checked: %s"
			% ", ".join(_axe_strike_root_candidates)
		)
		_static_texture = _sprite.texture
		if _sprite.texture:
			_initialize_planted_root(_sprite.texture)
			_set_tree_texture(_sprite.texture)
			_sprite.visible = true
		return

	_static_texture = _axe_strike_frames[0]
	_initialize_planted_root(_static_texture)
	_set_tree_texture(_static_texture)
	_sprite.visible = true
	_refresh_sort_textures()
	print(
		"MatureTree: using variant %s (%d chop frames, root %s)"
		% [_tree_variant, _axe_strike_frames.size(), _planted_root]
	)

func _load_fall_frames() -> void:
	if not _fall_frames.is_empty():
		return

	_fall_frames = CharacterWalk.load_png_sequence_from_candidates(
		_fall_animation_root_candidates,
		FALL_ANIMATION_PREFIXES,
		true
	)
	if _fall_frames.is_empty():
		push_warning(
			"MatureTree: no fall frames found for %s. Checked: %s"
			% [_tree_variant, ", ".join(_fall_animation_root_candidates)]
		)
	else:
		_refresh_sort_textures()

func _pick_random_variant() -> void:
	var variant_index := randi() % TREE_VARIANT_NAMES.size()
	_set_variant_paths(TREE_VARIANT_NAMES[variant_index])

func _set_variant_paths(variant_name: String) -> void:
	_tree_variant = variant_name
	_axe_strike_root_candidates.clear()
	_fall_animation_root_candidates.clear()
	for base_path in ANIMATION_BASE_CANDIDATES:
		_axe_strike_root_candidates.append(
			"%s/%s/axe_strike_animation" % [base_path, variant_name]
		)
		_fall_animation_root_candidates.append(
			"%s/%s/fall_animation" % [base_path, variant_name]
		)

func _get_texture_anchor(texture: Texture2D) -> Vector2:
	if texture == null:
		return Vector2.ZERO

	var cache_key := texture.resource_path
	if cache_key.is_empty():
		cache_key = str(texture.get_instance_id())
	if _trunk_anchor_cache.has(cache_key):
		return _trunk_anchor_cache[cache_key]

	var anchor := CharacterWalk.get_texture_trunk_base(texture)
	_trunk_anchor_cache[cache_key] = anchor
	return anchor

func _initialize_planted_root(texture: Texture2D) -> void:
	if _planted_root_initialized or texture == null:
		return
	_planted_root = _get_texture_anchor(texture)
	_planted_root_initialized = true

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
	_foreground_sprite.visible = false

func _update_chop_foreground() -> void:
	_clear_stale_chopper()
	_foreground_sprite.visible = false

func _set_tree_texture(texture: Texture2D) -> void:
	var sprite_offset := -_planted_root

	_sprite.centered = false
	_sprite.position = sprite_offset
	_sprite.texture = texture

	_sprite.z_as_relative = true
	_sprite.z_index = 0

func _refresh_sort_textures() -> void:
	var textures: Array[Texture2D] = []
	if _static_texture != null:
		textures.append(_static_texture)
	for texture in _axe_strike_frames:
		if texture != null:
			textures.append(texture)
	for texture in _fall_frames:
		if texture != null:
			textures.append(texture)
	set_meta("_y_sort_extra_textures", textures)
	YSortDepth.apply_to_entity(self, true)
