class_name CharacterWalk
extends RefCounted

const FRAME_SIZE := 32
const WALK_FRAMES := 4

static func build_sprite_frames(
	walk_sheet: Texture2D,
	walk_speed: float = 6.0,
	idle_speed: float = 1.0
) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.add_animation(&"walk")
	frames.set_animation_loop(&"walk", true)
	frames.set_animation_speed(&"walk", walk_speed)
	frames.add_animation(&"idle")
	frames.set_animation_loop(&"idle", true)
	frames.set_animation_speed(&"idle", idle_speed)

	for i in WALK_FRAMES:
		var atlas := AtlasTexture.new()
		atlas.atlas = walk_sheet
		atlas.region = Rect2(i * FRAME_SIZE, 0, FRAME_SIZE, FRAME_SIZE)
		frames.add_frame(&"walk", atlas)

	var idle_atlas := AtlasTexture.new()
	idle_atlas.atlas = walk_sheet
	idle_atlas.region = Rect2(0, 0, FRAME_SIZE, FRAME_SIZE)
	frames.add_frame(&"idle", idle_atlas)

	return frames

static func apply(sprite: AnimatedSprite2D, walk_sheet: Texture2D, walk_speed: float = 6.0) -> void:
	sprite.sprite_frames = build_sprite_frames(walk_sheet, walk_speed)
	sprite.play(&"idle")

static func update_motion(sprite: AnimatedSprite2D, is_walking: bool, move_offset: Vector2) -> void:
	if is_walking:
		if sprite.animation != &"walk":
			sprite.play(&"walk")
		if move_offset.x < -0.01:
			sprite.flip_h = true
		elif move_offset.x > 0.01:
			sprite.flip_h = false
	elif sprite.animation != &"idle":
		sprite.play(&"idle")
