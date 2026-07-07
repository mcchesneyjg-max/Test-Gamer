extends RefCounted

## Per-building stockpile slot (input or output).
signal changed(current_amount: int, capacity_amount: int)

var capacity: int = 0
var current: int = 0

func _init(max_capacity: int = 0, starting_amount: int = 0) -> void:
	capacity = maxi(max_capacity, 0)
	current = clampi(starting_amount, 0, capacity)

func is_enabled() -> bool:
	return capacity > 0

func is_full() -> bool:
	return is_enabled() and current >= capacity

func is_empty() -> bool:
	return current <= 0

func free_space() -> int:
	return maxi(capacity - current, 0)

func try_add(amount: int) -> int:
	if not is_enabled() or amount <= 0 or is_full():
		return 0
	var added: int = mini(amount, free_space())
	current += added
	changed.emit(current, capacity)
	return added

func try_remove(amount: int) -> int:
	if amount <= 0 or is_empty():
		return 0
	var removed: int = mini(amount, current)
	current -= removed
	changed.emit(current, capacity)
	return removed
