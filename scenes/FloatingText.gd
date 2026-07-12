extends Label

func init_text(amount_text: String, is_crit: bool, custom_color: Color = Color.WHITE) -> void:
	text = amount_text
	
	if custom_color != Color.WHITE:
		add_theme_color_override("font_color", custom_color)
		if is_crit:
			add_theme_font_size_override("font_size", 36)
		else:
			add_theme_font_size_override("font_size", 24)
	elif is_crit:
		# Gold color for crits
		add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
		add_theme_font_size_override("font_size", 36)
	else:
		# Neon cyan/white
		add_theme_color_override("font_color", Color(0.0, 0.94, 1.0))
		add_theme_font_size_override("font_size", 24)
		
	# Outline for legibility
	add_theme_color_override("font_outline_color", Color(0.05, 0.02, 0.1, 0.8))
	add_theme_constant_override("outline_size", 8)
	
	# Set pivot to center for nice scaling
	# We wait a frame so size is computed
	await get_tree().process_frame
	pivot_offset = size / 2.0
	
	# Spawn scaling effect
	scale = Vector2(0.3, 0.3)
	
	# Setup Tweens
	var tween = create_tween().set_parallel(true)
	
	# Random arc movement
	var random_x = randf_range(-80.0, 80.0)
	var target_pos = position + Vector2(random_x, -150.0)
	
	# Animate float
	tween.tween_property(self, "position", target_pos, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Animate fade out
	tween.tween_property(self, "modulate:a", 0.0, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	
	# Scale punch tween
	var scale_tween = create_tween()
	var peak_scale = Vector2(1.5, 1.5) if is_crit else Vector2(1.1, 1.1)
	scale_tween.tween_property(self, "scale", peak_scale, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	scale_tween.tween_property(self, "scale", Vector2(0.9, 0.9), 0.65).set_trans(Tween.TRANS_LINEAR)
	
	await tween.finished
	queue_free()
