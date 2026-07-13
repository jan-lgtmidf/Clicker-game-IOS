extends Control

signal core_clicked(position: Vector2, is_crit: bool, ore_amount: float)

@export var floating_text_scene: PackedScene = preload("res://scenes/FloatingText.tscn")

var core_tex_stage1 = preload("res://assets/Kenney/kenney_space-shooter-remastered/PNG/Meteors/meteorBrown_big2.png")
var core_tex_stage2 = preload("res://assets/Kenney/kenney_planets/Planets/planet01.png")
var core_tex_stage3 = preload("res://assets/Kenney/kenney_planets/Planets/planet00.png")
var core_tex_stage4 = preload("res://assets/Kenney/kenney_planets/Planets/planet08.png")

var normal_particle_tex = preload("res://assets/Kenney/kenney_space-shooter-remastered/PNG/Meteors/meteorGrey_tiny1.png")
var crit_particle_tex = preload("res://assets/Kenney/kenney_space-shooter-remastered/PNG/Effects/star1.png")

# Visual customization
var base_radius: float = 90.0
var asteroid_points: PackedVector2Array = []
var asteroid_rot: float = 0.0
var ring_rot: float = 0.0

# Colors matching the neon dark-mode theme
var fill_color: Color = Color(0.05, 0.03, 0.12, 1.0)
var border_color: Color = Color(0.0, 0.94, 1.0, 1.0)
var glow_color: Color = Color(0.0, 0.94, 1.0, 0.25)

# Squash and Stretch Spring variables (Reactor Spring)
var current_scale: Vector2 = Vector2.ONE
var spring_velocity: Vector2 = Vector2.ZERO
const SPRING_K: float = 260.0
const SPRING_DAMPING: float = 12.0

# Click Combo System
var click_combo: int = 0
var combo_decay_timer: float = 0.0
const COMBO_DECAY_MAX: float = 1.2

# Super-Nova Active Warning contraction ring scale (0.0 means inactive)
var supernova_ring_scale: float = 0.0

# Hover state
var is_hovered: bool = false
var pulse_time: float = 0.0

# Reference to the Particle Emitter (configured dynamically)
var particle_emitter: CPUParticles2D

func _ready() -> void:
	set_process(true)
	generate_asteroid_shape()
	custom_minimum_size = Vector2(300, 300)
	pivot_offset = Vector2(150, 150)
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_setup_particle_emitter()

func _setup_particle_emitter() -> void:
	particle_emitter = CPUParticles2D.new()
	add_child(particle_emitter)
	
	particle_emitter.emitting = false
	particle_emitter.one_shot = true
	particle_emitter.amount = 40
	particle_emitter.lifetime = 0.6
	particle_emitter.explosiveness = 0.95
	particle_emitter.spread = 180.0
	particle_emitter.gravity = Vector2(0, 180)
	particle_emitter.initial_velocity_min = 130.0
	particle_emitter.initial_velocity_max = 260.0
	particle_emitter.damping_min = 60.0
	particle_emitter.damping_max = 120.0
	particle_emitter.scale_amount_min = 4.0
	particle_emitter.scale_amount_max = 12.0
	
	var curve = Curve.new()
	curve.add_point(Vector2(0, 1))
	curve.add_point(Vector2(1, 0))
	particle_emitter.scale_amount_curve = curve
	particle_emitter.position = Vector2(150, 150)

func generate_asteroid_shape() -> void:
	asteroid_points.clear()
	var num_vertices = 18
	var rng = RandomNumberGenerator.new()
	rng.seed = 42
	
	for i in range(num_vertices):
		var angle = (float(i) / num_vertices) * TAU
		var r_mult = rng.randf_range(0.85, 1.15)
		
		# Make it more irregular for Rocky stage
		var r = base_radius * r_mult
		asteroid_points.append(Vector2(cos(angle) * r, sin(angle) * r))

func _process(delta: float) -> void:
	_update_colors_by_tier()
	
	# Combo system decay
	if combo_decay_timer > 0.0:
		combo_decay_timer -= delta
		if combo_decay_timer <= 0.0:
			click_combo = 0
	
	# Rotation speeds
	var rot_speed = 0.35 + float(GameManager.upgrade_levels["drill"]) * 0.015
	# Boost rotation based on combos
	rot_speed += float(click_combo) * 0.05
	
	asteroid_rot += rot_speed * delta
	ring_rot -= (rot_speed * 1.4) * delta
	
	# Breathing/Pulsing effect when idle
	pulse_time += delta * 2.2
	var pulse = 1.0 + sin(pulse_time) * (0.012 if not is_hovered else 0.032)
	
	# Spring physics for Squash & Stretch
	var displacement = current_scale - Vector2(pulse, pulse)
	var force = -SPRING_K * displacement - SPRING_DAMPING * spring_velocity
	spring_velocity += force * delta
	current_scale += spring_velocity * delta
	
	scale = current_scale
	queue_redraw()

