class_name GridMovement
extends RefCounted

class StepResult:
	var step := Vector2.ZERO
	var direction := Vector2.ZERO

static func snap_eight_directions(raw: Vector2) -> Vector2:
	if raw.length_squared() < 0.01:
		return Vector2.ZERO
	return Vector2.from_angle(snappedf(raw.angle(), PI / 4.0))

static func step_toward(
	current_position: Vector2,
	target_position: Vector2,
	speed: float,
	delta: float,
	locked_direction: Vector2 = Vector2.ZERO
) -> StepResult:
	var result := StepResult.new()
	var offset := target_position - current_position
	if offset.length_squared() <= 0.001:
		return result

	var desired := snap_eight_directions(offset)
	var direction := desired

	if locked_direction.length_squared() > 0.001:
		var projected_step := locked_direction * speed * delta
		var distance_before := offset.length_squared()
		var distance_after := (offset - projected_step).length_squared()
		if distance_after < distance_before:
			direction = locked_direction

	result.direction = direction
	result.step = direction * speed * delta
	return result
