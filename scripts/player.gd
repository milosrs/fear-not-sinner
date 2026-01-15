extends Area2D
const states := preload("res://scripts/movement/movement_states.gd")
@onready var sprite := $player_sprite

@export var speed := 100.0
@export_range(0.0, 1.0, 0.001, "Interpolation factor for player movement") var speedupDelta := 0.5




var movement_fsm := MovementFSM.new()

var screen_size
var animation_lock := false
var move_state: states.MoveState = states.MoveState.IDLE
var previous_move_state: states.MoveState = states.MoveState.IDLE
var direction := states.Direction.RIGHT
var walking = false


func _ready():
	screen_size = get_viewport_rect().size
	movement_fsm.current = states.MoveState.IDLE

func _process(_delta: float) -> void:
	_update_location()
	_update_animation_state()
	_update_animation()
	_play_sfx()

func _update_location() -> void:
	match move_state:
		states.MoveState.WALK:
			pass
		states.MoveState.WALK_CROUCH:
			pass
		

func _update_animation_state() -> void:
	if Input.is_action_pressed("move_right"):
		walking = true
		direction = states.Direction.RIGHT
	elif Input.is_action_pressed("move_left"):
		walking = true
		direction = states.Direction.LEFT

	if animation_lock:
		return
		
	var crouching := Input.is_action_pressed("crouch")
	var standingup := Input.is_action_just_released("crouch")
	var jumping := Input.is_action_just_pressed("jump")

	if jumping:
		move_state = states.MoveState.JUMP
		animation_lock = true
	elif walking and crouching:
		move_state = states.MoveState.WALK_CROUCH
	elif walking:
		move_state = states.MoveState.WALK
	elif crouching:
		move_state = states.MoveState.CROUCH
	elif standingup:
		move_state = states.MoveState.STAND_UP
		animation_lock = true
	else:
		move_state = states.MoveState.IDLE

func _update_animation() -> void:
	sprite.flip_h = direction == states.Direction.LEFT
		
	var target_anim := _state_to_animation(move_state)
	
	if sprite.animation != target_anim:
		sprite.play(target_anim)

func _state_to_animation(state: states.MoveState) -> String:
	match state:
		states.MoveState.IDLE:
			return "idle"
		states.MoveState.WALK:
			return "walk"
		states.MoveState.CROUCH:
			return "crouch"
		states.MoveState.WALK_CROUCH:
			return "walk_crouch"
		states.MoveState.JUMP:
			return "jump"
		states.MoveState.STAND_UP:
			return "stand_up"
		_:
			return "idle"



func _on_player_sprite_animation_finished() -> void:
	if move_state == states.MoveState.STAND_UP || move_state == states.MoveState.JUMP:
		move_state = states.MoveState.IDLE
		animation_lock = false

func _play_sfx() -> void:
	match move_state:
		states.MoveState.JUMP:
			$walk.stop()
			_play_sound($jump, 1)
		states.MoveState.WALK:
			$jump.stop()
			$walk.pitch_scale = 1
			_play_sound($walk, 1)
		states.MoveState.WALK_CROUCH:
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
	elif audio.playing && !pitch_equal:
		audio.stop()
	
	audio.play()
	
