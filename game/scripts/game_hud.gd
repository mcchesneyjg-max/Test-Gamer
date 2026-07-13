extends CanvasLayer

@onready var _wood_label: Label = $MarginContainer/VBoxContainer/WoodLogsLabel
@onready var _tree_label: Label = $MarginContainer/VBoxContainer/TreesLabel
@onready var _sapling_label: Label = $MarginContainer/VBoxContainer/SaplingsLabel
@onready var _camp_logs_label: Label = $MarginContainer/VBoxContainer/CampLogsLabel
@onready var _worker_pool_label: Label = $MarginContainer/VBoxContainer/WorkerPoolLabel

var _refresh_timer: float = 0.0

func _ready() -> void:
	_update_wood_label()
	_update_tree_label()
	_update_sapling_label()
	_update_camp_logs_label()
	_update_worker_pool_label()
	Warehouse.wood_logs_changed.connect(func(_v): _update_wood_label())
	TreeRegistry.tree_count_changed.connect(func(_c): _update_tree_label())
	SaplingRegistry.sapling_count_changed.connect(func(_c): _update_sapling_label())
	WorkerPool.pool_changed.connect(func(_a, _b, _c): _update_worker_pool_label())

func _process(delta: float) -> void:
	_refresh_timer += delta
	if _refresh_timer < 0.5:
		return
	_refresh_timer = 0.0
	_update_camp_logs_label()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_T:
		Warehouse.add_wood_logs(1)

func _update_wood_label() -> void:
	_wood_label.text = "Wood Logs: %d" % Warehouse.wood_logs

func _update_tree_label() -> void:
	var counts := TreeRegistry.get_variant_counts()
	_tree_label.text = "Trees: %d (1:%d 2:%d 3:%d)" % [
		TreeRegistry.get_tree_count(),
		counts.get("summer_tree_1", 0),
		counts.get("summer_tree_2", 0),
		counts.get("summer_tree_3", 0),
	]

func _update_sapling_label() -> void:
	_sapling_label.text = "Saplings: %d" % SaplingRegistry.get_sapling_count()

func _update_worker_pool_label() -> void:
	_worker_pool_label.text = "Workers available: %d" % WorkerPool.get_available()

func _update_camp_logs_label() -> void:
	var waiting := 0
	for camp in CampRegistry.get_active_camps():
		if camp.has_method("get_output_log_count"):
			waiting += camp.get_output_log_count()
	_camp_logs_label.text = "Camp Logs (waiting): %d" % waiting
