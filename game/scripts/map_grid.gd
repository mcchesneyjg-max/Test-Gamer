extends TileMap

const MAP_SIZE := Vector2i(250, 250)

func _ready() -> void:
	for x in MAP_SIZE.x:
		for y in MAP_SIZE.y:
			set_cell(0, Vector2i(x, y), 0, Vector2i((x + y) % 3, 0))
