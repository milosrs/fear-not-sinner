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

func move(
	sprite: Node2D, 
	to_state: States.MoveState, 
	fsm: MovementFSM, 
	current_speed: float,
) -> void:
	print("Transitioning from ", fsm.current, " to ", to_state)
	if fsm.current == to_state:
		return
		
	var transition: MovementTransition
	var target_speed: float
	var duration: float
	
	match [fsm.current, to_state]:
		[States.MoveState.IDLE, States.MoveState.WALK]:
			transition = MovementTransition.new(
				fsm.current,
				to_state,
				_get_duration(walk_curve),
				walk_curve,
			)
			target_speed = _get_target_speed(walk_curve)
		[States.MoveState.WALK, States.MoveState.IDLE]:
			transition = MovementTransition.new(
				fsm.current,
				to_state,
				_get_duration(walk_stop_curve),
				walk_stop_curve,
			)
			target_speed = _get_target_speed(walk_stop_curve)
		[States.MoveState.WALK, States.MoveState.SPRINT]:
			transition = MovementTransition.new(
				fsm.current,
				to_state,
				_get_duration(walk_sprint_curve),
				walk_sprint_curve,
			)
			target_speed = _get_target_speed(walk_sprint_curve)
		[States.MoveState.SPRINT, States.MoveState.IDLE]:
			transition = MovementTransition.new(
				fsm.current,
				to_state,
				_get_duration(sprint_stop_curve),
				sprint_stop_curve,
			)
			target_speed = _get_target_speed(sprint_stop_curve)
		[States.MoveState.SPRINT, States.MoveState.IDLE]:
			transition = MovementTransition.new(
				fsm.current,
				to_state,
				_get_duration(sprint_stop_curve),
				sprint_stop_curve,
			)
			target_speed = _get_target_speed(walk_curve)
		[_, States.MoveState.ROLL]:
			transition = MovementTransition.new(
				fsm.current,
				to_state,
				_get_duration(roll_curve),
				roll_curve,
			)
			target_speed = _get_target_speed(roll_curve)
		_:
			pass
		
	fsm.start_transition(
		sprite,
		transition,
		current_speed,
		target_speed,
	)
	
func _get_target_speed(c: Curve2D) -> float:
	return c.get_point_position(c.point_count-1).y

func _get_duration(c: Curve2D) -> float:
	return c.get_point_position(c.point_count-1).x