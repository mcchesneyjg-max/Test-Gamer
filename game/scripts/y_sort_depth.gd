class_name YSortDepth
extends RefCounted

const ALPHA_THRESHOLD := 0.04
const APPLIED_META_KEY := "_y_sort_applied"
const LOGICAL_POS_META_KEY := "_y_sort_logical_pos"
const STABLE_DEPTH_META_KEY := "_y_sort_stable_depth"
const INITIALIZED_META_KEY := "_y_sort_initialized"

static var _opaque_bottom_cache: Dictionary = {}

static func apply_to_entity(entity: Node2D, force_recompute_depth: bool = false) -> void:
	if entity == null:
		return

	var applied: float = entity.get_meta(APPLIED_META_KEY, 0.0)
	var logical_pos: Vector2
	if entity.has_meta(LOGICAL_POS_META_KEY):
		logical_pos = entity.get_meta(LOGICAL_POS_META_KEY)
	else:
		logical_pos = Vector2(roundf(entity.position.x), roundf(entity.position.y))
		entity.set_meta(LOGICAL_POS_META_KEY, logical_pos)

	var expected_sort_pos := logical_pos + Vector2(0.0, applied)
	if entity.position.distance_squared_to(expected_sort_pos) > 0.01:
		if entity.position.distance_squared_to(logical_pos) < entity.position.distance_squared_to(expected_sort_pos):
			pass
		else:
			logical_pos += entity.position - expected_sort_pos
			logical_pos = Vector2(roundf(logical_pos.x), roundf(logical_pos.y))

	var sprites := _collect_sprites(entity)
	var stable_depth := _get_stable_depth(entity, sprites, applied, force_recompute_depth)

	if not entity.has_meta(INITIALIZED_META_KEY):
		_apply_depth_compensation(sprites, applied, stable_depth)
		entity.set_meta(INITIALIZED_META_KEY, true)
	elif force_recompute_depth and roundf(stable_depth) != roundf(applied):
		_apply_depth_compensation(sprites, applied, stable_depth)

	applied = entity.get_meta(APPLIED_META_KEY, stable_depth)
	entity.set_meta(LOGICAL_POS_META_KEY, logical_pos)
	entity.position = Vector2(
		roundf(logical_pos.x),
		roundf(logical_pos.y + applied)
	)

static func _apply_depth_compensation(
	sprites: Array[Dictionary],
	current_applied: float,
	target_depth: float
) -> void:
	var delta := target_depth - current_applied
	if absf(delta) < 0.001:
		return

	for sprite_entry in sprites:
		var sprite := sprite_entry["sprite"] as Node2D
		sprite.position.y = roundf(sprite.position.y - delta)

static func _get_stable_depth(
	entity: Node2D,
	sprites: Array[Dictionary],
	applied: float,
	force_recompute: bool
) -> float:
	if not force_recompute and entity.has_meta(STABLE_DEPTH_META_KEY):
		return float(entity.get_meta(STABLE_DEPTH_META_KEY))

	var deepest := 0.0
	for sprite_entry in sprites:
		deepest = maxf(
			deepest,
			_stable_sprite_depth(entity, sprite_entry["sprite"], sprite_entry["offset"], applied)
		)

	deepest = roundf(deepest)
	entity.set_meta(STABLE_DEPTH_META_KEY, deepest)
	entity.set_meta(APPLIED_META_KEY, deepest)
	return deepest

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

static func _stable_sprite_depth(
	entity: Node2D,
	sprite: Node,
	parent_offset: Vector2,
	sort_compensation: float
) -> float:
	if sprite is Sprite2D:
		return _sprite_deepest_y(entity, sprite as Sprite2D, parent_offset, sort_compensation)
	if sprite is AnimatedSprite2D:
		return _animated_sprite_stable_deepest_y(sprite as AnimatedSprite2D, parent_offset, sort_compensation)
	return 0.0

static func _animated_sprite_stable_deepest_y(
	sprite: AnimatedSprite2D,
	parent_offset: Vector2,
	sort_compensation: float
) -> float:
	if not sprite.visible or sprite.sprite_frames == null:
		return 0.0

	var deepest := 0.0
	for animation_name in sprite.sprite_frames.get_animation_names():
		var frame_count := sprite.sprite_frames.get_frame_count(animation_name)
		for frame_index in range(frame_count):
			var texture := sprite.sprite_frames.get_frame_texture(animation_name, frame_index)
			if texture == null:
				continue
			deepest = maxf(
				deepest,
				_sprite_deepest_y_from_texture(
					parent_offset + sprite.position + Vector2(0.0, sort_compensation),
					sprite.offset,
					sprite.centered,
					sprite.scale,
					texture
				)
			)
	return deepest

static func _sprite_deepest_y(
	entity: Node2D,
	sprite: Sprite2D,
	parent_offset: Vector2,
	sort_compensation: float
) -> float:
	if not sprite.visible:
		return 0.0

	var sprite_position := parent_offset + sprite.position + Vector2(0.0, sort_compensation)
	var deepest := 0.0
	if sprite.texture != null:
		deepest = _sprite_deepest_y_from_texture(
			sprite_position,
			sprite.offset,
			sprite.centered,
			sprite.scale,
			sprite.texture
		)

	for texture in entity.get_meta("_y_sort_extra_textures", []):
		if texture is Texture2D:
			deepest = maxf(
				deepest,
				_sprite_deepest_y_from_texture(
					sprite_position,
					sprite.offset,
					sprite.centered,
					sprite.scale,
					texture
				)
			)
	return deepest

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
