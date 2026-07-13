extends Node

# Global Signals
signal resource_changed(type: String, current_amount: float)
signal stats_changed()
signal skill_unlocked(skill_id: String)
signal game_reset()
signal achievement_unlocked(id: String)

# Resource Variables
var space_ore: float = 0.0:
	set(val):
		space_ore = max(0.0, val)
		resource_changed.emit("space_ore", space_ore)

var cosmic_gas: float = 0.0:
	set(val):
		cosmic_gas = max(0.0, val)
		resource_changed.emit("cosmic_gas", cosmic_gas)

var star_crystals: float = 0.0:
	set(val):
		star_crystals = max(0.0, val)
		resource_changed.emit("star_crystals", star_crystals)

var stardust: float = 0.0:
	set(val):
		stardust = max(0.0, val)
		resource_changed.emit("stardust", stardust)

# Tier-2 Prestige Currency
var dark_matter: float = 0.0:
	set(val):
		dark_matter = max(0.0, val)
		resource_changed.emit("dark_matter", dark_matter)

var stardust_invested: float = 0.0:
	set(val):
		stardust_invested = max(0.0, val)
		resource_changed.emit("stardust_invested", stardust_invested)

# Lifetime statistics
var lifetime_space_ore: float = 0.0
var lifetime_stardust: float = 0.0

var current_sector: int = 1

func get_sector_target() -> float:
	var safe_sector = max(1, current_sector)
	return 1000.0 * pow(5.0, float(safe_sector - 1))

# Stats tracking for achievements
var stats: Dictionary = {
	"manual_clicks": 0.0,
	"lifetime_gas": 0.0,
	"lifetime_crystals": 0.0,
	"lifetime_comets": 0.0,
	"stabilizations": 0.0,
	"prestige_count": 0.0
}

var unlocked_achievements: Array = []

var unlocked_artifacts: Array = []
var equipped_artifacts: Array = []

const ARTIFACTS_CONFIG: Dictionary = {
	"dark_matter_mirror": {
		"title": "Dunkelmaterie-Spiegel",
		"desc": "+15% Krit-Chance auf Klicks.",
		"buff_type": "crit_chance",
		"buff_val": 0.15
	},
	"crystal_amplifier": {
		"title": "Kristall-Verstärker",
		"desc": "+25% globaler passiver Ressourcenertrag.",
		"buff_type": "passive_mult",
		"buff_val": 0.25
	},
	"grav_anchor": {
		"title": "Gravitations-Anker",
		"desc": "Kernschmelze-Abkühlzeit dauert 3 Sek länger.",
		"buff_type": "meltdown_time",
		"buff_val": 3.0
	},
	"pulse_generator": {
		"title": "Impuls-Generator",
		"desc": "+30% Klickkraft.",
		"buff_type": "click_power_mult",
		"buff_val": 0.30
	},
	"cosmic_collector": {
		"title": "Kosmischer Kollektor",
		"desc": "Drohnen sammeln 40% mehr Erze pro Zyklus.",
		"buff_type": "drone_yield_mult",
		"buff_val": 0.40
	}
}