func _update_colors_by_tier() -> void:
	var click_lvl = GameManager.upgrade_levels["click_power"]
	if click_lvl < 10:
		border_color = Color(0.0, 0.94, 1.0) # Cyan
		glow_color = Color(0.0, 0.94, 1.0, 0.25)
	elif click_lvl < 25:
		border_color = Color(1.0, 0.0, 0.5) # Pink
		glow_color = Color(1.0, 0.0, 0.5, 0.25)
	elif click_lvl < 50:
		border_color = Color(1.0, 0.84, 0.0) # Gold
		glow_color = Color(1.0, 0.84, 0.0, 0.25)
	else:
		border_color = Color(0.22, 1.0, 0.08) # Green
		glow_color = Color(0.22, 1.0, 0.08, 0.35)

func _draw() -> void:
	var center = Vector2(150, 150)
	var click_lvl = GameManager.upgrade_levels["click_power"]
	
	# Draw Super-Nova alert timing ring (flashing orange contraction ring)
	if supernova_ring_scale > 0.0:
		var alert_color = Color(1.0, 0.35, 0.0, 0.8)
		# Flashes faster near containing size
		if fmod(Time.get_ticks_msec() / 100.0, 2.0) > 1.0:
			alert_color = Color(1.0, 0.8, 0.0, 0.9)
		draw_circle(center, base_radius * supernova_ring_scale, alert_color)
		# Draw outer ring border
		draw_arc(center, base_radius * supernova_ring_scale + 5, 0.0, TAU, 32, alert_color, 2.0)
	
	# Determine Core Evolution Stage
	var stage = 1
	if click_lvl >= 50: stage = 4 # Stage 4: Singularity Black Hole
	elif click_lvl >= 25: stage = 3 # Stage 3: Pulsar Star
	elif click_lvl >= 10: stage = 2 # Stage 2: Magnetic Geometric Cage
	
	# Stage-specific drawing background layer
	if stage == 4:
		# Draw 3D Gravitational Accretion Disk (Skewed Ellipse)
		var disk_pts = PackedVector2Array()
		var num_disk_pts = 32
		var skew_y_mult = 0.35
		var rotation_offset = ring_rot * 0.8
		for i in range(num_disk_pts + 1):
			var angle = (float(i) / num_disk_pts) * TAU + rotation_offset
			var pt = Vector2(cos(angle) * (base_radius * 1.9), sin(angle) * (base_radius * 1.9) * skew_y_mult)
			disk_pts.append(center + pt)
		# Accretion Glow backing
		draw_polyline(disk_pts, Color(1.0, 0.38, 0.0, 0.65), 14.0, true)
		draw_polyline(disk_pts, Color(1.0, 0.84, 0.0, 0.85), 4.0, true)
		
		# Accretion inner disk
		var disk_in_pts = PackedVector2Array()
		for i in range(num_disk_pts + 1):
			var angle = (float(i) / num_disk_pts) * TAU + (rotation_offset * -1.3)
			var pt = Vector2(cos(angle) * (base_radius * 1.4), sin(angle) * (base_radius * 1.4) * skew_y_mult)
			disk_in_pts.append(center + pt)
		draw_polyline(disk_in_pts, Color(1.0, 0.0, 0.5, 0.4), 6.0, true)
		
	elif stage == 3:
		# Draw Pulsar Jet Beams (rotating vertical plasma beams)
		var beam_rot = ring_rot * 0.5
		var rot_xform_beams = Transform2D(beam_rot, Vector2.ZERO)
		
		var beam1 = PackedVector2Array([
			center + rot_xform_beams * Vector2(-15, -10),
			center + rot_xform_beams * Vector2(0, -320),
			center + rot_xform_beams * Vector2(15, -10)
		])
		var beam2 = PackedVector2Array([
			center + rot_xform_beams * Vector2(-15, 10),
			center + rot_xform_beams * Vector2(0, 320),
			center + rot_xform_beams * Vector2(15, 10)
		])
		# Glowing beams
		draw_colored_polygon(beam1, Color(0.0, 0.94, 1.0, 0.15 + (sin(pulse_time * 2.0) * 0.05)))
		draw_colored_polygon(beam2, Color(0.0, 0.94, 1.0, 0.15 + (sin(pulse_time * 2.0) * 0.05)))
		draw_polyline(beam1, Color(0.0, 0.94, 1.0, 0.35), 1.5, true)
		draw_polyline(beam2, Color(0.0, 0.94, 1.0, 0.35), 1.5, true)
		
	# Draw Concentric Orbital Rings (alternating directions)
	# Ring 1 (Inner) - Pink
	var r1_dots = 12
	var r1_radius = base_radius + 15.0
	for i in range(r1_dots):
		var angle = (float(i) / r1_dots) * TAU + ring_rot
		var dot_pos = center + Vector2(cos(angle) * r1_radius, sin(angle) * r1_radius)
		draw_circle(dot_pos, 3.0, Color(1.0, 0.0, 0.5, 0.35))
		
	# Ring 2 (Middle) - Cyan
	var r2_dots = 16
	var r2_radius = base_radius + 35.0
	for i in range(r2_dots):
		var angle = (float(i) / r2_dots) * TAU + (ring_rot * -1.4)
		var dot_pos = center + Vector2(cos(angle) * r2_radius, sin(angle) * r2_radius)
		draw_circle(dot_pos, 4.5, Color(0.0, 0.94, 1.0, 0.25))
		
	# Core Glow Layer Backing
	var rot_xform = Transform2D(asteroid_rot, Vector2.ZERO)
	var rotated_pts = []
	for p in asteroid_points:
		rotated_pts.append(center + rot_xform * p)
		
	var glow_layers = 4
	for i in range(glow_layers):
		var factor = 1.0 + (float(i + 1) * 0.04)
		var glow_pts = []
		for p in asteroid_points:
			glow_pts.append(center + (rot_xform * p) * factor)
		var current_glow = glow_color
		# Glow increases during high click combos!
		current_glow.a = (glow_color.a + float(click_combo) * 0.02) / (i + 1.1)
		
		if stage == 4:
			# Singularity has dense cyan/black event horizon glow
			current_glow = Color(0.0, 0.94, 1.0, 0.15) / (i + 1.0)
			
		draw_colored_polygon(PackedVector2Array(glow_pts), current_glow)
		
	# Draw Core using preloaded Kenney textures
	var active_tex = core_tex_stage1
	var tex_scale = 1.0
	match stage:
		1:
			active_tex = core_tex_stage1
			tex_scale = 1.05
		2:
			active_tex = core_tex_stage2
			tex_scale = 1.1
		3:
			active_tex = core_tex_stage3
			tex_scale = 1.15
		4:
			active_tex = core_tex_stage4
			tex_scale = 1.2
			
	if active_tex:
		draw_set_transform(center, asteroid_rot, Vector2.ONE)
		var size_to_draw = Vector2(base_radius * 2 * tex_scale, base_radius * 2 * tex_scale)
		draw_texture_rect(active_tex, Rect2(-size_to_draw/2, size_to_draw), false)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		
	# Draw stage overlays
	if stage == 4:
		# Draw Singularity Event Horizon (Black hole center)
		draw_circle(center, base_radius * 0.45, Color(0.01, 0.0, 0.03, 1.0))
		draw_arc(center, base_radius * 0.45, 0.0, TAU, 32, border_color, 2.5, true)
	elif stage == 3:
		# Draw Pulsar star sphere inner glow border
		draw_arc(center, base_radius * 0.90, 0.0, TAU, 32, border_color, 2.5, true)
	else:
		# Draw standard Rocky Core neon outline for Stage 1 & 2
		var poly_pts = PackedVector2Array(rotated_pts)
		poly_pts.append(poly_pts[0])
		draw_polyline(poly_pts, border_color, 4.0 if is_hovered else 2.5, true)
		
	# Draw Stage 2: Geometric Iron Cage around core
	if stage == 2:
		var cage_rot = ring_rot * 0.7
		var cage_xform = Transform2D(cage_rot, Vector2.ZERO)
		var cage_pts = []
		var num_cage_vertices = 6
		for i in range(num_cage_vertices):
			var angle = (float(i) / num_cage_vertices) * TAU
			var pt = Vector2(cos(angle) * (base_radius * 1.25), sin(angle) * (base_radius * 1.25))
			cage_pts.append(center + cage_xform * pt)
		cage_pts.append(cage_pts[0])
		# Draw cage wireframes
		draw_polyline(PackedVector2Array(cage_pts), Color(0.0, 0.94, 1.0, 0.75), 1.5, true)
		for pt in cage_pts:
			draw_line(center, pt, Color(0.0, 0.94, 1.0, 0.25), 1.0)
			draw_circle(pt, 5.0, Color(0.0, 0.94, 1.0, 0.9))

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		trigger_click(event.position)

