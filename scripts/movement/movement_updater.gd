class_name MoveTable

const states := preload("res://scripts/movement/movement_states.gd")

@export var walkCurve: Curve
@export var walkStopCurve: Curve
@export var sprintCurve: Curve
@export var sprintStopCurve: Curve
@export var walkToSprintCurve: Curve
@export var sprintToWalkCurve: Curve
@export var rollCurve: Curve

@export var walkDuration: float
@export var walkStopDuration: float
@export var sprintDuration: float
@export var sprintStopDuration: float
@export var walkToSprintDuration: float
@export var sprintToWalkDuration: Curve
@export var rollDuration: float

func move(sprite: Sprite2D, toState: states.MoveState, fsm: MovementFSM, currentSpeed: float, targetSpeed: float):
	if fsm.current == toState:
		return
		
	var transition: MovementTransition
	
	match [fsm.current, toState]:
		[states.MoveState.IDLE, states.MoveState.WALK]:
			transition = MovementTransition.new(
				fsm.current,
				toState,
				walkDuration,
				walkCurve,
			)
		[states.MoveState.WALK, states.MoveState.IDLE]:
			transition = MovementTransition.new(
				fsm.current,
				toState,
				walkStopDuration,
				walkStopCurve,
			)
		[states.MoveState.WALK, states.MoveState.SPRINT]:
			transition = MovementTransition.new(
				fsm.current,
				toState,
				walkToSprintDuration,
				walkToSprintCurve,
			)
		[states.MoveState.SPRINT, states.MoveState.IDLE]:
			transition = MovementTransition.new(
				fsm.current,
				toState,
				sprintStopDuration,
				sprintStopCurve,
			)
		[states.MoveState.SPRINT, states.MoveState.IDLE]:
			transition = MovementTransition.new(
				fsm.current,
				toState,
				sprintToWalkDuration,
				sprintToWalkDuration,
			)
		[_, states.MoveState.ROLL]:
			transition = MovementTransition.new(
				fsm.current,
				toState,
				rollDuration,
				rollCurve,
			)
		_:
			pass
	
	fsm.start_transition(
		sprite,
		transition,
		currentSpeed,
		targetSpeed,
	)
