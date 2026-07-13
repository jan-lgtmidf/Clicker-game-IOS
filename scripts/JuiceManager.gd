extends Node

var main_camera: Camera2D
var floating_text_scene: PackedScene = preload("res://scenes/FloatingText.tscn")

# Centralized Flash overlay nodes
var flash_canvas: CanvasLayer
var flash_overlay: ColorRect

func _ready() -> void:
	_setup_flash_overlay()

func _setup_flash_overlay() -> void:
	flash_canvas = CanvasLayer.new()
	flash_canvas.layer = 99 # Keep it on top of everything
	add_child(flash_canvas)
	
	flash_overlay = ColorRect.new()
	flash_overlay.anchors_preset = Control.PRESET_FULL_RECT
	flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_overlay.color = Color(1, 1, 1, 0)
	flash_canvas.add_child(flash_overlay)

# Register the camera for global access
func register_camera(cam: Camera2D) -> void:
	main_camera = cam

# Apply a screenshake effect to the registered camera with smooth sine-based decay
func shake_camera(intensity: float, duration: float = 0.3) -> void:
	if not is_instance_valid(main_camera):
		return
		
	var tween = create_tween()
	var steps = 8
	var step_duration = duration / float(steps)
	
	for i in range(steps):
		var t = float(i) / float(steps)
		# Smooth sine decay factor
		var decay = cos(t * PI / 2.0)
		var current_intensity = intensity * decay
		
		# Alternating angles for offset
		var angle = randf_range(0.0, TAU)
		var offset = Vector2(cos(angle), sin(angle)) * current_intensity
		
		tween.tween_property(main_camera, "offset", offset, step_duration)
		
	# Return to center
	tween.tween_property(main_camera, "offset", Vector2.ZERO, 0.05)

# Centralized full-screen flash
func trigger_flash(color: Color, duration: float) -> void:
	if not flash_overlay:
		return
		
	flash_overlay.color = color
	var tween = create_tween()
	tween.tween_property(flash_overlay, "color:a", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

# Spawn juicy floating damage-style text popups with custom color coding
func spawn_floating_text(parent: Node, global_pos: Vector2, text_val: String, is_crit: bool, custom_color: Color = Color.WHITE, combo: int = 1) -> void:
	if not parent:
		return
		
	var text_instance = floating_text_scene.instantiate()
	text_instance.position = global_pos
	parent.add_child(text_instance)
	text_instance.init_text(text_val, is_crit, custom_color, combo)

# Spawn glowing spark particle burst on button presses
func spawn_spark_burst(parent: Node, global_pos: Vector2, color: Color) -> void:
	if not parent:
		return
		
	for i in range(6):
		var spark = Line2D.new()
		spark.width = 2.0
		spark.default_color = color
		
		# Define spark segment vector line
		var angle = randf_range(0.0, TAU)
		var length = randf_range(4.0, 10.0)
		var dir = Vector2(cos(angle), sin(angle))
		spark.points = PackedVector2Array([Vector2.ZERO, dir * length])
		spark.position = global_pos
		parent.add_child(spark)
		
		var dist = randf_range(20.0, 45.0)
		var target_pos = global_pos + dir * dist
		
		var tween = parent.create_tween().set_parallel(true)
		tween.tween_property(spark, "position", target_pos, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(spark, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		
		tween.finished.connect(spark.queue_free)