func trigger_click(click_pos: Vector2) -> void:
	# 1. Combo scaling
	click_combo = min(10, click_combo + 1)
	combo_decay_timer = COMBO_DECAY_MAX
	
	# 2. Squash & Stretch Rebound
	current_scale = Vector2(0.75, 0.75)
	spring_velocity = Vector2(12.0, 12.0)
	
	# Determine Crit state
	var is_crit = randf() <= GameManager.get_crit_chance()
	var base_power = GameManager.get_click_power()
	
	# Apply Click Combo Multiplier to ore yield (+10% per combo level, up to +100% at combo 10)
	var combo_mult = 1.0 + float(click_combo) * 0.1
	var mined_ore = base_power * combo_mult
	if is_crit:
		mined_ore *= GameManager.get_crit_multiplier()
		
	# Add resource
	GameManager.add_resource("space_ore", mined_ore)
	GameManager.add_stat("manual_clicks", 1.0)
	
	# Skill upgrades bonus
	var mined_gas = 0.0
	var mined_crystals = 0.0
	if is_crit and GameManager.is_skill_unlocked("crystal_refiner"):
		if randf() <= 0.30:
			mined_gas = float(int(base_power * 0.2) + 1)
			GameManager.add_resource("cosmic_gas", mined_gas)
		if randf() <= 0.10:
			mined_crystals = float(int(base_power * 0.05) + 1)
			GameManager.add_resource("star_crystals", mined_crystals)

	# Emit Click Signal
	core_clicked.emit(click_pos, is_crit, mined_ore)
	
	# Combo-pitched sound chimes
	var combo_pitch = 1.0 + float(click_combo) * 0.05
	if is_crit:
		SoundManager.play_sound(SoundManager.crit_stream, 0.02, -2.0, combo_pitch)
	else:
		SoundManager.play_sound(SoundManager.click_stream, 0.04, -4.0, combo_pitch)

	# Spurt Particles
	var color_to_use = Color(0.0, 0.94, 1.0)
	if is_crit:
		color_to_use = Color(1.0, 0.84, 0.0)
	if mined_crystals > 0:
		color_to_use = Color(1.0, 0.84, 0.0)
	elif mined_gas > 0:
		color_to_use = Color(1.0, 0.0, 0.5)
		
	# Combo particles scaling
	particle_emitter.amount = 40 + click_combo * 4
	particle_emitter.color = color_to_use
	particle_emitter.position = click_pos
	
	if is_crit:
		particle_emitter.texture = crit_particle_tex
		particle_emitter.scale_amount_min = 0.08
		particle_emitter.scale_amount_max = 0.22
	else:
		particle_emitter.texture = normal_particle_tex
		particle_emitter.scale_amount_min = 0.4
		particle_emitter.scale_amount_max = 1.0
		
	particle_emitter.restart()
	
	# Spawning color-coded floating text popups (with combo text sizing)
	if is_crit:
		JuiceManager.spawn_floating_text(self, click_pos, "CRIT! +" + str(int(mined_ore)) + " Ore", true, Color(1.0, 0.84, 0.0), click_combo)
	else:
		JuiceManager.spawn_floating_text(self, click_pos, "+" + str(int(mined_ore)) + " Ore", false, Color(0.0, 0.94, 1.0), click_combo)
		
	if mined_gas > 0:
		JuiceManager.spawn_floating_text(self, click_pos + Vector2(-50, -25), "+" + str(int(mined_gas)) + " Gas", false, Color(1.0, 0.0, 0.5), click_combo)
	if mined_crystals > 0:
		JuiceManager.spawn_floating_text(self, click_pos + Vector2(50, -25), "+" + str(int(mined_crystals)) + " Crystal", true, Color(1.0, 0.84, 0.0), click_combo)

func _on_mouse_entered() -> void:
	is_hovered = true
	current_scale = Vector2(1.08, 1.08)

func _on_mouse_exited() -> void:
	is_hovered = false
