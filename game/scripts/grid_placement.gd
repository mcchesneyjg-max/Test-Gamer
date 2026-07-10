class_name GridPlacement
extends RefCounted

const TILE_SIZE := 32

static func mouse_tile_coords(tilemap: TileMap) -> Vector2i:
	return tilemap.local_to_map(tilemap.get_global_mouse_position())

static func tile_to_world(tilemap: TileMap, tile_coords: Vector2i) -> Vector2:
	return tilemap.map_to_local(tile_coords)

static func is_cardinal_tile_in_bounds(tile_coords: Vector2i, map_size: Vector2i = Vector2i(250, 250)) -> bool:
	return tile_coords.x >= 0 and tile_coords.y >= 0 and tile_coords.x < map_size.x and tile_coords.y < map_size.y

static func cardinal_rect_from_tiles(a: Vector2i, b: Vector2i) -> Rect2i:
	var x0 := mini(a.x, b.x)
	var y0 := mini(a.y, b.y)
	var x1 := maxi(a.x, b.x)
	var y1 := maxi(a.y, b.y)
	return Rect2i(x0, y0, x1 - x0 + 1, y1 - y0 + 1)

static func footprint_tiles(top_left: Vector2i, size: Vector2i) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for y in range(size.y):
		for x in range(size.x):
			tiles.append(top_left + Vector2i(x, y))
	return tiles
