extends Node

const BuildingStorage := preload("res://scripts/building_storage.gd")
const WOOD_LOG_TEXTURE := preload("res://assets/sprites/wood_log.png")

## Reusable input/output storage for production buildings.
signal input_changed(current_amount: int, capacity_amount: int)
signal output_changed(current_amount: int, capacity_amount: int)

@export var input_capacity: int = 0
@export var output_capacity: int = 20

var input
var output

@onready var _input_label: Label = $InputLabel
@onready var _output_label: Label = $OutputLabel
@onready var _output_pile: Node2D = $OutputPile

func _ready() -> void:
	input = BuildingStorage.new(input_capacity)
	output = BuildingStorage.new(output_capacity)
	input.changed.connect(_on_input_changed)
	output.changed.connect(_on_output_changed)
	_setup_output_pile_textures()
	_refresh_labels()
	_refresh_output_pile()

func _setup_output_pile_textures() -> void:
	if _output_pile == null:
		return
	for child in _output_pile.get_children():
		var slot := child as Sprite2D
		if slot:
			slot.texture = WOOD_LOG_TEXTURE

func output_is_full() -> bool:
	return output.is_full()

func input_is_empty() -> bool:
	return not input.is_enabled() or input.is_empty()

func _on_input_changed(current_amount: int, capacity_amount: int) -> void:
	input_changed.emit(current_amount, capacity_amount)
	_refresh_labels()

func _on_output_changed(current_amount: int, capacity_amount: int) -> void:
	output_changed.emit(current_amount, capacity_amount)
	_refresh_labels()
	_refresh_output_pile()

func _refresh_labels() -> void:
	if _input_label:
		if input.is_enabled():
			_input_label.visible = true
			_input_label.text = "In: %d/%d" % [input.current, input.capacity]
		else:
			_input_label.visible = false

	if _output_label:
		if output.is_enabled():
			_output_label.visible = true
			_output_label.text = "Out: %d/%d" % [output.current, output.capacity]
		else:
			_output_label.visible = false

func _refresh_output_pile() -> void:
	if _output_pile == null or not output.is_enabled():
		return

	var slots := _output_pile.get_child_count()
	if slots <= 0:
		return

	var filled_slots := int(ceil(float(output.current) / float(output.capacity) * float(slots)))
	filled_slots = clampi(filled_slots, 0, slots)

	for i in slots:
		var slot := _output_pile.get_child(i) as CanvasItem
		if slot:
			slot.visible = i < filled_slots
