extends Control

signal travel_completed

@onready var color_rect = $ColorRect
@onready var viewport_container = $SubViewportContainer
@onready var mesh_instance = $SubViewportContainer/SubViewport/MeshInstance3D
@onready var camera = $SubViewportContainer/SubViewport/Camera3D

var warp_lines: Array = []
var warp_speed: float = 800.0
var travel_time: float = 0.0
var pivot: Node3D = null

func _ready() -> void:
	# Hide mouse cursor during cinematic travel
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	
	# Auto-scale the loaded 3D mesh using a pivot Node3D to ensure centered rotation
	if mesh_instance and mesh_instance.mesh:
		var aabb = mesh_instance.mesh.get_aabb()
		var max_dim = max(aabb.size.x, max(aabb.size.y, aabb.size.z))
		if max_dim > 0.0:
			var target_scale = 6.5 / max_dim
			
			# Create pivot Node3D
			pivot = Node3D.new()
			pivot.name = "ShipPivot"
			$SubViewportContainer/SubViewport.add_child(pivot)
			
			# Reparent mesh_instance to pivot
			mesh_instance.reparent(pivot)
			
			# Center mesh at pivot's local origin
			var center = aabb.position + aabb.size / 2.0
			mesh_instance.position = -center
			mesh_instance.scale = Vector3.ONE
			mesh_instance.rotation = Vector3.ZERO
			
			# Scale and rotate the pivot
			pivot.scale = Vector3(target_scale, target_scale, target_scale)
			pivot.rotation_degrees = Vector3(-15, 180, 0)
			
		# Override the voxel palette material with a vivid neon material so the ship is VISIBLE
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.5, 0.8, 1.0)   # Icy blue base
		mat.metallic = 0.7
		mat.roughness = 0.25
		mat.emission_enabled = true
		mat.emission = Color(0.0, 0.6, 1.0)        # Neon cyan self-glow
		mat.emission_energy_multiplier = 1.8
		mesh_instance.set_surface_override_material(0, mat)
		
	# Ensure camera is current and looks at the pivot origin (the ship center)
	if camera:
		camera.current = true
		camera.look_at(Vector3.ZERO, Vector3.UP)
		
	# Add extra bright OmniLight inside the SubViewport
	var sub_vp = $SubViewportContainer/SubViewport
	var light = OmniLight3D.new()
	light.position = Vector3(2.0, 2.0, 4.0)
	light.light_energy = 3.5
	light.light_color = Color(0.8, 0.9, 1.0)
	light.omni_range = 20.0
	sub_vp.add_child(light)
	
	var light2 = OmniLight3D.new()
	light2.position = Vector3(-2.0, -1.0, 3.0)
	light2.light_energy = 1.5
	light2.light_color = Color(1.0, 0.5, 0.8)   # Pink rim light
	light2.omni_range = 15.0
	sub_vp.add_child(light2)
	# Generate initial warp lines
	for i in range(30):
		_spawn_warp_line(true)
		
	# Animate the 3D ship viewport container: slide in from left, hesitate, warp speed off right edge
	viewport_container.position.x = -450.0
	
	var tween = create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	# Slide in to center
	tween.tween_property(viewport_container, "position:x", 70.0, 1.2)
	# Engine shake pause
	tween.tween_interval(1.0)
	# Warp jump off screen!
	tween.tween_property(viewport_container, "position:x", 650.0, 0.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	
	tween.finished.connect(_on_tween_finished)

func _spawn_warp_line(random_x: bool = false) -> void:
	var x = randf_range(0, 540) if random_x else 560.0
	var y = randf_range(100, 860)
	var length = randf_range(40.0, 140.0)
	var speed = randf_range(1400.0, 2600.0)
	var col = Color(0.0, 0.94, 1.0, randf_range(0.3, 0.75)) if randf() > 0.4 else Color(1.0, 1.0, 1.0, randf_range(0.3, 0.75))
	
	warp_lines.append({
		"pos": Vector2(x, y),
		"len": length,
		"speed": speed,
		"color": col
	})

func _process(delta: float) -> void:
	travel_time += delta
	
	# Slowly rotate pivot to show off the 3D spaceship model
	if pivot:
		pivot.rotate_y(delta * 1.5)
		pivot.rotate_x(delta * 0.3)
		# Engine visual vibration displacement (oscillates around Y = 0)
		pivot.position.y = sin(travel_time * 25.0) * 0.005
		
	# Update warp lines
	var active_lines = []
	for line in warp_lines:
		line["pos"].x -= line["speed"] * delta
		if line["pos"].x + line["len"] > -50.0:
			active_lines.append(line)
		else:
			_spawn_warp_line()
	warp_lines = active_lines
	
	queue_redraw()

func _draw() -> void:
	# Draw background horizontal warp lines
	for line in warp_lines:
		var p1 = line["pos"]
		var p2 = p1 + Vector2(line["len"], 0.0)
		draw_line(p1, p2, line["color"], 1.5)

func _on_tween_finished() -> void:
	# Trigger warp flash sound or effect
	JuiceManager.trigger_flash(Color.WHITE, 0.4)
	
	var flash_tween = create_tween()
	flash_tween.tween_interval(0.4)
	flash_tween.finished.connect(func():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		travel_completed.emit()
		queue_free()
	)
