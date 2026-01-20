enum MoveState {
	IDLE,
	WALK,
	SPRINT,
	CROUCH,
	WALK_CROUCH,
	JUMP,
	STAND_UP,
	ROLL,
}

enum Direction {
	LEFT,
	RIGHT
}

func move_state_string(ms: MoveState) -> String:
	match ms:
		MoveState.IDLE:
			return "idle"
		MoveState.WALK:
			return "walk"
		MoveState.SPRINT:
			return "sprint"
		MoveState.CROUCH:
			return "crouch"
		MoveState.WALK_CROUCH:
			return "walk crouch"
		MoveState.JUMP:
			return "jump"
		MoveState.STAND_UP:
			return "stand up"
		MoveState.ROLL:
			return "roll"
		_:
			return "unknown"
