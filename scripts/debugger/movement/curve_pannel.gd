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
var selected_segment_index: int = -1  # For adding points between segments

# Zoom state
var zoomed_curve_index: int = -1
var show_tangents: bool = true

func _ready() -> void:
	_load_curves()
	_reset_out_of_range_points()
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
# Reset out-of-range points
# -------------------------
func _reset_out_of_range_points():
	for curve in curves:
		for i in range(curve.get_point_count()):
			var point = curve.get_point_position(i)
			var new_point = point
			var changed = false
			
			# Clamp X between 0 and 10
			if point.x < 0 or point.x > 10:
				new_point.x = clamp(point.x, 0.0, 10.0)
				changed = true
			
			# Clamp Y between 0 and 20
			if point.y < 0 or point.y > 20:
				new_point.y = clamp(point.y, 0.0, 20.0)
				changed = true
			
			if changed:
				curve.set_point_position(i, new_point)
				print("Reset point ", i, " from ", point, " to ", new_point)
			
			# Reset tangent handles to keep them in bounds
			var in_offset = curve.get_point_in(i)
			var out_offset = curve.get_point_out(i)
			
			# Calculate absolute positions of handles
			var in_abs = new_point + in_offset
			var out_abs = new_point + out_offset
			
			# Clamp handle absolute positions
			var new_in_abs = Vector2(clamp(in_abs.x, 0.0, 10.0), clamp(in_abs.y, 0.0, 20.0))
			var new_out_abs = Vector2(clamp(out_abs.x, 0.0, 10.0), clamp(out_abs.y, 0.0, 20.0))
			
			# Convert back to relative offsets
			var new_in_offset = new_in_abs - new_point
			var new_out_offset = new_out_abs - new_point
			
			if in_offset != new_in_offset:
				curve.set_point_in(i, new_in_offset)
				print("Reset in handle ", i, " from ", in_offset, " to ", new_in_offset)
			
			if out_offset != new_out_offset:
				curve.set_point_out(i, new_out_offset)
				print("Reset out handle ", i, " from ", out_offset, " to ", new_out_offset)

# -------------------------
# Drawing
# -------------------------
func _calc_cols() -> int:
	var x = size.x - padding
	var y = cell_size.x + padding
	var size_calc = x / y
	return max(1, size_calc)

func _draw():
	if zoomed_curve_index != -1:
		# Draw zoomed view
		_draw_zoomed_curve()
	else:
		# Draw grid view
		var cols := _calc_cols()
		for i in range(curves.size()):
			var col := i % cols
			var row := i / cols
			var origin := Vector2(
				padding + col * (cell_size.x + padding),
				padding + row * (cell_size.y + padding)
			)

			_draw_curve_cell(curves[i], curve_names[i], origin, i == active_rect_index)

# -------------------------
# Calculate bounds
# -------------------------
func _get_curve_bounds(curve: Curve2D) -> Rect2:
	# Fixed bounds: X from 0 to 10, Y from 0 to 20
	return Rect2(Vector2(0, 0), Vector2(10, 20))

