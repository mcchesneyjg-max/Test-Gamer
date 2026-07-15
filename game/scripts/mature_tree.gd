extends Node2D

signal fall_animation_finished
signal fallen_chop_started
signal log_pile_ready
signal log_pile_pickup_taken(remaining: int)

## Depletable wood source for future lumber camps.
@export var harvest_remaining: int = 10
@export var chop_stand_distance: float = 14.0
@export var chop_stand_north_offset: float = 0.0
@export var fallen_log_chop_offset: Vector2 = Vector2.ZERO

const TREE_VARIANT_NAMES: Array[String] = [
	"summer_tree_1",
	"summer_tree_2",
	"summer_tree_3",
]
const ANIMATION_BASE_PATH := "res://assets/sprites/summer_tree_animation"
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
	"fall_animation_frame",
	"fall",
	"tree_fall",
]
const FALLEN_CHOP_PREFIXES: Array[String] = [
	"fallen_tree_chop_animation",
	"fallen_tree_chop",
	"summer_tree_fallen_chop_frame",
	"summer_tree_fallen_chop",
	"fallen_chop",
]
const AXE_STRIKE_PLAY_SPEED := 40.0
const FALL_ANIMATION_PLAY_SPEED := 40.0
const FALLEN_CHOP_PLAY_SPEED := 80.0
const TREE_TO_LOG_ROOT := "res://assets/sprites/tree_to_log_animation"
const TREE_TO_LOG_PREFIXES: Array[String] = [
	"logs_post_tree_fall",
	"log_post_tree_fall",
	"tree_to_log",
]
const TREE_TO_LOG_PLAY_SPEED := 40.0
const TREE_TO_LOG_ANIM_END_FRAME := 2
const LOG_PILE_PICKUPS := 3
const CHOP_FOREGROUND_Z_INDEX := 4

enum TreeLifePhase { STANDING, LOG_PILE, DEPLETED }
enum FallPhase { NONE, FALLING, FALLEN_CHOP, TREE_TO_LOG }

var _chopper: Node = null
var _chop_overlay_active: bool = false
var _tree_variant: String = ""
var _axe_strike_root_candidates: Array[String] = []
var _fall_animation_root_candidates: Array[String] = []
var _fallen_chop_root_candidates: Array[String] = []
var _static_texture: Texture2D
var _axe_strike_frames: Array[Texture2D] = []
var _fall_frames: Array[Texture2D] = []
var _fallen_chop_frames: Array[Texture2D] = []
var _tree_to_log_frames: Array[Texture2D] = []
var _life_phase: TreeLifePhase = TreeLifePhase.STANDING
var _log_pile_pickups_remaining: int = 0
var _trunk_anchor_cache: Dictionary = {}
var _planted_root: Vector2 = Vector2.ZERO
var _planted_root_initialized: bool = false
var _axe_strike_active: bool = false
var _fall_phase: FallPhase = FallPhase.NONE
var _axe_strike_elapsed: float = 0.0
var _fall_elapsed: float = 0.0
var _uses_fallback_axe_art: bool = false

static var _variant_bag: Array[String] = []

@onready var _sprite: Sprite2D = $Sprite
@onready var _foreground_sprite: Sprite2D = $ForegroundSprite

func _ready() -> void:
	_pick_random_variant()
	TreeRegistry.register_tree(self)
	_load_axe_strike_frames()
	_load_fall_frames()
	_load_fallen_chop_frames()
	_load_tree_to_log_frames()
	_validate_variant_assets()
	_setup_chop_foreground_sprite()

func _process(delta: float) -> void:
	match _fall_phase:
		FallPhase.FALLING:
			_advance_fall_animation(delta)
		FallPhase.FALLEN_CHOP:
			_advance_fallen_chop_animation(delta)
		FallPhase.TREE_TO_LOG:
			_advance_tree_to_log_animation(delta)
		_:
			if _axe_strike_active and not _axe_strike_frames.is_empty():
				_axe_strike_elapsed += delta
				var frame_index := int(_axe_strike_elapsed * AXE_STRIKE_PLAY_SPEED) % _axe_strike_frames.size()
				_set_tree_texture(_axe_strike_frames[frame_index])

func _exit_tree() -> void:
	_chopper = null
	TreeRegistry.unregister_tree(self)

func is_available_to(chopper: Node) -> bool:
	_clear_stale_chopper()
	if _fall_phase != FallPhase.NONE:
		return false
	if _life_phase == TreeLifePhase.DEPLETED:
		return false
	if _life_phase == TreeLifePhase.LOG_PILE:
		if _log_pile_pickups_remaining <= 0:
			return false
		if _chopper == null:
			return true
		return _chopper == chopper
	if _chopper == null:
		return true
	return _chopper == chopper

