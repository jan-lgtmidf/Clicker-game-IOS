extends Control

signal hexagon_pressed()
signal hexagon_hovered(id: String, type: String, is_hovered: bool)

@export var upgrade_id: String = ""
@export var upgrade_type: String = "upgrade" # "upgrade", "skill", "singularity"
@export var radius: float = 78.0 # Increased from 65.0 for better readability

var hovered: bool = false
var pressed: bool = false

var icon_rect: TextureRect
var title_lbl: Label
var level_lbl: Label

var active_tween: Tween

const ICON_PATHS = {
	"click_power": "res://assets/Kenney/kenney_space-shooter-remastered/PNG/Power-ups/bolt_gold.png",
	"crit_chance": "res://assets/Kenney/kenney_space-shooter-remastered/PNG/Power-ups/star_gold.png",
	"crit_multiplier": "res://assets/Kenney/kenney_space-shooter-remastered/PNG/Power-ups/things_gold.png",
	"combo_booster": "res://assets/Kenney/kenney_space-shooter-remastered/PNG/Power-ups/pill_yellow.png",
	"quantum_clicks": "res://assets/Kenney/kenney_space-shooter-remastered/PNG/Lasers/laserBlue08.png",
	"crystal_shards": "res://assets/Kenney/kenney_space-shooter-remastered/PNG/Power-ups/things_silver.png",
	"solar_flare": "res://assets/Kenney/kenney_space-shooter-remastered/PNG/Power-ups/powerupRed.png",
	"plasma_charge": "res://assets/Kenney/kenney_space-shooter-remastered/PNG/Power-ups/pill_red.png",
	"resonance_harmonic": "res://assets/Kenney/kenney_space-shooter-remastered/PNG/Power-ups/powerupGreen_star.png",
	"gamma_overload": "res://assets/Kenney/kenney_space-shooter-remastered/PNG/Lasers/laserRed08.png",
	"matter_duplication": "res://assets/Kenney/kenney_space-shooter-remastered/PNG/Power-ups/things_bronze.png",
	"stellar_dust_extractor": "res://assets/Kenney/kenney_space-shooter-remastered/PNG/Power-ups/powerupBlue_star.png",
	"astral_luck": "res://assets/Kenney/kenney_space-shooter-remastered/PNG/Power-ups/powerupRed_star.png",
	"drill": "res://assets/Kenney/kenney_space-shooter-remastered/PNG/playerShip1_blue.png",
	"siphon": "res://assets/Kenney/kenney_space-shooter-remastered/PNG/ufoGreen.png",
	"synthesizer": "res://assets/Kenney/kenney_space-shooter-remastered/PNG/ufoYellow.png",
	"nanite_swarm": "res://assets/Kenney/kenney_space-shooter-remastered/PNG/Power-ups/powerupGreen.png",
	"plasma_condenser": "res://assets/Kenney/kenney_space-shooter-remastered/PNG/Power-ups/pill_green.png",
	"quantum_pipeline": "res://assets/Kenney/kenney_space-shooter-remastered/PNG/Power-ups/powerupYellow.png",
	"drone_count": "res://assets/Kenney/kenney_space-shooter-remastered/PNG/playerShip2_blue.png",
	"drone_speed": "res://assets/Kenney/kenney_space-shooter-remastered/PNG/Effects/speed.png",
	"meteor_collector": "res://assets/Kenney/kenney_space-shooter-remastered/PNG/ufoBlue.png",
	"warp_drive": "res://assets/Kenney/kenney_space-shooter-remastered/PNG/playerShip1_orange.png",
	"efficiency_algorithms": "res://assets/Kenney/kenney_space-shooter-remastered/PNG/Power-ups/powerupYellow_shield.png",
	"vacuum_collector": "res://assets/Kenney/kenney_space-shooter-remastered/PNG/Power-ups/pill_blue.png",
	"dark_matter_siphon": "res://assets/Kenney/kenney_space-shooter-remastered/PNG/Power-ups/powerupBlue_shield.png",
	"drone_cargo_expansion": "res://assets/Kenney/kenney_space-shooter-remastered/PNG/playerShip3_blue.png",
	"stellar_wind_turbines": "res://assets/Kenney/kenney_space-shooter-remastered/PNG/playerShip2_orange.png",
	"overdrive_governor": "res://assets/Kenney/kenney_space-shooter-remastered/PNG/Power-ups/powerupRed_bolt.png",
	"ore_magnet": "res://assets/Kenney/kenney_space-shooter-remastered/PNG/Power-ups/powerupGreen_bolt.png",
	"gas_igniter": "res://assets/Kenney/kenney_space-shooter-remastered/PNG/Power-ups/pill_green.png",
	"crystal_refiner": "res://assets/Kenney/kenney_space-shooter-remastered/PNG/Power-ups/shield_gold.png",
	"quantum_drill": "res://assets/Kenney/kenney_space-shooter-remastered/PNG/Power-ups/powerupYellow_bolt.png",
	"cosmic_forge": "res://assets/Kenney/kenney_space-shooter-remastered/PNG/Power-ups/powerupYellow_star.png",
	"gravitational_pull": "res://assets/Kenney/kenney_space-shooter-remastered/PNG/Power-ups/powerupBlue_star.png",
	"quantum_tunneling": "res://assets/Kenney/kenney_space-shooter-remastered/PNG/Power-ups/powerupBlue_bolt.png",
	"chamber_stabilization": "res://assets/Kenney/kenney_space-shooter-remastered/PNG/Power-ups/powerupBlue_shield.png"
}

