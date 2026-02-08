extends Resource
class_name JumpController

@export var gravity: float = 2600.0
@export var time_to_apex: float = 0.32
@export var fall_speed_multiplier: float = 2.4
@export var terminal_velocity: float = 1800.0

@export var coyote_time: float = 0.1
@export var buffer_time: float = 0.1
@export var variable_height: bool = true

var jump_velocity: float
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var should_jump: bool = false


func _init() -> void:
	jump_velocity = gravity * time_to_apex


func update(body: CharacterBody2D, delta: float) -> void:
	update_timers(body, delta)
	process_jump_input()
	apply_gravity(body, delta)

func update_timers(body: CharacterBody2D, delta: float) -> void:
	if body.is_on_floor():
		body.release_animation_lock()
		coyote_timer = coyote_time
	else:
		coyote_timer -= delta

	jump_buffer_timer -= delta


func process_jump_input() -> void:
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = buffer_time

	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		execute_jump()


func execute_jump() -> void:
	# Store flag to apply jump in next gravity update
	jump_buffer_timer = 0.0
	coyote_timer = 0.0
	should_jump = true


func apply_jump(body: CharacterBody2D) -> void:
	body.velocity.y = -jump_velocity


func apply_gravity(body: CharacterBody2D, delta: float) -> void:
	# Apply jump if queued
	if should_jump:
		body.velocity.y = -jump_velocity
		should_jump = false
	
	if body.is_on_floor() and body.velocity.y >= 0.0:
		return

	var g := gravity

	if body.velocity.y > 0.0:
		g *= fall_speed_multiplier

	if variable_height \
	and body.velocity.y < 0.0 \
	and not Input.is_action_pressed("jump"):
		g *= fall_speed_multiplier

	body.velocity.y += g * delta
	body.velocity.y = min(body.velocity.y, terminal_velocity)