const ACHIEVEMENTS_CONFIG: Dictionary = {
	"first_click": {
		"title": "Erster Kontakt",
		"desc": "Baue dein erstes Weltraumerz manuell ab.",
		"progress_needed": 1.0,
		"stat_tracked": "manual_clicks",
		"buff": "+1% Klickleistung"
	},
	"ore_1k": {
		"title": "Erz-Schürfer",
		"desc": "Besitze insgesamt 1.000 Weltraumerz.",
		"progress_needed": 1000.0,
		"stat_tracked": "lifetime_space_ore",
		"buff": "+1% Erz-Bohrer-Produktion"
	},
	"gas_100": {
		"title": "Gas-Pionier",
		"desc": "Besitze insgesamt 100 Kosmisches Gas.",
		"progress_needed": 100.0,
		"stat_tracked": "lifetime_gas",
		"buff": "+1% Gas-Siphon-Produktion"
	},
	"crystals_10": {
		"title": "Kristallsammler",
		"desc": "Sammle insgesamt 10 Sternenkristalle.",
		"progress_needed": 10.0,
		"stat_tracked": "lifetime_crystals",
		"buff": "+1% Krit-Chance"
	},
	"comets_10": {
		"title": "Astronom",
		"desc": "Klicke 10 fliegende Kometen an.",
		"progress_needed": 10.0,
		"stat_tracked": "lifetime_comets",
		"buff": "+5% Globaler Ertrag"
	},
	"supernova_10": {
		"title": "Kern-Stabilisator",
		"desc": "Verhindere 10 Supernova-Kernschmelzen.",
		"progress_needed": 10.0,
		"stat_tracked": "stabilizations",
		"buff": "+5% Reaktor-Fenster"
	},
	"prestige_first": {
		"title": "Kollaps-Überlebender",
		"desc": "Löse deinen ersten Kosmischen Kollaps (Prestige) aus.",
		"progress_needed": 1.0,
		"stat_tracked": "prestige_count",
		"buff": "+5% Sternenstaub-Ertrag"
	}
}

# Upgrades levels
var upgrade_levels: Dictionary = {
	"click_power": 1,
	"crit_chance": 0,
	"crit_multiplier": 0,
	"drill": 0,       # Ore miner
	"siphon": 0,      # Gas miner
	"synthesizer": 0, # Crystal miner
	"drone_count": 0, # Drone network count
	"drone_speed": 0  # Drone speed upgrade
}

# Stardust permanent perks
var perk_levels: Dictionary = {
	"global_boost": 0,    # +5% production per level
	"starting_ore": 0,    # Starts new run with +1000 Ore per level
	"crit_juice": 0       # Crits spawn +10% more particles and resource
}

# Tier-2 Singularity Upgrades (Purchased with Dark Matter)
var singularity_upgrades: Dictionary = {
	"gravitational_pull": 0,    # +10% Comet spawn freq & +10% speed
	"quantum_tunneling": 0,     # 5% chance for double tick on automation
	"chamber_stabilization": 0  # Extends Super-Nova reaction window by +15%
}

# Unlocked Skill Tree Nodes
var unlocked_skills: Array = []

# Game Loop Accumulator
var time_accumulator: float = 0.0
const UPDATE_INTERVAL: float = 0.1 # 10 ticks per second

# Save System Settings
const SAVE_PATH = "user://savegame.save"
var save_timer: float = 0.0
const AUTO_SAVE_INTERVAL: float = 15.0 # More frequent saves
var last_save_time: float = 0.0

# Offline Earnings Cache
var offline_ore_earned: float = 0.0
var offline_gas_earned: float = 0.0
var offline_crystals_earned: float = 0.0
var offline_seconds: float = 0.0
var show_offline_popup: bool = false

# Active Spells Modifiers
var overdrive_active: bool = false
var overdrive_timer: float = 0.0
var magnetic_net_active: bool = false
var magnetic_net_timer: float = 0.0
var meltdown_active: bool = false

# Upgrade Configurations (Base Cost, Multiplier, Rates)
const UPGRADE_CONFIG = {
	"click_power": {
		"base_cost": 8.0,
		"cost_mult": 1.10,
		"cost_type": "space_ore"
	},
	"crit_chance": {
		"base_cost": 40.0,
		"cost_mult": 1.14,
		"cost_type": "space_ore"
	},
	"crit_multiplier": {
		"base_cost": 90.0,
		"cost_mult": 1.15,
		"cost_type": "space_ore"
	},
	"drill": {
		"base_cost": 35.0,
		"cost_mult": 1.12,
		"cost_type": "space_ore"
	},
	"siphon": {
		"base_cost": 200.0,
		"cost_mult": 1.14,
		"cost_type": "space_ore"
	},
	"synthesizer": {
		"base_cost": 800.0,
		"cost_mult": 1.16,
		"cost_type": "space_ore"
	},
	"drone_count": {
		"base_cost": 500.0,
		"cost_mult": 1.50,
		"cost_type": "space_ore"
	},
	"drone_speed": {
		"base_cost": 300.0,
		"cost_mult": 1.40,
		"cost_type": "space_ore"
	}
}

