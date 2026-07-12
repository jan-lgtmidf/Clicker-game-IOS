extends Node

# Dynamically synthesized sound streams
var click_stream: AudioStreamWAV
var crit_stream: AudioStreamWAV
var upgrade_stream: AudioStreamWAV
var prestige_stream: AudioStreamWAV

# Warning & spell sounds
var alarm_stream: AudioStreamWAV
var perfect_stream: AudioStreamWAV
var meltdown_stream: AudioStreamWAV
var spell_stream: AudioStreamWAV

# Looping ambient music synth streams
var music_normal_stream: AudioStreamWAV
var music_overdrive_stream: AudioStreamWAV
var music_meltdown_stream: AudioStreamWAV

# Mix rate for synthesis
const MIX_RATE = 22050

# Ambient music players
var music_player_1: AudioStreamPlayer
var music_player_2: AudioStreamPlayer
var active_player: AudioStreamPlayer
var current_music_state: String = ""

func _ready() -> void:
	# Generate sound streams in memory on startup
	click_stream = _generate_click_sound(false)
	crit_stream = _generate_click_sound(true)
	upgrade_stream = _generate_upgrade_sound()
	prestige_stream = _generate_prestige_sound()
	
	alarm_stream = _generate_alarm_sound()
	perfect_stream = _generate_perfect_sound()
	meltdown_stream = _generate_meltdown_sound()
	spell_stream = _generate_spell_sound()
	
	# Synthesize 4-second mathematically perfect looping chord pads
	music_normal_stream = _generate_chord_loop([220.0, 261.75, 329.75, 440.0]) # A3 minor chord (A, C, E, A)
	music_overdrive_stream = _generate_chord_loop([220.0, 277.25, 329.75, 415.25]) # A3 Major 7 chord (A, C#, E, G#)
	music_meltdown_stream = _generate_chord_loop([110.0, 155.50, 220.0, 311.00]) # Low dissonant A2/D# tritone rumble
	
	_setup_music_players()

func _setup_music_players() -> void:
	music_player_1 = AudioStreamPlayer.new()
	music_player_2 = AudioStreamPlayer.new()
	add_child(music_player_1)
	add_child(music_player_2)
	
	# Start playing normal chord
	music_player_1.stream = music_normal_stream
	music_player_1.volume_db = -16.0
	music_player_1.play()
	
	active_player = music_player_1
	current_music_state = "normal"

