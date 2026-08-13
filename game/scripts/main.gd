extends Node2D

@onready var _tilemap: TileMap = $TileMap
@onready var _zone_overlay: Node2D = $ForesterZoneOverlay
@onready var _forester_ui: CanvasLayer = $ForesterUi
@onready var _lumber_camp_ui: CanvasLayer = $LumberCampUi
@onready var _warehouse_ui: CanvasLayer = $WarehouseUi

func _ready() -> void:
	_forester_ui.setup(_tilemap, _zone_overlay)
	_lumber_camp_ui.setup(_tilemap)
	_warehouse_ui.setup(_tilemap, _zone_overlay)
	_zone_overlay.setup(_tilemap)

	for lodge in ForesterLodgeRegistry.get_active_lodges():
		_forester_ui.register_new_lodge(lodge)
