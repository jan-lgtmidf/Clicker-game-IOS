extends Control

const VERSION_URL = "https://raw.githubusercontent.com/jan-lgtmidf/Clicker-game-IOS/ota-assets/version.json"
const LOCAL_VERSION_FILE = "user://ota_version.json"
const LOCAL_PCK_FILE = "user://game.pck"
const MAIN_SCENE_PATH = "res://scenes/Main.tscn"

@onready var status_label: Label = %StatusLabel
@onready var loader_ring: Control = %LoaderRing
@onready var percentage_label: Label = %PercentageLabel
@onready var version_label: Label = %VersionLabel
@onready var version_check: HTTPRequest = %VersionCheckRequest
@onready var pack_download: HTTPRequest = %PackDownloadRequest

var local_version_data: Dictionary = {"version": 0}
var remote_version_data: Dictionary = {}

var is_updating: bool = false
var timeout_timer: Timer

# Satisfying Animation Variables
var ring_rotation: float = 0.0
var download_percent: float = 0.0
var target_percent: float = 0.0
var pulse_time: float = 0.0

func _ready() -> void:
	if OS.has_feature("editor"):
		print("Running in Editor. Bypassing OTA update system.")
		get_tree().call_deferred("change_scene_to_file", MAIN_SCENE_PATH)
		return

	# 1. Setup satisfy-loading starfield programmatically
	_setup_starfield()
	
	# 2. Connect Custom Drawer to LoaderRing
	loader_ring.draw.connect(_on_loader_ring_draw)
	percentage_label.text = ""
	
	# 3. HTTP Signals Setup
	version_check.request_completed.connect(_on_version_check_completed)
	pack_download.request_completed.connect(_on_pack_download_completed)
	
	# 4. Timeout Safeguard (max 4 seconds for update check)
	timeout_timer = Timer.new()
	timeout_timer.wait_time = 4.0
	timeout_timer.one_shot = true
	timeout_timer.timeout.connect(_on_timeout)
	add_child(timeout_timer)
	
	# 5. Load & Display Local Version
	_load_local_version()
	version_label.text = "v%s (Lokal)" % str(local_version_data.version)
	
	# 6. Start OTA Check
	_start_version_check()

func _process(delta: float) -> void:
	# 1. Rotate the loader dots
	ring_rotation += delta * 2.2
	
	# 2. Pulsing subtitle/loading label effect
	pulse_time += delta * 3.0
	var label_pulse = 0.7 + sin(pulse_time) * 0.3
	status_label.modulate.a = label_pulse
	
	# 3. Monitor download progress
	if is_updating:
		var total = pack_download.get_body_size()
		var current = pack_download.get_downloaded_bytes()
		if total > 0:
			target_percent = (float(current) / float(total)) * 100.0
			
		# Smooth interpolation for a satisfying, non-jagged fill effect!
		download_percent = lerp(download_percent, target_percent, 0.12)
		percentage_label.text = "%d%%" % int(download_percent)
		
		# Change colors dynamically as it finishes
		var pct_color = Color(1.0, 0.0, 0.5).lerp(Color(0.0, 0.94, 1.0), download_percent / 100.0)
		percentage_label.add_theme_color_override("font_color", pct_color)
	else:
		if download_percent > 0.0 and download_percent < 100.0:
			download_percent = lerp(download_percent, 100.0, 0.15)
			percentage_label.text = "%d%%" % int(download_percent)
			
	# Redraw the LoaderRing
	loader_ring.queue_redraw()

