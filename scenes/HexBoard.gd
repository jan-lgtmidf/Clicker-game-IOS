extends Control

signal node_hovered(id: String, type: String, is_hovered: bool)

@export var board_type: String = "click"
@export var radius: float = 78.0 # Increased from 65.0 for better readability

# Base offset shifted down to 1750.0 to start upgrades near the bottom
var center_offset: Vector2 = Vector2(1200.0, 1750.0)

# Zoom state
var zoom: float = 1.0
const ZOOM_MIN: float = 0.5
const ZOOM_MAX: float = 1.5

# Manual scroll state
var scroll_pos: Vector2 = Vector2.ZERO
var dragging: bool = false
var drag_start: Vector2 = Vector2.ZERO
var scroll_start: Vector2 = Vector2.ZERO

var _is_first_setup: bool = true
var _is_ready: bool = false
var _rebuild_pending: bool = false

func _ready() -> void:
	_is_ready = true
	clip_contents = true
	mouse_filter = MOUSE_FILTER_STOP
	
	# Set canvas size in _ready() to avoid layout crash on scene load
	var canvas: Control = get_node_or_null("GridCanvas")
	if canvas:
		canvas.custom_minimum_size = Vector2(2400.0, 2400.0)
		canvas.size = Vector2(2400.0, 2400.0)
		canvas.mouse_filter = MOUSE_FILTER_PASS
		# Pivot offset in center for zooming
		canvas.pivot_offset = Vector2(1200.0, 1200.0)
		if not canvas.draw.is_connected(_on_canvas_draw):
			canvas.draw.connect(_on_canvas_draw)
	
	GameManager.stats_changed.connect(_on_stats_changed)
	
	call_deferred("rebuild_board")
	call_deferred("center_on_root")
	call_deferred("set_first_setup_done")

func _on_stats_changed() -> void:
	if _rebuild_pending:
		return
	_rebuild_pending = true
	call_deferred("_do_rebuild")

func _do_rebuild() -> void:
	_rebuild_pending = false
	if _is_ready:
		rebuild_board()

func set_first_setup_done() -> void:
	_is_first_setup = false

func center_on_root() -> void:
	scroll_pos = center_offset - size / 2.0
	_apply_scroll()

func _apply_scroll() -> void:
	var canvas: Control = get_node_or_null("GridCanvas")
	if canvas:
		canvas.position = -scroll_pos

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = true
				drag_start = event.global_position
				scroll_start = scroll_pos
			else:
				dragging = false
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			if event.pressed:
				_change_zoom(0.05)
				accept_event()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if event.pressed:
				_change_zoom(-0.05)
				accept_event()
	elif event is InputEventMouseMotion:
		if dragging:
			var delta: Vector2 = event.global_position - drag_start
			# Adjust drag rate by zoom factor so dragging speed remains natural
			scroll_pos = scroll_start - delta / zoom
			_apply_scroll()

func _change_zoom(delta: float) -> void:
	var new_zoom = clamp(zoom + delta, ZOOM_MIN, ZOOM_MAX)
	if new_zoom != zoom:
		zoom = new_zoom
		var canvas: Control = get_node_or_null("GridCanvas")
		if canvas:
			canvas.scale = Vector2(zoom, zoom)
			_apply_scroll()

func _get_hex_center(id: String) -> Vector2:
	var coords: Vector2i = Vector2i.ZERO
	var config: Dictionary = {}
	
	if board_type == "click" or board_type == "automation":
		config = GameManager.UPGRADE_CONFIG.get(id, {})
	elif board_type == "skill":
		config = GameManager.SKILL_CONFIG.get(id, {})
	elif board_type == "singularity":
		config = GameManager.SINGULARITY_CONFIG.get(id, {})
		
	if config.has("grid_coords"):
		coords = config["grid_coords"]
		
	var q: float = float(coords.x)
	var r: float = float(coords.y)
	
	# Strict pointy-topped hexagon spacing math:
	# Width spacing: radius * sqrt(3)
	# Height spacing: radius * 1.5
	var x: float = radius * sqrt(3.0) * (q + r / 2.0)
	
	# Negating the Y offset so that positive coordinate 'r' moves upwards
	var y: float = -radius * 1.5 * r
	
	return center_offset + Vector2(x, y)

func _make_button(key: String) -> Control:
	var script: GDScript = load("res://scenes/HexButton.gd") as GDScript
	var btn: Control = Control.new()
	btn.set_script(script)
	btn.name = key
	btn.upgrade_id = key
	btn.upgrade_type = "upgrade" if (board_type == "click" or board_type == "automation") else board_type
	btn.radius = radius
	return btn