# -------------------------
# Draw zoomed curve (full screen)
# -------------------------
func _draw_zoomed_curve():
	var curve = curves[zoomed_curve_index]
	var title = curve_names[zoomed_curve_index]
	
	# Semi-transparent background
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.05, 0.05, 0.95), true)
	
	# Title
	draw_string(
		get_theme_default_font(),
		Vector2(20, 30),
		title + " (Press ESC to exit)",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		16,
		Color.WHITE
	)
	
	# Draw X button in top right
	var button_size = 40.0
	var button_pos = Vector2(size.x - button_size - 20, 20)
	var button_rect = Rect2(button_pos, Vector2(button_size, button_size))
	
	# Button background
	draw_rect(button_rect, Color(0.8, 0.2, 0.2, 0.8), true)
	draw_rect(button_rect, Color(1, 1, 1), false, 2)
	
	# Draw X
	var center = button_pos + Vector2(button_size / 2, button_size / 2)
	var x_size = 12.0
	draw_line(center + Vector2(-x_size, -x_size), center + Vector2(x_size, x_size), Color.WHITE, 3)
	draw_line(center + Vector2(-x_size, x_size), center + Vector2(x_size, -x_size), Color.WHITE, 3)
	
	# Draw toggle tangents button
	var toggle_button_pos = Vector2(size.x - button_size - 20, 70)
	var toggle_button_rect = Rect2(toggle_button_pos, Vector2(button_size, button_size))
	
	# Button background - different color based on state
	var toggle_color = Color(0.2, 0.8, 0.2, 0.8) if show_tangents else Color(0.5, 0.5, 0.5, 0.8)
	draw_rect(toggle_button_rect, toggle_color, true)
	draw_rect(toggle_button_rect, Color(1, 1, 1), false, 2)
	
	# Draw T for Tangents
	draw_string(
		get_theme_default_font(),
		toggle_button_pos + Vector2(12, 28),
		"T",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		20,
		Color.WHITE
	)
	
	# Draw save button
	var save_button_pos = Vector2(size.x - button_size - 20, 120)
	var save_button_rect = Rect2(save_button_pos, Vector2(button_size, button_size))
	
	# Button background
	draw_rect(save_button_rect, Color(0.2, 0.6, 0.8, 0.8), true)
	draw_rect(save_button_rect, Color(1, 1, 1), false, 2)
	
	# Draw S for Save
	draw_string(
		get_theme_default_font(),
		save_button_pos + Vector2(12, 28),
		"S",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		20,
		Color.WHITE
	)
	
	# Draw add point button
	var add_button_pos = Vector2(size.x - button_size - 20, 170)
	var add_button_rect = Rect2(add_button_pos, Vector2(button_size, button_size))
	
	# Button background
	draw_rect(add_button_rect, Color(0.8, 0.6, 0.2, 0.8), true)
	draw_rect(add_button_rect, Color(1, 1, 1), false, 2)
	
	# Draw + for Add
	var add_center = add_button_pos + Vector2(button_size / 2, button_size / 2)
	var plus_size = 10.0
	draw_line(add_center + Vector2(-plus_size, 0), add_center + Vector2(plus_size, 0), Color.WHITE, 3)
	draw_line(add_center + Vector2(0, -plus_size), add_center + Vector2(0, plus_size), Color.WHITE, 3)
	
	var plot_margin = 60.0
	var plot_origin := Vector2(plot_margin, plot_margin + 20)
	var plot_size := size - Vector2(plot_margin * 2, plot_margin * 2 + 20)
	var bounds = _get_curve_bounds(curve)
	
	# Draw coordinate grid
	_draw_coordinate_grid(plot_origin, plot_size)
	
	# Draw the curve line
	var prev: Variant = null
	for i in range(samples + 1):
		var t = i / samples
		var sample = curve.sample(0, t)
		var x = (sample.x - bounds.position.x) / bounds.size.x
		var y = (sample.y - bounds.position.y) / bounds.size.y
		var p = plot_origin + Vector2(x * plot_size.x, (1 - y) * plot_size.y)

		if prev != null:
			draw_line(prev, p, Color.RED, 3)
		prev = p
	
	# Draw points and handles with values
	_draw_curve_points_with_values(curve, plot_origin, plot_size)