const UPGRADE_NAMES = {
	"click_power": "Laser-Power",
	"crit_chance": "Krit-Chance",
	"crit_multiplier": "Krit-Schaden",
	"combo_booster": "Combo-Booster",
	"quantum_clicks": "Quanten-Klicks",
	"crystal_shards": "Kristallsplitter",
	"solar_flare": "Solar-Eruption",
	"plasma_charge": "Plasma-Ladung",
	"resonance_harmonic": "Harmonische Resonanz",
	"gamma_overload": "Gamma-Überlastung",
	"matter_duplication": "Materieduplikation",
	"stellar_dust_extractor": "Sternenstaub-Extraktor",
	"astral_luck": "Astrales Glück",
	"drill": "Plasmabohrer",
	"siphon": "Gas-Siphon",
	"synthesizer": "Synthesizer",
	"nanite_swarm": "Naniten-Schwarm",
	"plasma_condenser": "Plasma-Kondensator",
	"quantum_pipeline": "Quanten-Pipeline",
	"drone_count": "Drohnen-Zahl",
	"drone_speed": "Drohnen-Tempo",
	"meteor_collector": "Kometen-Fänger",
	"warp_drive": "Warp-Antrieb",
	"efficiency_algorithms": "Effizienz-Algorithmen",
	"vacuum_collector": "Vakuum-Kollektor",
	"dark_matter_siphon": "Dunkelmaterie-Siphon",
	"drone_cargo_expansion": "Drohnen-Frachtraum",
	"stellar_wind_turbines": "Sonnenwind-Turbinen",
	"overdrive_governor": "Overdrive-Regler"
}

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_PASS
	
	# Compute size from radius (pointy-topped coordinates)
	var w: float = radius * sqrt(3.0)
	var h: float = radius * 2.0
	custom_minimum_size = Vector2(w, h)
	size = custom_minimum_size
	pivot_offset = Vector2(w / 2.0, h / 2.0)

	# Icon
	icon_rect = TextureRect.new()
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(icon_rect)
	
	# Title label - increased font size to 11
	title_lbl = Label.new()
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	title_lbl.add_theme_constant_override("outline_size", 4)
	title_lbl.add_theme_font_size_override("font_size", 11)
	add_child(title_lbl)
	
	# Level/cost label - increased font size to 10
	level_lbl = Label.new()
	level_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	level_lbl.add_theme_constant_override("outline_size", 4)
	level_lbl.add_theme_font_size_override("font_size", 10)
	add_child(level_lbl)
	
	_layout_children()
	
	mouse_exited.connect(_on_mouse_exited)
	GameManager.stats_changed.connect(update_state)
	GameManager.resource_changed.connect(func(_type, _amount): update_state())
	update_state()

func _process(_delta: float) -> void:
	if visible:
		queue_redraw() # Force smooth 60fps glow pulsing

func _layout_children() -> void:
	var w: float = size.x
	var h: float = size.y
	if w < 4.0 or h < 4.0:
		return
	
	var cx: float = w / 2.0
	var cy: float = h / 2.0
	var icon_size: float = radius * 0.65
	
	if icon_rect:
		icon_rect.size = Vector2(icon_size, icon_size)
		icon_rect.position = Vector2(cx - icon_size / 2.0, cy - icon_size * 0.85)
	if title_lbl:
		title_lbl.size = Vector2(w - 12, 28)
		title_lbl.position = Vector2(6, cy - 2)
		title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if level_lbl:
		level_lbl.size = Vector2(w - 12, 28)
		level_lbl.position = Vector2(6, cy + radius * 0.32)
		level_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_children()

func get_category_color() -> Color:
	if upgrade_type == "skill":
		return Color(1.0, 0.65, 0.0, 1.0)      # Orange
	elif upgrade_type == "singularity":
		return Color(0.9, 0.1, 0.65, 1.0)       # Magenta
	else:
		if upgrade_id in ["click_power", "crit_chance", "crit_multiplier"]:
			return Color(0.05, 0.55, 1.0, 1.0)  # Blue
		else:
			return Color(0.0, 0.85, 0.35, 1.0)  # Green

