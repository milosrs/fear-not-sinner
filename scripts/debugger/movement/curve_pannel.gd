extends Control

@export var curves_dir := "res://scripts/movement/curves"
@export var cell_size := Vector2(200, 200)
@export var padding = 16.0
@export var samples := 64.0

var curves: Array[Curve2D] = []
var curve_names: Array[String] = []
var active_rect_index: int = -1

# Editable state
var selected_curve_index: int = -1
var selected_point_index: int = -1
var selected_handle: String = "" # "in", "out", or ""
var drag_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	_load_curves()
	queue_redraw()
	focus_mode = Control.FOCUS_ALL
	grab_focus()

# -------------------------
# Loading Curves
# -------------------------
func _load_curves():
	curves.clear()
	curve_names.clear()

	var dir := DirAccess.open(curves_dir)
	if dir == null:
		push_error("Invalid curve directory")
		return

	dir.list_dir_begin()
	var file := dir.get_next()

	while file != "":
		if file.get_extension() == "tres":
			var res := load(curves_dir + "/" + file)
			if res is Curve2D:
				curves.append(res)
				curve_names.append(file.get_basename())
		file = dir.get_next()

	dir.list_dir_end()
	print("Loaded curves: ", curves.size())

# -------------------------
# Drawing
# -------------------------
func _calc_cols() -> int:
	var x = size.x - padding
	var y = cell_size.x + padding
	var size_calc = x / y
	return max(1, size_calc)

func _draw():
	var cols := _calc_cols()

	for i in range(curves.size()):
		var col := i % cols
		var row := i / cols
		var origin := Vector2(
			padding + col * (cell_size.x + padding),
			padding + row * (cell_size.y + padding)
		)

		_draw_curve_cell(curves[i], curve_names[i], origin, i == active_rect_index)

		if i == selected_curve_index:
			_draw_curve_points(curves[i], origin)

# Map curve points and handles into its rectangle
# -------------------------
# Calculate bounds including handles
# -------------------------
func _get_curve_bounds(curve: Curve2D) -> Rect2:
	if curve.get_point_count() == 0:
		return Rect2(Vector2.ZERO, Vector2.ONE)
	
	var first = curve.get_point_position(0)
	var minv = first
	var maxv = first

	for i in range(curve.get_point_count()):
		var p = curve.get_point_position(i)
		var in_p = p + curve.get_point_in(i)
		var out_p = p + curve.get_point_out(i)

		# Update min/max including point and handles
		minv.x = min(minv.x, p.x, in_p.x, out_p.x)
		minv.y = min(minv.y, p.y, in_p.y, out_p.y)
		maxv.x = max(maxv.x, p.x, in_p.x, out_p.x)
		maxv.y = max(maxv.y, p.y, in_p.y, out_p.y)

	# Avoid zero-size
	if minv.x == maxv.x:
		maxv.x += 1
	if minv.y == maxv.y:
		maxv.y += 1

	return Rect2(minv, maxv - minv)

# Draw a curve in its rectangle
func _draw_curve_cell(curve: Curve2D, title: String, origin: Vector2, active_rect: bool = false):
	var rect := Rect2(origin, cell_size)

	# Background
	if active_rect:
		draw_rect(rect, Color(1, 1, 0, 0.2), true)  # yellow highlight
	else:
		draw_rect(rect, Color(0.1, 0.1, 0.1), true)

	# Border - white if active, gray if not
	var border_color = Color.WHITE if active_rect else Color(0.3, 0.3, 0.3)
	var border_width = 2 if active_rect else 1
	draw_rect(rect, border_color, false, border_width)

	# Title
	draw_string(
		get_theme_default_font(), 
		origin + Vector2(8, 18), 
		title, 
		HORIZONTAL_ALIGNMENT_LEFT, 
		-1, 
		14, 
		Color.WHITE,
	)

	var plot_origin := origin + Vector2(10, 30)
	var plot_size := cell_size - Vector2(20, 40)
	var bounds = _get_curve_bounds(curve)

	var prev: Variant = null
	for i in range(samples + 1):
		var t = i / samples
		var sample = curve.sample(0, t)
		var x = (sample.x - bounds.position.x) / bounds.size.x
		var y = (sample.y - bounds.position.y) / bounds.size.y
		var p = plot_origin + Vector2(x * plot_size.x, (1 - y) * plot_size.y)

		if prev != null:
			draw_line(prev, p, Color.RED, 2)
		prev = p

# -------------------------
# Draw points and tangent handles
# -------------------------
func _draw_curve_points(curve: Curve2D, origin: Vector2):
	var plot_origin := origin + Vector2(10, 30)
	var plot_size := cell_size - Vector2(20, 40)
	var bounds = _get_curve_bounds(curve)

	for i in range(curve.get_point_count()):
		var point = curve.get_point_position(i)
		var x = (point.x - bounds.position.x) / bounds.size.x
		var y = (point.y - bounds.position.y) / bounds.size.y
		var pos = plot_origin + Vector2(x * plot_size.x, (1 - y) * plot_size.y)

		# Draw main point
		draw_circle(pos, 5, Color.YELLOW)

		# Tangent handles
		var in_offset = curve.get_point_in(i)
		var out_offset = curve.get_point_out(i)

		# Map handle positions relative to bounds
		var in_pos = Vector2(
			(point.x + in_offset.x - bounds.position.x) / bounds.size.x * plot_size.x,
			(1 - (point.y + in_offset.y - bounds.position.y) / bounds.size.y) * plot_size.y
		) + plot_origin

		var out_pos = Vector2(
			(point.x + out_offset.x - bounds.position.x) / bounds.size.x * plot_size.x,
			(1 - (point.y + out_offset.y - bounds.position.y) / bounds.size.y) * plot_size.y
		) + plot_origin

		# Draw handle lines
		draw_line(pos, in_pos, Color.CYAN, 1)
		draw_line(pos, out_pos, Color.MAGENTA, 1)

		# Draw handle points
		draw_circle(in_pos, 3, Color.CYAN)
		draw_circle(out_pos, 3, Color.MAGENTA)

