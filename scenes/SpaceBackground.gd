extends Control

# Background Starfield and Nebula Shader simulation
var stars: Array = []
var nebula_particles: Array = []
var num_stars = 40
var num_nebulae = 4

var center: Vector2
var rot_angle: float = 0.0

# Sound-to-light Sync Pulsing
var pulse_intensity: float = 0.0
var pulse_color: Color = Color.WHITE

# Reactor border electricity sparks
var border_sparks: Array = []
const NUM_SPARKS = 8

# Interactive Fluid Space Dust particles
var dust_particles: Array = []
const NUM_DUST = 30

# Click Ripple Rings (glowing expanding shockwaves)
var ripples: Array = []

func _ready() -> void:
	custom_minimum_size = Vector2(540, 960)
	center = Vector2(270, 480)
	
	var rng = RandomNumberGenerator.new()
	rng.seed = 77
	for i in range(num_stars):
		stars.append({
			"pos": Vector2(rng.randf_range(-400, 400), rng.randf_range(-500, 500)),
			"size": rng.randf_range(1.0, 3.5),
			"brightness": rng.randf_range(0.3, 0.95),
			"speed": rng.randf_range(0.01, 0.04)
		})
		
	for i in range(num_nebulae):
		var neb_color = Color(0.0, 0.94, 1.0, 0.04)
		if i % 2 == 0:
			neb_color = Color(1.0, 0.0, 0.5, 0.03)
		elif i % 3 == 0:
			neb_color = Color(1.0, 0.84, 0.0, 0.03)
			
		nebula_particles.append({
			"pos": Vector2(rng.randf_range(-150, 150), rng.randf_range(-150, 150)),
			"radius": rng.randf_range(100.0, 240.0),
			"color": neb_color,
			"phase": rng.randf_range(0.0, TAU),
			"speed": rng.randf_range(0.08, 0.25)
		})
		
	# Generate border sparks
	for i in range(NUM_SPARKS):
		var is_left = i % 2 == 0
		border_sparks.append({
			"y": rng.randf_range(0, 960),
			"speed": rng.randf_range(120.0, 280.0),
			"length": rng.randf_range(12.0, 30.0),
			"left": is_left
		})
		
	# Generate interactive space dust particles distributed across screen
	for i in range(NUM_DUST):
		var base_p = Vector2(rng.randf_range(40, 500), rng.randf_range(80, 880))
		dust_particles.append({
			"pos": base_p,
			"base_pos": base_p,
			"velocity": Vector2.ZERO,
			"size": rng.randf_range(2.0, 5.0),
			"phase": rng.randf_range(0.0, TAU),
			"drift_speed": rng.randf_range(0.4, 1.2),
			"color": Color(0.0, 0.94, 1.0, 0.35) if i % 2 == 0 else Color(1.0, 0.0, 0.5, 0.35)
		})

func trigger_critical_pulse(col: Color) -> void:
	pulse_intensity = 1.0
	pulse_color = col

# Apply displacement force when clicking (fluid wind simulation)
func apply_click_displacement(click_pos: Vector2, color_tint: Color = Color.WHITE) -> void:
	# Add shockwave ripple ring
	ripples.append({
		"pos": click_pos,
		"scale": 0.1,
		"color": color_tint,
		"opacity": 1.0
	})
	
	# Displace space dust
	for dust in dust_particles:
		var dpos = dust["pos"]
		var dist = dpos.distance_to(click_pos)
		if dist < 320.0:
			var dir = (dpos - click_pos).normalized()
			if dir == Vector2.ZERO:
				dir = Vector2.UP
			# Inverse distance push force
			var force = (dir * 180.0) / (dist + 15.0)
			dust["velocity"] += force * 150.0 # Push impulse
			
			# Blend dust color slightly to the clicked resource color
			if color_tint != Color.WHITE:
				dust["color"] = dust["color"].lerp(color_tint, 0.5)

func _process(delta: float) -> void:
	rot_angle += 0.015 * delta * (1.0 + pulse_intensity * 3.0)
	pulse_intensity = max(0.0, pulse_intensity - 3.5 * delta)
	
	# Update nebula phases
	for neb in nebula_particles:
		neb["phase"] += neb["speed"] * delta
		neb["pos"] += Vector2(
			sin(neb["phase"]) * 10.0 * delta,
			cos(neb["phase"]) * 10.0 * delta
		)
		
	# Update border sparks
	for spark in border_sparks:
		spark["y"] += spark["speed"] * delta
		if spark["y"] > 960.0:
			spark["y"] = -40.0
			spark["speed"] = randf_range(120.0, 280.0)
			
	# Update interactive space dust physics (fluid restoring forces)
	for dust in dust_particles:
		dust["phase"] += dust["drift_speed"] * delta
		
		# Restoring spring force pulls dust back to home position
		var home_displacement = dust["base_pos"] - dust["pos"]
		dust["velocity"] += home_displacement * 4.5 * delta # stiffness
		
		# Apply friction/drag decay
		dust["velocity"] = dust["velocity"].lerp(Vector2.ZERO, 3.2 * delta)
		
		# Passive ambient drifting movement
		var drift = Vector2(
			sin(dust["phase"]) * 8.0,
			cos(dust["phase"] * 1.5) * 8.0
		)
		
		# Move dust
		dust["pos"] += (dust["velocity"] * delta) + (drift * delta)
		
	# Update active click ripples
	var active_ripples = []
	for ripple in ripples:
		ripple["scale"] += 3.2 * delta # expands
		ripple["opacity"] -= 1.67 * delta # fades
		if ripple["opacity"] > 0.0:
			active_ripples.append(ripple)
	ripples = active_ripples
			
	queue_redraw()

