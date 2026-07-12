class_name YSortDepth
extends RefCounted

const ALPHA_THRESHOLD := 0.04
const APPLIED_META_KEY := "_y_sort_applied"
const LOGICAL_POS_META_KEY := "_y_sort_logical_pos"

static var _opaque_bottom_cache: Dictionary = {}

static func apply_to_entity(entity: Node2D) -> void:
	if entity == null:
		return

	var applied: float = entity.get_meta(APPLIED_META_KEY, 0.0)
	var logical_pos: Vector2
	if entity.has_meta(LOGICAL_POS_META_KEY):
		logical_pos = entity.get_meta(LOGICAL_POS_META_KEY)
	else:
		logical_pos = entity.position
		entity.set_meta(LOGICAL_POS_META_KEY, logical_pos)

	var expected_sort_pos := logical_pos + Vector2(0.0, applied)
	if entity.position.distance_squared_to(expected_sort_pos) > 0.01:
		if entity.position.distance_squared_to(logical_pos) < entity.position.distance_squared_to(expected_sort_pos):
			pass
		else:
			logical_pos += entity.position - expected_sort_pos

	var sprites := _collect_sprites(entity)
	var deepest := 0.0
	for sprite_entry in sprites:
		deepest = maxf(
			deepest,
			_deepest_visible_sprite_y(sprite_entry["sprite"], sprite_entry["offset"], applied)
		)

	var delta := deepest - applied
	if absf(delta) >= 0.001:
		for sprite_entry in sprites:
			var sprite := sprite_entry["sprite"] as Node2D
			sprite.position.y -= delta

	entity.set_meta(LOGICAL_POS_META_KEY, logical_pos)
	entity.set_meta(APPLIED_META_KEY, deepest)
	entity.position = logical_pos + Vector2(0.0, deepest)

static func _collect_sprites(entity: Node2D) -> Array[Dictionary]:
	var sprites: Array[Dictionary] = []
	_collect_sprites_recursive(entity, entity, Vector2.ZERO, sprites)
	return sprites

static func _collect_sprites_recursive(
	entity: Node2D,
	node: Node,
	accumulated_offset: Vector2,
	sprites: Array[Dictionary]
) -> void:
	if node is Node2D and node != entity:
		accumulated_offset += (node as Node2D).position

	if node is Sprite2D or node is AnimatedSprite2D:
		sprites.append({
			"sprite": node,
			"offset": accumulated_offset,
		})

	for child in node.get_children():
		_collect_sprites_recursive(entity, child, accumulated_offset, sprites)

static func _deepest_visible_sprite_y(sprite: Node, parent_offset: Vector2, sort_compensation: float) -> float:
	if sprite is Sprite2D:
		return _sprite_deepest_y(sprite as Sprite2D, parent_offset, sort_compensation)
	if sprite is AnimatedSprite2D:
		return _animated_sprite_deepest_y(sprite as AnimatedSprite2D, parent_offset, sort_compensation)
	return 0.0

static func _animated_sprite_deepest_y(
	sprite: AnimatedSprite2D,
	parent_offset: Vector2,
	sort_compensation: float
) -> float:
	if not sprite.visible or sprite.sprite_frames == null:
		return 0.0

	var frame_count := sprite.sprite_frames.get_frame_count(sprite.animation)
	if frame_count <= 0:
		return 0.0

	var texture := sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	if texture == null:
		return 0.0

	return _sprite_deepest_y_from_texture(
		parent_offset + sprite.position + Vector2(0.0, sort_compensation),
		sprite.offset,
		sprite.centered,
		sprite.scale,
		texture
	)

static func _sprite_deepest_y(sprite: Sprite2D, parent_offset: Vector2, sort_compensation: float) -> float:
	if not sprite.visible or sprite.texture == null:
		return 0.0

	return _sprite_deepest_y_from_texture(
		parent_offset + sprite.position + Vector2(0.0, sort_compensation),
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
