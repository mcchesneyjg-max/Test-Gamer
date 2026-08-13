extends Node2D

@onready var _tilemap: TileMap = $TileMap
@onready var _zone_overlay: Node2D = $ForesterZoneOverlay
@onready var _forester_ui: CanvasLayer = $ForesterUi
@onready var _lumber_camp_ui: CanvasLayer = $LumberCampUi
@onready var _log_storage_ui: CanvasLayer = $LogStorageUi
@onready var _tree_placer: TreePlacer = $TreePlacer
@onready var _building_menu_ui: CanvasLayer = $BuildingMenuUi

func _ready() -> void:
	_forester_ui.setup(_tilemap, _zone_overlay)
	_lumber_camp_ui.setup(_tilemap)
	_log_storage_ui.setup(_tilemap, _zone_overlay)
	_building_menu_ui.setup(_tree_placer, _log_storage_ui)
	_zone_overlay.setup(_tilemap)

	for lodge in ForesterLodgeRegistry.get_active_lodges():
		_forester_ui.register_new_lodge(lodge)
