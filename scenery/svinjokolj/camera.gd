extends Camera2D

@export var player: CharacterBody2D
@export var smoothing: float = 0.1

func _process(delta: float) -> void:
	if player == null:
		return
	
	# Keep camera centered on player's X position
	# Y can stay fixed or follow - adjust as needed
	var target_pos = Vector2(player.global_position.x, global_position.y)
	global_position = global_position.lerp(target_pos, smoothing)
