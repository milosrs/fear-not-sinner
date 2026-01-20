extends Resource
class_name MovementUpdate

const states := preload("res://scripts/movement/movement_states.gd")

@export var walkCurve: Curve2D
@export var walkStopCurve: Curve2D
@export var sprintCurve: Curve2D
@export var sprintStopCurve: Curve2D
@export var walkToSprintCurve: Curve2D
@export var sprintToWalkCurve: Curve2D
@export var rollCurve: Curve2D

@export var walkDuration: float
@export var walkStopDuration: float
@export var sprintDuration: float
@export var sprintStopDuration: float
@export var walkToSprintDuration: float
@export var sprintToWalkDuration: float
@export var rollDuration: float

func move(sprite: Node2D, toState: states.MoveState, fsm: MovementFSM, currentSpeed: float):
	print("CURRENT - TO STATE: ", states.new().move_state_string(toState), " ", states.new().move_state_string(fsm.current))
	if fsm.current == toState:
		return
		
	var transition: MovementTransition
	var targetSpeed: float
	
	match [fsm.current, toState]:
		[states.MoveState.IDLE, states.MoveState.WALK]:
			transition = MovementTransition.new(
				fsm.current,
				toState,
				walkDuration,
				walkCurve,
			)
			targetSpeed = _get_target_speed(walkCurve)
		[states.MoveState.WALK, states.MoveState.IDLE]:
			transition = MovementTransition.new(
				fsm.current,
				toState,
				walkStopDuration,
				walkStopCurve,
			)
			targetSpeed = _get_target_speed(walkStopCurve)
		[states.MoveState.WALK, states.MoveState.SPRINT]:
			transition = MovementTransition.new(
				fsm.current,
				toState,
				walkToSprintDuration,
				walkToSprintCurve,
			)
			targetSpeed = _get_target_speed(walkToSprintCurve)
		[states.MoveState.SPRINT, states.MoveState.IDLE]:
			transition = MovementTransition.new(
				fsm.current,
				toState,
				sprintStopDuration,
				sprintStopCurve,
			)
			targetSpeed = _get_target_speed(sprintStopCurve)
		[states.MoveState.SPRINT, states.MoveState.IDLE]:
			transition = MovementTransition.new(
				fsm.current,
				toState,
				sprintToWalkDuration,
				sprintStopCurve,
			)
			targetSpeed = _get_target_speed(walkCurve)
		[_, states.MoveState.ROLL]:
			transition = MovementTransition.new(
				fsm.current,
				toState,
				rollDuration,
				rollCurve,
			)
			targetSpeed = _get_target_speed(rollCurve)
		_:
			pass
	
	print("Transition")
	fsm.start_transition(
		sprite,
		transition,
		currentSpeed,
		targetSpeed,
	)
	
func _get_target_speed(c: Curve2D) -> float:
	return c.get_point_in(c.point_count-1).y