func transition_music_to(state: String) -> void:
	if current_music_state == state:
		return
	current_music_state = state
	
	var target_stream: AudioStreamWAV
	match state:
		"normal":
			target_stream = music_normal_stream
		"overdrive":
			target_stream = music_overdrive_stream
		"meltdown":
			target_stream = music_meltdown_stream
			
	var inactive_player = music_player_2 if active_player == music_player_1 else music_player_1
	inactive_player.stream = target_stream
	inactive_player.volume_db = -80.0
	inactive_player.play()
	
	# Cross-fade tween
	var tween = create_tween().set_parallel(true)
	tween.tween_property(active_player, "volume_db", -80.0, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	var target_vol = -10.0 if state == "meltdown" else -16.0
	tween.tween_property(inactive_player, "volume_db", target_vol, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	active_player = inactive_player

# Play a stream using a temporary AudioStreamPlayer with custom pitch (combo support)
func play_sound(stream: AudioStreamWAV, pitch_randomness: float = 0.0, volume_db: float = 0.0, custom_pitch: float = 1.0) -> void:
	if not stream:
		return
	var player = AudioStreamPlayer.new()
	add_child(player)
	player.stream = stream
	player.volume_db = volume_db
	
	var pitch = custom_pitch
	if pitch_randomness > 0.0:
		pitch *= randf_range(1.0 - pitch_randomness, 1.0 + pitch_randomness)
		
	player.pitch_scale = clamp(pitch, 0.1, 4.0)
	player.finished.connect(player.queue_free)
	player.play()

# ----------------- SOUND SYNTHESIS -----------------

# Click Sound (sine slide downward)
func _generate_click_sound(is_crit: bool) -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	
	var duration = 0.12 if is_crit else 0.07
	var num_samples = int(MIX_RATE * duration)
	var bytes = PackedByteArray()
	bytes.resize(num_samples * 2)
	
	var start_freq = 900.0 if is_crit else 600.0
	var end_freq = 200.0 if is_crit else 150.0
	
	var phase = 0.0
	for i in range(num_samples):
		var t = float(i) / num_samples
		var freq = lerp(start_freq, end_freq, t * t)
		phase += (freq * TAU) / MIX_RATE
		
		var sample = sin(phase)
		var envelope = 1.0 - t
		if is_crit:
			sample = 1.0 if sample > 0 else -1.0
			sample *= 1.2
			sample = clamp(sample, -1.0, 1.0)
			
		var val = int(sample * envelope * 28000.0)
		bytes.encode_s16(i * 2, val)
		
	wav.data = bytes
	return wav

# Upgrade Chime (arpeggio)
func _generate_upgrade_sound() -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	
	var notes = [523.25, 659.25, 783.99, 1046.50] # C5, E5, G5, C6
	var note_duration = 0.06
	var total_duration = note_duration * notes.size()
	var num_samples = int(MIX_RATE * total_duration)
	
	var bytes = PackedByteArray()
	bytes.resize(num_samples * 2)
	
	var phase = 0.0
	for i in range(num_samples):
		var t = float(i) / num_samples
		var note_idx = int(t * notes.size())
		note_idx = clamp(note_idx, 0, notes.size() - 1)
		
		var freq = notes[note_idx]
		phase += (freq * TAU) / MIX_RATE
		
		var sample = (abs(fmod(phase, TAU) - PI) / PI) * 2.0 - 1.0
		var sub_t = fmod(float(i), MIX_RATE * note_duration) / (MIX_RATE * note_duration)
		var envelope = 1.0 - sub_t
		
		var val = int(sample * envelope * 24000.0)
		bytes.encode_s16(i * 2, val)
		
	wav.data = bytes
	return wav

# Prestige Sweep (white noise + low sweep)
func _generate_prestige_sound() -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	
	var duration = 1.5
	var num_samples = int(MIX_RATE * duration)
	var bytes = PackedByteArray()
	bytes.resize(num_samples * 2)
	
	var rng = RandomNumberGenerator.new()
	rng.seed = 99
	
	var phase = 0.0
	for i in range(num_samples):
		var t = float(i) / num_samples
		var noise = rng.randf_range(-1.0, 1.0)
		var sweep_freq = lerp(300.0, 40.0, t)
		phase += (sweep_freq * TAU) / MIX_RATE
		var bass_sweep = sin(phase)
		
		var noise_mult = lerp(0.6, 0.0, t * 1.5)
		var bass_mult = lerp(0.4, 0.8, t) * (1.0 - t)
		
		var sample = (noise * noise_mult) + (bass_sweep * bass_mult)
		sample = clamp(sample, -1.0, 1.0)
		var envelope = exp(-t * 3.5)
		
		var val = int(sample * envelope * 28000.0)
		bytes.encode_s16(i * 2, val)
		
	wav.data = bytes
	return wav

# Warning alarm (siren)
func _generate_alarm_sound() -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	
	var duration = 0.6
	var num_samples = int(MIX_RATE * duration)
	var bytes = PackedByteArray()
	bytes.resize(num_samples * 2)
	
	var phase = 0.0
	for i in range(num_samples):
		var t = float(i) / num_samples
		var freq = 350.0 + sin(t * TAU * 1.5) * 80.0
		phase += (freq * TAU) / MIX_RATE
		
		var sample = 1.0 if sin(phase) > 0.0 else -1.0
		var envelope = sin(t * PI)
		
		var val = int(sample * envelope * 12000.0)
		bytes.encode_s16(i * 2, val)
		
	wav.data = bytes
	return wav

# Perfect Containment (sparkling chime)
func _generate_perfect_sound() -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	
	var duration = 0.4
	var num_samples = int(MIX_RATE * duration)
	var bytes = PackedByteArray()
	bytes.resize(num_samples * 2)
	
	var phase1 = 0.0
	var phase2 = 0.0
	for i in range(num_samples):
		var t = float(i) / num_samples
		phase1 += (1200.0 * TAU) / MIX_RATE
		phase2 += (1800.0 * TAU) / MIX_RATE
		
		var sample = (sin(phase1) + sin(phase2)) * 0.5
		var envelope = exp(-t * 5.0)
		
		var val = int(sample * envelope * 24000.0)
		bytes.encode_s16(i * 2, val)
		
	wav.data = bytes
	return wav

# Meltdown (low distorted rumble)
func _generate_meltdown_sound() -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	
	var duration = 1.2
	var num_samples = int(MIX_RATE * duration)
	var bytes = PackedByteArray()
	bytes.resize(num_samples * 2)
	
	var rng = RandomNumberGenerator.new()
	rng.seed = 444
	
	var phase = 0.0
	for i in range(num_samples):
		var t = float(i) / num_samples
		phase += (65.0 * TAU) / MIX_RATE
		var bass = sin(phase)
		
		var noise = rng.randf_range(-1.0, 1.0)
		var sample = (bass * 0.75) + (noise * 0.25)
		
		sample = clamp(sample * 1.5, -1.0, 1.0)
		var envelope = 1.0 - t
		
		var val = int(sample * envelope * 28000.0)
		bytes.encode_s16(i * 2, val)
		
	wav.data = bytes
	return wav

# Spell (laser charge)
func _generate_spell_sound() -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	
	var duration = 0.5
	var num_samples = int(MIX_RATE * duration)
	var bytes = PackedByteArray()
	bytes.resize(num_samples * 2)
	
	var phase = 0.0
	for i in range(num_samples):
		var t = float(i) / num_samples
		var freq = lerp(200.0, 1200.0, t * t)
		phase += (freq * TAU) / MIX_RATE
		
		var sample = (abs(fmod(phase, TAU) - PI) / PI) * 2.0 - 1.0
		sample = lerp(sample, sin(phase), 0.5)
		
		var envelope = 1.0 - t
		if t < 0.15:
			envelope = t / 0.15
			
		var val = int(sample * envelope * 22000.0)
		bytes.encode_s16(i * 2, val)
		
	wav.data = bytes
	return wav

# Synthesize a mathematically perfect looping chord WAV stream
func _generate_chord_loop(freqs: Array) -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	
	var duration = 4.0
	var num_samples = int(MIX_RATE * duration)
	var bytes = PackedByteArray()
	bytes.resize(num_samples * 2)
	
	for i in range(num_samples):
		var sample = 0.0
		for freq in freqs:
			# Strict integer cycle math ensures phase align at loop boundaries
			sample += sin((float(i) * freq * TAU) / MIX_RATE)
		sample /= float(freqs.size())
		
		# Soft pad volume scaling
		var val = int(sample * 14000.0)
		bytes.encode_s16(i * 2, val)
		
	wav.data = bytes
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = num_samples
	return wav
