class_name MovementTransition

const states = preload("res://scripts/movement/movement_states.gd")

var from: states.MoveState
var to: states.MoveState
var duration: float
var curve: Curve2D

func _init(_from, _to, _duration, _curve):
	from = _from
	to = _to
	duration = _duration
	curve = _curve
