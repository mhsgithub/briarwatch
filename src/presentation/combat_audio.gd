extends Node
## Original synthesized cues, generated once per actor; no third-party assets.
var swing: AudioStreamWAV
var impact: AudioStreamWAV
var death: AudioStreamWAV

func _ready() -> void:
	swing = _tone(240, 0.14, 0.3, 11)
	impact = _tone(85, 0.12, 0.8, 23)
	death = _tone(64, 0.38, 0.25, 41)
	var actor := get_parent()
	actor.get_node("Attack").resolved.connect(func(): play(swing, -22))
	actor.get_node("Health").damaged.connect(func(_amount: float): play(impact, -17))
	actor.get_node("Health").died.connect(func(): play(death, -18))

func play(stream: AudioStreamWAV, volume: float) -> void:
	var voice := AudioStreamPlayer3D.new()
	get_parent().add_child(voice)
	voice.stream = stream
	voice.volume_db = volume
	voice.max_distance = 25
	voice.unit_size = 12
	voice.finished.connect(voice.queue_free)
	voice.play()

func _exit_tree() -> void:
	# Explicitly release active playback when encounters unload during a sound.
	for child in get_parent().get_children():
		if child is AudioStreamPlayer3D:
			child.stop()

func _tone(frequency: float, duration: float, noise_mix: float, seed_value: int) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var samples := int(22050 * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for i in range(samples):
		var t := float(i) / 22050
		var envelope := pow(1.0 - float(i) / samples, 2)
		var sample := lerpf(sin(TAU * frequency * t * (1 - t)), rng.randf_range(-1, 1), noise_mix) * envelope * 18000
		data.encode_s16(i * 2, int(sample))
	stream.data = data
	return stream