# Singularity Upgrades Configuration (Cost in Dark Matter)
const SINGULARITY_CONFIG = {
	"gravitational_pull": {
		"name": "Gravitationszug",
		"base_cost": 1.0,
		"cost_mult": 1.80,
		"desc": "+10% Kometen-Frequenz & -Geschwindigkeit"
	},
	"quantum_tunneling": {
		"name": "Quantentunnelung",
		"base_cost": 2.0,
		"cost_mult": 2.00,
		"desc": "5% Chance auf doppelte Ticks bei Automation"
	},
	"chamber_stabilization": {
		"name": "Kammerstabilisierung",
		"base_cost": 3.0,
		"cost_mult": 1.90,
		"desc": "+15% Super-Nova Reaktionsfenster"
	}
}

# Skill Tree Configuration
const SKILL_CONFIG = {
	"ore_magnet": {
		"name": "Erzmagnet",
		"cost": 10.0,
		"cost_type": "star_crystals",
		"desc": "+25% Klick-Erz. Schaltet Overdrive-Zauber frei.",
		"deps": []
	},
	"gas_igniter": {
		"name": "Gaszünder",
		"cost": 25.0,
		"cost_type": "star_crystals",
		"desc": "+20% Gas. Schaltet Anomalie-Siphon-Zauber frei.",
		"deps": ["ore_magnet"]
	},
	"crystal_refiner": {
		"name": "Kristallraffinerie",
		"cost": 50.0,
		"cost_type": "star_crystals",
		"desc": "Kritische Klicks erzeugen Gas/Kristalle.",
		"deps": ["gas_igniter"]
	},
	"quantum_drill": {
		"name": "Quantenbohrer",
		"cost": 75.0,
		"cost_type": "star_crystals",
		"desc": "+30% Erzbohrer. Schaltet Magnetnetz-Zauber frei.",
		"deps": ["ore_magnet"]
	},
	"cosmic_forge": {
		"name": "Kosmische Schmiede",
		"cost": 150.0,
		"cost_type": "star_crystals",
		"desc": "+100% Sternenstaub-Ertrag bei Reset.",
		"deps": ["crystal_refiner", "quantum_drill"]
	}
}

func _ready() -> void:
	load_game()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or \
	   what == NOTIFICATION_APPLICATION_FOCUS_OUT or \
	   what == NOTIFICATION_APPLICATION_PAUSED:
		save_game()

func _process(delta: float) -> void:
	# Spells timer decay
	if overdrive_active:
		overdrive_timer -= delta
		if overdrive_timer <= 0.0:
			overdrive_active = false
			stats_changed.emit()
			
	if magnetic_net_active:
		magnetic_net_timer -= delta
		if magnetic_net_timer <= 0.0:
			magnetic_net_active = false
			stats_changed.emit()

	# Idle Income Loop
	time_accumulator += delta
	if time_accumulator >= UPDATE_INTERVAL:
		_process_idle_income(UPDATE_INTERVAL)
		time_accumulator -= UPDATE_INTERVAL
	
	# Auto-save Loop
	save_timer += delta
	if save_timer >= AUTO_SAVE_INTERVAL:
		save_game()
		save_timer = 0.0

# ----------------- ECONOMY MATH -----------------

func get_upgrade_cost(id: String) -> float:
	if not UPGRADE_CONFIG.has(id):
		return 0.0
	var config = UPGRADE_CONFIG[id]
	var lvl = upgrade_levels[id]
	
	# Cap drone count at 8
	if id == "drone_count" and lvl >= 8:
		return 999999999.0
		
	return floor(config["base_cost"] * pow(config["cost_mult"], lvl))

func get_upgrade_cost_type(id: String) -> String:
	if not UPGRADE_CONFIG.has(id):
		return "space_ore"
	return UPGRADE_CONFIG[id]["cost_type"]

