extends Control

signal jump_initiated(target_node_id: String)

@onready var close_btn: Button = $CloseBtn
@onready var map_content: Control = $ScrollContainer/MapContent
@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var sector_name_lbl: Label = $DetailPanel/MarginContainer/VBox/SectorName
@onready var sector_bonus_lbl: Label = $DetailPanel/MarginContainer/VBox/SectorBonus
@onready var sector_status_lbl: Label = $DetailPanel/MarginContainer/VBox/SectorStatus
@onready var jump_btn: Button = $DetailPanel/MarginContainer/VBox/JumpBtn

var selected_node_id: String = ""
var node_buttons: Dictionary = {}

func _ready() -> void:
	close_btn.pressed.connect(queue_free)
	jump_btn.pressed.connect(_on_jump_pressed)
	
	# Connect the draw signal of the MapContent container
	map_content.draw.connect(_on_map_content_draw)
	
	# Build the node map dynamically
	_build_star_map()
	
	# Select current sector by default
	_select_node(GameManager.current_sector_node_id)
	
	# Center the scroll view on the player's current node
	_center_on_node(GameManager.current_sector_node_id)

func _build_star_map() -> void:
	# Clear any existing child nodes in MapContent
	for child in map_content.get_children():
		child.queue_free()
	node_buttons.clear()
	
	# Iterate over all nodes in the map configuration
	for node_id in GameManager.STAR_MAP_NODES.keys():
		var node_data = GameManager.STAR_MAP_NODES[node_id]
		var pos = node_data["pos"]
		var type = node_data["type"]
		
		# Create a styled circle button for each star node
		var btn = Button.new()
		btn.name = "Node_" + node_id
		btn.custom_minimum_size = Vector2(28, 28)
		# Position the button so its center is exactly at 'pos'
		btn.position = pos - Vector2(14, 14)
		
		# Apply custom theme styling to make it a glowing circle
		var style = StyleBoxFlat.new()
		style.set_corner_radius_all(14)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		
		var node_color = _get_color_for_type(type)
		style.bg_color = node_color
		
		# Highlighting visited / unlocked / current nodes
		var is_unlocked = GameManager.unlocked_sector_nodes.has(node_id)
		var is_current = (node_id == GameManager.current_sector_node_id)
		
		if is_current:
			style.border_color = Color.WHITE
			style.shadow_color = Color(1.0, 0.94, 0.0, 0.8) # Pulsing gold shadow
			style.shadow_size = 10
			# Create a visual indicator (like a tiny satellite icon or pulsator)
			_create_pulsator(btn)
		elif is_unlocked:
			style.border_color = Color(0.0, 0.94, 1.0, 0.8) # Cyan border for visited
			style.shadow_color = node_color
			style.shadow_size = 6
		else:
			style.bg_color = Color(0.1, 0.08, 0.15, 0.9) # Dark grey for locked
			style.border_color = Color(0.3, 0.3, 0.3, 0.6) # Dim grey border
			style.shadow_size = 0
			
		btn.add_theme_stylebox_override("normal", style)
		
		# Hover styles
		var style_hover = style.duplicate() as StyleBoxFlat
		if is_unlocked:
			style_hover.shadow_size = 12
			btn.mouse_entered.connect(func():
				btn.pivot_offset = btn.size / 2.0
				var t = btn.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				t.tween_property(btn, "scale", Vector2(1.15, 1.15), 0.15)
			)
			btn.mouse_exited.connect(func():
				var t = btn.create_tween().set_trans(Tween.TRANS_SINE)
				t.tween_property(btn, "scale", Vector2.ONE, 0.1)
			)
		btn.add_theme_stylebox_override("hover", style_hover)
		
		# Pressed styles
		var style_pressed = style.duplicate() as StyleBoxFlat
		btn.add_theme_stylebox_override("pressed", style_pressed)
		
		# Setup button tooltip/action
		btn.pressed.connect(func():
			_select_node(node_id)
			SoundManager.play_sound(SoundManager.click_stream, 0.02, 1.0)
		)
		
		map_content.add_child(btn)
		node_buttons[node_id] = btn
		
	# Request draw to update connection lines
	map_content.queue_redraw()

func _create_pulsator(parent: Node) -> void:
	var pulsator = Control.new()
	pulsator.name = "Pulsator"
	pulsator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pulsator.position = Vector2(14, 14) # center of 28x28 button
	parent.add_child(pulsator)
	
	# Draw pulsing circle in code
	pulsator.draw.connect(func():
		var t = Time.get_ticks_msec() / 1000.0
		var r = 14.0 + sin(t * 8.0) * 4.0
		var alpha = 0.6 - sin(t * 8.0) * 0.3
		pulsator.draw_arc(Vector2.ZERO, r, 0, TAU, 32, Color(1.0, 0.84, 0.0, alpha), 1.5)
	)
	
	# Create a simple process loop on pulsator to redraw it every frame
	var script = GDScript.new()
	script.source_code = "extends Control\nfunc _process(_d):\n\tqueue_redraw()"
	script.reload()
	pulsator.set_script(script)

