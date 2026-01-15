class_name MovementFSM extends Node

var sprite:Sprite2D
var current: MovementTransition.states.MoveState
var target: MovementTransition.states.MoveState
var transition: MovementTransition
var transitionTime: float
var from: float
var to: float

func start_transition(_sprite: Sprite2D, _transition: MovementTransition, currentSpeed: float, targetSpeed: float):
	sprite = _sprite
	transition = _transition
	transitionTime = 0
	current = _transition.from
	target = _transition.to
	from = currentSpeed
	to = targetSpeed

func update(delta: float) -> float:
	if transition == null:
		return to
	
	transitionTime += delta
	
	var t = clamp(transitionTime/transition.duration, 0.0, 1.0)
	if t >= 1.0:
		current = target
		transition = null
	
	var eased = transition.curve.sample(t)
	var speed = lerp(from, to, eased)
	
	return speed


#func walk(sprite: Sprite2D, speed: float, duration: float):
	#var tween := create_tween()
	#tween.tween_property(
		#sprite,
		#"speed",
		#speed,
		#duration,
	#).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
#
#func stop_walk(sprite: Sprite2D, duration: float):
	#var tween := create_tween()
	#tween.tween_property(
		#sprite,
		#"speed",
		#0,
		#duration,
	#).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	#
#func sprint(sprite: Sprite2D, speed: float, duration: float):
	#var tween := create_tween()
	#tween.tween_property(
		#sprite,
		#"speed",
		#speed,
		#duration,
	#).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
#
#func walk_sprint(sprite: Sprite2D, speed: float, duration: float):
	#var tween := create_tween()
	#tween.tween_property(
		#sprite,
		#"speed",
		#speed,
		#duration,
	#).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	#
#func roll(sprite: Sprite2D, roll_speed: float, walk_speed: float, duration: float):
	#var tween := create_tween()
	#tween.tween_property(
		#sprite,
		#"speed",
		#roll_speed,
		#duration,
	#).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	#
	#tween.tween_property(
		#sprite,
		#"speed",
		#walk_speed,
		#0.1
	#)