func _draw() -> void:
	# Draw background vacuum
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.02, 0.09, 1.0))
	
	# Pulse background glow
	if pulse_intensity > 0.0:
		var glow = pulse_color
		glow.a = pulse_intensity * 0.18
		draw_circle(center, 360.0, glow)
		
		var glow_inner = pulse_color
		glow_inner.a = pulse_intensity * 0.35
		draw_circle(center, 160.0, glow_inner)
	
	# 1. Draw Nebulae
	for neb in nebula_particles:
		var n_center = center + neb["pos"]
		var rad = neb["radius"] + sin(neb["phase"]) * 15.0
		if pulse_intensity > 0.0:
			rad += pulse_intensity * 40.0
			
		var col = neb["color"]
		if pulse_intensity > 0.0:
			col = col.lerp(pulse_color, pulse_intensity * 0.4)
			col.a += pulse_intensity * 0.04
		
		var steps = 6
		for step in range(steps):
			var r = rad * (float(steps - step) / steps)
			var alpha_factor = float(step + 1) / steps
			var step_color = col
			step_color.a = col.a * alpha_factor
			draw_circle(n_center, r, step_color)
			
	# 2. Draw Stars
	var rot_xform = Transform2D(rot_angle, Vector2.ZERO)
	for star in stars:
		var rotated_pos = center + rot_xform * star["pos"]
		var pulse = star["brightness"] * (0.8 + 0.2 * sin(rot_angle * 120.0 * star["speed"]))
		if pulse_intensity > 0.0:
			pulse += pulse_intensity * 0.4
			
		var c = Color(1.0, 1.0, 1.0, min(1.0, pulse))
		
		if star["size"] > 2.8:
			c = Color(0.7, 0.95, 1.0, min(1.0, pulse))
			draw_circle(rotated_pos, star["size"], c)
			draw_line(rotated_pos - Vector2(5, 0), rotated_pos + Vector2(5, 0), Color(0.0, 0.94, 1.0, c.a * 0.5), 1.0)
			draw_line(rotated_pos - Vector2(0, 5), rotated_pos + Vector2(0, 5), Color(0.0, 0.94, 1.0, c.a * 0.5), 1.0)
		else:
			draw_circle(rotated_pos, star["size"], c)

	# 3. Draw Interactive Space Dust particles (with vector trails)
	for dust in dust_particles:
		var p = dust["pos"]
		var c = dust["color"]
		# Make dust glow during pulses
		if pulse_intensity > 0.0:
			c = c.lerp(pulse_color, pulse_intensity * 0.3)
			c.a = min(1.0, c.a + pulse_intensity * 0.4)
			
		# Draw trailing tail representing vector velocity
		if dust["velocity"].length() > 5.0:
			var trail_end = p - dust["velocity"] * 0.08
			draw_line(p, trail_end, Color(c.r, c.g, c.b, c.a * 0.5), 1.5)
			
		draw_circle(p, dust["size"], c)
		
	# 4. Draw Expanding Click Ripple Rings
	for ripple in ripples:
		var draw_col = ripple["color"]
		draw_col.a = ripple["opacity"]
		
		# Draw expanding vector ring outline
		var radius = 40.0 * ripple["scale"]
		draw_arc(ripple["pos"], radius, 0.0, TAU, 32, draw_col, 3.0, true)
		# Secondary outer ring
		draw_col.a = ripple["opacity"] * 0.4
		draw_arc(ripple["pos"], radius + 8.0, 0.0, TAU, 32, draw_col, 1.5, true)

	# 5. Draw UI Electricity Reactor Borders
	var left_border_col = Color(0.0, 0.94, 1.0, 0.20)
	var right_border_col = Color(1.0, 0.0, 0.5, 0.20)
	
	if pulse_intensity > 0.0:
		left_border_col = left_border_col.lerp(pulse_color, pulse_intensity * 0.5)
		left_border_col.a += pulse_intensity * 0.2
		right_border_col = right_border_col.lerp(pulse_color, pulse_intensity * 0.5)
		right_border_col.a += pulse_intensity * 0.2
		
	draw_line(Vector2(2, 0), Vector2(2, 960), left_border_col, 2.0)
	draw_line(Vector2(538, 0), Vector2(538, 960), right_border_col, 2.0)
	
	# Draw running electricity sparks as jagged lightning polylines
	for spark in border_sparks:
		var x = 2.0 if spark["left"] else 538.0
		var col = Color(0.0, 0.94, 1.0, 0.8) if spark["left"] else Color(1.0, 0.0, 0.5, 0.8)
		if pulse_intensity > 0.0:
			col = col.lerp(pulse_color, pulse_intensity * 0.5)
			
		var pts = PackedVector2Array()
		var segments = 4
		var seg_len = spark["length"] / segments
		for s in range(segments + 1):
			var sy = spark["y"] + s * seg_len
			var sx = x
			if s > 0 and s < segments:
				# Jagged displacement outwards
				var offset_dir = 1.0 if spark["left"] else -1.0
				sx += randf_range(1.0, 6.0) * offset_dir
			pts.append(Vector2(sx, sy))
			
		draw_polyline(pts, col, 2.5)