# -------------------------
# Draw curve cell (grid view)
# -------------------------
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
	
	# Draw coordinate grid
	_draw_coordinate_grid(plot_origin, plot_size)

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
# Draw coordinate grid
# -------------------------
func _draw_coordinate_grid(plot_origin: Vector2, plot_size: Vector2):
	var grid_color = Color(0.3, 0.3, 0.3, 0.5)
	var axis_color = Color(0.5, 0.5, 0.5, 0.8)
	
	# Draw vertical grid lines (X axis)
	for i in range(11):  # 0 to 10
		var x = plot_origin.x + (i / 10.0) * plot_size.x
		var color = axis_color if i == 0 else grid_color
		draw_line(Vector2(x, plot_origin.y), Vector2(x, plot_origin.y + plot_size.y), color, 1)
		
		# Draw X labels
		if i % 2 == 0:  # Label every 2 units
			draw_string(
				get_theme_default_font(),
				Vector2(x - 5, plot_origin.y + plot_size.y + 15),
				str(i),
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				10,
				Color(0.6, 0.6, 0.6)
			)
	
	# Draw horizontal grid lines (Y axis)
	for i in range(21):  # 0 to 20
		var y = plot_origin.y + plot_size.y - (i / 20.0) * plot_size.y
		var color = axis_color if i == 0 else grid_color
		draw_line(Vector2(plot_origin.x, y), Vector2(plot_origin.x + plot_size.x, y), color, 1)
		
		# Draw Y labels
		if i % 4 == 0:  # Label every 4 units
			draw_string(
				get_theme_default_font(),
				Vector2(plot_origin.x - 20, y + 4),
				str(i),
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				10,
				Color(0.6, 0.6, 0.6)
			)
	
	# Draw axis labels
	# X axis label (Time)
	draw_string(
		get_theme_default_font(),
		Vector2(plot_origin.x + plot_size.x / 2 - 20, plot_origin.y + plot_size.y + 35),
		"X: Time",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		14,
		Color(0.8, 0.8, 0.8)
	)
	
	# Y axis label (Speed)
	draw_string(
		get_theme_default_font(),
		Vector2(plot_origin.x - 50, plot_origin.y - 10),
		"Y: Speed",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		14,
		Color(0.8, 0.8, 0.8)
	)

var offset_vector := Vector2(-35, 20)

# -------------------------
# Draw points and tangent handles with values
# -------------------------
func _draw_curve_points_with_values(curve: Curve2D, plot_origin: Vector2, plot_size: Vector2):
	var bounds = _get_curve_bounds(curve)

	for i in range(curve.get_point_count()):
		var point = curve.get_point_position(i)
		var x = (point.x - bounds.position.x) / bounds.size.x
		var y = (point.y - bounds.position.y) / bounds.size.y
		var pos = plot_origin + Vector2(x * plot_size.x, (1 - y) * plot_size.y)

		# Draw main point
		draw_circle(pos, 6, Color.YELLOW)
		
		# Draw point value label
		var point_label = "Point[%d] - X: %.2f, Y: %.2f" % [i, point.x, point.y]
		draw_string(
			get_theme_default_font(),
			pos,
			point_label,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			12,
			Color(1, 1, 0.5)
		)

		# Tangent handles
		var in_offset = curve.get_point_in(i)
		var out_offset = curve.get_point_out(i)

		if show_tangents:
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
			draw_line(pos, in_pos, Color.CYAN, 2)
			draw_line(pos, out_pos, Color.MAGENTA, 2)

			# Draw handle points
			draw_circle(in_pos, 4, Color.CYAN)
			draw_circle(out_pos, 4, Color.MAGENTA)
			
			# Draw handle value labels (relative to point)
			var in_label = "X: %.2f, Y: %.2f" % [in_offset.x, in_offset.y]
			draw_string(
				get_theme_default_font(),
				in_pos,
				in_label,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				11,
				Color(0.5, 1, 1)
			)
			
			var out_label = "X: %.2f, Y: %.2f" % [out_offset.x, out_offset.y]
			draw_string(
				get_theme_default_font(),
				out_pos,
				out_label,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				11,
				Color(1, 0.5, 1)
			)

