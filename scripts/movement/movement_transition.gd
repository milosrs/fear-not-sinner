class_name MovementTransition

const States = preload("res://scripts/movement/movement_states.gd")

var from: States.MoveState
var to: States.MoveState
var duration: float
var curve: Curve2D

func _init(_from, _to, _duration, _curve):
	from = _from
	to = _to
	duration = _duration
	curve = _curve
