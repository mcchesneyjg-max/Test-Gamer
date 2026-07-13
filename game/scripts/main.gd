extends Node2D

@onready var _tilemap: TileMap = $TileMap
@onready var _zone_overlay: Node2D = $ForesterZoneOverlay
@onready var _forester_ui: CanvasLayer = $ForesterUi

func _ready() -> void:
	_forester_ui.setup(_tilemap, _zone_overlay)
	_zone_overlay.setup(_tilemap)

	for lodge in ForesterLodgeRegistry.get_active_lodges():
		_forester_ui.register_new_lodge(lodge)
