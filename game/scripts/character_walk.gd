class_name CharacterWalk
extends RefCounted

const WALK_ANIMATIONS_ROOT := "res://assets/sprites/walking_animations"
const WAITING_ANIMATIONS_ROOT := "res://assets/sprites/waiting_animation"
const WAITING_PREFIX := "waiting_animation"
const WOOD_CUTTING_ROOT := "res://assets/sprites/wood_cutting_animation"
const WOOD_CUTTING_PREFIX := "wood_cutting"
const WAIT_HOLD_SECONDS := 4.0
const META_WAS_WALKING := "character_walk_was_walking"
const META_WAIT_PHASE := "character_walk_wait_phase"
const META_WAIT_ELAPSED := "character_walk_wait_elapsed"
const META_PLAY_SPEED := "character_walk_play_speed"
const META_CHOP_PHASE := "character_walk_chop_phase"
const META_CHOP_ELAPSED := "character_walk_chop_elapsed"
const CHOP_LOOP_START_FRAME := 3
const DIRECTION_TO_FOLDER := {
	"n": "walk_north",
	"ne": "walk_north_east",
	"e": "walk_east",
	"se": "walk_south_east",
	"s": "walk_south",
	"sw": "walk_south_west",
	"w": "walk_west",
	"nw": "walk_north_west",
}
const FOLDER_ALIASES := {
	"walk_north_east": ["walk_northeast"],
	"walk_north_west": ["walk_northwest"],
	"walk_south_east": ["walk_southeast"],
	"walk_south_west": ["walk_southwest"],
}
const ALL_DIRECTION_FOLDERS: Array[String] = [
	"walk_north",
	"walk_north_east",
	"walk_north_west",
	"walk_east",
	"walk_south",
	"walk_south_east",
	"walk_south_west",
	"walk_west",
]
const FOLDER_FILENAME_PREFIXES := {
	"walk_north": ["walk_north"],
	"walk_north_east": ["walk_north_east", "walknortheast"],
	"walk_north_west": ["walk_north_west", "walknorthwest"],
	"walk_east": ["walk_east"],
	"walk_south": ["walk_south"],
	"walk_south_east": ["walk_south_east", "walk_southeast", "walksoutheast"],
	"walk_south_west": ["walk_south_west", "walk_southwest", "walksouthwest"],
	"walk_west": ["walk_west"],
}
const ANGLE_INDEX_TO_DIRECTION := ["e", "se", "s", "sw", "w", "nw", "n", "ne"]

static func apply_shared(sprite: AnimatedSprite2D, walk_speed: float = 10.0) -> void:
	var frames := SpriteFrames.new()
	var loaded_any := false

	for direction_key in DIRECTION_TO_FOLDER.keys():
		var folder_name: String = DIRECTION_TO_FOLDER[direction_key]
		var frame_textures := _load_direction_frames(folder_name)
		if frame_textures.is_empty():
			continue

		var animation_name := StringName(folder_name)
		frames.add_animation(animation_name)
		frames.set_animation_loop(animation_name, true)
		frames.set_animation_speed(animation_name, walk_speed)
		for texture in frame_textures:
			frames.add_frame(animation_name, texture)
		loaded_any = true
		print("CharacterWalk: loaded %d frames for %s" % [frame_textures.size(), folder_name])

	if not loaded_any:
		push_warning("CharacterWalk: no walk animations found under %s" % WALK_ANIMATIONS_ROOT)
		return

	var waiting_frames := _load_waiting_frames()
	if waiting_frames.is_empty():
		push_warning(
			"CharacterWalk: no waiting frames found in %s — using idle fallback. "
			% WAITING_ANIMATIONS_ROOT
		)
		_add_idle_fallback_animation(frames)
	else:
		_add_waiting_animation(frames, waiting_frames, walk_speed)
		print("CharacterWalk: loaded %d waiting frames" % waiting_frames.size())

	var wood_cutting_frames := _load_wood_cutting_frames()
	if wood_cutting_frames.is_empty():
		push_warning(
			"CharacterWalk: no wood cutting frames found in %s"
			% WOOD_CUTTING_ROOT
		)
	else:
		_add_wood_cutting_animation(frames, wood_cutting_frames, walk_speed)
		print("CharacterWalk: loaded %d wood cutting frames" % wood_cutting_frames.size())

	sprite.sprite_frames = frames
	sprite.flip_h = false
	sprite.set_meta(META_PLAY_SPEED, walk_speed)
	_reset_waiting_state(sprite)
	_start_waiting(sprite)