func try_reserve(chopper: Node) -> bool:
	_clear_stale_chopper()
	if _fall_phase != FallPhase.NONE:
		return false
	if _life_phase == TreeLifePhase.DEPLETED:
		return false
	if _life_phase == TreeLifePhase.LOG_PILE and _log_pile_pickups_remaining <= 0:
		return false
	if _chopper != null and _chopper != chopper:
		return false
	_chopper = chopper
	return true

func set_chopper_draws_behind_tree(active: bool) -> void:
	_chop_overlay_active = active
	_apply_chop_foreground()

func release_reservation(chopper: Node) -> void:
	if _chopper == chopper:
		_chopper = null
		set_chopper_draws_behind_tree(false)
		if _fall_phase == FallPhase.NONE and _life_phase == TreeLifePhase.STANDING:
			end_axe_strike()

func get_tree_variant() -> String:
	return _tree_variant

func is_falling() -> bool:
	return _fall_phase != FallPhase.NONE

func is_log_pile() -> bool:
	return _life_phase == TreeLifePhase.LOG_PILE and _log_pile_pickups_remaining > 0

func is_in_fallen_chop() -> bool:
	return _fall_phase == FallPhase.FALLEN_CHOP

func is_in_tree_to_log() -> bool:
	return _fall_phase == FallPhase.TREE_TO_LOG

func get_log_pile_pickups_remaining() -> int:
	return _log_pile_pickups_remaining

func get_fallen_log_chop_position() -> Vector2:
	return position + fallen_log_chop_offset

func begin_axe_strike() -> void:
	if _fall_phase != FallPhase.NONE or _axe_strike_frames.is_empty():
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

	_fall_phase = FallPhase.FALLING
	_fall_elapsed = 0.0
	_set_tree_texture(_fall_frames[0], true)
	print(
		"MatureTree: started fall animation for %s (%d frames)"
		% [_tree_variant, _fall_frames.size()]
	)

func get_chop_position() -> Vector2:
	# Tree position is the planted trunk base; lumberjack position is their feet.
	return position + Vector2(chop_stand_distance, chop_stand_north_offset)

func is_depleted() -> bool:
	return _life_phase == TreeLifePhase.DEPLETED

func harvest(amount: int = 1, chopper: Node = null) -> int:
	if _life_phase == TreeLifePhase.LOG_PILE:
		return _harvest_log_pile(chopper)
	if chopper != null and _chopper != chopper:
		return 0
	if harvest_remaining <= 0:
		return 0
	var taken := mini(amount, harvest_remaining)
	harvest_remaining -= taken
	if harvest_remaining <= 0:
		begin_fall_animation()
	return taken