func buy_upgrade(id: String) -> bool:
	var cost = get_upgrade_cost(id)
	var type = get_upgrade_cost_type(id)
	
	if id == "drone_count" and upgrade_levels["drone_count"] >= 8:
		return false
		
	if spend_resource(type, cost):
		upgrade_levels[id] += 1
		stats_changed.emit()
		SoundManager.play_sound(SoundManager.upgrade_stream, 0.0, -2.0)
		save_game()
		return true
	return false

# Click Power Calculations
func get_click_power() -> float:
	var base = float(upgrade_levels["click_power"])
	base += float(unlocked_skills.size() * 3.0)
	
	var mult = 1.0
	if unlocked_skills.has("ore_magnet"):
		mult += 0.25
	if is_achievement_unlocked("first_click"):
		mult += 0.01
	if equipped_artifacts.has("pulse_generator"):
		mult += 0.30
	
	mult += get_global_production_multiplier()
	return base * mult

func get_crit_chance() -> float:
	var base = float(upgrade_levels["crit_chance"]) * 0.01 + 0.05
	if is_achievement_unlocked("crystals_10"):
		base += 0.01
	if equipped_artifacts.has("dark_matter_mirror"):
		base += 0.15
	return min(0.65, base)

func get_crit_multiplier() -> float:
	var base = 2.0 + float(upgrade_levels["crit_multiplier"]) * 0.3
	if unlocked_skills.has("gas_igniter"):
		base += 0.5
	return base

# Passive Production Rate Calculations
func get_production_rate(id: String) -> float:
	if meltdown_active:
		return 0.0
		
	var lvl = float(upgrade_levels[id])
	if lvl == 0:
		return 0.0
		
	var base_rate = 0.0
	var mult = 1.0 + get_global_production_multiplier()
	
	# Apply active spells modifier (Overdrive gives +200% production)
	if overdrive_active:
		mult += 2.0
		
	match id:
		"drill":
			base_rate = lvl * 1.5
			if unlocked_skills.has("quantum_drill"):
				mult += 0.30
			if is_achievement_unlocked("ore_1k"):
				mult += 0.01
		"siphon":
			base_rate = lvl * 0.4
			if unlocked_skills.has("gas_igniter"):
				mult += 0.20
			if is_achievement_unlocked("gas_100"):
				mult += 0.01
		"synthesizer":
			base_rate = lvl * 0.1
			
	return base_rate * mult

func get_global_production_multiplier() -> float:
	var mult = stardust * 0.02
	mult += perk_levels["global_boost"] * 0.05
	if is_achievement_unlocked("comets_10"):
		mult += 0.05
	
	# Sektor global production multiplier (+50% per sector beyond 1)
	mult += float(current_sector - 1) * 0.5
	
	if equipped_artifacts.has("crystal_amplifier"):
		mult += 0.25
		
	return mult

# Process idle income
func _process_idle_income(tick_delta: float) -> void:
	var ore_sec = get_production_rate("drill")
	var gas_sec = get_production_rate("siphon")
	var crystal_sec = get_production_rate("synthesizer")
	
	# Quantum Tunneling (Singularity Upgrade): 5% chance for double tick
	var qt_level = singularity_upgrades.get("quantum_tunneling", 0)
	var double_mult = 1.0
	if qt_level > 0 and randf() <= (float(qt_level) * 0.05):
		double_mult = 2.0
		
	add_resource("space_ore", ore_sec * tick_delta * double_mult)
	add_resource("cosmic_gas", gas_sec * tick_delta * double_mult)
	add_resource("star_crystals", crystal_sec * tick_delta * double_mult)
	
	# Passive Dark Matter generation from invested stardust
	if stardust_invested > 0.0:
		var dm_gained = stardust_invested * 0.02 * tick_delta
		dark_matter += dm_gained

# ----------------- PASSIVE COLLECTOR DRONES -----------------

func get_drone_count() -> int:
	return upgrade_levels["drone_count"]

func get_drone_speed() -> float:
	var base_speed = 130.0
	return base_speed + float(upgrade_levels["drone_speed"]) * 25.0