# -------------------------
# Input Handling
# -------------------------
func _gui_input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE and zoomed_curve_index != -1:
			# Exit zoom mode
			_exit_zoom_mode()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_S and event.ctrl_pressed:
			_save_all_curves()
			get_viewport().set_input_as_handled()
			return

	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if zoomed_curve_index != -1:
				# Check if clicking X button first
				if _is_clicking_exit_button(event.position):
					_exit_zoom_mode()
					get_viewport().set_input_as_handled()
					return
				# Check if clicking toggle tangents button
				if _is_clicking_toggle_button(event.position):
					show_tangents = !show_tangents
					queue_redraw()
					get_viewport().set_input_as_handled()
					return
				# Check if clicking save button
				if _is_clicking_save_button(event.position):
					_save_current_curve()
					get_viewport().set_input_as_handled()
					return
				# Check if clicking add point button
				if _is_clicking_add_button(event.position):
					_add_point_to_curve()
					get_viewport().set_input_as_handled()
					return
				# In zoom mode - select point or handle
				_select_point_or_handle_zoomed(event.position)
			else:
				# In grid mode - check if clicking on a cell to zoom
				_handle_grid_click(event.position)
		else:
			selected_point_index = -1
			selected_handle = ""
		get_viewport().set_input_as_handled()
		
	elif event is InputEventMouseMotion:
		if zoomed_curve_index != -1 and selected_point_index != -1:
			_drag_selected_zoomed(event.relative)
			get_viewport().set_input_as_handled()

# -------------------------
# Handle clicking in grid mode
# -------------------------
func _handle_grid_click(mouse_pos: Vector2):
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
			# Zoom into this curve
			zoomed_curve_index = i
			selected_curve_index = i
			queue_redraw()
			return

# -------------------------
# Select a point or handle in zoomed mode
# -------------------------
func _select_point_or_handle_zoomed(mouse_pos: Vector2):
	selected_point_index = -1
	selected_handle = ""

	var plot_margin = 60.0
	var plot_origin := Vector2(plot_margin, plot_margin + 20)
	var plot_size := size - Vector2(plot_margin * 2, plot_margin * 2 + 20)
	var curve = curves[zoomed_curve_index]
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

		if show_tangents:
			var in_pos = Vector2(
				(point.x + in_offset.x - bounds.position.x) / bounds.size.x * plot_size.x,
				(1 - (point.y + in_offset.y - bounds.position.y) / bounds.size.y) * plot_size.y
			) + plot_origin

			var out_pos = Vector2(
				(point.x + out_offset.x - bounds.position.x) / bounds.size.x * plot_size.x,
				(1 - (point.y + out_offset.y - bounds.position.y) / bounds.size.y) * plot_size.y
			) + plot_origin

			# Check handles first (smaller targets, should have priority)
			if mouse_pos.distance_to(in_pos) <= 8:
				selected_point_index = j
				selected_handle = "in"
				queue_redraw()
				return
			if mouse_pos.distance_to(out_pos) <= 8:
				selected_point_index = j
				selected_handle = "out"
				queue_redraw()
				return
		
		# Then check main point
		if mouse_pos.distance_to(pos) <= 10:
			selected_point_index = j
			selected_handle = ""
			queue_redraw()
			return

	queue_redraw()