func _get_color_for_type(type: String) -> Color:
	match type:
		"ore":
			return Color(0.95, 0.45, 0.1) # Orange
		"gas":
			return Color(0.2, 0.9, 0.4) # Green/Cyan
		"crystal":
			return Color(0.9, 0.2, 0.7) # Pink/Magenta
		"anomaly":
			return Color(0.95, 0.1, 0.1) # Red
		"normal":
			return Color(0.8, 0.8, 0.8) # Gray/White
		_:
			return Color(1, 1, 1)

func _select_node(node_id: String) -> void:
	selected_node_id = node_id
	
	var node_data = GameManager.STAR_MAP_NODES.get(node_id)
	if not node_data:
		return
		
	var name_str = node_data["name"]
	var type = node_data["type"]
	var level = node_data["level"]
	var bonus = node_data["bonus_desc"]
	
	# Format name
	sector_name_lbl.text = "Sektor: " + name_str + " (Lvl " + str(level) + ")"
	
	# Format bonus details
	var bonus_text = "Sektor-Typ: " + type.capitalize() + "\n" + bonus
	sector_bonus_lbl.text = bonus_text
	
	# Determine travel status
	var is_current = (node_id == GameManager.current_sector_node_id)
	
	# Travel possibility check:
	# 1. Selected node cannot be current node.
	# 2. Selected node must be connected directly to the current node.
	# 3. Player must have met the resource goal in the current node.
	var current_node_data = GameManager.STAR_MAP_NODES[GameManager.current_sector_node_id]
	var conns = current_node_data.get("conns", [])
	var can_jump_to = conns.has(node_id)
	
	var progress_target = GameManager.get_sector_target()
	var goal_met = (GameManager.space_ore >= progress_target)
	
	if is_current:
		sector_status_lbl.text = "Aktueller Standort"
		sector_status_lbl.add_theme_color_override("font_color", Color(0.0, 0.94, 1.0))
		jump_btn.disabled = true
	elif can_jump_to:
		if goal_met:
			sector_status_lbl.text = "Bereit zum Sprung (Boni aktiv)"
			sector_status_lbl.add_theme_color_override("font_color", Color(0.22, 1.0, 0.08))
			jump_btn.disabled = false
		else:
			var remaining = max(0.0, progress_target - GameManager.space_ore)
			sector_status_lbl.text = "Sektor-Triebwerk lädt... (Benötigt noch " + str(int(remaining)) + " Erz)"
			sector_status_lbl.add_theme_color_override("font_color", Color(0.95, 0.1, 0.1))
			jump_btn.disabled = true
	else:
		# Node is not directly connected to the current node
		sector_status_lbl.text = "Gesperrt (Keine direkte Hyperraum-Verbindung)"
		sector_status_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		jump_btn.disabled = true
		
	# Bouncy click animation on selected node
	var btn = node_buttons.get(node_id)
	if btn:
		btn.pivot_offset = btn.size / 2.0
		var t = btn.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(btn, "scale", Vector2(1.25, 1.25), 0.15)
		t.tween_property(btn, "scale", Vector2.ONE, 0.1)

func _center_on_node(node_id: String) -> void:
	var node_data = GameManager.STAR_MAP_NODES.get(node_id)
	if not node_data:
		return
	
	var pos = node_data["pos"]
	# Center ScrollContainer on position y
	var scroll_y = pos.y - (scroll_container.size.y / 2.0)
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(scroll_container, "scroll_vertical", int(clamp(scroll_y, 0, map_content.custom_minimum_size.y - scroll_container.size.y)), 0.6)

func _on_map_content_draw() -> void:
	# Draw background hyperraum connection lines
	for from_id in GameManager.STAR_MAP_NODES.keys():
		var from_node = GameManager.STAR_MAP_NODES[from_id]
		var conns = from_node.get("conns", [])
		for to_id in conns:
			# Prevent drawing line twice (A->B and B->A)
			if from_id < to_id:
				var to_node = GameManager.STAR_MAP_NODES.get(to_id)
				if to_node:
					var p1 = from_node["pos"]
					var p2 = to_node["pos"]
					
					var is_unlocked_p1 = GameManager.unlocked_sector_nodes.has(from_id)
					var is_unlocked_p2 = GameManager.unlocked_sector_nodes.has(to_id)
					
					if is_unlocked_p1 and is_unlocked_p2:
						# Traveled stable warp lane
						map_content.draw_line(p1, p2, Color(0.0, 0.94, 1.0, 0.8), 2.0)
					else:
						# Unstable / locked warp lane (dimmed dashed/dotted style line)
						_draw_dashed_line(p1, p2, Color(0.0, 0.94, 1.0, 0.18), 1.5, 6.0, 4.0)

func _draw_dashed_line(from: Vector2, to: Vector2, color: Color, width: float, dash_len: float, gap_len: float) -> void:
	var dir = (to - from).normalized()
	var dist = from.distance_to(to)
	var curr = 0.0
	while curr < dist:
		var start = from + dir * curr
		var end_dist = min(curr + dash_len, dist)
		var end = from + dir * end_dist
		map_content.draw_line(start, end, color, width)
		curr += dash_len + gap_len

func _on_jump_pressed() -> void:
	if selected_node_id != "" and selected_node_id != GameManager.current_sector_node_id:
		# Double check requirements
		var progress_target = GameManager.get_sector_target()
		if GameManager.space_ore >= progress_target:
			jump_initiated.emit(selected_node_id)
			SoundManager.play_sound(SoundManager.upgrade_stream, 0.05, 1.0)
			queue_free()
