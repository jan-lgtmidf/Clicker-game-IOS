extends Control

@onready var nodes_container: Control = $"../Nodes"

func _draw() -> void:
	if not nodes_container:
		return
		
	for skill_id in GameManager.SKILL_CONFIG.keys():
		var config = GameManager.SKILL_CONFIG[skill_id]
		var btn = nodes_container.get_node_or_null(skill_id) as Button
		if not btn:
			continue
			
		var center_to = btn.position + btn.size / 2.0
		
		# Draw a line from each dependency
		for dep_id in config["deps"]:
			var dep_btn = nodes_container.get_node_or_null(dep_id) as Button
			if not dep_btn:
				continue
				
			var center_from = dep_btn.position + dep_btn.size / 2.0
			
			# Decide line color
			var color = Color(0.2, 0.2, 0.25, 1.0) # Locked (Dark gray)
			var thickness = 2.0
			
			if GameManager.is_skill_unlocked(skill_id) and GameManager.is_skill_unlocked(dep_id):
				color = Color(0.22, 1.0, 0.08, 0.9) # Unlocked (Neon Green)
				thickness = 4.0
			elif GameManager.can_unlock_skill(skill_id) and GameManager.is_skill_unlocked(dep_id):
				color = Color(1.0, 0.84, 0.0, 0.8) # Unlockable (Neon Yellow)
				thickness = 3.0
			elif GameManager.is_skill_unlocked(dep_id):
				color = Color(0.0, 0.94, 1.0, 0.5) # Dep is unlocked, but this is locked (Neon Cyan fading)
				thickness = 2.5
				
			draw_line(center_from, center_to, color, thickness, true)
