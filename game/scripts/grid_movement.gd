class_name GridMovement
extends RefCounted

static func snap_eight_directions(raw: Vector2) -> Vector2:
	if raw.length_squared() < 0.01:
		return Vector2.ZERO
	return Vector2.from_angle(snappedf(raw.angle(), PI / 4.0))

static func step_toward(
	current_position: Vector2,
	target_position: Vector2,
	speed: float,
	delta: float
) -> Vector2:
	var offset := target_position - current_position
	if offset.length_squared() <= 0.001:
		return Vector2.ZERO
	var direction := snap_eight_directions(offset)
	return direction * speed * delta