func _setup_starfield() -> void:
	# Setup a beautiful space dust drift background
	var starfield = CPUParticles2D.new()
	starfield.name = "StarField"
	add_child(starfield)
	move_child(starfield, 1) # Directly above the background ColorRect
	
	starfield.amount = 35
	starfield.lifetime = 8.0
	starfield.preprocess = 8.0
	starfield.speed_scale = 0.65
	starfield.explosiveness = 0.0
	starfield.randomness = 0.4
	
	# Emit from bottom, drift upwards
	starfield.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	starfield.emission_rect_extents = Vector2(270, 10)
	starfield.position = Vector2(270, 970) # Just below viewport
	
	starfield.direction = Vector2(0, -1) # Up
	starfield.spread = 10.0
	starfield.gravity = Vector2.ZERO
	starfield.initial_velocity_min = 50.0
	starfield.initial_velocity_max = 90.0
	
	starfield.scale_amount_min = 1.0
	starfield.scale_amount_max = 3.0
	
	var scale_curve = Curve.new()
	scale_curve.add_point(Vector2(0, 0))
	scale_curve.add_point(Vector2(0.15, 1))
	scale_curve.add_point(Vector2(0.85, 1))
	scale_curve.add_point(Vector2(1, 0))
	starfield.scale_amount_curve = scale_curve
	
	starfield.color = Color(0.0, 0.94, 1.0, 0.2) # Deep neon cyan particles
	starfield.emitting = true

func _on_loader_ring_draw() -> void:
	var center = loader_ring.size / 2.0
	
	# A. Dark circle background plate
	loader_ring.draw_circle(center, 46.0, Color(0.06, 0.05, 0.1, 0.75))
	
	# B. Outer subtle glowing orbit track
	loader_ring.draw_arc(center, 54.0, 0.0, TAU, 48, Color(0.0, 0.94, 1.0, 0.08), 1.5, true)
	
	# C. Outer rotating dotted cyan ring (spinner)
	var dots = 9
	var dot_radius = 54.0
	for i in range(dots):
		var angle = (float(i) / dots) * TAU + ring_rotation
		var alpha = float(i) / float(dots)
		
		# Create a trailing brightness visual
		var dot_color = Color(0.0, 0.94, 1.0, alpha * 0.85)
		var dot_pos = center + Vector2(cos(angle), sin(angle)) * dot_radius
		
		# Draw trailing dots slightly smaller
		var size_factor = 1.0 + alpha * 1.5
		loader_ring.draw_circle(dot_pos, 1.5 * size_factor, dot_color)
		
	# D. Inner sweeping progress arc (neon pink)
	if download_percent > 0.0:
		var start_angle = -PI / 2.0 # Top center
		var end_angle = start_angle + (download_percent / 100.0) * TAU
		
		# Thick backing glow arc
		loader_ring.draw_arc(center, 44.0, start_angle, end_angle, 64, Color(1.0, 0.0, 0.5, 0.22), 6.5, true)
		# Sharp foreground progress arc
		var arc_color = Color(1.0, 0.0, 0.5, 0.95)
		# Interpolate arc color towards cyan as it reaches 100%
		if download_percent > 80.0:
			var t = (download_percent - 80.0) / 20.0
			arc_color = Color(1.0, 0.0, 0.5, 0.95).lerp(Color(0.0, 0.94, 1.0, 0.95), t)
		loader_ring.draw_arc(center, 44.0, start_angle, end_angle, 64, arc_color, 2.5, true)
	else:
		# Draw a pulsing static inner ring when idle/checking
		var pulse_alpha = 0.15 + sin(pulse_time * 1.5) * 0.08
		loader_ring.draw_arc(center, 44.0, 0.0, TAU, 48, Color(1.0, 0.0, 0.5, pulse_alpha), 2.0, true)

func _load_local_version() -> void:
	if FileAccess.file_exists(LOCAL_VERSION_FILE):
		var file = FileAccess.open(LOCAL_VERSION_FILE, FileAccess.READ)
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var error = json.parse(json_string)
		if error == OK:
			if typeof(json.data) == TYPE_DICTIONARY:
				local_version_data = json.data