static func update_motion(
	sprite: AnimatedSprite2D,
	is_walking: bool,
	move_offset: Vector2,
	delta: float = 0.0
) -> void:
	sprite.flip_h = false
	if not is_walking or move_offset.length_squared() <= 0.001:
		_update_waiting(sprite, delta)
		return

	sprite.set_meta(META_WAS_WALKING, true)

	var direction := _direction_suffix_from_offset(move_offset)
	var folder_name: String = DIRECTION_TO_FOLDER.get(direction, "")
	var animation_name := StringName(folder_name)
	if folder_name.is_empty() or not sprite.sprite_frames.has_animation(animation_name):
		_update_waiting(sprite, delta)
		return

	if sprite.animation != animation_name:
		sprite.play(animation_name)

static func reset_chopping(sprite: AnimatedSprite2D) -> void:
	sprite.set_meta(META_CHOP_PHASE, "intro")
	sprite.set_meta(META_CHOP_ELAPSED, 0.0)

static func update_chopping(sprite: AnimatedSprite2D, delta: float = 0.0) -> void:
	sprite.flip_h = false
	if sprite.sprite_frames == null:
		return

	if not sprite.sprite_frames.has_animation(&"wood_cutting"):
		_update_waiting(sprite, delta)
		return

	if sprite.animation != &"wood_cutting":
		reset_chopping(sprite)
		sprite.animation = &"wood_cutting"
	sprite.stop()
	_advance_chopping(sprite, delta)

static func _load_direction_frames(folder_name: String) -> Array[Texture2D]:
	for candidate in _folder_candidates(folder_name):
		var frame_textures := _load_frame_folder("%s/%s" % [WALK_ANIMATIONS_ROOT, candidate], candidate)
		if not frame_textures.is_empty():
			return frame_textures
	return []

static func _folder_candidates(folder_name: String) -> Array[String]:
	var candidates: Array[String] = [folder_name]
	if FOLDER_ALIASES.has(folder_name):
		for alias in FOLDER_ALIASES[folder_name]:
			candidates.append(alias)
	return candidates

static func _add_waiting_animation(
	frames: SpriteFrames,
	waiting_frames: Array[Texture2D],
	walk_speed: float
) -> void:
	frames.add_animation(&"waiting")
	frames.set_animation_loop(&"waiting", false)
	frames.set_animation_speed(&"waiting", walk_speed)
	for texture in waiting_frames:
		frames.add_frame(&"waiting", texture)

static func _add_wood_cutting_animation(
	frames: SpriteFrames,
	wood_cutting_frames: Array[Texture2D],
	walk_speed: float
) -> void:
	frames.add_animation(&"wood_cutting")
	frames.set_animation_loop(&"wood_cutting", false)
	frames.set_animation_speed(&"wood_cutting", walk_speed)
	for texture in wood_cutting_frames:
		frames.add_frame(&"wood_cutting", texture)