# ----------------- SINGULARITY PRESTIGE & UPGRADES -----------------

func invest_stardust(amount: float) -> bool:
	if stardust >= amount and amount > 0.0:
		stardust -= amount
		stardust_invested += amount
		stats_changed.emit()
		SoundManager.play_sound(SoundManager.upgrade_stream, 0.08, -1.0)
		save_game()
		return true
	return false

func get_singularity_cost(id: String) -> float:
	if not SINGULARITY_CONFIG.has(id):
		return 0.0
	var config = SINGULARITY_CONFIG[id]
	var lvl = singularity_upgrades[id]
	return floor(config["base_cost"] * pow(config["cost_mult"], lvl))

func buy_singularity_upgrade(id: String) -> bool:
	var cost = get_singularity_cost(id)
	if dark_matter >= cost:
		dark_matter -= cost
		singularity_upgrades[id] += 1
		stats_changed.emit()
		SoundManager.play_sound(SoundManager.upgrade_stream, 0.05, 0.0)
		save_game()
		return true
	return false

# ----------------- ACTIVE SPELLS ACTIONS -----------------

func is_spell_unlocked(id: String) -> bool:
	match id:
		"overdrive":
			return is_skill_unlocked("ore_magnet")
		"siphon":
			return is_skill_unlocked("gas_igniter")
		"magnetic_net":
			return is_skill_unlocked("quantum_drill")
	return false

func cast_spell(id: String) -> bool:
	if not is_spell_unlocked(id):
		return false
		
	match id:
		"overdrive":
			if overdrive_active: return false
			overdrive_active = true
			overdrive_timer = 10.0
		"siphon":
			# Awards 15% of remaining Space Ore to 100K threshold
			var remaining = max(0.0, 100000.0 - space_ore)
			if remaining > 0.0:
				var gain = remaining * 0.15
				add_resource("space_ore", gain)
		"magnetic_net":
			if magnetic_net_active: return false
			magnetic_net_active = true
			magnetic_net_timer = 15.0
			
	stats_changed.emit()
	return true

# ----------------- SKILL TREE & PERKS -----------------

func is_skill_unlocked(id: String) -> bool:
	return unlocked_skills.has(id)

func can_unlock_skill(id: String) -> bool:
	if unlocked_skills.has(id):
		return false
		
	var config = SKILL_CONFIG[id]
	for dep in config["deps"]:
		if not unlocked_skills.has(dep):
			return false
			
	var cost = config["cost"]
	var cost_type = config["cost_type"]
	return get_resource(cost_type) >= cost

func buy_skill(id: String) -> bool:
	if not can_unlock_skill(id):
		return false
		
	var config = SKILL_CONFIG[id]
	var cost = config["cost"]
	var cost_type = config["cost_type"]
	
	if spend_resource(cost_type, cost):
		unlocked_skills.append(id)
		skill_unlocked.emit(id)
		stats_changed.emit()
		SoundManager.play_sound(SoundManager.upgrade_stream, 0.05, -2.0)
		return true
		
	return false

# ----------------- PRESTIGE SYSTEM -----------------

func get_pending_stardust() -> float:
	if lifetime_space_ore < 100000.0:
		return 0.0
	
	var mult = 1.0
	if unlocked_skills.has("cosmic_forge"):
		mult += 1.0
	if is_achievement_unlocked("prestige_first"):
		mult += 0.05
		
	var earned = floor(100.0 * sqrt(lifetime_space_ore / 100000.0))
	var pending = earned - lifetime_stardust
	return max(0.0, pending) * mult

