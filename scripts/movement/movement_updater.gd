extends Resource
class_name MovementUpdate

const States := preload("res://scripts/movement/movement_states.gd")

@export var walk_curve: Curve2D
@export var walk_stop_curve: Curve2D
@export var sprint_curve: Curve2D
@export var sprint_stop_curve: Curve2D
@export var walk_sprint_curve: Curve2D
@export var sprint_walk_curve: Curve2D
@export var roll_curve: Curve2D

class Movement:
	var curve_name: String
	var duration: float = -1.0
	var speed_mult: float = 1.0
	var has_target_speed: bool = false
	var target_speed: float = 0.0

	func _init(
		_curve_name: String = "", 
		_duration: float = -1.0, 
		_speed_mult: float = 1.0, 
		_has_target_speed: bool = false, 
		_target_speed: float = 0.0,
	) -> void:
		curve_name = _curve_name
		duration = _duration
		speed_mult = _speed_mult
		has_target_speed = _has_target_speed
		target_speed = _target_speed

var _transitions: Dictionary[Array, Movement] = {
	[States.MoveState.IDLE, States.MoveState.WALK]: Movement.new("walk_curve", 0.1, 1.0),
	[States.MoveState.WALK, States.MoveState.IDLE]: Movement.new("walk_stop_curve", -1.0, 1.0),
	[States.MoveState.WALK, States.MoveState.SPRINT]: Movement.new("walk_sprint_curve", -1.0, 1.0),
	[States.MoveState.SPRINT, States.MoveState.WALK]: Movement.new("sprint_walk_curve", -1.0, 1.0),
	[States.MoveState.SPRINT, States.MoveState.IDLE]: Movement.new("sprint_stop_curve", -1.0, 1.0),
	[States.MoveState.JUMP, States.MoveState.IDLE]: Movement.new("", 0.1, 1.0, true, 0.0),
	[States.MoveState.CROUCH, States.MoveState.WALK_CROUCH]: Movement.new("walk_curve", 0.05, 0.45),
	[States.MoveState.CROUCH, States.MoveState.WALK]: Movement.new("walk_curve", 0.05, 1.0),
	[States.MoveState.IDLE, States.MoveState.WALK_CROUCH]: Movement.new("walk_curve", 0.05, 0.45),
	[States.MoveState.WALK, States.MoveState.WALK_CROUCH]: Movement.new("walk_curve", 0.05, 0.45),
	[States.MoveState.WALK_CROUCH, States.MoveState.WALK]: Movement.new("walk_curve", 0.05, 1.0),
	[States.MoveState.WALK_CROUCH, States.MoveState.IDLE]: Movement.new("walk_stop_curve", -1.0, 0.5),
}

func move(
	sprite: Node2D, 
	to_state: States.MoveState, 
	fsm: MovementFSM, 
	current_speed: float,
) -> void:		
	var transition: MovementTransition
	var target_speed: float = 0.0

	# Special-cases: CROUCH stops horizontal movement, JUMP keeps current horizontal target
	if to_state == States.MoveState.CROUCH:
		fsm.current = to_state
		fsm.transition = null
		fsm.to = 0.0
		return

	if to_state == States.MoveState.JUMP:
		fsm.current = to_state
		fsm.transition = null
		return

	var key = [fsm.current, to_state]
	if not _transitions.has(key):
		return

	var def: Movement = _transitions[key]
	var curve: Curve2D = null
	if def.curve_name != "":
		curve = get(def.curve_name)

	var duration: float = def.duration
	if duration < 0.0:
		duration = _get_duration(curve) if curve != null else 0.1

	if def.has_target_speed:
		target_speed = def.target_speed
	elif curve != null:
		target_speed = _get_target_speed(curve) * def.speed_mult
	else:
		target_speed = 0.0

	transition = MovementTransition.new(fsm.current, to_state, duration, curve)
	fsm.start_transition(sprite, transition, current_speed, target_speed)
	
func _get_target_speed(c: Curve2D) -> float:
	return c.get_point_position(c.point_count-1).y

func _get_duration(c: Curve2D) -> float:
	return c.get_point_position(c.point_count-1).x