# -------------------------
# Input Handling - FIXED
# -------------------------
func _gui_input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_S and event.ctrl_pressed:
			_save_all_curves()
			get_viewport().set_input_as_handled()

	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_select_point_or_handle(event.position)
		else:
			selected_point_index = -1
			selected_handle = ""
		get_viewport().set_input_as_handled()
		
	elif event is InputEventMouseMotion:
		if selected_curve_index != -1 and selected_point_index != -1:
			_drag_selected(event.relative)
			get_viewport().set_input_as_handled()

# -------------------------
# Select a point or handle
# -------------------------
func _select_point_or_handle(mouse_pos: Vector2):
	selected_curve_index = -1
	selected_point_index = -1
	selected_handle = ""
	active_rect_index = -1

	var cols := _calc_cols()
	

	for i in range(curves.size()):
		var col := i % cols
		var row := i / cols
		var origin := Vector2(
			padding + col * (cell_size.x + padding), 
			padding + row * (cell_size.y + padding),
		)
		var rect := Rect2(origin, cell_size)
	
		
		if rect.has_point(mouse_pos):
			active_rect_index = i
			selected_curve_index = i

		var plot_origin := origin + Vector2(10, 30)
		var plot_size := cell_size - Vector2(20, 40)
		var curve = curves[i]
		var bounds = _get_curve_bounds(curve)

		# Check for point/handle clicks
		for j in range(curve.get_point_count()):
			var point = curve.get_point_position(j)
			var in_offset = curve.get_point_in(j)
			var out_offset = curve.get_point_out(j)

			var pos = Vector2(
				(point.x - bounds.position.x) / bounds.size.x * plot_size.x,
				(1 - (point.y - bounds.position.y) / bounds.size.y) * plot_size.y
			) + plot_origin

			var in_pos = Vector2(
				(point.x + in_offset.x - bounds.position.x) / bounds.size.x * plot_size.x,
				(1 - (point.y + in_offset.y - bounds.position.y) / bounds.size.y) * plot_size.y
			) + plot_origin

			var out_pos = Vector2(
				(point.x + out_offset.x - bounds.position.x) / bounds.size.x * plot_size.x,
				(1 - (point.y + out_offset.y - bounds.position.y) / bounds.size.y) * plot_size.y
			) + plot_origin

			# Check handles first (smaller targets, should have priority)
			if mouse_pos.distance_to(in_pos) <= 5:
				selected_curve_index = i
				selected_point_index = j
				selected_handle = "in"
				drag_offset = in_pos - mouse_pos
				queue_redraw()
				return
			if mouse_pos.distance_to(out_pos) <= 5:
				selected_curve_index = i
				selected_point_index = j
				selected_handle = "out"
				drag_offset = out_pos - mouse_pos
				queue_redraw()
				return
			# Then check main point
			if mouse_pos.distance_to(pos) <= 8:
				selected_curve_index = i
				selected_point_index = j
				selected_handle = ""
				drag_offset = pos - mouse_pos
				queue_redraw()
				return

	queue_redraw()

# -------------------------
# Drag a selected point or handle
# -------------------------
func _drag_selected(_relative: Vector2):
	if selected_curve_index == -1 or selected_point_index == -1:
		return

	var curve = curves[selected_curve_index]
	var origin := _get_curve_origin(selected_curve_index)
	var plot_origin := origin + Vector2(10, 30)
	var plot_size := cell_size - Vector2(20, 40)
	var bounds = _get_curve_bounds(curve)

	# Get mouse position in local coordinates
	var mouse_pos := get_local_mouse_position()
	var local_pos := mouse_pos - plot_origin

	# Convert to normalized coordinates (0..1)
	var norm_x = clamp(local_pos.x / plot_size.x, 0.0, 1.0)
	var norm_y = clamp(1.0 - local_pos.y / plot_size.y, 0.0, 1.0)

	# Convert to curve space
	var curve_x = bounds.position.x + norm_x * bounds.size.x
	var curve_y = bounds.position.y + norm_y * bounds.size.y

	if selected_handle == "":
		# Moving the point itself
		curve.set_point_position(selected_point_index, Vector2(curve_x, curve_y))
	elif selected_handle == "in":
		# Moving the in handle
		var p = curve.get_point_position(selected_point_index)
		curve.set_point_in(selected_point_index, Vector2(curve_x - p.x, curve_y - p.y))
	elif selected_handle == "out":
		# Moving the out handle
		var p = curve.get_point_position(selected_point_index)
		curve.set_point_out(selected_point_index, Vector2(curve_x - p.x, curve_y - p.y))

	queue_redraw()
	_emit_curve_changed(curve)

func _get_curve_origin(index: int) -> Vector2:
	var cols := _calc_cols()
	var col := index % cols
	var row := index / cols
	return Vector2(padding + col * (cell_size.x + padding), padding + row * (cell_size.y + padding))

func _emit_curve_changed(_curve: Curve2D):
	# Example: notify your character controller that this curve changed
	# emit_signal("curve_updated", curve)
	pass

# -------------------------
# Save curves
# -------------------------
func _save_all_curves():
	print("SAVING CURVES")
	for i in range(curves.size()):
		var path := curves_dir + "/" + curve_names[i] + ".tres"
		var err = ResourceSaver.save(curves[i], path)
		if err != OK:
			push_error("Failed to save curve: " + path)
		else:
			print("Saved curve: ", path)
