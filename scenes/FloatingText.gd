extends Label

func init_text(amount_text: String, is_crit: bool, custom_color: Color = Color.WHITE, combo: int = 1) -> void:
	text = amount_text
	
	# Calculate scale multiplier based on combo (+8% text size per combo level)
	var size_mult = 1.0 + float(combo - 1) * 0.08
	var crit_size = int(36 * size_mult)
	var normal_size = int(24 * size_mult)
	
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
	var peak_scale = (Vector2(1.5, 1.5) if is_crit else Vector2(1.1, 1.1)) * (1.0 + float(combo - 1) * 0.05)
	scale_tween.tween_property(self, "scale", peak_scale, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	scale_tween.tween_property(self, "scale", Vector2(0.9, 0.9) * (1.0 + float(combo - 1) * 0.04), 0.65).set_trans(Tween.TRANS_LINEAR)
	
	await tween.finished
	queue_free()