func _check_is_unlocked() -> bool:
	if upgrade_type == "upgrade":
		return GameManager.upgrade_levels.get(upgrade_id, 0) > 0
	elif upgrade_type == "skill":
		return GameManager.is_skill_unlocked(upgrade_id)
	elif upgrade_type == "singularity":
		return GameManager.singularity_upgrades.get(upgrade_id, 0) > 0
	return false

func _check_is_unlockable() -> bool:
	if upgrade_type == "upgrade":
		return GameManager.is_upgrade_discovered(upgrade_id)
	elif upgrade_type == "skill":
		return GameManager.can_unlock_skill(upgrade_id) or GameManager.is_skill_unlocked(upgrade_id)
	elif upgrade_type == "singularity":
		return GameManager.is_singularity_discovered(upgrade_id)
	return false

func get_hexagon_points(center: Vector2, r: float) -> PackedVector2Array:
	var points = PackedVector2Array()
	for i in range(6):
		var angle = deg_to_rad(30.0 + i * 60.0)
		points.append(center + Vector2(cos(angle), sin(angle)) * r)
	return points

func _draw() -> void:
	var w = size.x
	var h = size.y
	var center = Vector2(w / 2.0, h / 2.0)
	
	var is_unlocked = _check_is_unlocked()
	var is_unlockable = _check_is_unlockable()
	var cat_color = get_category_color()
	
	var fill_color = Color(0.08, 0.08, 0.12, 0.95)
	var border_color = Color(0.25, 0.25, 0.28, 1.0)
	var border_width = 2.0
	
	# Animated pulse scale (cycles between 0.0 and 1.0)
	var pulse = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.0035)
	
	if is_unlocked:
		border_color = cat_color
		# Glow borders slightly pulse
		border_color.a = 0.75 + 0.25 * pulse
		fill_color = cat_color * Color(1.0, 1.0, 1.0, 0.18 + 0.05 * pulse)
		fill_color.a = 0.88
		if hovered:
			fill_color.a = 0.97
			border_width = 3.0
	elif is_unlockable:
		border_color = cat_color * Color(1.0, 1.0, 1.0, 0.6 + 0.2 * pulse)
		fill_color = cat_color * Color(1.0, 1.0, 1.0, 0.05)
		fill_color.a = 0.6
		if hovered:
			fill_color.a = 0.75
			border_width = 2.5
	else:
		# Hologram pulse outline
		border_color = cat_color * Color(1.0, 1.0, 1.0, 0.15 + 0.15 * pulse)
		fill_color = Color(0.04, 0.04, 0.06, 0.3)
		border_width = 1.5
		if hovered:
			border_width = 2.0
			
	# Draw hexagon fill
	var points = get_hexagon_points(center, radius)
	draw_polygon(points, PackedColorArray([fill_color]))
	
	# Draw glowing outer rings if unlocked/unlockable
	if is_unlockable or is_unlocked:
		var glow_color = cat_color
		var hover_mult = 1.5 if hovered else 1.0
		glow_color.a = (0.12 + 0.08 * pulse) * hover_mult
		
		# Rings size pulses slightly as well
		var ring_offset_1 = 2.0 + 1.0 * pulse
		var ring_offset_2 = 4.0 + 1.5 * pulse
		
		var glow_points_1 = get_hexagon_points(center, radius + ring_offset_1)
		var glow_points_2 = get_hexagon_points(center, radius + ring_offset_2)
		draw_polyline(glow_points_1, glow_color, 1.5, true)
		draw_polyline(glow_points_2, glow_color * 0.5, 1.0, true)
		
	# Draw final closed border outline
	var closed_points = PackedVector2Array(points)
	closed_points.append(points[0])
	draw_polyline(closed_points, border_color, border_width, true)

