extends AnimatedSprite2D

@export var walk_start_curve: Curve
@export var walk_stop_curve: Curve
@export var sprint_start_curve: Curve
@export var sprint_stop_curve: Curve
@export var walk_to_sprint_curve: Curve
@export var roll_curve: Curve

func apply_transition(
	from_speed: float,
	to_speed: float,
	curve: Curve,
	elapsed: float,
	duration: float
) -> float:
	var t := clampf(elapsed / duration, 0.0, 1.0)
	var eased := curve.sample(t)
	return lerp(from_speed, to_speed, eased)