func trigger_prestige() -> bool:
	var pending = get_pending_stardust()
	if pending <= 0.0:
		return false
		
	stardust += pending
	lifetime_stardust += pending
	
	space_ore = float(perk_levels["starting_ore"] * 1000.0)
	cosmic_gas = 0.0
	star_crystals = 0.0
	
	# Keep dark matter, invested stardust, and singularity upgrades intact!
	
	upgrade_levels["click_power"] = 1
	upgrade_levels["crit_chance"] = 0
	upgrade_levels["crit_multiplier"] = 0
	upgrade_levels["drill"] = 0
	upgrade_levels["siphon"] = 0
	upgrade_levels["synthesizer"] = 0
	# Drones are preserved too!
	
	unlocked_skills.clear()
	
	overdrive_active = false
	magnetic_net_active = false
	
	# Reset sector back to 1 on prestige
	current_sector = 1
	
	game_reset.emit()
	stats_changed.emit()
	SoundManager.play_sound(SoundManager.prestige_stream, 0.0, 0.0)
	save_game()
	return true

func hard_reset() -> void:
	# Delete save file if exists
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
		
	# Reset resources
	space_ore = 0.0
	cosmic_gas = 0.0
	star_crystals = 0.0
	stardust = 0.0
	dark_matter = 0.0
	stardust_invested = 0.0
	lifetime_space_ore = 0.0
	lifetime_stardust = 0.0
	
	# Reset upgrades
	for up_id in upgrade_levels.keys():
		if up_id == "click_power":
			upgrade_levels[up_id] = 1
		else:
			upgrade_levels[up_id] = 0
			
	# Reset singularity upgrades
	for sing_id in singularity_upgrades.keys():
		singularity_upgrades[sing_id] = 0
		
	# Reset perks
	for perk_id in perk_levels.keys():
		perk_levels[perk_id] = 0
		
	# Reset skills
	unlocked_skills.clear()
	
	# Reset achievements & stats
	unlocked_achievements.clear()
	for k in stats.keys():
		stats[k] = 0.0
	
	overdrive_active = false
	overdrive_timer = 0.0
	magnetic_net_active = false
	magnetic_net_timer = 0.0
	
	# Reset sector
	current_sector = 1
	
	# Reset artifacts
	unlocked_artifacts.clear()
	equipped_artifacts.clear()
	
	game_reset.emit()
	stats_changed.emit()
	
	SoundManager.play_sound(SoundManager.prestige_stream, 0.0, 0.0)
	save_game()

func get_perk_cost(id: String) -> float:
	var lvl = perk_levels[id]
	match id:
		"global_boost":
			return floor(1.0 + lvl * 1.5)
		"starting_ore":
			return floor(2.0 + lvl * 2.0)
		"crit_juice":
			return floor(1.0 + lvl * 1.0)
	return 999.0

func buy_perk(id: String) -> bool:
	var cost = get_perk_cost(id)
	if stardust >= cost:
		stardust -= cost
		perk_levels[id] += 1
		stats_changed.emit()
		SoundManager.play_sound(SoundManager.upgrade_stream, 0.1, -1.0)
		save_game()
		return true
	return false

# ----------------- ACHIEVEMENTS STATS & LOGIC -----------------

func add_stat(id: String, amount: float) -> void:
	if not stats.has(id):
		stats[id] = 0.0
	stats[id] += amount
	_check_achievements()

func is_achievement_unlocked(id: String) -> bool:
	return unlocked_achievements.has(id)

func _check_achievements() -> void:
	var unlocked_any = false
	for id in ACHIEVEMENTS_CONFIG.keys():
		if unlocked_achievements.has(id):
			continue
			
		var config = ACHIEVEMENTS_CONFIG[id]
		var stat_name = config["stat_tracked"]
		var current_val = 0.0
		if stat_name == "lifetime_space_ore":
			current_val = lifetime_space_ore
		elif stats.has(stat_name):
			current_val = stats[stat_name]
			
		if current_val >= config["progress_needed"]:
			unlocked_achievements.append(id)
			achievement_unlocked.emit(id)
			unlocked_any = true
			
	if unlocked_any:
		stats_changed.emit()
		save_game()

# ----------------- STATE FUNCTIONS -----------------

