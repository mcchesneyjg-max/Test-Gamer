extends CanvasLayer

@onready var _label: Label = $MarginContainer/WoodLogsLabel

func _ready() -> void:
	_update_label()
	Warehouse.wood_logs_changed.connect(_on_wood_logs_changed)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_T:
			Warehouse.add_wood_logs(1)

func _on_wood_logs_changed(_new_total: int) -> void:
	_update_label()

func _update_label() -> void:
	_label.text = "Wood Logs: %d" % Warehouse.wood_logs
