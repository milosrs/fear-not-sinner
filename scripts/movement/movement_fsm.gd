extends Resource
class_name MovementFSM

const States = preload("res://scripts/movement/movement_states.gd")

var sprite:Node
var current: States.MoveState
var target: States.MoveState
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
	sprite = _sprite
	transition_time = 0
	from = current_speed
	to = target_speed
	transition = _transition
	
	if transition != null:
		current = _transition.from
		target = _transition.to

func update(delta: float) -> float:
	if transition == null:
		return to
	
	transition_time += delta
	
	var t = clamp(transition_time/transition.duration, 0.0, 1.0)
	if t >= 1.0:
		current = target
		transition = null
		return to
	
	var eased = transition.curve.sample(0, t)
	var speed = lerp(from, to, eased)
	
	return speed