# -------------------------
# Drag a selected point or handle in zoomed mode
# -------------------------
func _drag_selected_zoomed(_relative: Vector2):
	if selected_point_index == -1:
		return

	var curve = curves[zoomed_curve_index]
	var plot_margin = 60.0
	var plot_origin := Vector2(plot_margin, plot_margin + 20)
	var plot_size := size - Vector2(plot_margin * 2, plot_margin * 2 + 20)
	var bounds = _get_curve_bounds(curve)

	# Get mouse position in local coordinates
	var mouse_pos := get_local_mouse_position()
	var local_pos := mouse_pos - plot_origin

	# Convert to normalized coordinates (0..1)
	var norm_x = clamp(local_pos.x / plot_size.x, 0.0, 1.0)
	var norm_y = clamp(1.0 - local_pos.y / plot_size.y, 0.0, 1.0)

	# Convert to curve space with constraints
	var curve_x = clamp(bounds.position.x + norm_x * bounds.size.x, 0.0, 10.0)
	var curve_y = clamp(bounds.position.y + norm_y * bounds.size.y, 0.0, 20.0)

	if selected_handle == "":
		# Moving the point itself - tangents stay relative (maintain their offset)
		var old_point = curve.get_point_position(selected_point_index)
		var delta = Vector2(curve_x, curve_y) - old_point
		
		# Update point position
		curve.set_point_position(selected_point_index, Vector2(curve_x, curve_y))
		
		# Tangents don't need to be updated - they're stored as offsets relative to the point
		# so they automatically move with the point
		
	elif selected_handle == "in":
		# Moving the in handle - update offset relative to point
		var p = curve.get_point_position(selected_point_index)
		var offset_x = clamp(curve_x - p.x, -p.x, 10.0 - p.x)
		var offset_y = clamp(curve_y - p.y, -p.y, 20.0 - p.y)
		curve.set_point_in(selected_point_index, Vector2(offset_x, offset_y))
		
	elif selected_handle == "out":
		# Moving the out handle - update offset relative to point
		var p = curve.get_point_position(selected_point_index)
		var offset_x = clamp(curve_x - p.x, -p.x, 10.0 - p.x)
		var offset_y = clamp(curve_y - p.y, -p.y, 20.0 - p.y)
		curve.set_point_out(selected_point_index, Vector2(offset_x, offset_y))

	queue_redraw()

# -------------------------
# Exit zoom mode
# -------------------------
func _exit_zoom_mode():
	zoomed_curve_index = -1
	selected_curve_index = -1
	selected_point_index = -1
	selected_handle = ""

	# Reload curves from disk to ensure values are updated
	_load_curves()
	queue_redraw()

# -------------------------
# Check if clicking the exit button
# -------------------------
func _is_clicking_exit_button(mouse_pos: Vector2) -> bool:
	var button_size = 40.0
	var button_pos = Vector2(size.x - button_size - 20, 20)
	var button_rect = Rect2(button_pos, Vector2(button_size, button_size))
	return button_rect.has_point(mouse_pos)

# -------------------------
# Check if clicking the toggle tangents button
# -------------------------
func _is_clicking_toggle_button(mouse_pos: Vector2) -> bool:
	var button_size = 40.0
	var button_pos = Vector2(size.x - button_size - 20, 70)
	var button_rect = Rect2(button_pos, Vector2(button_size, button_size))
	return button_rect.has_point(mouse_pos)

# -------------------------
# Check if clicking the save button
# -------------------------
func _is_clicking_save_button(mouse_pos: Vector2) -> bool:
	var button_size = 40.0
	var button_pos = Vector2(size.x - button_size - 20, 120)
	var button_rect = Rect2(button_pos, Vector2(button_size, button_size))
	return button_rect.has_point(mouse_pos)

# -------------------------
# Check if clicking the add point button
# -------------------------
func _is_clicking_add_button(mouse_pos: Vector2) -> bool:
	var button_size = 40.0
	var button_pos = Vector2(size.x - button_size - 20, 170)
	var button_rect = Rect2(button_pos, Vector2(button_size, button_size))
	return button_rect.has_point(mouse_pos)

# -------------------------
# Add a point between two existing points
# -------------------------
func _add_point_to_curve():
	if zoomed_curve_index == -1:
		return
	var curve = curves[zoomed_curve_index]
	if curve.get_point_count() < 2:
		print("Need at least 2 points to add a point between them")
		return
	var point_index = 0
	if selected_point_index != -1 and selected_point_index < curve.get_point_count() - 1:
		point_index = selected_point_index
	var t_start = float(point_index) / float(curve.get_point_count() - 1)
	var t_end = float(point_index + 1) / float(curve.get_point_count() - 1)
	var t_mid = (t_start + t_end) / 2.0
	var new_pos = curve.sample(0, t_mid)
	new_pos.x = clamp(new_pos.x, 0.0, 10.0)
	new_pos.y = clamp(new_pos.y, 0.0, 20.0)
	curve.add_point(new_pos, Vector2.ZERO, Vector2.ZERO, point_index + 1)
	print("Added point at ", new_pos, " between points ", point_index, " and ", point_index + 1)
	queue_redraw()

