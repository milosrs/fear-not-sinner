extends Resource
class_name JumpController

@export var launch_force := 0
@export var time_to_apex := 0
@export var fall_speed_multiplier := 0

@export var coyote_time := 0
@export var buffer_time := 0
@export var terminal_velocity := 0
@export var double_jump: bool
@export var variable_height: bool

func execute_jump(body: Area2D, delta: float) -> void:
    var collision: CollisionShape2D = null
    
    # Find the CollisionShape2D child
    for child in body.get_children():
        if child is CollisionShape2D:
            collision = child
            break
    
    if collision == null:
        push_error("No CollisionShape2D found in body: ", body.name)
        return


    return
    