func add_resource(type: String, amount: float) -> void:
	if amount <= 0.0:
		return
		
	match type:
		"space_ore":
			space_ore += amount
			lifetime_space_ore += amount
			_check_achievements() # Also check achievements since lifetime_space_ore changed
		"cosmic_gas":
			cosmic_gas += amount
			add_stat("lifetime_gas", amount)
		"star_crystals":
			star_crystals += amount
			add_stat("lifetime_crystals", amount)
		"stardust":
			stardust += amount
		"dark_matter":
			dark_matter += amount
		_:
			push_error("Unknown resource type: " + type)

func spend_resource(type: String, amount: float) -> bool:
	if amount <= 0.0:
		return true
		
	var current_amount = get_resource(type)
	if current_amount >= amount:
		match type:
			"space_ore":
				space_ore -= amount
			"cosmic_gas":
				cosmic_gas -= amount
			"star_crystals":
				star_crystals -= amount
			"stardust":
				stardust -= amount
			"dark_matter":
				dark_matter -= amount
			_:
				push_error("Unknown resource type: " + type)
				return false
		return true
	return false

func get_resource(type: String) -> float:
	match type:
		"space_ore":
			return space_ore
		"cosmic_gas":
			return cosmic_gas
		"star_crystals":
			return star_crystals
		"stardust":
			return stardust
		"dark_matter":
			return dark_matter
		_:
			push_error("Unknown resource type: " + type)
			return 0.0

# ----------------- SAVE / LOAD & OFFLINE PROGRESS -----------------

func save_game() -> void:
	var config = ConfigFile.new()
	
	# Currencies
	config.set_value("resources", "space_ore", space_ore)
	config.set_value("resources", "cosmic_gas", cosmic_gas)
	config.set_value("resources", "star_crystals", star_crystals)
	config.set_value("resources", "stardust", stardust)
	config.set_value("resources", "dark_matter", dark_matter)
	config.set_value("resources", "stardust_invested", stardust_invested)
	config.set_value("resources", "lifetime_space_ore", lifetime_space_ore)
	config.set_value("resources", "lifetime_stardust", lifetime_stardust)
	config.set_value("resources", "current_sector", current_sector)
	
	# Upgrades
	for up_id in upgrade_levels.keys():
		config.set_value("upgrades", up_id, upgrade_levels[up_id])
		
	# Singularity Upgrades
	for sing_id in singularity_upgrades.keys():
		config.set_value("singularity", sing_id, singularity_upgrades[sing_id])
		
	# Perks
	for perk_id in perk_levels.keys():
		config.set_value("perks", perk_id, perk_levels[perk_id])
		
	# Skills
	config.set_value("skills", "unlocked", unlocked_skills)
	
	# Achievements & Stats
	config.set_value("achievements", "unlocked", unlocked_achievements)
	config.set_value("achievements", "stats", stats)
	
	# Artifacts
	config.set_value("artifacts", "unlocked", unlocked_artifacts)
	config.set_value("artifacts", "equipped", equipped_artifacts)
	
	# Save time
	last_save_time = Time.get_unix_time_from_system()
	config.set_value("meta", "last_save_time", last_save_time)
	
	var err = config.save(SAVE_PATH)
	if err != OK:
		push_error("Failed to save game! Error code: ", err)