func _save_current_curve():
	if zoomed_curve_index == -1:
		return

	print("SAVING CURVE: ", curve_names[zoomed_curve_index])
	var path := curves_dir + "/" + curve_names[zoomed_curve_index] + ".tres"

	_save_curve_data(curves[zoomed_curve_index], path)

func _save_all_curves():
	print("SAVING ALL CURVES")
	for i in range(curves.size()):
		var path := curves_dir + "/" + curve_names[i] + ".tres"

		_save_curve_data(curves[i], path)

func _save_curve_data(curve: Curve2D, path: String):
	# Update the curve points with the displayed values using `pos`, `in_pos`, and `out_pos`
	var bounds = _get_curve_bounds(curve)
	
	_calculate_real_curve_position(curve, bounds)

	var err = ResourceSaver.save(curve, path)
	if err != OK:
		push_error("Failed to save curve: " + path)
	else:
		print("Saved curve: ", path)

func _calculate_real_curve_position(
	curve: Curve2D, 
	bounds: Rect2,
):
	var plot_margin = 60.0
	var plot_origin := Vector2(plot_margin, plot_margin + 20)
	var plot_size := size - Vector2(plot_margin * 2, plot_margin * 2 + 20)

	for i in range(curve.get_point_count()):
		var point = curve.get_point_position(i)
		var in_offset = curve.get_point_in(i)
		var out_offset = curve.get_point_out(i)

		# Calculate `pos`, `in_pos`, and `out_pos` based on the drawing logic
		var x = (point.x - bounds.position.x) / bounds.size.x
		var y = (point.y - bounds.position.y) / bounds.size.y
		var pos = plot_origin + Vector2(x * plot_size.x, (1 - y) * plot_size.y)

		var in_pos = Vector2(
			(point.x + in_offset.x - bounds.position.x) / bounds.size.x * plot_size.x,
			(1 - (point.y + in_offset.y - bounds.position.y) / bounds.size.y) * plot_size.y
		) + plot_origin

		var out_pos = Vector2(
			(point.x + out_offset.x - bounds.position.x) / bounds.size.x * plot_size.x,
			(1 - (point.y + out_offset.y - bounds.position.y) / bounds.size.y) * plot_size.y
		) + plot_origin

		# Convert `pos`, `in_pos`, and `out_pos` back to curve space
		var curve_x = bounds.position.x + (pos.x - plot_origin.x) / plot_size.x * bounds.size.x
		var curve_y = bounds.position.y + (1.0 - (pos.y - plot_origin.y) / plot_size.y) * bounds.size.y
		curve.set_point_position(i, Vector2(curve_x, curve_y))

		var in_curve_x = bounds.position.x + (in_pos.x - plot_origin.x) / plot_size.x * bounds.size.x
		var in_curve_y = bounds.position.y + (1.0 - (in_pos.y - plot_origin.y) / plot_size.y) * bounds.size.y
		curve.set_point_in(i, Vector2(in_curve_x - curve_x, in_curve_y - curve_y))

		var out_curve_x = bounds.position.x + (out_pos.x - plot_origin.x) / plot_size.x * bounds.size.x
		var out_curve_y = bounds.position.y + (1.0 - (out_pos.y - plot_origin.y) / plot_size.y) * bounds.size.y
		curve.set_point_out(i, Vector2(out_curve_x - curve_x, out_curve_y - curve_y))