func update_state() -> void:
	var discovered: bool = false
	var unlocked: bool = false
	var maxed: bool = false
	var name_text: String = ""
	var details_text: String = ""
	
	if upgrade_type == "upgrade":
		discovered = GameManager.is_upgrade_discovered(upgrade_id)
		unlocked = discovered
		name_text = UPGRADE_NAMES.get(upgrade_id, upgrade_id)
		
		var current_lvl: int = GameManager.upgrade_levels.get(upgrade_id, 0)
		var max_lvl: int = 999
		if upgrade_id == "drone_count":
			max_lvl = 8
		if current_lvl >= max_lvl:
			maxed = true
			details_text = "MAX"
		else:
			var cost: float = GameManager.get_upgrade_cost(upgrade_id)
			var cost_type: String = GameManager.get_upgrade_cost_type(upgrade_id)
			var currency_lbl: String = "Erz" if cost_type == "space_ore" else cost_type
			details_text = "Lvl %d\n(%s %s)" % [current_lvl, _format_number(cost), currency_lbl]
			
	elif upgrade_type == "skill":
		discovered = GameManager.is_skill_discovered(upgrade_id)
		unlocked = GameManager.can_unlock_skill(upgrade_id) or GameManager.is_skill_unlocked(upgrade_id)
		maxed = GameManager.is_skill_unlocked(upgrade_id)
		var config: Dictionary = GameManager.SKILL_CONFIG.get(upgrade_id, {})
		name_text = config.get("name", upgrade_id)
		if maxed:
			details_text = "Gekauft"
		else:
			var cost: float = config.get("cost", 0.0)
			details_text = "%s Krist." % _format_number(cost)
			
	elif upgrade_type == "singularity":
		discovered = GameManager.is_singularity_discovered(upgrade_id)
		var config: Dictionary = GameManager.SINGULARITY_CONFIG.get(upgrade_id, {})
		name_text = config.get("name", upgrade_id)
		var current_lvl: int = GameManager.singularity_upgrades.get(upgrade_id, 0)
		var cost: float = GameManager.get_singularity_cost(upgrade_id)
		details_text = "Lvl %d\n(%s DM)" % [current_lvl, _format_number(cost)]
		unlocked = discovered

	# Visibility
	visible = discovered
	if not visible:
		return
	
	queue_redraw()
	
	# Icon
	if icon_rect:
		if ICON_PATHS.has(upgrade_id):
			icon_rect.texture = load(ICON_PATHS[upgrade_id])
		else:
			icon_rect.texture = null
		icon_rect.self_modulate = Color.WHITE if unlocked else Color(0.3, 0.3, 0.3, 0.6)
	
	# Labels
	if title_lbl:
		title_lbl.text = name_text
		title_lbl.self_modulate = Color.WHITE if unlocked else Color(0.5, 0.5, 0.5, 0.7)
	
	if level_lbl:
		level_lbl.text = details_text
		if maxed:
			level_lbl.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
		elif not unlocked:
			level_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.7))
		else:
			var can_afford: bool = false
			if upgrade_type == "upgrade":
				var cost_type: String = GameManager.get_upgrade_cost_type(upgrade_id)
				can_afford = GameManager.get_resource(cost_type) >= GameManager.get_upgrade_cost(upgrade_id)
			elif upgrade_type == "skill":
				var cfg: Dictionary = GameManager.SKILL_CONFIG.get(upgrade_id, {})
				can_afford = GameManager.get_resource(cfg.get("cost_type", "")) >= cfg.get("cost", 0.0)
			elif upgrade_type == "singularity":
				can_afford = GameManager.dark_matter >= GameManager.get_singularity_cost(upgrade_id)
			if can_afford:
				level_lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
			else:
				level_lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))

func _is_pos_inside(pos: Vector2) -> bool:
	var center = size / 2.0
	var dx = abs(pos.x - center.x)
	var dy = abs(pos.y - center.y)
	
	# Precise pointy-topped hexagon hit testing:
	var h_limit = radius * sqrt(3.0) / 2.0
	if dx > h_limit or dy > radius:
		return false
	return dy + dx / sqrt(3.0) <= radius

func _gui_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseMotion:
		var was_hovered: bool = hovered
		hovered = _is_pos_inside(event.position)
		if was_hovered != hovered:
			_update_hover_anim()
			hexagon_hovered.emit(upgrade_id, upgrade_type, hovered)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if _is_pos_inside(event.position):
					pressed = true
					_update_press_anim()
					accept_event()
			else:
				if pressed:
					pressed = false
					_update_hover_anim()
					if _is_pos_inside(event.position):
						hexagon_pressed.emit()
						accept_event()

func _on_mouse_exited() -> void:
	if hovered or pressed:
		hovered = false
		pressed = false
		_update_hover_anim()
		hexagon_hovered.emit(upgrade_id, upgrade_type, false)

func _update_hover_anim() -> void:
	queue_redraw()
	if active_tween:
		active_tween.kill()
	active_tween = create_tween()
	var target_scale: Vector2 = Vector2(1.06, 1.06) if hovered else Vector2.ONE
	active_tween.tween_property(self, "scale", target_scale, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _update_press_anim() -> void:
	if active_tween:
		active_tween.kill()
	active_tween = create_tween()
	active_tween.tween_property(self, "scale", Vector2(0.94, 0.94), 0.08).set_trans(Tween.TRANS_LINEAR)

func _format_number(val: float) -> String:
	if val < 1000.0:
		return str(int(val))
	elif val < 1000000.0:
		return "%.1fK" % (val / 1000.0)
	elif val < 1000000000.0:
		return "%.1fM" % (val / 1000000.0)
	else:
		return "%.1fB" % (val / 1000000000.0)
