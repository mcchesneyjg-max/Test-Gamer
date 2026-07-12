class_name YSortDepth
extends RefCounted

const ALPHA_THRESHOLD := 0.04

static var _opaque_bottom_cache: Dictionary = {}

static func apply_to_entity(entity: Node2D) -> void:
	if entity == null:
		return

	var deepest := 0.0
	for child in entity.get_children():
		deepest = maxf(deepest, _deepest_visible_sprite_y(child))

	entity.y_sort_origin = deepest

static func _deepest_visible_sprite_y(node: Node) -> float:
	if node is Sprite2D:
		return _sprite_deepest_y(node as Sprite2D)
	if node is AnimatedSprite2D:
		return _animated_sprite_deepest_y(node as AnimatedSprite2D)
	return 0.0

static func _animated_sprite_deepest_y(sprite: AnimatedSprite2D) -> float:
	if not sprite.visible or sprite.sprite_frames == null:
		return 0.0

	var frame_count := sprite.sprite_frames.get_frame_count(sprite.animation)
	if frame_count <= 0:
		return 0.0

	var texture := sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	if texture == null:
		return 0.0

	return _sprite_deepest_y_from_texture(
		sprite.position,
		sprite.offset,
		sprite.centered,
		sprite.scale,
		texture
	)

static func _sprite_deepest_y(sprite: Sprite2D) -> float:
	if not sprite.visible or sprite.texture == null:
		return 0.0

	return _sprite_deepest_y_from_texture(
		sprite.position,
		sprite.offset,
		sprite.centered,
		sprite.scale,
		sprite.texture
	)

static func _sprite_deepest_y_from_texture(
	sprite_position: Vector2,
	sprite_offset: Vector2,
	centered: bool,
	sprite_scale: Vector2,
	texture: Texture2D
) -> float:
	var opaque_bottom := _get_opaque_bottom_y(texture)
	var texture_height := texture.get_height()
	var anchor_y := sprite_position.y + sprite_offset.y

	if centered:
		return anchor_y + (opaque_bottom - texture_height * 0.5) * sprite_scale.y

	return anchor_y + opaque_bottom * sprite_scale.y

static func _get_opaque_bottom_y(texture: Texture2D) -> float:
	if texture == null:
		return 0.0

	var cache_key := texture.resource_path
	if cache_key.is_empty():
		cache_key = str(texture.get_instance_id())
	if _opaque_bottom_cache.has(cache_key):
		return _opaque_bottom_cache[cache_key]

	var image := _get_readable_image(texture)
	var opaque_bottom := texture.get_height()
	if image != null and not image.is_empty():
		var max_y := -1
		for y in range(image.get_height()):
			for x in range(image.get_width()):
				if image.get_pixel(x, y).a > ALPHA_THRESHOLD:
					max_y = maxi(max_y, y)
		if max_y >= 0:
			opaque_bottom = max_y

	_opaque_bottom_cache[cache_key] = opaque_bottom
	return opaque_bottom

static func _get_readable_image(texture: Texture2D) -> Image:
	var image: Image = texture.get_image()
	if image != null and not image.is_empty():
		return image

	var texture_path := texture.resource_path
	if texture_path.is_empty():
		return null

	var global_path := ProjectSettings.globalize_path(texture_path)
	if not FileAccess.file_exists(global_path):
		return null

	return Image.load_from_file(global_path)
