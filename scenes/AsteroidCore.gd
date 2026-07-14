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
var solar_flare_counter: int = 0
var consecutive_clicks: int = 0
var photon_amplifier_stacks: float = 0.0
var photon_amplifier_timer: float = 0.0

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
			
	# Photon amplifier decay
	if photon_amplifier_timer > 0.0:
		photon_amplifier_timer -= delta
		if photon_amplifier_timer <= 0.0:
			photon_amplifier_stacks = 0.0
	
	# Rotation speeds
	var rot_speed = 0.35 + float(GameManager.upgrade_levels["drill"]) * 0.015
	# Boost rotation based on combos
	rot_speed += float(click_combo) * 0.05
	
	asteroid_rot += rot_speed * delta
	ring_rot -= (rot_speed * 1.4) * delta
	
	# Breathing/Pulsing effect when idle (intensified by combo)
	var combo_speed_mult = 1.0 + float(click_combo) * 0.2
	pulse_time += delta * 2.2 * combo_speed_mult
	var pulse_amp = 0.012 if not is_hovered else 0.032
	if click_combo >= 5:
		pulse_amp += float(click_combo) * 0.005
	var pulse = 1.0 + sin(pulse_time) * pulse_amp
	
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
		
	# Draw Concentric Orbital Rings (Option A: Thin vector orbits with single sliding sonds)
	# Ring 1 (Inner) - Pink Orbit & Sond
	var r1_radius = base_radius + 15.0
	draw_arc(center, r1_radius, 0.0, TAU, 48, Color(1.0, 0.0, 0.5, 0.12), 1.0, true)
	var angle1 = ring_rot
	var sonde_pos1 = center + Vector2(cos(angle1) * r1_radius, sin(angle1) * r1_radius)
	draw_circle(sonde_pos1, 3.5, Color(1.0, 0.0, 0.5, 0.8))
	draw_circle(sonde_pos1, 6.0, Color(1.0, 0.0, 0.5, 0.25))
		
	# Ring 2 (Middle) - Cyan Orbit & Sond
	var r2_radius = base_radius + 35.0
	draw_arc(center, r2_radius, 0.0, TAU, 64, Color(0.0, 0.94, 1.0, 0.08), 1.0, true)
	var angle2 = ring_rot * -1.4
	var sonde_pos2 = center + Vector2(cos(angle2) * r2_radius, sin(angle2) * r2_radius)
	draw_circle(sonde_pos2, 4.0, Color(0.0, 0.94, 1.0, 0.8))
	draw_circle(sonde_pos2, 7.0, Color(0.0, 0.94, 1.0, 0.2))
		
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
		# Option 1: Clean circular glass shield outline
		var shield_radius = base_radius * 1.15
		var shield_color = border_color
		shield_color.a = 0.55 if is_hovered else 0.35
		
		# Draw a very soft semi-transparent backing for the shield
		var shield_fill = border_color
		shield_fill.a = 0.04 if is_hovered else 0.015
		draw_circle(center, shield_radius, shield_fill)
		
		# Draw the circular shield ring
		draw_arc(center, shield_radius, 0.0, TAU, 64, shield_color, 1.2, true)
		
		# Draw a faint outer glow ring
		var outer_glow = shield_color
		outer_glow.a *= 0.3
		draw_arc(center, shield_radius + 2.0, 0.0, TAU, 64, outer_glow, 0.8, true)
			
	# Draw Combo Fever Visual Effects (Lightning, Energy Rings, Extra Glows)
	if click_combo >= 5:
		var base_color = Color(0.0, 0.94, 1.0) if click_combo < 10 else Color(1.0, 0.0, 0.5)
		# Subtle inner glow only — no big bloom
		for j in range(2):
			var layer_radius = base_radius * (1.05 + float(j) * 0.1 + sin(pulse_time * 2.0) * 0.03)
			var layer_color = base_color
			layer_color.a = 0.05 / (j + 1.0)
			draw_circle(center, layer_radius, layer_color)
			
		# Faint pulsing ring — barely visible
		var ring_scale = fmod(pulse_time * 0.5, 1.0)
		var ring_color = base_color
		ring_color.a = (1.0 - ring_scale) * 0.12
		draw_arc(center, base_radius * (1.0 + ring_scale * 0.6), 0.0, TAU, 24, ring_color, 1.2, true)
		
	# Small surface arcs — only appear at x5+, subtle at x3-4
	if click_combo >= 5:
		var num_arcs = 1 if click_combo < 10 else 2
		var rot_xform_local = Transform2D(asteroid_rot, Vector2.ZERO)
		for a in range(num_arcs):
			var idx1 = (randi() + a) % asteroid_points.size()
			var idx2 = (idx1 + 4 + (randi() % (asteroid_points.size() - 8))) % asteroid_points.size()
			var pt1 = center + rot_xform_local * asteroid_points[idx1]
			var pt2 = center + rot_xform_local * asteroid_points[idx2]
			
			var lt_color = Color(0.0, 0.94, 1.0, 0.35) if click_combo < 10 else Color(1.0, 0.0, 0.5, 0.4)
			_draw_lightning(pt1, pt2, lt_color, 1.5)
			
	if click_combo >= 10:
		var rot_xform_local = Transform2D(asteroid_rot, Vector2.ZERO)
		# Only 1 subtle outer arc at x10
		var idx = randi() % asteroid_points.size()
		var angle = (float(idx) / asteroid_points.size()) * TAU + asteroid_rot
		var start_pt = center + rot_xform_local * asteroid_points[idx]
		var end_pt = center + Vector2(cos(angle) * (base_radius * 1.4), sin(angle) * (base_radius * 1.4))
		_draw_lightning(start_pt, end_pt, Color(1.0, 0.0, 0.5, 0.35), 1.8)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		trigger_click(event.position)

