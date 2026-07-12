extends Control

@onready var ore_label: Label = $HUD/VBoxContainer/ResourceHeader/HBoxContainer/OreContainer/Amount
@onready var gas_label: Label = $HUD/VBoxContainer/ResourceHeader/HBoxContainer/GasContainer/Amount
@onready var crystal_label: Label = $HUD/VBoxContainer/ResourceHeader/HBoxContainer/CrystalContainer/Amount
@onready var stardust_label: Label = $HUD/VBoxContainer/ResourceHeader/HBoxContainer/StardustContainer/Amount

@onready var collapse_progress_bar: ProgressBar = $HUD/VBoxContainer/CollapseProgressBar

@onready var tab_upgrades: ScrollContainer = $HUD/VBoxContainer/PanelContainer/UpgradesPanel
@onready var tab_automation: ScrollContainer = $HUD/VBoxContainer/PanelContainer/AutomationPanel
@onready var tab_skilltree: Control = $HUD/VBoxContainer/PanelContainer/SkillTreePanel
@onready var tab_singularity: ScrollContainer = $HUD/VBoxContainer/PanelContainer/SingularityPanel
@onready var tab_prestige: ScrollContainer = $HUD/VBoxContainer/PanelContainer/PrestigePanel
@onready var panels_container: PanelContainer = $HUD/VBoxContainer/PanelContainer

@onready var upgrades_list: VBoxContainer = $HUD/VBoxContainer/PanelContainer/UpgradesPanel/VBox
@onready var automation_list: VBoxContainer = $HUD/VBoxContainer/PanelContainer/AutomationPanel/VBox
@onready var perks_list: VBoxContainer = $HUD/VBoxContainer/PanelContainer/PrestigePanel/VBox/PerksList

# Singularity Tab Elements
@onready var dm_amount_lbl: Label = $HUD/VBoxContainer/PanelContainer/SingularityPanel/VBox/DarkMatterHeader/VBox/DMAmount
@onready var invest_title_lbl: Label = $HUD/VBoxContainer/PanelContainer/SingularityPanel/VBox/DarkMatterHeader/VBox/InvestTitle
@onready var invest_btn: Button = $HUD/VBoxContainer/PanelContainer/SingularityPanel/VBox/DarkMatterHeader/VBox/InvestBtn
@onready var singularity_upgrades_list: VBoxContainer = $HUD/VBoxContainer/PanelContainer/SingularityPanel/VBox/UpgradesList

# Spells Action Bar Elements
@onready var spell_overdrive_btn: Button = $HUD/VBoxContainer/SpellsBar/OverdriveBtn
@onready var spell_siphon_btn: Button = $HUD/VBoxContainer/SpellsBar/SiphonBtn
@onready var spell_net_btn: Button = $HUD/VBoxContainer/SpellsBar/NetBtn

# Telemetry Diagnostics Panel
@onready var telemetry_drawer: Control = $HUD/TelemetryDrawer
@onready var tele_rate_ore: Label = $HUD/TelemetryDrawer/Panel/VBox/RateOre
@onready var tele_rate_gas: Label = $HUD/TelemetryDrawer/Panel/VBox/RateGas
@onready var tele_rate_crystal: Label = $HUD/TelemetryDrawer/Panel/VBox/RateCrystal
@onready var tele_combo: Label = $HUD/TelemetryDrawer/Panel/VBox/Combo
@onready var tele_comets: Label = $HUD/TelemetryDrawer/Panel/VBox/Comets
@onready var tele_supernova: Label = $HUD/TelemetryDrawer/Panel/VBox/SuperNova
@onready var tele_toggle_btn: Button = $HUD/TelemetryDrawer/ToggleBtn

# Welcome Back Offline Modal
@onready var offline_modal: ColorRect = $HUD/OfflineModal
@onready var offline_ore_lbl: Label = $HUD/OfflineModal/Center/Card/VBox/OreAmount
@onready var offline_gas_lbl: Label = $HUD/OfflineModal/Center/Card/VBox/GasAmount
@onready var offline_crystal_lbl: Label = $HUD/OfflineModal/Center/Card/VBox/CrystalAmount
@onready var offline_away_lbl: Label = $HUD/OfflineModal/Center/Card/VBox/AwayText
@onready var offline_confirm_btn: Button = $HUD/OfflineModal/Center/Card/VBox/ConfirmBtn

# Prestige elements
@onready var prestige_button: Button = $HUD/VBoxContainer/PanelContainer/PrestigePanel/VBox/PrestigeCard/VBox/PrestigeButton
@onready var lifetime_label: Label = $HUD/VBoxContainer/PanelContainer/PrestigePanel/VBox/PrestigeCard/VBox/LifetimeLabel
@onready var pending_label: Label = $HUD/VBoxContainer/PanelContainer/PrestigePanel/VBox/PrestigeCard/VBox/PendingLabel

@onready var camera: Camera2D = $GameCamera

# active diagnostic trackers
var last_click_tier: int = 0
var lifetime_comets_clicked: int = 0
var telemetry_open: bool = false

# Comet Spawning Timer
var comet_timer: float = 0.0
var next_comet_time: float = 30.0

# Super-Nova Alert Timer
var supernova_timer: float = 75.0
var supernova_alert_active: bool = false
var supernova_alert_elapsed: float = 0.0
var alarm_sound_timer: float = 0.0

# Meltdown active
var meltdown_active: bool = false
var meltdown_timer: float = 0.0
var cached_automation: Dictionary = {}

# Spells Cooldown trackers
var cooldown_overdrive: float = 0.0
var cooldown_siphon: float = 0.0
var cooldown_net: float = 0.0

# Collector Drones Array
var drones: Array = []
var drone_container: Control

# Active Tweens references for lifecycle checks (Tween-fighting safeguards)
var tween_telemetry: Tween
var tween_tabs: Tween

