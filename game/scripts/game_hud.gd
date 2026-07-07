extends CanvasLayer

@onready var _wood_label: Label = $MarginContainer/VBoxContainer/WoodLogsLabel
@onready var _tree_label: Label = $MarginContainer/VBoxContainer/TreesLabel
@onready var _sapling_label: Label = $MarginContainer/VBoxContainer/SaplingsLabel

func _ready() -> void:
	_update_wood_label()
	_update_tree_label()
	_update_sapling_label()
	Warehouse.wood_logs_changed.connect(func(_v): _update_wood_label())
	TreeRegistry.tree_count_changed.connect(func(_c): _update_tree_label())
	SaplingRegistry.sapling_count_changed.connect(func(_c): _update_sapling_label())

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_T:
		Warehouse.add_wood_logs(1)

func _update_wood_label() -> void:
	_wood_label.text = "Wood Logs: %d" % Warehouse.wood_logs

func _update_tree_label() -> void:
	_tree_label.text = "Trees: %d" % TreeRegistry.get_tree_count()

func _update_sapling_label() -> void:
	_sapling_label.text = "Saplings: %d" % SaplingRegistry.get_sapling_count()
