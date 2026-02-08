extends Resource
class_name MovementFSM

const States = preload("res://scripts/movement/movement_states.gd")

var sprite:Node
var current: States.MoveState
var transition: MovementTransition
var transition_time: float
var from: float
var to: float

func start_transition(
	_sprite: Node, 
	_transition: MovementTransition,
	current_speed: float,
	target_speed: float,
) -> void:
	if transition != null and transition == _transition:
		return

	sprite = _sprite
	transition_time = 0
	from = current_speed
	to = target_speed
	transition = _transition
	
	if transition != null:
		current = _transition.to

func update(delta: float) -> float:
	if transition == null:
		return to
	
	transition_time += delta
	
	var t = clamp(transition_time/transition.duration, 0.0, 1.0)
	if t >= 1.0:
		transition = null
		print("Speed: ", to, " t: ", t, " transition_time: ", transition_time)
		return to
	
	var speed_point = transition.curve.sample(0, t)
	
	print("Speed: ", speed_point, " t: ", t, " transition_time: ", transition_time)

	return speed_point.y