func _ready() -> void:
	# Connect GameManager signals
	GameManager.resource_changed.connect(_on_resource_changed)
	GameManager.stats_changed.connect(_on_stats_changed)
	GameManager.game_reset.connect(_on_game_reset)
	
	# Connect Asteroid Click
	$HUD/VBoxContainer/CoreContainer/AsteroidCore.core_clicked.connect(_on_core_clicked)
	
	# Navigation Tab Buttons
	$HUD/VBoxContainer/NavigationTabs/UpgradesTabBtn.pressed.connect(func(): select_tab(0))
	$HUD/VBoxContainer/NavigationTabs/AutoTabBtn.pressed.connect(func(): select_tab(1))
	$HUD/VBoxContainer/NavigationTabs/SkillsTabBtn.pressed.connect(func(): select_tab(2))
	$HUD/VBoxContainer/NavigationTabs/SingularityTabBtn.pressed.connect(func(): select_tab(3))
	$HUD/VBoxContainer/NavigationTabs/PrestigeTabBtn.pressed.connect(func(): select_tab(4))
	
	prestige_button.pressed.connect(_on_prestige_pressed)
	
	# Spells Bar Actions
	spell_overdrive_btn.pressed.connect(_cast_overdrive)
	spell_siphon_btn.pressed.connect(_cast_siphon)
	spell_net_btn.pressed.connect(_cast_magnetic_net)
	
	# Setup spell buttons hover & 3D clicks & sparks
	for s_btn in [spell_overdrive_btn, spell_siphon_btn, spell_net_btn]:
		s_btn.pivot_offset = s_btn.size / 2.0
		s_btn.mouse_entered.connect(func():
			var t = s_btn.create_tween()
			t.tween_property(s_btn, "scale", Vector2(1.03, 1.03), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		)
		s_btn.mouse_exited.connect(func():
			var t = s_btn.create_tween()
			t.tween_property(s_btn, "scale", Vector2.ONE, 0.1)
		)
		s_btn.button_down.connect(func():
			var t = s_btn.create_tween()
			t.tween_property(s_btn, "scale", Vector2(0.95, 0.95), 0.05)
			s_btn.position.y += 2.0
		)
		s_btn.button_up.connect(func():
			var t = s_btn.create_tween()
			t.tween_property(s_btn, "scale", Vector2(1.03, 1.03) if s_btn.is_hovered() else Vector2.ONE, 0.08)
			s_btn.position.y -= 2.0
		)
	
	# Specific spell color spark bursts
	spell_overdrive_btn.pressed.connect(func():
		JuiceManager.spawn_spark_burst(self, spell_overdrive_btn.global_position + spell_overdrive_btn.size / 2.0, Color(0.0, 0.94, 1.0))
	)
	spell_siphon_btn.pressed.connect(func():
		JuiceManager.spawn_spark_burst(self, spell_siphon_btn.global_position + spell_siphon_btn.size / 2.0, Color(1.0, 0.0, 0.5))
	)
	spell_net_btn.pressed.connect(func():
		JuiceManager.spawn_spark_burst(self, spell_net_btn.global_position + spell_net_btn.size / 2.0, Color(1.0, 0.84, 0.0))
	)
	
	# Telemetry drawer toggle
	tele_toggle_btn.pressed.connect(_toggle_telemetry_drawer)
	
	# Offline confirmation
	offline_confirm_btn.pressed.connect(_hide_offline_modal)
	
	# Singularity Tab stardust invest
	invest_btn.pressed.connect(_on_invest_stardust)
	
	# Setup Drone canvas layer
	drone_container = Control.new()
	drone_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$HUD.add_child(drone_container)
	# Insert behind vertical tabs box container but in front of background
	$HUD.move_child(drone_container, 1)
	drone_container.draw.connect(_on_drone_container_draw)
	
	# Viewport Size Resize Connection
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	
	JuiceManager.register_camera(camera)
	
	last_click_tier = _get_click_power_tier(GameManager.upgrade_levels["click_power"])
	
	# Dynamic German UI translations on startup
	$HUD/VBoxContainer/ResourceHeader/HBoxContainer/OreContainer/Title.text = "ERZ"
	$HUD/VBoxContainer/ResourceHeader/HBoxContainer/GasContainer/Title.text = "GAS"
	$HUD/VBoxContainer/ResourceHeader/HBoxContainer/CrystalContainer/Title.text = "KRISTALLE"
	$HUD/VBoxContainer/ResourceHeader/HBoxContainer/StardustContainer/Title.text = "STAUB"
	
	$HUD/TelemetryDrawer/Panel/VBox/Header.text = "REAKTOR-TELEMETRIE"
	
	$HUD/VBoxContainer/NavigationTabs/UpgradesTabBtn.text = "Shop"
	$HUD/VBoxContainer/NavigationTabs/AutoTabBtn.text = "Automation"
	$HUD/VBoxContainer/NavigationTabs/SkillsTabBtn.text = "Talente"
	$HUD/VBoxContainer/NavigationTabs/SingularityTabBtn.text = "Singularität"
	$HUD/VBoxContainer/NavigationTabs/PrestigeTabBtn.text = "Prestige"
	
	$HUD/VBoxContainer/PanelContainer/PrestigePanel/VBox/PrestigeCard/VBox/Title.text = "KOSMISCHER KOLLAPS"
	$HUD/VBoxContainer/PanelContainer/PrestigePanel/VBox/PrestigeCard/VBox/Desc.text = "Setze alle aktuellen Gegenstände und Ressourcen zurück, um rohen Sternenstaub freizusetzen. Jeder Sternenstaub erhöht die globale Produktionsgeschwindigkeit permanent um +2%."
	$HUD/VBoxContainer/PanelContainer/PrestigePanel/VBox/PerksHeading.text = "PERMANENTE STERNENSTAUB-PERKS"
	
	$HUD/VBoxContainer/PanelContainer/SingularityPanel/VBox/DarkMatterHeader/VBox/Title.text = "SINGULARITÄTS-KAMMER"
	$HUD/OfflineModal/Center/Card/VBox/Welcome.text = "WILLKOMMEN ZURÜCK, COMMANDER"
	$HUD/OfflineModal/Center/Card/VBox/ConfirmBtn.text = "DATEN BERGEN"
	
	select_tab(0)
	_update_all_labels()
	rebuild_upgrade_lists()
	rebuild_automation_lists()
	rebuild_singularity_upgrades()
	rebuild_perks_lists()
	_update_prestige_card()
	setup_skill_tree_buttons()
	_check_offline_popup()

func _process(delta: float) -> void:
	# Decays spell cooldown timers
	if cooldown_overdrive > 0.0: cooldown_overdrive = max(0.0, cooldown_overdrive - delta)
	if cooldown_siphon > 0.0:    cooldown_siphon = max(0.0, cooldown_siphon - delta)
	if cooldown_net > 0.0:       cooldown_net = max(0.0, cooldown_net - delta)
	
	_update_spells_ui()
	_process_supernova(delta)
	_process_meltdown(delta)
	_process_comets_and_drones(delta)
	_update_telemetry_labels()
	
	# Synthesized Ambient Music Transitions
	var target_music = "normal"
	if meltdown_active or supernova_alert_active:
		target_music = "meltdown"
	elif GameManager.overdrive_active:
		target_music = "overdrive"
	SoundManager.transition_music_to(target_music)

func _process_supernova(delta: float) -> void:
	if meltdown_active:
		return
		
	if supernova_alert_active:
		supernova_alert_elapsed += delta
		alarm_sound_timer -= delta
		if alarm_sound_timer <= 0.0:
			alarm_sound_timer = 0.6
			SoundManager.play_sound(SoundManager.alarm_stream, 0.0, -2.0)
			
		# Update core's contraction ring
		var duration = 3.0
		# stabilization extends reaction window
		var stab_lvl = GameManager.singularity_upgrades.get("chamber_stabilization", 0)
		duration += float(stab_lvl) * 0.45
		
		var progress = min(1.0, supernova_alert_elapsed / duration)
		var ring_scale = lerp(2.6, 1.0, progress)
		$HUD/VBoxContainer/CoreContainer/AsteroidCore.supernova_ring_scale = ring_scale
		
		# Edge warning flash
		if fmod(supernova_alert_elapsed, 0.5) < delta:
			JuiceManager.trigger_flash(Color(1.0, 0.0, 0.0, 0.12), 0.35)
			
		if supernova_alert_elapsed >= duration:
			_trigger_meltdown()
	else:
		supernova_timer -= delta
		if supernova_timer <= 0.0:
			supernova_alert_active = true
			supernova_alert_elapsed = 0.0
			alarm_sound_timer = 0.0

func _trigger_meltdown() -> void:
	supernova_alert_active = false
	$HUD/VBoxContainer/CoreContainer/AsteroidCore.supernova_ring_scale = 0.0
	supernova_timer = randf_range(90.0, 120.0)
	
	if meltdown_active: return
	meltdown_active = true
	meltdown_timer = 6.0
	
	# Disable all automation by temporarily setting levels to 0
	cached_automation["drill"] = GameManager.upgrade_levels["drill"]
	cached_automation["siphon"] = GameManager.upgrade_levels["siphon"]
	cached_automation["synthesizer"] = GameManager.upgrade_levels["synthesizer"]
	
	GameManager.upgrade_levels["drill"] = 0
	GameManager.upgrade_levels["siphon"] = 0
	GameManager.upgrade_levels["synthesizer"] = 0
	GameManager.stats_changed.emit()
	
	# Shake and flash
	SoundManager.play_sound(SoundManager.meltdown_stream)
	JuiceManager.trigger_flash(Color(1.0, 0.0, 0.0, 0.65), 1.0)
	JuiceManager.shake_camera(28.0, 0.8)
	
	JuiceManager.spawn_floating_text(self, Vector2(270, 360), "REAKTOR-KERNSCHMELZE!\nAutomatisierung offline für 6 Sek.", true, Color(1.0, 0.0, 0.0))

func _process_meltdown(delta: float) -> void:
	if meltdown_active:
		meltdown_timer -= delta
		# Red edge warnings while offline
		if fmod(meltdown_timer, 0.8) < delta:
			JuiceManager.trigger_flash(Color(1.0, 0.0, 0.0, 0.08), 0.5)
			
		if meltdown_timer <= 0.0:
			meltdown_active = false
			# Restore levels
			GameManager.upgrade_levels["drill"] = cached_automation.get("drill", 0)
			GameManager.upgrade_levels["siphon"] = cached_automation.get("siphon", 0)
			GameManager.upgrade_levels["synthesizer"] = cached_automation.get("synthesizer", 0)
			GameManager.stats_changed.emit()
			
			JuiceManager.trigger_flash(Color(0.0, 0.94, 1.0, 0.3), 0.5)
			JuiceManager.spawn_floating_text(self, Vector2(270, 360), "Reaktor abgekühlt\nAutomatisierung online", false, Color(0.0, 0.94, 1.0))

func _process_comets_and_drones(delta: float) -> void:
	# Comet Spawn Clock
	comet_timer += delta
	if comet_timer >= next_comet_time:
		comet_timer = 0.0
		# pull upgrades: comets spawn 10% faster per level
		var pull_lvl = GameManager.singularity_upgrades.get("gravitational_pull", 0)
		var rate_mult = 1.0 - float(pull_lvl) * 0.10
		next_comet_time = randf_range(45.0, 60.0) * max(0.5, rate_mult)
		spawn_cosmic_comet()
		
	# Drones processing
	var core_pos = $HUD/VBoxContainer/CoreContainer/AsteroidCore.global_position + Vector2(150, 150)
	
	# Spawn/despawn Drones
	var target_count = GameManager.get_drone_count()
	while drones.size() < target_count:
		drones.append({
			"pos": core_pos,
			"target": core_pos,
			"state": "mining",
			"timer": 0.0
		})
	while drones.size() > target_count:
		drones.pop_back()
		
	# Move Drones
	var speed = GameManager.get_drone_speed()
	for drone in drones:
		if drone["state"] == "mining":
			drone["pos"] = drone["pos"].move_toward(drone["target"], speed * delta)
			if drone["pos"].distance_to(drone["target"]) < 5.0:
				drone["state"] = "idle"
				drone["timer"] = 0.8
		elif drone["state"] == "idle":
			drone["timer"] -= delta
			if drone["timer"] <= 0.0:
				drone["state"] = "deposit"
		elif drone["state"] == "deposit":
			drone["pos"] = drone["pos"].move_toward(core_pos, speed * delta)
			if drone["pos"].distance_to(core_pos) < 5.0:
				# Deposit and reward
				var power = GameManager.get_click_power()
				var yield_val = float(int(power * 0.1) + 1)
				GameManager.add_resource("space_ore", yield_val)
				JuiceManager.spawn_floating_text(self, core_pos + Vector2(randf_range(-20,20), randf_range(-20,20)), "+" + str(int(yield_val)), false, Color(0.22, 1.0, 0.08))
				
				# Minor core squash
				$HUD/VBoxContainer/CoreContainer/AsteroidCore.current_scale = Vector2(0.92, 0.92)
				
				# Select new target
				drone["state"] = "mining"
				drone["target"] = Vector2(randf_range(40.0, 500.0), randf_range(180.0, 520.0))
				
	if target_count > 0:
		drone_container.queue_redraw()

func _on_drone_container_draw() -> void:
	for drone in drones:
		var pos = drone["pos"]
		# Draw tiny glowing green triangle
		var pts = PackedVector2Array([
			pos + Vector2(0, -6),
			pos + Vector2(-5, 4),
			pos + Vector2(5, 4)
		])
		drone_container.draw_colored_polygon(pts, Color(0.22, 1.0, 0.08))
		drone_container.draw_circle(pos + Vector2(0, 5), 1.5, Color(0.22, 1.0, 0.08, 0.45))

func _update_spells_ui() -> void:
	# Overdrive Spell status
	if not GameManager.is_spell_unlocked("overdrive"):
		spell_overdrive_btn.disabled = true
		spell_overdrive_btn.text = "Overdrive (Gesperrt)"
	elif GameManager.overdrive_active:
		spell_overdrive_btn.disabled = true
		spell_overdrive_btn.text = "AKTIV: %.1fs" % GameManager.overdrive_timer
	elif cooldown_overdrive > 0.0:
		spell_overdrive_btn.disabled = true
		spell_overdrive_btn.text = "CD: %ds" % int(cooldown_overdrive)
	else:
		spell_overdrive_btn.disabled = false
		spell_overdrive_btn.text = "Overdrive (10s Schub)"
		
	# Siphon Spell status
	if not GameManager.is_spell_unlocked("siphon"):
		spell_siphon_btn.disabled = true
		spell_siphon_btn.text = "Siphon (Gesperrt)"
	elif cooldown_siphon > 0.0:
		spell_siphon_btn.disabled = true
		spell_siphon_btn.text = "CD: %ds" % int(cooldown_siphon)
	else:
		spell_siphon_btn.disabled = false
		spell_siphon_btn.text = "Siphon: 15% Kollaps"
		
	# Magnetic Net Spell status
	if not GameManager.is_spell_unlocked("magnetic_net"):
		spell_net_btn.disabled = true
		spell_net_btn.text = "Magnetnetz (Gesperrt)"
	elif GameManager.magnetic_net_active:
		spell_net_btn.disabled = true
		spell_net_btn.text = "AKTIV: %.1fs" % GameManager.magnetic_net_timer
	elif cooldown_net > 0.0:
		spell_net_btn.disabled = true
		spell_net_btn.text = "CD: %ds" % int(cooldown_net)
	else:
		spell_net_btn.disabled = false
		spell_net_btn.text = "Magnetnetz (15s)"
		
	# Magnetic net pulls all comets
	if GameManager.magnetic_net_active:
		for comet in get_tree().get_nodes_in_group("comets"):
			if is_instance_valid(comet) and not comet.is_queued_for_deletion():
				# Move directly to core, click immediately
				_on_comet_clicked(comet)

func _cast_overdrive() -> void:
	if GameManager.cast_spell("overdrive"):
		cooldown_overdrive = 60.0
		SoundManager.play_sound(SoundManager.spell_stream)
		JuiceManager.trigger_flash(Color(0.0, 0.94, 1.0, 0.25), 0.4)

func _cast_siphon() -> void:
	if GameManager.cast_spell("siphon"):
		cooldown_siphon = 90.0
		SoundManager.play_sound(SoundManager.spell_stream, 0.0, -1.0)
		JuiceManager.trigger_flash(Color(1.0, 0.0, 0.5, 0.25), 0.4)

func _cast_magnetic_net() -> void:
	if GameManager.cast_spell("magnetic_net"):
		cooldown_net = 120.0
		SoundManager.play_sound(SoundManager.spell_stream, 0.0, 1.0)
		JuiceManager.trigger_flash(Color(1.0, 0.84, 0.0, 0.25), 0.4)

# ----------------- TABS TRANSITIONS -----------------

func select_tab(index: int) -> void:
	if tween_tabs and tween_tabs.is_valid():
		tween_tabs.kill()
		
	var tabs = [tab_upgrades, tab_automation, tab_skilltree, tab_singularity, tab_prestige]
	var active_tab = tabs[index]
	
	# Slide-in transition for active tab
	tween_tabs = create_tween().set_parallel(true)
	for t in tabs:
		if t == active_tab:
			t.visible = true
			t.modulate.a = 0.0
			t.position.x = 20.0
			tween_tabs.tween_property(t, "modulate:a", 1.0, 0.22)
			tween_tabs.tween_property(t, "position:x", 0.0, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		else:
			t.visible = false
			
	var buttons = [
		$HUD/VBoxContainer/NavigationTabs/UpgradesTabBtn,
		$HUD/VBoxContainer/NavigationTabs/AutoTabBtn,
		$HUD/VBoxContainer/NavigationTabs/SkillsTabBtn,
		$HUD/VBoxContainer/NavigationTabs/SingularityTabBtn,
		$HUD/VBoxContainer/NavigationTabs/PrestigeTabBtn
	]
	
	for i in range(buttons.size()):
		if i == index:
			buttons[i].add_theme_color_override("font_color", Color(0.0, 0.94, 1.0))
			buttons[i].modulate.a = 1.0
			
			buttons[i].pivot_offset = buttons[i].size / 2.0
			var scale_tween = create_tween()
			scale_tween.tween_property(buttons[i], "scale", Vector2(1.06, 1.06), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			scale_tween.tween_property(buttons[i], "scale", Vector2.ONE, 0.08)
		else:
			buttons[i].remove_theme_color_override("font_color")
			buttons[i].modulate.a = 0.50

# ----------------- COLLAPSIBLE DRAWERS -----------------

func _toggle_telemetry_drawer() -> void:
	telemetry_open = not telemetry_open
	if tween_telemetry and tween_telemetry.is_valid():
		tween_telemetry.kill()
		
	var viewport_w = get_viewport().get_visible_rect().size.x
	var drawer_w = telemetry_drawer.size.x
	var target_x = (viewport_w - drawer_w) if telemetry_open else viewport_w
	
	tween_telemetry = create_tween()
	tween_telemetry.tween_property(telemetry_drawer, "position:x", target_x, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tele_toggle_btn.text = ">" if telemetry_open else "<"

# Snaps Telemetry snappily on resize to follow correct layout boundary
func _on_viewport_size_changed() -> void:
	if not telemetry_drawer:
		return
	var viewport_w = get_viewport().get_visible_rect().size.x
	var drawer_w = telemetry_drawer.size.x
	var target_x = (viewport_w - drawer_w) if telemetry_open else viewport_w
	telemetry_drawer.position.x = target_x

func _update_telemetry_labels() -> void:
	if not telemetry_open:
		return
	var ore_rate = GameManager.get_production_rate("drill")
	var gas_rate = GameManager.get_production_rate("siphon")
	var crystal_rate = GameManager.get_production_rate("synthesizer")
	var combo = $HUD/VBoxContainer/CoreContainer/AsteroidCore.click_combo
	
	tele_rate_ore.text = "Erz/s: " + _format_number(ore_rate)
	tele_rate_gas.text = "Gas/s: " + _format_number(gas_rate)
	tele_rate_crystal.text = "Kristall/s: " + _format_number(crystal_rate)
	tele_combo.text = "Kern-Kombo: x" + str(1.0 + float(combo) * 0.1)
	tele_comets.text = "Kometentreffer: " + str(lifetime_comets_clicked)
	
	if meltdown_active:
		tele_supernova.text = "Kernschmelze: " + "%.1fs" % meltdown_timer
	elif supernova_alert_active:
		tele_supernova.text = "ALARM AKTIV"
	else:
		tele_supernova.text = "Nächster Alarm: " + str(int(supernova_timer)) + " Sek."

# ----------------- OFFLINE MODAL POPUP -----------------

func _check_offline_popup() -> void:
	if GameManager.show_offline_popup:
		offline_away_lbl.text = "Während deiner Abwesenheit für " + _format_seconds(GameManager.offline_seconds) + " hat dein automatisches Netzwerk gesammelt:"
		offline_ore_lbl.text = "+" + _format_number(GameManager.offline_ore_earned) + " Weltraumerz"
		offline_gas_lbl.text = "+" + _format_number(GameManager.offline_gas_earned) + " Kosmisches Gas"
		offline_crystal_lbl.text = "+" + _format_number(GameManager.offline_crystals_earned) + " Sternenkristalle"
		offline_modal.visible = true
		GameManager.show_offline_popup = false
		GameManager.save_game()

func _format_seconds(sec: float) -> String:
	var hours = int(sec) / 3600
	var minutes = (int(sec) % 3600) / 60
	var seconds = int(sec) % 60
	
	if hours > 0:
		return "%d Std. %d Min. %d Sek." % [hours, minutes, seconds]
	elif minutes > 0:
		return "%d Min. %d Sek." % [minutes, seconds]
	else:
		return "%d Sek." % seconds

func _hide_offline_modal() -> void:
	offline_modal.visible = false
	SoundManager.play_sound(SoundManager.upgrade_stream, 0.05, 0.0)

# ----------------- CORE INTERFACES -----------------

func _on_resource_changed(_type: String, _amount: float) -> void:
	_update_all_labels()
	_update_prestige_card()
	_refresh_purchase_buttons()

func _on_stats_changed() -> void:
	_update_all_labels()
	_update_prestige_card()
	rebuild_upgrade_lists()
	rebuild_automation_lists()
	rebuild_singularity_upgrades()
	rebuild_perks_lists()
	_refresh_skill_nodes()
	
	var click_lvl = GameManager.upgrade_levels["click_power"]
	var current_tier = _get_click_power_tier(click_lvl)
	if current_tier > last_click_tier:
		last_click_tier = current_tier
		_trigger_milestone_pop(current_tier)

func _get_click_power_tier(lvl: int) -> int:
	if lvl >= 50: return 3
	if lvl >= 25: return 2
	if lvl >= 10: return 1
	return 0

func _trigger_milestone_pop(tier: int) -> void:
	SoundManager.play_sound(SoundManager.upgrade_stream, 0.0, 3.0)
	
	var flash_color = Color(0.0, 0.94, 1.0, 0.4)
	var title = "TIER 2 CORE UNLOCKED!"
	var subtitle = "Core Laser Mined activated"
	
	match tier:
		1:
			flash_color = Color(0.0, 0.94, 1.0, 0.4)
			title = "KERN-STUFE 2 FREIGESCHALTET!"
			subtitle = "Magnetisierter Laserkern online."
		2:
			flash_color = Color(1.0, 0.0, 0.5, 0.4)
			title = "KERN-STUFE 3 FREIGESCHALTET!"
			subtitle = "Plasmakern-Anomalie online."
		3:
			flash_color = Color(1.0, 0.84, 0.0, 0.4)
			title = "QUANTEN-SINGULARITÄT STUFE 4!"
			subtitle = "Ultimativer Extraktionskern aktiv."
			
	JuiceManager.trigger_flash(flash_color, 0.65)
	
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.03, 0.12, 0.85)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = flash_color
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	var title_lbl = Label.new()
	title_lbl.text = title
	title_lbl.add_theme_color_override("font_color", flash_color)
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_lbl)
	
	var sub_lbl = Label.new()
	sub_lbl.text = subtitle
	sub_lbl.add_theme_color_override("font_color", Color.WHITE)
	sub_lbl.add_theme_font_size_override("font_size", 11)
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(sub_lbl)
	
	$HUD.add_child(panel)
	panel.size = Vector2(360, 85)
	panel.position = Vector2(90, 320)
	panel.pivot_offset = panel.size / 2.0
	
	panel.scale = Vector2(0.2, 0.2)
	var pop_tween = create_tween().set_parallel(true)
	pop_tween.tween_property(panel, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop_tween.tween_property(panel, "modulate:a", 1.0, 0.4)
	
	var exit_tween = create_tween()
	exit_tween.tween_interval(2.0)
	exit_tween.tween_property(panel, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	await exit_tween.finished
	panel.queue_free()

func _on_game_reset() -> void:
	$HUD/VBoxContainer/CoreContainer/AsteroidCore.generate_asteroid_shape()
	trigger_flash(Color(0.22, 1.0, 0.08, 0.5), 0.8)
	last_click_tier = 0

func _update_all_labels() -> void:
	ore_label.text = _format_number(GameManager.space_ore)
	gas_label.text = _format_number(GameManager.cosmic_gas)
	crystal_label.text = _format_number(GameManager.star_crystals)
	stardust_label.text = _format_number(GameManager.stardust)
	
	# Update Collapse Progress Bar
	collapse_progress_bar.max_value = 100000.0
	collapse_progress_bar.value = clamp(GameManager.space_ore, 0.0, 100000.0)
	
	# Update Singularity Chamber UI
	dm_amount_lbl.text = "Dark Matter: %.3f" % GameManager.dark_matter
	invest_title_lbl.text = "Stardust Invested: " + _format_number(GameManager.stardust_invested)
	invest_btn.disabled = GameManager.stardust < 10.0

func _format_number(val: float) -> String:
	if val < 1000.0:
		return str(int(val))
	elif val < 1000000.0:
		return "%.2f K" % (val / 1000.0)
	elif val < 1000000000.0:
		return "%.2f M" % (val / 1000000.0)
	else:
		return "%.2f B" % (val / 1000000000.0)

func _on_core_clicked(click_pos: Vector2, is_crit: bool, _ore_amount: float) -> void:
	var color = Color(1.0, 0.84, 0.0) if is_crit else Color(0.0, 0.94, 1.0)
	$HUD/Background.trigger_critical_pulse(color)
	
	# Apply shockwave click ripples & dust repulsion vector lines
	$HUD/Background.apply_click_displacement(click_pos, color)

	if supernova_alert_active:
		var ring_scale = $HUD/VBoxContainer/CoreContainer/AsteroidCore.supernova_ring_scale
		if ring_scale >= 0.92 and ring_scale <= 1.15:
			supernova_alert_active = false
			$HUD/VBoxContainer/CoreContainer/AsteroidCore.supernova_ring_scale = 0.0
			supernova_timer = randf_range(80.0, 110.0)
			
			SoundManager.play_sound(SoundManager.perfect_stream)
			JuiceManager.trigger_flash(Color(0.22, 1.0, 0.08, 0.45), 0.5)
			JuiceManager.shake_camera(12.0, 0.45)
			
			var reward = GameManager.get_click_power() * 150.0
			GameManager.add_resource("space_ore", reward)
			
			GameManager.overdrive_active = true
			GameManager.overdrive_timer = 15.0
			
			JuiceManager.spawn_floating_text(self, click_pos, "PERFEKT ABGEFANGEN!\n+150x Klick-Ertrag\nOverdrive-Protokoll aktiv!", true, Color(0.22, 1.0, 0.08))
		else:
			_trigger_meltdown()
	else:
		if is_crit:
			JuiceManager.shake_camera(12.0)
			trigger_flash(Color(1.0, 0.84, 0.0, 0.25), 0.2)
		else:
			JuiceManager.shake_camera(2.5)

func trigger_flash(color: Color, duration: float) -> void:
	JuiceManager.trigger_flash(color, duration)

# ----------------- ITEM LISTS GENERATION -----------------

func create_shop_row(title: String, desc: String, cost: float, cost_type: String, lvl: int, buy_callback: Callable) -> PanelContainer:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.08, 0.20, 0.70)
	style.border_width_bottom = 2
	style.border_color = Color(0.0, 0.94, 1.0, 0.15)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	
	var hbox = HBoxContainer.new()
	panel.add_child(hbox)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)
	
	var title_lbl = Label.new()
	title_lbl.text = title + " (Lvl " + str(lvl) + ")"
	title_lbl.add_theme_font_size_override("font_size", 14)
	title_lbl.add_theme_color_override("font_color", Color(0.0, 0.94, 1.0))
	vbox.add_child(title_lbl)
	
	var desc_lbl = Label.new()
	desc_lbl.text = desc
	desc_lbl.add_theme_font_size_override("font_size", 10)
	desc_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	vbox.add_child(desc_lbl)
	
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(110, 42)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	var currency_short = "Ore"
	var btn_color = Color(0.0, 0.94, 1.0)
	match cost_type:
		"cosmic_gas":
			currency_short = "Gas"
			btn_color = Color(1.0, 0.0, 0.5)
		"star_crystals":
			currency_short = "Crystal"
			btn_color = Color(1.0, 0.84, 0.0)
		"stardust":
			currency_short = "Staub"
			btn_color = Color(0.22, 1.0, 0.08)
		"dark_matter":
			currency_short = "DM"
			btn_color = Color(1.0, 0.45, 0.0)
			
	btn.text = _format_number(cost) + " " + currency_short
	if cost_type == "dark_matter":
		btn.text = "%.1f DM" % cost
	
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(btn_color.r, btn_color.g, btn_color.b, 0.12)
	btn_style.border_width_left = 2
	btn_style.border_width_right = 2
	btn_style.border_width_top = 2
	btn_style.border_width_bottom = 2
	btn_style.border_color = btn_color
	btn_style.corner_radius_top_left = 6
	btn_style.corner_radius_top_right = 6
	btn_style.corner_radius_bottom_right = 6
	btn_style.corner_radius_bottom_left = 6
	btn.add_theme_stylebox_override("normal", btn_style)
	
	var btn_hover = btn_style.duplicate()
	btn_hover.bg_color = Color(btn_color.r, btn_color.g, btn_color.b, 0.25)
	btn.add_theme_stylebox_override("hover", btn_hover)
	
	var btn_disabled = btn_style.duplicate()
	btn_disabled.bg_color = Color(0.1, 0.1, 0.1, 0.4)
	btn_disabled.border_color = Color(0.3, 0.3, 0.3)
	btn.add_theme_stylebox_override("disabled", btn_disabled)
	
	btn.add_theme_color_override("font_color", btn_color)
	
	var current_res = GameManager.get_resource(cost_type)
	btn.disabled = current_res < cost
	
	# Drone count cap at 8
	if title == "Sammler-Drohnen" and lvl >= 8:
		btn.disabled = true
		btn.text = "MAX. DROHNEN"
		
	btn.pressed.connect(buy_callback)
	hbox.add_child(btn)
	
	btn.set_meta("cost", cost)
	btn.set_meta("cost_type", cost_type)
	btn.add_to_group("shop_buttons")
	
	# Dynamic 3D click and hover response
	btn.pivot_offset = Vector2(55, 21) # Center of 110x42 custom minimum size
	btn.mouse_entered.connect(func():
		var t = btn.create_tween()
		t.tween_property(btn, "scale", Vector2(1.04, 1.04), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	btn.mouse_exited.connect(func():
		var t = btn.create_tween()
		t.tween_property(btn, "scale", Vector2.ONE, 0.1)
	)
	btn.button_down.connect(func():
		var t = btn.create_tween()
		t.tween_property(btn, "scale", Vector2(0.94, 0.94), 0.05)
		btn.position.y += 2.0
	)
	btn.button_up.connect(func():
		var t = btn.create_tween()
		t.tween_property(btn, "scale", Vector2(1.04, 1.04) if btn.is_hovered() else Vector2.ONE, 0.08)
		btn.position.y -= 2.0
	)
	
	# Connect neon sparks explosion on successful press
	btn.pressed.connect(func():
		JuiceManager.spawn_spark_burst(self, btn.global_position + Vector2(55, 21), btn_color)
	)
	
	return panel

func rebuild_upgrade_lists() -> void:
	for child in upgrades_list.get_children():
		child.queue_free()
		
	var power_cost = GameManager.get_upgrade_cost("click_power")
	var power_lvl = GameManager.upgrade_levels["click_power"]
	var row_power = create_shop_row(
		"Laser-Klicker", 
		"Erhöht die manuelle Abbauleistung. Basis +1. Skaliert den Ertrag.", 
		power_cost, "space_ore", power_lvl, 
		func(): GameManager.buy_upgrade("click_power")
	)
	upgrades_list.add_child(row_power)
	
	var cc_cost = GameManager.get_upgrade_cost("crit_chance")
	var cc_lvl = GameManager.upgrade_levels["crit_chance"]
	var cc_desc = "Kritische Chance: +1%% (Aktuell: %d%%)" % int(GameManager.get_crit_chance() * 100.0)
	var row_cc = create_shop_row(
		"Präzisionslinse", 
		cc_desc, 
		cc_cost, "space_ore", cc_lvl, 
		func(): GameManager.buy_upgrade("crit_chance")
	)
	upgrades_list.add_child(row_cc)
	
	var cm_cost = GameManager.get_upgrade_cost("crit_multiplier")
	var cm_lvl = GameManager.upgrade_levels["crit_multiplier"]
	var cm_desc = "Crit multiplier: +30%% (Current: %.1fx)" % GameManager.get_crit_multiplier()
	var row_cm = create_shop_row(
		"Hyperladungs-Kern", 
		cm_desc, 
		cm_cost, "space_ore", cm_lvl, 
		func(): GameManager.buy_upgrade("crit_multiplier")
	)
	upgrades_list.add_child(row_cm)

func rebuild_automation_lists() -> void:
	for child in automation_list.get_children():
		child.queue_free()
		
	var drill_cost = GameManager.get_upgrade_cost("drill")
	var drill_lvl = GameManager.upgrade_levels["drill"]
	var drill_rate = GameManager.get_production_rate("drill")
	var row_drill = create_shop_row(
		"Plasmabohrer", 
		"Automatisiert den Abbau. Produktion: +1.5 Erz/Sek. (Gesamt: %.1f Erz/s)" % drill_rate, 
		drill_cost, "space_ore", drill_lvl, 
		func(): GameManager.buy_upgrade("drill")
	)
	automation_list.add_child(row_drill)
	
	var siphon_cost = GameManager.get_upgrade_cost("siphon")
	var siphon_lvl = GameManager.upgrade_levels["siphon"]
	var siphon_rate = GameManager.get_production_rate("siphon")
	var row_siphon = create_shop_row(
		"Atmosphärischer Siphon", 
		"Saugt Gase aus der Anomalie: +0.4 Gas/Sek. (Gesamt: %.2f Gas/s)" % siphon_rate, 
		siphon_cost, "space_ore", siphon_lvl, 
		func(): GameManager.buy_upgrade("siphon")
	)
	automation_list.add_child(row_siphon)
	
	var synth_cost = GameManager.get_upgrade_cost("synthesizer")
	var synth_lvl = GameManager.upgrade_levels["synthesizer"]
	var synth_rate = GameManager.get_production_rate("synthesizer")
	var row_synth = create_shop_row(
		"Kristallsynthetisierer", 
		"Kondensiert Gas in Kristalle: +0.10 Kristalle/Sek. (Gesamt: %.3f Kristall/s)" % synth_rate, 
		synth_cost, "space_ore", synth_lvl, 
		func(): GameManager.buy_upgrade("synthesizer")
	)
	automation_list.add_child(row_synth)
	
	var d_count_cost = GameManager.get_upgrade_cost("drone_count")
	var d_count_lvl = GameManager.upgrade_levels["drone_count"]
	var row_d_count = create_shop_row(
		"Sammler-Drohnen", 
		"Spawnt automatische Drohnen, die Trümmer sammeln. (Max 8)", 
		d_count_cost, "space_ore", d_count_lvl, 
		func(): GameManager.buy_upgrade("drone_count")
	)
	automation_list.add_child(row_d_count)
	
	var d_speed_cost = GameManager.get_upgrade_cost("drone_speed")
	var d_speed_lvl = GameManager.upgrade_levels["drone_speed"]
	var row_d_speed = create_shop_row(
		"Drohnen-Triebwerke", 
		"Erhöht die Fluggeschwindigkeit der Drohnen um +25 Einheiten/s pro Stufe.", 
		d_speed_cost, "space_ore", d_speed_lvl, 
		func(): GameManager.buy_upgrade("drone_speed")
	)
	automation_list.add_child(row_d_speed)

func rebuild_singularity_upgrades() -> void:
	for child in singularity_upgrades_list.get_children():
		child.queue_free()
		
	var gp_cost = GameManager.get_singularity_cost("gravitational_pull")
	var gp_lvl = GameManager.singularity_upgrades["gravitational_pull"]
	var gp_row = create_shop_row(
		"Gravitationszug",
		"Erhöht Kometenhäufigkeit um +10% und deren Fluggeschwindigkeit.",
		gp_cost, "dark_matter", gp_lvl,
		func(): GameManager.buy_singularity_upgrade("gravitational_pull")
	)
	singularity_upgrades_list.add_child(gp_row)
	
	var qt_cost = GameManager.get_singularity_cost("quantum_tunneling")
	var qt_lvl = GameManager.singularity_upgrades["quantum_tunneling"]
	var qt_row = create_shop_row(
		"Quantentunnelung",
		"Gewährt 5% Chance auf doppelte Erträge bei jeder Automation.",
		qt_cost, "dark_matter", qt_lvl,
		func(): GameManager.buy_singularity_upgrade("quantum_tunneling")
	)
	singularity_upgrades_list.add_child(qt_row)
	
	var cs_cost = GameManager.get_singularity_cost("chamber_stabilization")
	var cs_lvl = GameManager.singularity_upgrades["chamber_stabilization"]
	var cs_row = create_shop_row(
		"Kammerstabilisierung",
		"Verlängert das Super-Nova Containment-Reaktionsfenster um +15%.",
		cs_cost, "dark_matter", cs_lvl,
		func(): GameManager.buy_singularity_upgrade("chamber_stabilization")
	)
	singularity_upgrades_list.add_child(cs_row)

func _on_invest_stardust() -> void:
	GameManager.invest_stardust(10.0)

func rebuild_perks_lists() -> void:
	for child in perks_list.get_children():
		child.queue_free()
		
	var gb_cost = GameManager.get_perk_cost("global_boost")
	var gb_lvl = GameManager.perk_levels["global_boost"]
	var row_gb = create_shop_row(
		"Kosmische Effizienz",
		"Steigert alle Produktionsraten permanent um +5%.",
		gb_cost, "stardust", gb_lvl,
		func(): GameManager.buy_perk("global_boost")
	)
	perks_list.add_child(row_gb)
	
	var so_cost = GameManager.get_perk_cost("starting_ore")
	var so_lvl = GameManager.perk_levels["starting_ore"]
	var row_so = create_shop_row(
		"Sternenstaub-Injektion",
		"Starte nachfolgende Resets mit +1.000 Weltraumerz pro Stufe.",
		so_cost, "stardust", so_lvl,
		func(): GameManager.buy_perk("starting_ore")
	)
	perks_list.add_child(row_so)

func _update_prestige_card() -> void:
	lifetime_label.text = "Lebenszeit Weltraumerz abgebaut: " + _format_number(GameManager.lifetime_space_ore)
	
	var pending = GameManager.get_pending_stardust()
	pending_label.text = "Ausstehender Sternenstaub: +" + _format_number(pending)
	
	if pending > 0.0:
		prestige_button.disabled = false
		prestige_button.text = "KOSMISCHEN KOLLAPS AUSLÖSEN"
		prestige_button.add_theme_color_override("font_color", Color(0.22, 1.0, 0.08))
	else:
		prestige_button.disabled = true
		prestige_button.text = "Kollaps: Benötigt 100,00 K Erz"
		prestige_button.remove_theme_color_override("font_color")

func _on_prestige_pressed() -> void:
	JuiceManager.trigger_flash(Color(1, 1, 1, 1), 1.2)
	GameManager.trigger_prestige()

func _refresh_purchase_buttons() -> void:
	for btn in get_tree().get_nodes_in_group("shop_buttons"):
		if is_instance_valid(btn):
			var cost = btn.get_meta("cost")
			var cost_type = btn.get_meta("cost_type")
			var current_res = GameManager.get_resource(cost_type)
			
			# Drone Count caps
			var is_max_drones = false
			if btn.get_parent() and btn.get_parent().get_parent():
				var lbl = btn.get_parent().get_parent().get_child(0).get_child(0)
				if lbl is Label and lbl.text.begins_with("Sammler-Drohnen") and GameManager.upgrade_levels["drone_count"] >= 8:
					is_max_drones = true
					
			if is_max_drones:
				btn.disabled = true
			else:
				btn.disabled = current_res < cost

# ----------------- SKILL TREE VISUALS -----------------

func setup_skill_tree_buttons() -> void:
	for skill_id in GameManager.SKILL_CONFIG.keys():
		var node_path = "HUD/VBoxContainer/PanelContainer/SkillTreePanel/Nodes/" + skill_id
		var btn = get_node_or_null(node_path)
		if btn is Button:
			for c in btn.pressed.get_connections():
				btn.pressed.disconnect(c.callable)
			btn.pressed.connect(func(): _on_skill_node_pressed(skill_id))
	_refresh_skill_nodes()

func _on_skill_node_pressed(skill_id: String) -> void:
	if GameManager.buy_skill(skill_id):
		$HUD/VBoxContainer/PanelContainer/SkillTreePanel/SkillLineDrawer.queue_redraw()

func _refresh_skill_nodes() -> void:
	for skill_id in GameManager.SKILL_CONFIG.keys():
		var node_path = "HUD/VBoxContainer/PanelContainer/SkillTreePanel/Nodes/" + skill_id
		var btn = get_node_or_null(node_path)
		if btn is Button:
			var config = GameManager.SKILL_CONFIG[skill_id]
			btn.text = config["name"] + "\n(" + str(int(config["cost"])) + " Kristalle)"
			btn.tooltip_text = config["desc"]
			
			var btn_style = StyleBoxFlat.new()
			btn_style.border_width_left = 2
			btn_style.border_width_right = 2
			btn_style.border_width_top = 2
			btn_style.border_width_bottom = 2
			btn_style.corner_radius_top_left = 8
			btn_style.corner_radius_top_right = 8
			btn_style.corner_radius_bottom_right = 8
			btn_style.corner_radius_bottom_left = 8
			
			if GameManager.is_skill_unlocked(skill_id):
				btn_style.bg_color = Color(0.10, 0.35, 0.10, 0.75)
				btn_style.border_color = Color(0.22, 1.0, 0.08)
				btn.add_theme_color_override("font_color", Color(0.22, 1.0, 0.08))
				btn.disabled = false
			elif GameManager.can_unlock_skill(skill_id):
				btn_style.bg_color = Color(0.22, 0.22, 0.08, 0.75)
				btn_style.border_color = Color(1.0, 0.84, 0.0)
				btn.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
				btn.disabled = false
			else:
				btn_style.bg_color = Color(0.08, 0.05, 0.15, 0.8)
				btn_style.border_color = Color(0.25, 0.25, 0.25)
				btn.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))
				btn.disabled = true
				
			btn.add_theme_stylebox_override("normal", btn_style)
			btn.add_theme_stylebox_override("hover", btn_style)
			btn.add_theme_stylebox_override("disabled", btn_style)
			
	var line_drawer = get_node_or_null("HUD/VBoxContainer/PanelContainer/SkillTreePanel/SkillLineDrawer")
	if line_drawer:
		line_drawer.queue_redraw()

# ----------------- COMET ACTIVE EVENTS -----------------

func spawn_cosmic_comet() -> void:
	var comet = Button.new()
	comet.custom_minimum_size = Vector2(28, 28)
	comet.size = Vector2(28, 28)
	comet.add_to_group("comets")
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.84, 0.0, 0.85)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(1.0, 1.0, 1.0, 0.9)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_right = 14
	style.corner_radius_bottom_left = 14
	style.shadow_color = Color(1.0, 0.84, 0.0, 0.4)
	style.shadow_size = 8
	comet.add_theme_stylebox_override("normal", style)
	comet.add_theme_stylebox_override("hover", style)
	comet.add_theme_stylebox_override("pressed", style)
	
	var tail = CPUParticles2D.new()
	comet.add_child(tail)
	tail.amount = 16
	tail.lifetime = 0.45
	tail.spread = 15.0
	tail.gravity = Vector2.ZERO
	tail.initial_velocity_min = 60.0
	tail.initial_velocity_max = 120.0
	tail.scale_amount_min = 2.0
	tail.scale_amount_max = 6.0
	tail.color = Color(1.0, 0.84, 0.0, 0.65)
	
	var curve = Curve.new()
	curve.add_point(Vector2(0, 1))
	curve.add_point(Vector2(1, 0))
	tail.scale_amount_curve = curve
	tail.direction = Vector2(-1, 0)
	tail.position = Vector2(14, 14)
	
	var start_y = randf_range(160.0, 480.0)
	var end_y = randf_range(160.0, 480.0)
	comet.position = Vector2(-40.0, start_y)
	
	$HUD.add_child(comet)
	comet.pressed.connect(func(): _on_comet_clicked(comet))
	
	var tween = create_tween()
	var duration = randf_range(4.0, 5.5)
	
	var pull_lvl = GameManager.singularity_upgrades.get("gravitational_pull", 0)
	var speed_mult = 1.0 + float(pull_lvl) * 0.10
	duration /= speed_mult
	
	tween.tween_property(comet, "position", Vector2(580.0, end_y), duration).set_trans(Tween.TRANS_LINEAR)
	
	await tween.finished
	if is_instance_valid(comet):
		comet.queue_free()

func _on_comet_clicked(comet: Button) -> void:
	if not is_instance_valid(comet) or comet.is_queued_for_deletion():
		return
		
	var pos = comet.global_position + Vector2(14, 14)
	comet.queue_free()
	
	lifetime_comets_clicked += 1
	
	var power = GameManager.get_click_power()
	var ore_reward = power * 30.0
	GameManager.add_resource("space_ore", ore_reward)
	
	var extra_gas = 0.0
	var extra_crystals = 0.0
	
	if randf() <= 0.30:
		extra_gas = 5.0
		GameManager.add_resource("cosmic_gas", extra_gas)
	if randf() <= 0.10:
		extra_crystals = 1.0
		GameManager.add_resource("star_crystals", extra_crystals)
		
	SoundManager.play_sound(SoundManager.crit_stream, 0.08, 0.0)
	JuiceManager.shake_camera(8.0, 0.4)
	
	JuiceManager.spawn_floating_text(self, pos, "KOMETEN-ERNTE!\n+" + str(int(ore_reward)) + " Erz", true, Color(1.0, 0.84, 0.0))
	if extra_gas > 0:
		JuiceManager.spawn_floating_text(self, pos + Vector2(-60, -30), "+5 Gas", false, Color(1.0, 0.0, 0.5))
	if extra_crystals > 0:
		JuiceManager.spawn_floating_text(self, pos + Vector2(60, -30), "+1 Kristall", true, Color(1.0, 0.84, 0.0))
