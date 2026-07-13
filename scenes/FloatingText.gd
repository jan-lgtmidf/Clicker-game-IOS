extends Label

func init_text(amount_text: String, is_crit: bool, custom_color: Color = Color.WHITE, _combo: int = 1) -> void:
	text = amount_text
	
	# Much smaller, clean, non-intrusive font sizes
	var crit_size = 15
	var normal_size = 11
	
	if custom_color != Color.WHITE:
		add_theme_color_override("font_color", custom_color)
		if is_crit:
			add_theme_font_size_override("font_size", crit_size)
		else:
			add_theme_font_size_override("font_size", normal_size)
	elif is_crit:
		# Gold color for crits
		add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
		add_theme_font_size_override("font_size", crit_size)
	else:
		# Neon cyan/white
		add_theme_color_override("font_color", Color(0.0, 0.94, 1.0))
		add_theme_font_size_override("font_size", normal_size)
		
	# Subtle outline for legibility (smaller outline for smaller text)
	add_theme_color_override("font_outline_color", Color(0.05, 0.02, 0.1, 0.8))
	add_theme_constant_override("outline_size", 3)
	
	# Set pivot to center for nice scaling
	await get_tree().process_frame
	pivot_offset = size / 2.0
	
	# Spawn scaling effect
	scale = Vector2(0.5, 0.5)
	
	# Setup Tweens
	var tween = create_tween().set_parallel(true)
	
	# Less float drift to keep the viewport clean
	var random_x = randf_range(-40.0, 40.0)
	var target_pos = position + Vector2(random_x, -90.0)
	
	# Animate float
	tween.tween_property(self, "position", target_pos, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Animate fade out
	tween.tween_property(self, "modulate:a", 0.0, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	
	# Scale punch tween
	var scale_tween = create_tween()
	var peak_scale = Vector2(1.2, 1.2) if is_crit else Vector2(1.0, 1.0)
	scale_tween.tween_property(self, "scale", peak_scale, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	scale_tween.tween_property(self, "scale", Vector2(0.85, 0.85), 0.55).set_trans(Tween.TRANS_LINEAR)
	
	await tween.finished
	queue_free()