func rebuild_board() -> void:
	var config_keys: Array = []
	if board_type == "click":
		config_keys = ["click_power", "crit_chance", "crit_multiplier", "combo_booster", "quantum_clicks", "crystal_shards", "solar_flare", "plasma_charge", "resonance_harmonic", "gamma_overload", "matter_duplication", "stellar_dust_extractor", "astral_luck"]
	elif board_type == "automation":
		config_keys = ["drill", "siphon", "synthesizer", "drone_count", "drone_speed", "nanite_swarm", "plasma_condenser", "quantum_pipeline", "meteor_collector", "warp_drive", "efficiency_algorithms", "vacuum_collector", "dark_matter_siphon", "drone_cargo_expansion", "stellar_wind_turbines", "overdrive_governor"]
	elif board_type == "skill":
		config_keys = GameManager.SKILL_CONFIG.keys()
	elif board_type == "singularity":
		config_keys = GameManager.SINGULARITY_CONFIG.keys()
		
	var canvas: Control = get_node_or_null("GridCanvas")
	if not canvas:
		return
		
	for key in config_keys:
		var discovered: bool = false
		if board_type == "click" or board_type == "automation":
			discovered = GameManager.is_upgrade_discovered(key)
		elif board_type == "skill":
			discovered = GameManager.is_skill_discovered(key)
		elif board_type == "singularity":
			discovered = GameManager.is_singularity_discovered(key)
			
		var button: Control = canvas.get_node_or_null(key) as Control
		
		if discovered:
			if not button:
				button = _make_button(key)
				canvas.add_child(button)
				button.hexagon_pressed.connect(func(): _on_hex_pressed(key))
				# Forward hover signals to Main
				button.hexagon_hovered.connect(func(id, type, is_hover): node_hovered.emit(id, type, is_hover))
				
				var center_pos: Vector2 = _get_hex_center(key)
				button.position = center_pos - button.custom_minimum_size / 2.0
				
				if not _is_first_setup:
					button.scale = Vector2.ZERO
					var tween: Tween = create_tween()
					tween.tween_property(button, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
					JuiceManager.spawn_spark_burst(canvas, center_pos, button.get_category_color())
					SoundManager.play_sound(SoundManager.upgrade_stream, 0.0, -1.0)
			else:
				button.update_state()
		else:
			if button:
				button.queue_free()
				
	canvas.queue_redraw()

func _get_category_color_for_lines(key: String) -> Color:
	if board_type == "skill":
		return Color(1.0, 0.65, 0.0, 1.0)      # Orange
	elif board_type == "singularity":
		return Color(0.9, 0.1, 0.65, 1.0)       # Magenta
	else:
		if key in ["click_power", "crit_chance", "crit_multiplier"]:
			return Color(0.05, 0.55, 1.0, 1.0)  # Blue
		else:
			return Color(0.0, 0.85, 0.35, 1.0)  # Green

func _on_canvas_draw() -> void:
	var canvas: Control = get_node_or_null("GridCanvas")
	if not canvas:
		return
		
	var config_keys: Array = []
	var config_dict: Dictionary = {}
	
	if board_type == "click":
		config_keys = ["click_power", "crit_chance", "crit_multiplier", "combo_booster", "quantum_clicks", "crystal_shards", "solar_flare", "plasma_charge", "resonance_harmonic", "gamma_overload", "matter_duplication", "stellar_dust_extractor", "astral_luck"]
		config_dict = GameManager.UPGRADE_CONFIG
	elif board_type == "automation":
		config_keys = ["drill", "siphon", "synthesizer", "drone_count", "drone_speed", "nanite_swarm", "plasma_condenser", "quantum_pipeline", "meteor_collector", "warp_drive", "efficiency_algorithms", "vacuum_collector", "dark_matter_siphon", "drone_cargo_expansion", "stellar_wind_turbines", "overdrive_governor"]
		config_dict = GameManager.UPGRADE_CONFIG
	elif board_type == "skill":
		config_keys = GameManager.SKILL_CONFIG.keys()
		config_dict = GameManager.SKILL_CONFIG
	elif board_type == "singularity":
		config_keys = GameManager.SINGULARITY_CONFIG.keys()
		config_dict = GameManager.SINGULARITY_CONFIG
		
	for key in config_keys:
		var config = config_dict.get(key, {})
		var discovered = false
		if board_type == "click" or board_type == "automation":
			discovered = GameManager.is_upgrade_discovered(key)
		elif board_type == "skill":
			discovered = GameManager.is_skill_discovered(key)
		elif board_type == "singularity":
			discovered = GameManager.is_singularity_discovered(key)
			
		if not discovered:
			continue
			
		var center_to = _get_hex_center(key)
		
		# Draw connection lines from dependencies
		for dep_id in config.get("deps", []):
			var dep_discovered = false
			if board_type == "click" or board_type == "automation":
				dep_discovered = GameManager.is_upgrade_discovered(dep_id)
			elif board_type == "skill":
				dep_discovered = GameManager.is_skill_discovered(dep_id)
			elif board_type == "singularity":
				dep_discovered = GameManager.is_singularity_discovered(dep_id)
				
			if not dep_discovered:
				continue
				
			var center_from = _get_hex_center(dep_id)
			
			# Decide line color and thickness based on unlock states
			var line_color = Color(0.2, 0.2, 0.25, 0.5)
			var thickness = 2.0
			
			var from_unlocked = false
			var to_unlocked = false
			
			if board_type == "click" or board_type == "automation":
				from_unlocked = GameManager.upgrade_levels.get(dep_id, 0) > 0
				to_unlocked = GameManager.upgrade_levels.get(key, 0) > 0
			elif board_type == "skill":
				from_unlocked = GameManager.is_skill_unlocked(dep_id)
				to_unlocked = GameManager.is_skill_unlocked(key)
			elif board_type == "singularity":
				from_unlocked = GameManager.singularity_upgrades.get(dep_id, 0) > 0
				to_unlocked = GameManager.singularity_upgrades.get(key, 0) > 0
				
			var cat_color = _get_category_color_for_lines(key)
			
			if from_unlocked and to_unlocked:
				line_color = cat_color
				line_color.a = 0.85
				thickness = 4.0
			elif from_unlocked:
				# Dependency unlocked, target is unlockable/available
				line_color = cat_color * Color(1.0, 1.0, 1.0, 0.5)
				thickness = 2.5
			else:
				# Both locked
				line_color = cat_color * Color(1.0, 1.0, 1.0, 0.15)
				thickness = 1.5
				
			canvas.draw_line(center_from, center_to, line_color, thickness, true)

func _on_hex_pressed(id: String) -> void:
	if board_type == "click" or board_type == "automation":
		GameManager.buy_upgrade(id)
	elif board_type == "skill":
		GameManager.buy_skill(id)
	elif board_type == "singularity":
		GameManager.buy_singularity_upgrade(id)
