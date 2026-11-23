class_name Sfx
extends Node
## Procedurally generated sound effects (no audio assets needed).

var sounds: Dictionary = {}
var players: Array = []
var idx := 0
var enabled := true

func _ready() -> void:
	for i in 12:
		var p := AudioStreamPlayer.new()
		add_child(p)
		players.append(p)
	sounds["slash"] = _make(1200.0, 400.0, 0.10, 0.55, 0.35)
	sounds["hit"] = _make(320.0, 80.0, 0.12, 0.6, 0.5)
	sounds["hurt"] = _make(520.0, 90.0, 0.30, 0.4, 0.6)
	sounds["roll"] = _make(200.0, 520.0, 0.15, 0.7, 0.22)
	sounds["jump"] = _make(300.0, 720.0, 0.12, 0.0, 0.3)
	sounds["rune"] = _make(500.0, 1250.0, 0.25, 0.1, 0.35)
	sounds["boom"] = _make(130.0, 30.0, 0.50, 0.7, 0.7)
	sounds["pickup"] = _make(700.0, 1500.0, 0.20, 0.0, 0.3)
	sounds["shoot"] = _make(700.0, 260.0, 0.16, 0.3, 0.3)
	sounds["beam"] = _make(80.0, 420.0, 1.40, 0.35, 0.5)
	sounds["select"] = _make(620.0, 640.0, 0.06, 0.0, 0.3)
	sounds["die"] = _make(420.0, 40.0, 0.90, 0.4, 0.6)
	sounds["roar"] = _make(95.0, 55.0, 0.90, 0.5, 0.7)
	sounds["spear"] = _make(800.0, 200.0, 0.20, 0.3, 0.3)
	sounds["stone"] = _make(240.0, 120.0, 0.18, 0.7, 0.5)

func _make(f0: float, f1: float, dur: float, noise: float, vol: float) -> AudioStreamWAV:
	var rate := 22050
	var n := int(rate * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	var phase := 0.0
	for i in n:
		var k := float(i) / float(n)
		phase += TAU * lerpf(f0, f1, k) / float(rate)
		var env := (1.0 - k) * (1.0 - k)
		var s := sin(phase) * (1.0 - noise) + (randf() * 2.0 - 1.0) * noise
		data.encode_s16(i * 2, int(clampf(s * env * vol, -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = data
	return w

func play(name: String, vol_db: float = 0.0, pitch: float = 1.0) -> void:
	if not enabled or not sounds.has(name) or players.is_empty():
		return
	var p: AudioStreamPlayer = players[idx]
	idx = (idx + 1) % players.size()
	p.stream = sounds[name]
	p.volume_db = vol_db
	p.pitch_scale = pitch * randf_range(0.94, 1.06)
	p.play()
