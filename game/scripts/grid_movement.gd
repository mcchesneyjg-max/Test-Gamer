class_name GridMovement
extends RefCounted

class StepResult:
	var step := Vector2.ZERO
	var direction := Vector2.ZERO

const CLOSE_RANGE_DISTANCE := 4.0

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
	var distance := offset.length()
	if distance <= 0.001:
		return result

	var desired := snap_eight_directions(offset)
	var direction := desired

	if locked_direction.length_squared() > 0.001:
		if distance <= CLOSE_RANGE_DISTANCE:
			direction = locked_direction
		elif locked_direction.dot(offset) > 0.0:
			direction = locked_direction

	var step_length: float = minf(speed * delta, distance)
	if step_length <= 0.001:
		return result

	result.direction = direction
	result.step = direction * step_length
	return result