func _save_local_version(version: int) -> void:
	var data = {
		"version": version,
		"updated_at": Time.get_datetime_string_from_system()
	}
	var file = FileAccess.open(LOCAL_VERSION_FILE, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

func _start_version_check() -> void:
	status_label.text = "Verbinde mit Orbit..."
	timeout_timer.start()
	
	version_check.use_threads = true
	var err = version_check.request(VERSION_URL)
	if err != OK:
		print("Version check request failed immediately: ", err)
		_on_timeout()

func _on_version_check_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	timeout_timer.stop()
	
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		var json = JSON.new()
		var error = json.parse(body.get_string_from_utf8())
		if error == OK and typeof(json.data) == TYPE_DICTIONARY:
			remote_version_data = json.data
			var remote_version = int(remote_version_data.get("version", 0))
			var local_version = int(local_version_data.get("version", 0))
			
			print("Local version: ", local_version, " | Remote version: ", remote_version)
			
			if remote_version > local_version and remote_version_data.has("pck_url"):
				_start_download()
				return
			else:
				print("App is up to date.")
				status_label.text = "System nominal."
				_load_and_start_game()
				return
				
	# If check failed (offline)
	print("Failed to complete version check. Falling back to local.")
	_load_and_start_game()

func _start_download() -> void:
	status_label.text = "Lade Updates herunter..."
	percentage_label.text = "0%"
	download_percent = 0.0
	target_percent = 0.0
	is_updating = true
	
	pack_download.download_file = LOCAL_PCK_FILE
	pack_download.use_threads = true
	
	var err = pack_download.request(remote_version_data.pck_url)
	if err != OK:
		print("Download request failed immediately: ", err)
		_load_and_start_game()

func _on_pack_download_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	is_updating = false
	
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		print("PCK download completed successfully!")
		_save_local_version(int(remote_version_data.get("version", 0)))
		status_label.text = "Update abgeschlossen!"
		target_percent = 100.0
		await get_tree().create_timer(0.6).timeout
		_load_and_start_game()
	else:
		print("PCK download failed. Result: ", result, " Code: ", response_code)
		status_label.text = "Ladefehler. Starte lokal..."
		if FileAccess.file_exists(LOCAL_PCK_FILE):
			DirAccess.remove_absolute(LOCAL_PCK_FILE)
		await get_tree().create_timer(1.0).timeout
		_load_and_start_game()

func _on_timeout() -> void:
	print("OTA update check timed out.")
	status_label.text = "Verbindung instabil. Starte offline..."
	version_check.cancel_request()
	pack_download.cancel_request()
	_load_and_start_game()

func _load_and_start_game() -> void:
	status_label.text = "Initialisiere Module..."
	
	# 1. Mount downloaded PCK file if exists
	if FileAccess.file_exists(LOCAL_PCK_FILE):
		var success = ProjectSettings.load_resource_pack(LOCAL_PCK_FILE)
		if success:
			print("Successfully mounted remote PCK file: ", LOCAL_PCK_FILE)
			# 2. Hot-Reload Autoloads
			_reload_autoload("GameManager", "res://scripts/GameManager.gd")
			_reload_autoload("SoundManager", "res://scripts/SoundManager.gd")
			_reload_autoload("JuiceManager", "res://scripts/JuiceManager.gd")
		else:
			print("Failed to mount remote PCK file. Deleting corrupted file.")
			DirAccess.remove_absolute(LOCAL_PCK_FILE)
	else:
		print("No remote PCK file found. Starting built-in version.")
	
	# 3. Transition to the main scene
	var err = get_tree().change_scene_to_file(MAIN_SCENE_PATH)
	if err != OK:
		status_label.text = "Startfehler!"
		print("Failed to change scene to Main.tscn: ", err)

func _reload_autoload(autoload_name: String, script_path: String) -> void:
	var root = get_tree().root
	if root.has_node(autoload_name):
		var node = root.get_node(autoload_name)
		print("Reloading Autoload: ", autoload_name)
		
		# Immediately free all children of the Autoload (like music players, overlays, etc.)
		for child in node.get_children():
			node.remove_child(child)
			child.free()
			
		# Detach old script
		node.set_script(null)
		
		# Load the new script bypassing the resource cache
		var new_script = ResourceLoader.load(script_path, "", ResourceLoader.CACHE_MODE_REPLACE)
		if new_script:
			node.set_script(new_script)
			# Re-trigger ready sequence
			node.notification(NOTIFICATION_READY)
			print("Autoload ", autoload_name, " reloaded successfully.")
		else:
			print("Failed to load script: ", script_path)