func _harvest_log_pile(chopper: Node = null) -> int:
	if _log_pile_pickups_remaining <= 0:
		return 0
	if chopper != null and _chopper != chopper:
		return 0
	_log_pile_pickups_remaining -= 1
	_show_log_pile_frame(5 - _log_pile_pickups_remaining)
	log_pile_pickup_taken.emit(_log_pile_pickups_remaining)
	print(
		"MatureTree: log pile pickup (%d remaining) showing logs_post_tree_fall_%d"
		% [_log_pile_pickups_remaining, 5 - _log_pile_pickups_remaining]
	)
	if _log_pile_pickups_remaining <= 0:
		_life_phase = TreeLifePhase.DEPLETED
		_chopper = null
	return 1

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
				"MatureTree: no axe strike frames for %s — falling back to %s axe art only"
				% [_tree_variant, TREE_VARIANT_NAMES[0]]
			)
			var fallback_roots: Array[String] = [
				"%s/%s/axe_strike_animation" % [ANIMATION_BASE_PATH, TREE_VARIANT_NAMES[0]]
			]
			_axe_strike_frames = CharacterWalk.load_png_sequence_from_candidates(
				fallback_roots,
				AXE_STRIKE_PREFIXES,
				true
			)
			if not _axe_strike_frames.is_empty():
				_uses_fallback_axe_art = true
				push_warning(
					"MatureTree: %s is using summer_tree_1 axe art and may look like variant 1"
					% _tree_variant
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
	_log_loaded_sequence("axe", _axe_strike_frames, _axe_strike_root_candidates)

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
		_log_loaded_sequence("fall", _fall_frames, _fall_animation_root_candidates)

func _load_fallen_chop_frames() -> void:
	if not _fallen_chop_frames.is_empty():
		return

	_fallen_chop_frames = CharacterWalk.load_png_sequence_from_candidates(
		_fallen_chop_root_candidates,
		FALLEN_CHOP_PREFIXES,
		true
	)
	if _fallen_chop_frames.is_empty():
		push_warning(
			"MatureTree: no fallen chop frames found for %s. Checked: %s"
			% [_tree_variant, ", ".join(_fallen_chop_root_candidates)]
		)
	else:
		_refresh_sort_textures()
		_log_loaded_sequence("fallen_chop", _fallen_chop_frames, _fallen_chop_root_candidates)

func _load_tree_to_log_frames() -> void:
	if not _tree_to_log_frames.is_empty():
		return

	var roots: Array[String] = [TREE_TO_LOG_ROOT]
	_tree_to_log_frames = CharacterWalk.load_png_sequence_from_candidates(
		roots,
		TREE_TO_LOG_PREFIXES,
		true
	)
	if _tree_to_log_frames.is_empty():
		push_warning(
			"MatureTree: no tree-to-log frames found in %s"
			% TREE_TO_LOG_ROOT
		)
	else:
		_refresh_sort_textures()
		print(
			"MatureTree: loaded %d tree-to-log frames from %s"
			% [_tree_to_log_frames.size(), TREE_TO_LOG_ROOT]
		)

func _pick_random_variant() -> void:
	_replenish_variant_bag_if_needed()
	var variant_name: String = _variant_bag.pop_back()
	_set_variant_paths(variant_name)

static func _replenish_variant_bag_if_needed() -> void:
	if not _variant_bag.is_empty():
		return
	_variant_bag = TREE_VARIANT_NAMES.duplicate()
	_variant_bag.shuffle()

func _validate_variant_assets() -> void:
	var missing: PackedStringArray = []
	if _axe_strike_frames.is_empty():
		missing.append("axe")
	if _fall_frames.is_empty():
		missing.append("fall")
	if _fallen_chop_frames.is_empty():
		missing.append("fallen_chop")
	if missing.is_empty():
		print(
			"MatureTree: %s ready with axe=%d fall=%d fallen_chop=%d%s"
			% [
				_tree_variant,
				_axe_strike_frames.size(),
				_fall_frames.size(),
				_fallen_chop_frames.size(),
				" (borrowed axe art)" if _uses_fallback_axe_art else "",
			]
		)
		return
	push_warning(
		"MatureTree: %s is missing animations: %s"
		% [_tree_variant, ", ".join(missing)]
	)

func _set_variant_paths(variant_name: String) -> void:
	_tree_variant = variant_name
	_axe_strike_root_candidates.clear()
	_fall_animation_root_candidates.clear()
	_fallen_chop_root_candidates.clear()
	_axe_strike_root_candidates.append(
		"%s/%s/axe_strike_animation" % [ANIMATION_BASE_PATH, variant_name]
	)
	_fall_animation_root_candidates.append(
		"%s/%s/fall_animation" % [ANIMATION_BASE_PATH, variant_name]
	)
	_fallen_chop_root_candidates.append(
		"%s/%s/fallen_tree_chop_animation" % [ANIMATION_BASE_PATH, variant_name]
	)

func _log_loaded_sequence(
	sequence_name: String,
	frames: Array[Texture2D],
	root_candidates: Array[String]
) -> void:
	var first_path := ""
	if not frames.is_empty() and frames[0] != null:
		first_path = frames[0].resource_path
	print(
		"MatureTree: %s loaded %d frames for %s from %s (first=%s)"
		% [sequence_name, frames.size(), _tree_variant, root_candidates[0], first_path]
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
		_finish_fall_sequence()
		return

	_fall_elapsed += delta
	var frame_index := int(_fall_elapsed * FALL_ANIMATION_PLAY_SPEED)
	if frame_index >= _fall_frames.size():
		_begin_fallen_chop()
		return
	_set_tree_texture(_fall_frames[frame_index], true)

func _begin_fallen_chop() -> void:
	_load_fallen_chop_frames()
	if _fallen_chop_frames.is_empty():
		_finish_fall_sequence()
		return

	_fall_phase = FallPhase.FALLEN_CHOP
	_fall_elapsed = 0.0
	_set_tree_texture(_fallen_chop_frames[0], true)
	fallen_chop_started.emit()
	print(
		"MatureTree: started fallen chop animation for %s (%d frames)"
		% [_tree_variant, _fallen_chop_frames.size()]
	)

func _advance_fallen_chop_animation(delta: float) -> void:
	if _fallen_chop_frames.is_empty():
		_finish_fall_sequence()
		return

	_fall_elapsed += delta
	var frame_index := int(_fall_elapsed * FALLEN_CHOP_PLAY_SPEED)
	if frame_index >= _fallen_chop_frames.size():
		_begin_tree_to_log()
		return
	_set_tree_texture(_fallen_chop_frames[frame_index], true)

func _begin_tree_to_log() -> void:
	_load_tree_to_log_frames()
	if _tree_to_log_frames.is_empty():
		_begin_log_pile_phase()
		return

	_fall_phase = FallPhase.TREE_TO_LOG
	_fall_elapsed = 0.0
	_set_tree_to_log_frame(1)
	print(
		"MatureTree: started tree-to-log animation (%d frames, stops at frame %d)"
		% [_tree_to_log_frames.size(), TREE_TO_LOG_ANIM_END_FRAME]
	)

func _advance_tree_to_log_animation(delta: float) -> void:
	if _tree_to_log_frames.is_empty():
		_begin_log_pile_phase()
		return

	_fall_elapsed += delta
	var frame_index := int(_fall_elapsed * TREE_TO_LOG_PLAY_SPEED)
	if frame_index >= TREE_TO_LOG_ANIM_END_FRAME:
		_begin_log_pile_phase()
		return
	_set_tree_to_log_frame(frame_index + 1)

func _begin_log_pile_phase() -> void:
	_fall_phase = FallPhase.NONE
	_life_phase = TreeLifePhase.LOG_PILE
	_log_pile_pickups_remaining = LOG_PILE_PICKUPS
	_show_log_pile_frame(TREE_TO_LOG_ANIM_END_FRAME)
	log_pile_ready.emit()
	print(
		"MatureTree: log pile ready at logs_post_tree_fall_%d (%d pickups available)"
		% [TREE_TO_LOG_ANIM_END_FRAME, _log_pile_pickups_remaining]
	)

func _show_log_pile_frame(frame_number: int) -> void:
	var texture := _get_tree_to_log_texture(frame_number)
	if texture == null:
		push_warning("MatureTree: missing tree-to-log frame %d" % frame_number)
		return
	_set_tree_texture(texture, true)

func _set_tree_to_log_frame(frame_number: int) -> void:
	var texture := _get_tree_to_log_texture(frame_number)
	if texture == null:
		return
	_set_tree_texture(texture, true)

func _get_tree_to_log_texture(frame_number: int) -> Texture2D:
	for texture in _tree_to_log_frames:
		if texture == null:
			continue
		var path_frame := _get_png_frame_number(texture.resource_path)
		if path_frame == frame_number:
			return texture
	if frame_number <= 0 or frame_number > _tree_to_log_frames.size():
		return null
	return _tree_to_log_frames[frame_number - 1]

func _get_png_frame_number(path: String) -> int:
	var basename := path.get_file().get_basename()
	var digits := ""
	for i in range(basename.length() - 1, -1, -1):
		var character := basename[i]
		if character >= "0" and character <= "9":
			digits = character + digits
		elif not digits.is_empty():
			break
	if digits.is_valid_int():
		return digits.to_int()
	return 0

func _finish_fall_sequence() -> void:
	if _fall_phase == FallPhase.NONE:
		return
	_fall_phase = FallPhase.NONE
	fall_animation_finished.emit()
	queue_free()

func _clear_stale_chopper() -> void:
	if _chopper != null and not is_instance_valid(_chopper):
		_chopper = null
		if _fall_phase == FallPhase.NONE and _life_phase == TreeLifePhase.STANDING:
			end_axe_strike()
		set_chopper_draws_behind_tree(false)

func _setup_chop_foreground_sprite() -> void:
	_foreground_sprite.z_as_relative = false
	_foreground_sprite.z_index = CHOP_FOREGROUND_Z_INDEX
	_foreground_sprite.visible = false

func _apply_chop_foreground() -> void:
	_foreground_sprite.visible = _chop_overlay_active
	if _chop_overlay_active:
		_sync_chop_foreground_sprite()

func _sync_chop_foreground_sprite() -> void:
	_foreground_sprite.texture = _sprite.texture
	_foreground_sprite.position = _sprite.position
	_foreground_sprite.centered = _sprite.centered
	_foreground_sprite.texture_filter = _sprite.texture_filter

func _set_tree_texture(texture: Texture2D, use_frame_anchor: bool = false) -> void:
	var anchor := _get_texture_anchor(texture) if use_frame_anchor else _planted_root
	if not use_frame_anchor and not _planted_root_initialized:
		anchor = _get_texture_anchor(texture)
	var sprite_offset := -anchor

	_sprite.centered = false
	_sprite.position = sprite_offset
	_sprite.texture = texture

	_sprite.z_as_relative = true
	_sprite.z_index = 0
	if _chop_overlay_active:
		_sync_chop_foreground_sprite()

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
	for texture in _fallen_chop_frames:
		if texture != null:
			textures.append(texture)
	for texture in _tree_to_log_frames:
		if texture != null:
			textures.append(texture)
	set_meta("_y_sort_extra_textures", textures)
	YSortDepth.apply_to_entity(self, true)
