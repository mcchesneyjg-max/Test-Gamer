class_name CharacterWalk
extends RefCounted

const WALK_ANIMATIONS_ROOT := "res://assets/sprites/walking_animations"
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

	_add_idle_animation(frames)

	sprite.sprite_frames = frames
	sprite.flip_h = false
	sprite.play(&"idle")

static func update_motion(sprite: AnimatedSprite2D, is_walking: bool, move_offset: Vector2) -> void:
	sprite.flip_h = false
	if not is_walking or move_offset.length_squared() <= 0.001:
		if sprite.animation != &"idle":
			sprite.play(&"idle")
		return

	var direction := _direction_suffix_from_offset(move_offset)
	var folder_name: String = DIRECTION_TO_FOLDER.get(direction, "")
	var animation_name := StringName(folder_name)
	if folder_name.is_empty() or not sprite.sprite_frames.has_animation(animation_name):
		if sprite.animation != &"idle":
			sprite.play(&"idle")
		return

	if sprite.animation != animation_name:
		sprite.play(animation_name)

static func _load_direction_frames(folder_name: String) -> Array[Texture2D]:
	for candidate in _folder_candidates(folder_name):
		var frame_textures := _load_frame_folder("%s/%s" % [WALK_ANIMATIONS_ROOT, candidate])
		if not frame_textures.is_empty():
			return frame_textures
	return []

static func _folder_candidates(folder_name: String) -> Array[String]:
	var candidates: Array[String] = [folder_name]
	if FOLDER_ALIASES.has(folder_name):
		for alias in FOLDER_ALIASES[folder_name]:
			candidates.append(alias)
	return candidates

static func _add_idle_animation(frames: SpriteFrames) -> void:
	frames.add_animation(&"idle")
	frames.set_animation_loop(&"idle", true)
	frames.set_animation_speed(&"idle", 1.0)

	if frames.has_animation(&"walk_north") and frames.get_frame_count(&"walk_north") > 0:
		frames.add_frame(&"idle", frames.get_frame_texture(&"walk_north", 0))
		return

	var fallback := _first_walk_animation(frames)
	if fallback != StringName() and frames.get_frame_count(fallback) > 0:
		frames.add_frame(&"idle", frames.get_frame_texture(fallback, 0))

static func _load_frame_folder(folder_path: String) -> Array[Texture2D]:
	var textures: Array[Texture2D] = []
	var dir := DirAccess.open(folder_path)
	if dir == null:
		return textures

	var file_names: Array[String] = []
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.to_lower().ends_with(".png"):
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