static func _advance_chopping(sprite: AnimatedSprite2D, delta: float) -> void:
	var frame_count := sprite.sprite_frames.get_frame_count(&"wood_cutting")
	if frame_count <= 0:
		return

	var phase: String = sprite.get_meta(META_CHOP_PHASE, "intro")
	var elapsed: float = float(sprite.get_meta(META_CHOP_ELAPSED, 0.0)) + delta
	var play_speed: float = float(sprite.get_meta(META_PLAY_SPEED, 10.0))
	var loop_start_frame := mini(CHOP_LOOP_START_FRAME, maxi(frame_count - 1, 0))

	if phase == "intro":
		var frame_index := int(elapsed * play_speed)
		if frame_index >= frame_count:
			phase = "loop"
			elapsed = 0.0
			sprite.frame = loop_start_frame
		else:
			sprite.frame = frame_index
	else:
		var loop_length := frame_count - loop_start_frame
		if loop_length <= 0:
			sprite.frame = frame_count - 1
		else:
			var frame_index := loop_start_frame + (int(elapsed * play_speed) % loop_length)
			sprite.frame = frame_index

	sprite.set_meta(META_CHOP_PHASE, phase)
	sprite.set_meta(META_CHOP_ELAPSED, elapsed)

static func _add_idle_fallback_animation(frames: SpriteFrames) -> void:
	frames.add_animation(&"idle")
	frames.set_animation_loop(&"idle", true)
	frames.set_animation_speed(&"idle", 1.0)

	if frames.has_animation(&"walk_north") and frames.get_frame_count(&"walk_north") > 0:
		frames.add_frame(&"idle", frames.get_frame_texture(&"walk_north", 0))
		return

	var fallback := _first_walk_animation(frames)
	if fallback != StringName() and frames.get_frame_count(fallback) > 0:
		frames.add_frame(&"idle", frames.get_frame_texture(fallback, 0))

static func _load_waiting_frames() -> Array[Texture2D]:
	return _load_png_sequence(WAITING_ANIMATIONS_ROOT, WAITING_PREFIX)

static func _load_wood_cutting_frames() -> Array[Texture2D]:
	return _load_png_sequence(WOOD_CUTTING_ROOT, WOOD_CUTTING_PREFIX)

static func _load_png_sequence(folder_root: String, file_prefix: String) -> Array[Texture2D]:
	var textures: Array[Texture2D] = []
	var dir := DirAccess.open(folder_root)
	if dir == null:
		return textures

	var file_names: Array[String] = []
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.to_lower().ends_with(".png"):
			var basename := file_name.get_basename()
			if basename == file_prefix or basename.begins_with("%s_" % file_prefix):
				file_names.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

	if file_names.is_empty():
		return textures

	file_names.sort_custom(func(a: String, b: String) -> bool:
		return _frame_sort_key(a) < _frame_sort_key(b)
	)

	for png_name in file_names:
		var texture_path := "%s/%s" % [folder_root, png_name]
		var texture := _load_texture(texture_path)
		if texture != null:
			textures.append(texture)

	return textures

static func _load_texture(texture_path: String) -> Texture2D:
	var texture: Texture2D = load(texture_path) as Texture2D
	if texture != null:
		return texture

	var global_path := ProjectSettings.globalize_path(texture_path)
	var loaded_image: Image = Image.load_from_file(global_path)
	if loaded_image != null:
		return ImageTexture.create_from_image(loaded_image)

	push_warning("CharacterWalk: failed to load %s" % texture_path)
	return null

static func _update_waiting(sprite: AnimatedSprite2D, delta: float) -> void:
	if sprite.sprite_frames == null:
		return

	if sprite.get_meta(META_WAS_WALKING, false):
		_reset_waiting_state(sprite)
	sprite.set_meta(META_WAS_WALKING, false)

	if sprite.sprite_frames.has_animation(&"waiting"):
		_advance_waiting(sprite, delta)
		return

	if sprite.sprite_frames.has_animation(&"idle"):
		if sprite.animation != &"idle":
			sprite.play(&"idle")