func trigger_click(click_pos: Vector2) -> void:
	# 1. Combo scaling (Combo Booster increases combo cap)
	var max_combo = 10 + GameManager.upgrade_levels.get("combo_booster", 0)
	click_combo = min(max_combo, click_combo + 1)
	combo_decay_timer = COMBO_DECAY_MAX
	
	# 2. Squash & Stretch Rebound (gentler, more elastic bounce)
	current_scale = Vector2(0.94, 0.94)
	spring_velocity = Vector2(3.5, 3.5)
	
	# Retrieve base click power
	var base_power = GameManager.get_click_power()
	
	# Apply photon_amplifier (+2% click power per stack per level, stacks up to 25 times)
	var pa_lvl = GameManager.upgrade_levels.get("photon_amplifier", 0)
	if pa_lvl > 0:
		base_power *= (1.0 + photon_amplifier_stacks * 0.02 * float(pa_lvl))
		photon_amplifier_stacks = min(25.0, photon_amplifier_stacks + 1.0)
		photon_amplifier_timer = 2.0
	
	# Apply plasma_charge (+1% click power per level per cosmic_gas owned)
	var pc_lvl = GameManager.upgrade_levels.get("plasma_charge", 0)
	if pc_lvl > 0:
		base_power *= (1.0 + float(pc_lvl) * 0.01 * GameManager.cosmic_gas)
	
	# Apply resonance_harmonic (+1% crit chance per consecutive click per level, resets on crit)
	var rh_lvl = GameManager.upgrade_levels.get("resonance_harmonic", 0)
	var resonance_bonus = 0.0
	if rh_lvl > 0:
		resonance_bonus = float(consecutive_clicks) * 0.01 * float(rh_lvl)
	
	# Determine Crit state
	var is_crit = randf() <= (GameManager.get_crit_chance() + resonance_bonus)
	if is_crit:
		consecutive_clicks = 0
	else:
		consecutive_clicks += 1
		
	# Apply matter_duplication (+25% chance per level on crit for 4-fold reward mult)
	var md_lvl = GameManager.upgrade_levels.get("matter_duplication", 0)
	var matter_mult = 1.0
	if is_crit and md_lvl > 0 and randf() <= float(md_lvl) * 0.25:
		matter_mult = 4.0
		JuiceManager.spawn_floating_text(self, click_pos, "MATERIEDUPLIKATION!\n4x Ressourcen!", true, Color(1.0, 0.0, 0.85))
		JuiceManager.trigger_flash(Color(1.0, 0.0, 0.85, 0.3), 0.4)
	
	# Apply Click Combo Multiplier to ore yield (+10% per combo level)
	var combo_mult = 1.0 + float(click_combo) * 0.1
	var mined_ore = base_power * combo_mult
	if is_crit:
		mined_ore *= GameManager.get_crit_multiplier()
		
	# Apply matter_duplication multiplier to ore
	mined_ore *= matter_mult
	
	# Apply quantum_clicks chance (+3% chance per level for double resources mined)
	var qc_lvl = GameManager.upgrade_levels.get("quantum_clicks", 0)
	var double_clicked = false
	if qc_lvl > 0 and randf() <= float(qc_lvl) * 0.03:
		mined_ore *= 2.0
		double_clicked = true
		
	# Add resource
	GameManager.add_resource("space_ore", mined_ore)
	GameManager.add_stat("manual_clicks", 1.0)
	
	# Skill upgrades bonus
	var mined_gas = 0.0
	var mined_crystals = 0.0
	if is_crit and GameManager.is_skill_unlocked("crystal_refiner"):
		if randf() <= 0.30:
			mined_gas = float(int(base_power * 0.2) + 1)
			if double_clicked: mined_gas *= 2.0
			mined_gas *= matter_mult
			GameManager.add_resource("cosmic_gas", mined_gas)
		if randf() <= 0.10:
			mined_crystals = float(int(base_power * 0.05) + 1)
			if double_clicked: mined_crystals *= 2.0
			mined_crystals *= matter_mult
			GameManager.add_resource("star_crystals", mined_crystals)

	# Apply crystal_shards upgrade (+2% gas / +0.5% crystal per level on ANY manual click)
	var cs_lvl = GameManager.upgrade_levels.get("crystal_shards", 0)
	if cs_lvl > 0:
		if randf() <= float(cs_lvl) * 0.02:
			var shard_gas = 1.0 * (2.0 if double_clicked else 1.0) * matter_mult
			mined_gas += shard_gas
			GameManager.add_resource("cosmic_gas", shard_gas)
		if randf() <= float(cs_lvl) * 0.005:
			var shard_crys = 1.0 * (2.0 if double_clicked else 1.0) * matter_mult
			mined_crystals += shard_crys
			GameManager.add_resource("star_crystals", shard_crys)

	# Apply stellar_dust_extractor (+0.1% chance per level on click to direct stardust reward, boosted by stardust_catalyst)
	var sde_lvl = GameManager.upgrade_levels.get("stellar_dust_extractor", 0)
	if sde_lvl > 0:
		var cat_lvl = GameManager.upgrade_levels.get("stardust_catalyst", 0)
		var dust_chance = float(sde_lvl) * 0.001 * (1.0 + float(cat_lvl) * 0.50)
		if randf() <= dust_chance:
			GameManager.add_resource("stardust", 1.0)
			JuiceManager.spawn_floating_text(self, click_pos + Vector2(0, -35), "+1 Sternenstaub!", true, Color(0.22, 1.0, 0.08))

	# Apply quantum_vacuum_extractor (+5% chance per level on crit to generate +0.05 DM)
	var qve_lvl = GameManager.upgrade_levels.get("quantum_vacuum_extractor", 0)
	if is_crit and qve_lvl > 0 and randf() <= float(qve_lvl) * 0.05:
		GameManager.add_resource("dark_matter", 0.05)
		JuiceManager.spawn_floating_text(self, click_pos + Vector2(-40, -45), "+0.05 Dunkelmaterie!", true, Color(1.0, 0.45, 0.0))

	# Apply gamma_overload (+10% chance on crit per level to activate Overdrive)
	var go_lvl = GameManager.upgrade_levels.get("gamma_overload", 0)
	if is_crit and go_lvl > 0 and randf() <= float(go_lvl) * 0.10:
		GameManager.overdrive_active = true
		var gov_lvl = GameManager.upgrade_levels.get("overdrive_governor", 0)
		var overdrive_dur = 5.0 + float(gov_lvl) * 1.5
		GameManager.overdrive_timer = max(GameManager.overdrive_timer, overdrive_dur)
		GameManager.stats_changed.emit()
		JuiceManager.trigger_flash(Color(0.8, 0.0, 1.0, 0.4), 0.5)
		JuiceManager.spawn_floating_text(self, click_pos, "GAMMA-ÜBERLASTUNG!\nOverdrive aktiv!", true, Color(0.8, 0.0, 1.0))

	# Apply solar_flare counter (triggers Overdrive every X clicks)
	var sf_lvl = GameManager.upgrade_levels.get("solar_flare", 0)
	if sf_lvl > 0:
		solar_flare_counter += 1
		var threshold = max(20, 60 - sf_lvl * 5)
		if solar_flare_counter >= threshold:
			solar_flare_counter = 0
			GameManager.overdrive_active = true
			var gov_lvl = GameManager.upgrade_levels.get("overdrive_governor", 0)
			GameManager.overdrive_timer = 8.0 + float(sf_lvl) * 1.0 + float(gov_lvl) * 1.5
			GameManager.stats_changed.emit()
			JuiceManager.trigger_flash(Color(1.0, 0.45, 0.0, 0.45), 0.6)
			JuiceManager.spawn_floating_text(self, click_pos, "SOLAR-ERUPTION!\nProduktion verdoppelt!", true, Color(1.0, 0.45, 0.0))

	# Apply hyper_drive_clicks (+5% * level chance to extend active overdrive by 1s on click)
	if GameManager.overdrive_active:
		var hdc_lvl = GameManager.upgrade_levels.get("hyper_drive_clicks", 0)
		if hdc_lvl > 0 and randf() <= float(hdc_lvl) * 0.05:
			GameManager.overdrive_timer += 1.0
			JuiceManager.spawn_floating_text(self, click_pos + Vector2(40, -25), "+1s Overdrive!", false, Color(1.0, 0.45, 0.0))

	# Emit Click Signal
	core_clicked.emit(click_pos, is_crit, mined_ore)
	
	if click_combo >= 10 and is_crit:
		JuiceManager.shake_camera(6.0, 0.25)
	
	# Combo-pitched sound chimes (softened volumes)
	var combo_pitch = 1.0 + float(click_combo) * 0.04
	if is_crit:
		SoundManager.play_sound(SoundManager.crit_stream, 0.02, -12.0, combo_pitch)
	else:
		SoundManager.play_sound(SoundManager.click_stream, 0.04, -18.0, combo_pitch)

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

func _draw_lightning(start_pos: Vector2, end_pos: Vector2, color: Color, thickness: float) -> void:
	var pts = PackedVector2Array()
	pts.append(start_pos)
	
	var segments = 4
	var current = start_pos
	for i in range(1, segments):
		var t = float(i) / segments
		var target = start_pos.lerp(end_pos, t)
		var diff = end_pos - start_pos
		var normal = Vector2(-diff.y, diff.x).normalized()
		var jitter = normal * randf_range(-10.0, 10.0)
		current = target + jitter
		pts.append(current)
		
	pts.append(end_pos)
	draw_polyline(pts, color, thickness, true)
