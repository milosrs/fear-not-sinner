extends CharacterBody2D

const States := preload("res://scripts/movement/movement_states.gd")

@onready var sprite := $player_sprite
@onready var walk_sfx: AudioStreamPlayer2D = $walk
@onready var jump_sfx: AudioStreamPlayer2D = $jump

@export var speed_multiplier := 100.0
@export var movement_fsm: MovementFSM
@export var movement_updater: MovementUpdate
@export var jump_controller: JumpController

const STATE_ANIMS: Dictionary = {
	States.MoveState.IDLE:        "idle",
	States.MoveState.WALK:        "walk",
	States.MoveState.CROUCH:      "crouch",
	States.MoveState.WALK_CROUCH: "walk_crouch",
	States.MoveState.JUMP:        "jump",
	States.MoveState.STAND_UP:    "stand_up",
	States.MoveState.ROLL:        "roll",
}

var animation_lock := false
var move_state: States.MoveState = States.MoveState.IDLE
var direction := States.Direction.RIGHT
var walking := false

# Buffered just-pressed inputs, set in _process, consumed in _physics_process.
var _input_jump := false
var _input_roll_right := false
var _input_roll_left := false
var _input_stand_up := false

func _ready() -> void:
	movement_fsm.current = States.MoveState.IDLE

func _process(_delta: float) -> void:
	_read_input()
	_update_animation()
	_play_sfx()

func _physics_process(delta: float) -> void:
	_update_movement_state()
	_update_location(delta)
	jump_controller.update(self, delta)
	move_and_slide()
	_clear_buffered_input()

# ---------------------------------------------------------------------------
# Input
# ---------------------------------------------------------------------------

func _read_input() -> void:
	if Input.is_action_pressed("move_right"):
		walking = true
		direction = States.Direction.RIGHT
	elif Input.is_action_pressed("move_left"):
		walking = true
		direction = States.Direction.LEFT
	else:
		walking = false

	# Buffer just-pressed events so they aren't missed across process/physics boundary.
	_input_jump       = _input_jump       or Input.is_action_just_pressed("jump")
	_input_roll_right = _input_roll_right or Input.is_action_just_pressed("roll_right")
	_input_roll_left  = _input_roll_left  or Input.is_action_just_pressed("roll_left")
	_input_stand_up   = _input_stand_up   or Input.is_action_just_released("crouch")

func _clear_buffered_input() -> void:
	_input_jump       = false
	_input_roll_right = false
	_input_roll_left  = false
	_input_stand_up   = false

# ---------------------------------------------------------------------------
# Movement state
# ---------------------------------------------------------------------------

func _update_movement_state() -> void:
	if animation_lock:
		return
	move_state = _resolve_move_state()

func _resolve_move_state() -> States.MoveState:
	# Priority: jump > roll > crouch-walk > walk > crouch > stand-up > idle
	if _input_jump:
		animation_lock = true
		return States.MoveState.JUMP

	if _input_roll_right:
		direction = States.Direction.RIGHT
		animation_lock = true
		return States.MoveState.ROLL

	if _input_roll_left:
		direction = States.Direction.LEFT
		animation_lock = true
		return States.MoveState.ROLL

	var crouching := Input.is_action_pressed("crouch")

	if walking and crouching:
		return States.MoveState.WALK_CROUCH

	if walking:
		return States.MoveState.WALK

	if crouching:
		return States.MoveState.CROUCH

	# Crouch just released — play stand-up animation before returning to idle.
	if _input_stand_up and move_state in [States.MoveState.CROUCH, States.MoveState.WALK_CROUCH]:
		animation_lock = true
		return States.MoveState.STAND_UP

	return States.MoveState.IDLE

# ---------------------------------------------------------------------------
# Location / velocity
# ---------------------------------------------------------------------------

func _update_location(delta: float) -> void:
	movement_updater.move(self, move_state, movement_fsm, velocity.x)
	var new_speed := movement_fsm.update(delta)

	match direction:
		States.Direction.RIGHT:
			velocity.x = new_speed * speed_multiplier
		States.Direction.LEFT:
			velocity.x = -new_speed * speed_multiplier
		_:
			velocity.x = 0.0

# ---------------------------------------------------------------------------
# Animation
# ---------------------------------------------------------------------------

func _update_animation() -> void:
	sprite.flip_h = direction == States.Direction.LEFT
	var target_anim := STATE_ANIMS.get(move_state, "idle") as String
	if sprite.animation != target_anim:
		sprite.play(target_anim)

func _on_player_sprite_animation_finished() -> void:
	if move_state in [States.MoveState.STAND_UP, States.MoveState.JUMP, States.MoveState.ROLL]:
		move_state = States.MoveState.IDLE
		animation_lock = false

func release_animation_lock() -> void:
	animation_lock = false

# ---------------------------------------------------------------------------
# SFX
# ---------------------------------------------------------------------------

func _play_sfx() -> void:
	match move_state:
		States.MoveState.JUMP:
			walk_sfx.stop()
			_play_sound(jump_sfx, 1.0)
		States.MoveState.WALK:
			jump_sfx.stop()
			_play_sound(walk_sfx, 1.0)
		States.MoveState.WALK_CROUCH:
			jump_sfx.stop()
			_play_sound(walk_sfx, 0.8)
		_:
			walk_sfx.stop()
			jump_sfx.stop()

func _play_sound(audio: AudioStreamPlayer2D, pitch: float) -> void:
	if audio.playing and snapped(audio.pitch_scale, 0.0001) == snapped(pitch, 0.0001):
		return
	audio.pitch_scale = pitch
	audio.stop()
	audio.play()
