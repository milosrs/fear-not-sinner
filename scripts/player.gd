extends CharacterBody2D
const States := preload("res://scripts/movement/movement_states.gd")
@onready var sprite := $player_sprite

@export var speed := 100.0
@export var movement_fsm: MovementFSM
@export var movement_updater: MovementUpdate
@export var jump_controller: JumpController
var movement_states := States.new()

var screen_size
var animation_lock := false
var move_state: States.MoveState = States.MoveState.IDLE
var previous_move_state: States.MoveState = States.MoveState.IDLE
var direction := States.Direction.RIGHT
var walking = false

func _ready():
	screen_size = get_viewport_rect().size
	movement_fsm.current = States.MoveState.IDLE

func _process(_delta: float) -> void:
	_update_movement_state()
	_update_animation()
	_play_sfx()
	
func _physics_process(delta: float) -> void:
	_update_location(delta)
	
func _update_location(delta: float) -> void:
	movement_updater.move(self, move_state, movement_fsm, speed)
	var new_speed = movement_fsm.update(delta)
	if new_speed != speed:
		speed = new_speed
	
	match direction:
		States.Direction.RIGHT:
			position.x += speed
		States.Direction.LEFT:
			position.x -= speed
	
	position = position.clamp(Vector2.ZERO, screen_size)
	sprite.play()
		

func _update_movement_state() -> void:
	if Input.is_action_pressed("move_right"):
		walking = true
		direction = States.Direction.RIGHT
	elif Input.is_action_pressed("move_left"):
		walking = true
		direction = States.Direction.LEFT
	else:
		walking = false

	if animation_lock:
		return
		
	var crouching := Input.is_action_pressed("crouch")
	var standingup := Input.is_action_just_released("crouch")
	var jumping := Input.is_action_just_pressed("jump")

	if jumping:
		move_state = States.MoveState.JUMP
		animation_lock = true
	elif walking and crouching:
		move_state = States.MoveState.WALK_CROUCH
	elif walking:
		move_state = States.MoveState.WALK
	elif crouching:
		move_state = States.MoveState.CROUCH
	elif standingup:
		move_state = States.MoveState.STAND_UP
		animation_lock = true
	else:
		move_state = States.MoveState.IDLE

func _update_animation() -> void:
	sprite.flip_h = direction == States.Direction.LEFT
		
	var target_anim := _state_to_animation(move_state)
	
	if sprite.animation != target_anim:
		sprite.play(target_anim)

func _state_to_animation(state: States.MoveState) -> String:
	match state:
		States.MoveState.IDLE:
			return "idle"
		States.MoveState.WALK:
			return "walk"
		States.MoveState.CROUCH:
			return "crouch"
		States.MoveState.WALK_CROUCH:
			return "walk_crouch"
		States.MoveState.JUMP:
			return "jump"
		States.MoveState.STAND_UP:
			return "stand_up"
		_:
			return "idle"



func _on_player_sprite_animation_finished() -> void:
	if move_state == States.MoveState.STAND_UP || move_state == States.MoveState.JUMP:
		move_state = States.MoveState.IDLE
		animation_lock = false

func _play_sfx() -> void:
	match move_state:
		States.MoveState.JUMP:
			$walk.stop()
			_play_sound($jump, 1)
		States.MoveState.WALK:
			$jump.stop()
			$walk.pitch_scale = 1
			_play_sound($walk, 1)
		States.MoveState.WALK_CROUCH:
			$jump.stop()
			$walk.pitch_scale = 0.8
			_play_sound($walk, 0.8)
		_:
			$walk.stop()
			$jump.stop()

func _play_sound(audio: AudioStreamPlayer2D, expected_pitch: float) -> void:
	var pitch_equal = snapped(audio.pitch_scale, 0.0001) == snapped(expected_pitch, 0.0001)
	
	if audio.playing && pitch_equal:
		return
	if audio.playing && !pitch_equal:
		audio.stop()
		return
	
	audio.play()
	
