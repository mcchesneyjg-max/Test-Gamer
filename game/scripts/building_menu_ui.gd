extends CanvasLayer

@onready var _hint_label: Label = $Panel/Margin/VBox/HintLabel
@onready var _tree_button: Button = $Panel/Margin/VBox/Buttons/TreeButton
@onready var _camp_button: Button = $Panel/Margin/VBox/Buttons/CampButton
@onready var _station_button: Button = $Panel/Margin/VBox/Buttons/StationButton
@onready var _lodge_button: Button = $Panel/Margin/VBox/Buttons/LodgeButton
@onready var _storage_button: Button = $Panel/Margin/VBox/Buttons/StorageButton
@onready var _cancel_button: Button = $Panel/Margin/VBox/Buttons/CancelButton

var _tree_placer: Node2D
var _log_storage_ui: CanvasLayer

const HINTS := {
	TreePlacer.PlacementMode.NONE: "Select a building, then click the map to place it.",
	TreePlacer.PlacementMode.TREE: "Click grass to place a tree.",
	TreePlacer.PlacementMode.LUMBER_CAMP: "Click grass to place a lumber camp.",
	TreePlacer.PlacementMode.HAULER_STATION: "Click grass to place a hauler station.",
	TreePlacer.PlacementMode.FORESTER_LODGE: "Click grass to place a forester lodge (4x4 tiles).",
}

func setup(tree_placer: Node2D, log_storage_ui: CanvasLayer) -> void:
	_tree_placer = tree_placer
	_log_storage_ui = log_storage_ui
	_refresh_hint(TreePlacer.PlacementMode.NONE)

func _on_tree_pressed() -> void:
	_set_mode(TreePlacer.PlacementMode.TREE)

func _on_camp_pressed() -> void:
	_set_mode(TreePlacer.PlacementMode.LUMBER_CAMP)

func _on_station_pressed() -> void:
	_set_mode(TreePlacer.PlacementMode.HAULER_STATION)

func _on_lodge_pressed() -> void:
	_set_mode(TreePlacer.PlacementMode.FORESTER_LODGE)

func _on_storage_pressed() -> void:
	if _tree_placer != null:
		_tree_placer.clear_placement_mode()
	_tree_button.button_pressed = false
	_camp_button.button_pressed = false
	_station_button.button_pressed = false
	_lodge_button.button_pressed = false
	_cancel_button.button_pressed = false
	_storage_button.button_pressed = true
	_hint_label.text = "Drag on the map to draw a log storage area (1-5 pile slots). Esc to cancel."
	if _log_storage_ui != null and _log_storage_ui.has_method("start_draw_mode"):
		_log_storage_ui.start_draw_mode()

func _on_cancel_pressed() -> void:
	if _tree_placer != null:
		_tree_placer.clear_placement_mode()
	_refresh_hint(TreePlacer.PlacementMode.NONE)

func _set_mode(mode: TreePlacer.PlacementMode) -> void:
	if _tree_placer == null:
		return
	_tree_placer.set_placement_mode(mode)
	_refresh_hint(mode)

func _refresh_hint(mode: TreePlacer.PlacementMode) -> void:
	_update_button_states(mode)
	_hint_label.text = HINTS.get(mode, HINTS[TreePlacer.PlacementMode.NONE])

func _update_button_states(mode: TreePlacer.PlacementMode) -> void:
	_tree_button.button_pressed = mode == TreePlacer.PlacementMode.TREE
	_camp_button.button_pressed = mode == TreePlacer.PlacementMode.LUMBER_CAMP
	_station_button.button_pressed = mode == TreePlacer.PlacementMode.HAULER_STATION
	_lodge_button.button_pressed = mode == TreePlacer.PlacementMode.FORESTER_LODGE
	_storage_button.button_pressed = false
	_cancel_button.button_pressed = mode == TreePlacer.PlacementMode.NONE
