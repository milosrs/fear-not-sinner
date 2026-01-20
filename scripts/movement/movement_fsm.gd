extends Resource
class_name MovementFSM

var sprite:Node
var current: MovementTransition.states.MoveState
var target: MovementTransition.states.MoveState
var transition: MovementTransition
var transitionTime: float
var from: float
var to: float

func start_transition(_sprite: Node, _transition: MovementTransition, currentSpeed: float, targetSpeed: float):
	sprite = _sprite
	transitionTime = 0
	from = currentSpeed
	to = targetSpeed
	transition = _transition
	
	if transition != null:
		current = _transition.from
		target = _transition.to

func update(delta: float) -> float:
	if transition == null:
		return to
	
	transitionTime += delta
	
	var t = clamp(transitionTime/transition.duration, 0.0, 1.0)
	if t >= 1.0:
		current = target
		transition = null
		return to
	
	var eased = transition.curve.sample(0, t)
	var speed = lerp(from, to, eased)
	
	return speed
