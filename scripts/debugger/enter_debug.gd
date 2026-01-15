extends Node

const DEBUG_OVERLAY_SCENE := preload("res://scripts/debugger/debug_overlay.tscn")
const CURVES_SCENE := preload("res://scripts/debugger/movement/movement_curves.tscn")

var overlay: Control = null
var curves: Control = null

var curve_editor_active = false
var active = false

# Called when the node enters the scene tree for the first time.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_mode"):
		_toggle_debug_overlay()
	if active && event.is_action_pressed("curve editor"):
		_toggle_curves()
		
func _toggle_debug_overlay():
	if overlay != null:
		overlay.queue_free()
		
		if curves != null:
			curves.queue_free()
			
		overlay = null
		curves = null
		active = false
		curve_editor_active = false
	else:
		overlay = DEBUG_OVERLAY_SCENE.instantiate()
		get_tree().root.add_child(overlay)
		active = true

func _toggle_curves():
	if curves != null:
		curves.queue_free()
		curves = null
		curve_editor_active = false
	else:
		curves = CURVES_SCENE.instantiate()
		get_tree().root.add_child(curves)
		curve_editor_active = true
	
		
