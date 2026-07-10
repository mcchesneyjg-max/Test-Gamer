class_name CharacterWalk
extends RefCounted

const DIRECTION_SUFFIXES := ["n", "ne", "e", "se", "s", "sw", "w", "nw"]
const ANGLE_INDEX_TO_DIRECTION := ["e", "se", "s", "sw", "w", "nw", "n", "ne"]
const DEFAULT_FRAME_SIZE := 32

static func apply_from_folder(
	sprite: AnimatedSprite2D,
	folder: String,
	walk_speed: float = 6.0,
	frame_size: int = DEFAULT_FRAME_SIZE
) -> void:
	var frames := SpriteFrames.new()
	var loaded_walk_dirs: Array[String] = []

	for direction in DIRECTION_SUFFIXES:
		var sheet_path := "%s/walk_%s.png" % [folder, direction]
		if not ResourceLoader.exists(sheet_path):
			continue
		var sheet: Texture2D = load(sheet_path)
		var frame_count := _frame_count_for_sheet(sheet, frame_size)
		var animation_name := StringName("walk_%s" % direction)
		frames.add_animation(animation_name)
		frames.set_animation_loop(animation_name, true)
		frames.set_animation_speed(animation_name, walk_speed)
		_add_sheet_frames(frames, animation_name, sheet, frame_size, frame_count)
		loaded_walk_dirs.append(direction)

	if loaded_walk_dirs.is_empty():
		push_warning("CharacterWalk: no walk sprites found in %s" % folder)
		return

	_add_idle_animation(frames, folder, loaded_walk_dirs, frame_size)

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
	sprite.set_meta(&"last_walk_dir", direction)
	var animation_name := StringName("walk_%s" % direction)
	if not sprite.sprite_frames.has_animation(animation_name):
		animation_name = _first_walk_animation(sprite.sprite_frames)
		if animation_name == StringName():
			return

	if sprite.animation != animation_name:
		sprite.play(animation_name)

static func _add_idle_animation(
	frames: SpriteFrames,
	folder: String,
	loaded_walk_dirs: Array[String],
	frame_size: int
) -> void:
	frames.add_animation(&"idle")
	frames.set_animation_loop(&"idle", true)
	frames.set_animation_speed(&"idle", 1.0)

	var idle_path := "%s/idle.png" % folder
	if ResourceLoader.exists(idle_path):
		var idle_sheet: Texture2D = load(idle_path)
		var atlas := AtlasTexture.new()
		atlas.atlas = idle_sheet
		atlas.region = Rect2(0, 0, min(frame_size, idle_sheet.get_width()), min(frame_size, idle_sheet.get_height()))
		frames.add_frame(&"idle", atlas)
		return

	var idle_direction := "s" if "s" in loaded_walk_dirs else loaded_walk_dirs[0]
	var source_animation := StringName("walk_%s" % idle_direction)
	if frames.get_frame_count(source_animation) > 0:
		frames.add_frame(&"idle", frames.get_frame_texture(source_animation, 0))

static func _add_sheet_frames(
	frames: SpriteFrames,
	animation_name: StringName,
	sheet: Texture2D,
	frame_size: int,
	frame_count: int
) -> void:
	for frame_index in frame_count:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(frame_index * frame_size, 0, frame_size, frame_size)
		frames.add_frame(animation_name, atlas)

static func _frame_count_for_sheet(sheet: Texture2D, frame_size: int) -> int:
	return max(1, int(sheet.get_width() / float(frame_size)))

static func _direction_suffix_from_offset(offset: Vector2) -> String:
	var direction_index := int(round(offset.angle() / (PI / 4.0)))
	direction_index = posmod(direction_index, ANGLE_INDEX_TO_DIRECTION.size())
	return ANGLE_INDEX_TO_DIRECTION[direction_index]

static func _first_walk_animation(frames: SpriteFrames) -> StringName:
	for direction in DIRECTION_SUFFIXES:
		var animation_name := StringName("walk_%s" % direction)
		if frames.has_animation(animation_name):
			return animation_name
	return StringName()
