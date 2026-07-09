extends Camera2D

const ZOOM_MIN := 0.08
const ZOOM_MAX := 2.5
const ZOOM_STEP := 0.08

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_apply_zoom(ZOOM_STEP)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_apply_zoom(-ZOOM_STEP)

func _apply_zoom(delta: float) -> void:
	var next := zoom + Vector2.ONE * delta
	next.x = clampf(next.x, ZOOM_MIN, ZOOM_MAX)
	next.y = clampf(next.y, ZOOM_MIN, ZOOM_MAX)
	zoom = next
