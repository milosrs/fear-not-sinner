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

@export var walk_duration: float
@export var walk_stop_duration: float
@export var sprint_duration: float
@export var sprint_stop_duration: float
@export var walk_sprint_duration: float
@export var sprint_walk_duration: float
@export var roll_duration: float

func move(
	sprite: Node2D, 
	to_state: States.MoveState, 
	fsm: MovementFSM, 
	current_speed: float,
) -> void:
	if fsm.current == to_state:
		return
		
	var transition: MovementTransition
	var target_speed: float
	
	match [fsm.current, to_state]:
		[States.MoveState.IDLE, States.MoveState.WALK]:
			transition = MovementTransition.new(
				fsm.current,
				to_state,
				walk_duration,
				walk_curve,
			)
			target_speed = _get_target_speed(walk_curve)
		[States.MoveState.WALK, States.MoveState.IDLE]:
			transition = MovementTransition.new(
				fsm.current,
				to_state,
				walk_stop_duration,
				walk_stop_curve,
			)
			target_speed = _get_target_speed(walk_stop_curve)
		[States.MoveState.WALK, States.MoveState.SPRINT]:
			transition = MovementTransition.new(
				fsm.current,
				to_state,
				walk_sprint_duration,
				walk_sprint_curve,
			)
			target_speed = _get_target_speed(walk_sprint_curve)
		[States.MoveState.SPRINT, States.MoveState.IDLE]:
			transition = MovementTransition.new(
				fsm.current,
				to_state,
				sprint_stop_duration,
				sprint_stop_curve,
			)
			target_speed = _get_target_speed(sprint_stop_curve)
		[States.MoveState.SPRINT, States.MoveState.IDLE]:
			transition = MovementTransition.new(
				fsm.current,
				to_state,
				sprint_walk_duration,
				sprint_stop_curve,
			)
			target_speed = _get_target_speed(walk_curve)
		[_, States.MoveState.ROLL]:
			transition = MovementTransition.new(
				fsm.current,
				to_state,
				roll_duration,
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
	return c.get_point_in(c.point_count-1).y