static func _advance_waiting(sprite: AnimatedSprite2D, delta: float) -> void:
	if sprite.animation != &"waiting":
		sprite.animation = &"waiting"
	sprite.stop()

	var frame_count := sprite.sprite_frames.get_frame_count(&"waiting")
	if frame_count <= 0:
		return

	var phase: String = sprite.get_meta(META_WAIT_PHASE, "hold")

	if phase == "rest":
		sprite.frame = frame_count - 1
		return

	var elapsed: float = float(sprite.get_meta(META_WAIT_ELAPSED, 0.0)) + delta
	var play_speed: float = float(sprite.get_meta(META_PLAY_SPEED, 10.0))

	if phase == "hold":
		sprite.frame = 0
		if elapsed >= WAIT_HOLD_SECONDS:
			if frame_count <= 1:
				phase = "rest"
			else:
				phase = "cycle"
			elapsed = 0.0
	elif phase == "cycle":
		var frame_index := 1 + int(elapsed * play_speed)
		if frame_index >= frame_count:
			phase = "rest"
			elapsed = 0.0
			sprite.frame = frame_count - 1
		else:
			sprite.frame = frame_index

	sprite.set_meta(META_WAIT_PHASE, phase)
	sprite.set_meta(META_WAIT_ELAPSED, elapsed)

static func _reset_waiting_state(sprite: AnimatedSprite2D) -> void:
	sprite.set_meta(META_WAS_WALKING, false)
	sprite.set_meta(META_WAIT_PHASE, "hold")
	sprite.set_meta(META_WAIT_ELAPSED, 0.0)

static func _start_waiting(sprite: AnimatedSprite2D) -> void:
	if sprite.sprite_frames.has_animation(&"waiting"):
		sprite.animation = &"waiting"
		sprite.stop()
		sprite.frame = 0
	elif sprite.sprite_frames.has_animation(&"idle"):
		sprite.play(&"idle")

static func _load_frame_folder(folder_path: String, folder_name: String) -> Array[Texture2D]:
	var textures: Array[Texture2D] = []
	var dir := DirAccess.open(folder_path)
	if dir == null:
		return textures

	var file_names: Array[String] = []
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.to_lower().ends_with(".png"):
			if _file_matches_folder(file_name.get_basename(), folder_name):
				file_names.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

	if file_names.is_empty():
		return textures

	file_names.sort_custom(func(a: String, b: String) -> bool:
		return _frame_sort_key(a) < _frame_sort_key(b)
	)

	for png_name in file_names:
		var texture_path := "%s/%s" % [folder_path, png_name]
		if not ResourceLoader.exists(texture_path):
			push_warning("CharacterWalk: missing texture %s" % texture_path)
			continue
		var texture: Texture2D = load(texture_path)
		if texture != null:
			textures.append(texture)
		else:
			push_warning("CharacterWalk: failed to load %s" % texture_path)

	return textures

static func _file_matches_folder(basename: String, folder_name: String) -> bool:
	var prefixes: Array = FOLDER_FILENAME_PREFIXES.get(folder_name, [folder_name])
	var matched_prefix := ""

	for prefix in prefixes:
		if basename.begins_with("%s_" % prefix):
			matched_prefix = prefix
			break

	if matched_prefix.is_empty():
		return false

	for other_folder in ALL_DIRECTION_FOLDERS:
		if other_folder == folder_name:
			continue
		if not other_folder.begins_with("%s_" % folder_name):
			continue
		for other_prefix in FOLDER_FILENAME_PREFIXES.get(other_folder, [other_folder]):
			if basename.begins_with("%s_" % other_prefix):
				return false

	return true

static func _frame_sort_key(filename: String) -> int:
	var base := filename.get_basename()
	var number_part := ""
	for i in range(base.length() - 1, -1, -1):
		var character := base[i]
		if character >= "0" and character <= "9":
			number_part = character + number_part
		elif number_part.length() > 0:
			break
	if number_part.is_valid_int():
		return number_part.to_int()
	return 0

static func _direction_suffix_from_offset(offset: Vector2) -> String:
	var direction_index := int(round(offset.angle() / (PI / 4.0)))
	direction_index = posmod(direction_index, ANGLE_INDEX_TO_DIRECTION.size())
	return ANGLE_INDEX_TO_DIRECTION[direction_index]

static func _first_walk_animation(frames: SpriteFrames) -> StringName:
	for folder_name in DIRECTION_TO_FOLDER.values():
		var animation_name := StringName(folder_name)
		if frames.has_animation(animation_name):
			return animation_name
	return StringName()
