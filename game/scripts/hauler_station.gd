extends Node2D

@export_range(1, 8, 1) var hauler_count: int = 2

@onready var _hauler_label: Label = $HaulerLabel
@onready var _idle_haulers: Node2D = $IdleHaulers

func _ready() -> void:
	HaulerStationRegistry.register_station(self)
	_update_hauler_label()
	_refresh_idle_hauler_markers()

func _exit_tree() -> void:
	HaulerStationRegistry.unregister_station(self)

func get_hauler_count() -> int:
	return hauler_count

func _update_hauler_label() -> void:
	_hauler_label.text = "Haulers: %d" % hauler_count

func _refresh_idle_hauler_markers() -> void:
	if _idle_haulers == null:
		return

	var slots := _idle_haulers.get_child_count()
	for i in slots:
		var marker := _idle_haulers.get_child(i) as ColorRect
		if marker:
			marker.visible = i < hauler_count