func load_game() -> void:
	var config = ConfigFile.new()
	var err = config.load(SAVE_PATH)
	if err != OK:
		space_ore = float(perk_levels["starting_ore"] * 1000.0)
		return
		
	# Currencies (safely parsed as float/numeric)
	space_ore = float(config.get_value("resources", "space_ore", 0.0))
	cosmic_gas = float(config.get_value("resources", "cosmic_gas", 0.0))
	star_crystals = float(config.get_value("resources", "star_crystals", 0.0))
	stardust = float(config.get_value("resources", "stardust", 0.0))
	dark_matter = float(config.get_value("resources", "dark_matter", 0.0))
	stardust_invested = float(config.get_value("resources", "stardust_invested", 0.0))
	lifetime_space_ore = float(config.get_value("resources", "lifetime_space_ore", 0.0))
	lifetime_stardust = float(config.get_value("resources", "lifetime_stardust", 0.0))
	current_sector = int(config.get_value("resources", "current_sector", 1))
	
	# Upgrades validation against active keys
	var default_upgrades = {
		"click_power": 1,
		"crit_chance": 0,
		"crit_multiplier": 0,
		"drill": 0,
		"siphon": 0,
		"synthesizer": 0,
		"drone_count": 0,
		"drone_speed": 0
	}
	for up_id in default_upgrades.keys():
		var val = config.get_value("upgrades", up_id, default_upgrades[up_id])
		if typeof(val) == TYPE_INT or typeof(val) == TYPE_FLOAT:
			upgrade_levels[up_id] = int(val)
		else:
			upgrade_levels[up_id] = default_upgrades[up_id]
		
	# Singularity Upgrades validation
	var default_singularity = {
		"gravitational_pull": 0,
		"quantum_tunneling": 0,
		"chamber_stabilization": 0
	}
	for sing_id in default_singularity.keys():
		var val = config.get_value("singularity", sing_id, default_singularity[sing_id])
		if typeof(val) == TYPE_INT or typeof(val) == TYPE_FLOAT:
			singularity_upgrades[sing_id] = int(val)
		else:
			singularity_upgrades[sing_id] = default_singularity[sing_id]
		
	# Perks validation
	var default_perks = {
		"global_boost": 0,
		"starting_ore": 0,
		"crit_juice": 0
	}
	for perk_id in default_perks.keys():
		var val = config.get_value("perks", perk_id, default_perks[perk_id])
		if typeof(val) == TYPE_INT or typeof(val) == TYPE_FLOAT:
			perk_levels[perk_id] = int(val)
		else:
			perk_levels[perk_id] = default_perks[perk_id]
		
	# Skills (safely load array)
	var loaded_skills = config.get_value("skills", "unlocked", [])
	if typeof(loaded_skills) == TYPE_ARRAY:
		unlocked_skills = loaded_skills
	else:
		unlocked_skills = []
		
	# Achievements (safely load array)
	var loaded_achievements = config.get_value("achievements", "unlocked", [])
	if typeof(loaded_achievements) == TYPE_ARRAY:
		unlocked_achievements = loaded_achievements
	else:
		unlocked_achievements = []
		
	# Stats (safely load dictionary)
	var loaded_stats = config.get_value("achievements", "stats", {})
	if typeof(loaded_stats) == TYPE_DICTIONARY:
		for k in stats.keys():
			if loaded_stats.has(k):
				stats[k] = float(loaded_stats[k])
				
	# Artifacts loading
	var loaded_unlocked_art = config.get_value("artifacts", "unlocked", [])
	if typeof(loaded_unlocked_art) == TYPE_ARRAY:
		unlocked_artifacts = loaded_unlocked_art
	else:
		unlocked_artifacts = []
		
	var loaded_equipped_art = config.get_value("artifacts", "equipped", [])
	if typeof(loaded_equipped_art) == TYPE_ARRAY:
		equipped_artifacts = loaded_equipped_art
	else:
		equipped_artifacts = []
	
	# Calculate Offline earnings
	last_save_time = float(config.get_value("meta", "last_save_time", 0.0))
	if last_save_time > 0.0:
		var current_time = Time.get_unix_time_from_system()
		var diff = current_time - last_save_time
		if diff > 15.0: # Minimum 15 seconds to trigger
			var active_diff = min(diff, 43200.0) # Cap at 12 hours
			
			var ore_rate = get_production_rate("drill")
			var gas_rate = get_production_rate("siphon")
			var crystal_rate = get_production_rate("synthesizer")
			
			# 60% base offline efficiency
			var offline_efficiency = 0.60
			
			offline_ore_earned = ore_rate * active_diff * offline_efficiency
			offline_gas_earned = gas_rate * active_diff * offline_efficiency
			offline_crystals_earned = crystal_rate * active_diff * offline_efficiency
			offline_seconds = diff
			
			# Add resources
			add_resource("space_ore", offline_ore_earned)
			add_resource("cosmic_gas", offline_gas_earned)
			add_resource("star_crystals", offline_crystals_earned)
			
			show_offline_popup = true
	
	stats_changed.emit()
