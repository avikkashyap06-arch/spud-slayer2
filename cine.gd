class_name Cine
extends Node2D
## Cutscene player: procedural pixel scenes + typewriter captions (captions are drawn by GameUI).

var g: Node
var active := false
var scene := ""
var beats: Array = []
var bi := 0
var bt := 0.0
var total_t := 0.0
var next_cb: Callable
var bar := 0.0
var done := false

const CPS := 38.0   # caption characters per second

const AREA_FLAVOR := {
	"layer8": "The ash thickens. Something below is still screaming.",
	"layer7": "Chained choirs of the damned part before the climbing root.",
	"layer6": "Forges older than names. The heat tastes of iron.",
	"layer5": "The Infernal Citadel looms — demon dukes hold its stairs.",
	"layer4": "Torture halls of ten thousand years. Spud walks through them anyway.",
	"layer3": "The walls are the ribs of something enormous.",
	"layer2": "Almost near enough to smell the abyssal throne.",
	"layer1": "The last stair. Satan's laughter shakes the stones.",
	"sanctuary": "The marble hums with prayer. Every pillar has eyes.",
	"throne": "Light so bright it has weight. The Creator waits above.",
}

func start(id: String, cb: Callable, area_title: String = "", area_key: String = "") -> void:
	scene = id
	beats = _beats_for(id, area_title, area_key)
	bi = 0
	bt = 0.0
	total_t = 0.0
	bar = 0.0
	done = false
	active = true
	next_cb = cb
	visible = true

func _beats_for(id: String, title: String, key: String) -> Array:
	match id:
		"intro":
			return [
				{"art": "space_earth", "dur": 7.0, "text": Lore.PREMISE[0]},
				{"art": "soil_seed", "dur": 7.0, "text": Lore.PREMISE[1]},
				{"art": "war", "dur": 9.0, "text": Lore.PREMISE[2]},
				{"art": "march", "dur": 8.0, "text": Lore.PREMISE[3]},
			]
		"descent":
			return [
				{"art": "fall", "dur": 5.5, "text": "Cast out of the light, Spud falls through the nine layers of Hell."},
				{"art": "pit", "dur": 6.0, "text": "In the Ninth Pit, among ash and chains, something small refuses to die."},
			]
		"area":
			return [{"art": "area", "dur": 4.2, "title": title, "text": String(AREA_FLAVOR.get(key, "")), "key": key}]
		"elite":
			return [
				{"art": "elite", "dur": 5.0, "text": "The air goes still. Every ember in the dark holds its breath."},
				{"art": "elite2", "dur": 5.0, "text": "Something up ahead is smiling. It has been waiting for you to stop dodging."},
			]
		"satan":
			return [
				{"art": "satan", "dur": 6.0, "text": "Beyond the last layer, the Abyssal Throne burns."},
				{"art": "satan2", "dur": 6.0, "who": "SATAN", "text": Lore.SATAN_INTRO},
			]
		"ascent":
			return [
				{"art": "ascent", "dur": 7.0, "text": "The Fallen Sovereign's crown shatters. His Hellfire Wings tear free and bind to Spud's roots."},
				{"art": "ascent2", "dur": 6.0, "text": Lore.ACT2_NARRATIVE},
			]
		"god":
			return [
				{"art": "god", "dur": 6.0, "text": "At the summit, the Throne of Light waits."},
				{"art": "god2", "dur": 6.5, "who": "GOD", "text": Lore.GOD_REMATCH_INTRO},
			]
		"finale":
			return [
				{"art": "fin1", "dur": 6.0, "text": "The Throne of Light falls silent. The Creator's crown lies cracked at Spud's roots."},
				{"art": "fin2", "dur": 6.0, "text": "Behind Spud, fifty fallen guardians crumble — and from their ash, green shoots begin to rise."},
				{"art": "fin3", "dur": 8.0, "text": "Neither Heaven nor Hell can say what a potato will do next. Spud walks into the new dawn."},
			]
	return [{"art": "area", "dur": 2.0, "title": "", "text": ""}]

func cur() -> Dictionary:
	return beats[mini(bi, beats.size() - 1)] if beats.size() > 0 else {}

func chars_shown() -> int:
	return int(bt * CPS)

func tick(dt: float, accept: bool, skip: bool) -> void:
	if not active:
		return
	bt += dt
	total_t += dt
	bar = minf(1.0, bar + dt * 1.5)
	var b := cur()
	var txt_len := String(b.get("text", "")).length()
	if skip and total_t > 0.5:
		_finish()
		return
	if accept and total_t > 0.3:
		if chars_shown() < txt_len:
			bt = float(txt_len) / CPS
		else:
			_next_beat()
			return
	if bt >= float(b.get("dur", 4.0)):
		_next_beat()
	queue_redraw()

func _next_beat() -> void:
	bi += 1
	bt = 0.0
	if bi >= beats.size():
		_finish()

func _finish() -> void:
	active = false
	visible = false
	done = true
	if next_cb.is_valid():
		next_cb.call()

# ---------------------------------------------------------------- drawing helpers
func _h(i: int, s: float) -> float:
	return fposmod(sin(float(i) * 127.1 + s * 311.7) * 43758.5453, 1.0)

func _grad(c1: Color, c2: Color) -> void:
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(Cfg.W, 0), Vector2(Cfg.W, Cfg.H), Vector2(0, Cfg.H)]), PackedColorArray([c1, c1, c2, c2]))

func _stars(n: int, scroll: Vector2, tw: float) -> void:
	for i in n:
		var x := fposmod(_h(i, 1.0) * Cfg.W + scroll.x * (0.3 + _h(i, 4.0)), Cfg.W)
		var y := fposmod(_h(i, 2.0) * Cfg.H + scroll.y * (0.3 + _h(i, 4.0)), Cfg.H)
		var a := 0.35 + 0.65 * _h(i, 3.0) * (0.7 + 0.3 * sin(total_t * 2.0 + float(i)))
		draw_rect(Rect2(x, y, 3.0 if _h(i, 5.0) > 0.8 else 2.0, 3.0 if _h(i, 5.0) > 0.8 else 2.0), Color(1, 1, 1, a * tw))

func _spud(pos: Vector2, cell: float, rot: float = 0.0, flip: float = 1.0, tint: Color = Color.WHITE) -> void:
	draw_set_transform(pos, rot, Vector2(flip, 1.0))
	PixSprite.draw(self, PixSprite.SPUD, Vector2.ZERO, cell, 0.0, tint)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _embers(n: int, col: Color, speed: float, up: bool = true) -> void:
	for i in n:
		var x := _h(i, 7.0) * Cfg.W + sin(total_t * 1.2 + float(i)) * 20.0
		var y := fposmod(_h(i, 8.0) * Cfg.H + (-1.0 if up else 1.0) * total_t * speed * (0.4 + _h(i, 9.0)), Cfg.H)
		draw_rect(Rect2(x, y, 3, 3), Color(col.r, col.g, col.b, 0.3 + 0.6 * _h(i, 10.0)))

func _blob(c: Vector2, r: float, col: Color) -> void:
	draw_circle(c, r, col)

func _glow(c: Vector2, r: float, col: Color, a: float) -> void:
	Art.glow(self, c, r, col, a)

func _earth(c: Vector2, r: float, burn: float) -> void:
	_glow(c, r * 1.35, Color(0.4, 0.7, 1.0), 0.5)
	draw_circle(c, r, Color(0.12, 0.3, 0.7))
	draw_circle(c + Vector2(-r * 0.2, -r * 0.15), r * 0.55, Color(0.16, 0.42, 0.22))
	draw_circle(c + Vector2(r * 0.35, r * 0.3), r * 0.38, Color(0.2, 0.46, 0.25))
	draw_circle(c + Vector2(-r * 0.45, r * 0.4), r * 0.2, Color(0.8, 0.85, 0.9))
	for i in int(burn * 14.0):
		var a := _h(i, 11.0) * TAU
		var d := _h(i, 12.0) * r * 0.85
		var p := c + Vector2(cos(a), sin(a)) * d
		draw_circle(p, 3.5 + 2.0 * sin(total_t * 8.0 + float(i)), Color(1.0, 0.45 + 0.3 * _h(i, 13.0), 0.1, 0.9))
	draw_arc(c, r, 0, TAU, 40, Color(0.7, 0.85, 1.0, 0.7), 3.0)

func _angel(p: Vector2, s: float, flip: float) -> void:
	Art.feather_wing(self, p + Vector2(0, -6 * s), -1.0, 46.0 * s, 1.0, sin(total_t * 3.0 + p.x) * 4.0, Color(0.98, 0.93, 0.7), 0.0, 6)
	Art.feather_wing(self, p + Vector2(0, -6 * s), 1.0, 46.0 * s, 1.0, sin(total_t * 3.0 + p.x) * 4.0, Color(0.98, 0.93, 0.7), 0.0, 6)
	Art.shape(self, Art.P([p.x - 7 * s, p.y - 10 * s, p.x + 7 * s, p.y - 10 * s, p.x + 9 * s, p.y + 20 * s, p.x - 9 * s, p.y + 20 * s]), Color(1, 0.96, 0.8), 0.0, 2.0)
	draw_circle(p + Vector2(0, -16 * s), 6 * s, Color(1, 0.9, 0.75))

func _demon(p: Vector2, s: float, flip: float) -> void:
	Art.bat_wing(self, p + Vector2(0, -10 * s), -1.0, 40.0 * s, 26.0 * s, sin(total_t * 5.0 + p.y) * 6.0, Color(0.35, 0.05, 0.08))
	Art.bat_wing(self, p + Vector2(0, -10 * s), 1.0, 40.0 * s, 26.0 * s, sin(total_t * 5.0 + p.y) * 6.0, Color(0.35, 0.05, 0.08))
	Art.shape(self, Art.P([p.x - 8 * s, p.y - 12 * s, p.x + 8 * s, p.y - 12 * s, p.x + 10 * s, p.y + 18 * s, p.x - 10 * s, p.y + 18 * s]), Color(0.55, 0.08, 0.06), 0.0, 2.0)
	draw_circle(p + Vector2(0, -18 * s), 7 * s, Color(0.6, 0.1, 0.07))
	Art.horn(self, p + Vector2(-4 * s, -22 * s), -2.3, 14 * s, 3 * s, -0.5, Color(0.15, 0.05, 0.05))
	Art.horn(self, p + Vector2(4 * s, -22 * s), -0.84, 14 * s, 3 * s, 0.5, Color(0.15, 0.05, 0.05))
	Art.eye(self, p + Vector2(-3 * s, -18 * s), 1.6 * s, Color(1, 0.8, 0.1))
	Art.eye(self, p + Vector2(3 * s, -18 * s), 1.6 * s, Color(1, 0.8, 0.1))

func _clouds(scroll: float, col: Color, n: int, ymul: float = 1.0) -> void:
	for i in n:
		var x := _h(i, 21.0) * (Cfg.W + 200.0) - 100.0
		var y := fposmod(_h(i, 22.0) * Cfg.H + scroll * (0.5 + _h(i, 23.0)), Cfg.H + 120.0) - 60.0
		var w := 70.0 + _h(i, 24.0) * 90.0
		draw_circle(Vector2(x, y), w * 0.45, col)
		draw_circle(Vector2(x + w * 0.35, y + 8.0), w * 0.36, col)
		draw_circle(Vector2(x - w * 0.35, y + 10.0), w * 0.32, col)

# ---------------------------------------------------------------- scenes
func _draw() -> void:
	if not active or beats.is_empty():
		return
	var b := cur()
	var dur := float(b.get("dur", 4.0))
	var p := clampf(bt / dur, 0.0, 1.0)
	match String(b.get("art", "")):
		"space_earth": _a_space_earth(p)
		"soil_seed": _a_soil_seed(p)
		"war": _a_war(p)
		"march": _a_march(p)
		"fall": _a_fall(p)
		"pit": _a_pit(p)
		"area": _a_area(p, b)
		"satan": _a_satan(p, false)
		"satan2": _a_satan(p, true)
		"ascent": _a_ascent(p, false)
		"ascent2": _a_ascent(p, true)
		"god": _a_god(p, false)
		"god2": _a_god(p, true)
		"fin1": _a_fin(p, 1)
		"fin2": _a_fin(p, 2)
		"fin3": _a_fin(p, 3)
		"elite": _a_elite(p, false)
		"elite2": _a_elite(p, true)
	# fade in/out per beat
	var fa := clampf(1.0 - bt / 0.5, 0.0, 1.0) + clampf((bt - (dur - 0.5)) / 0.5, 0.0, 1.0)
	if fa > 0.0:
		draw_rect(Rect2(0, 0, Cfg.W, Cfg.H), Color(0, 0, 0, clampf(fa, 0.0, 1.0)))

func _a_space_earth(p: float) -> void:
	_grad(Color(0.01, 0.01, 0.06), Color(0.04, 0.02, 0.12))
	_stars(120, Vector2(-6.0, 0.0) * total_t, 1.0)
	_earth(Vector2(640, 380), 120.0 + 50.0 * p, 0.0)

func _a_soil_seed(p: float) -> void:
	_grad(Color(0.35, 0.55, 0.75), Color(0.35, 0.55, 0.75))
	var ground := 150.0
	draw_rect(Rect2(0, 0, Cfg.W, ground), Color(0.45, 0.7, 0.9))
	draw_rect(Rect2(0, ground, Cfg.W, Cfg.H - ground), Color(0.22, 0.13, 0.07))
	draw_rect(Rect2(0, ground, Cfg.W, 12), Color(0.2, 0.45, 0.18))
	for i in 7:
		var y := ground + 60.0 + i * 70.0
		draw_rect(Rect2(0, y, Cfg.W, 26), Color(0.18 + 0.02 * (i % 2), 0.1, 0.06, 0.8))
	for i in 40:
		draw_rect(Rect2(_h(i, 31.0) * Cfg.W, ground + 20.0 + _h(i, 32.0) * (Cfg.H - ground - 30.0), 6, 4), Color(0.4, 0.3, 0.22))
	# roots spreading
	for i in 9:
		var a := PI * (0.15 + 0.7 * float(i) / 8.0)
		var l := (60.0 + 110.0 * _h(i, 33.0)) * p
		var o := Vector2(640, 430)
		draw_line(o, o + Vector2(cos(a), sin(a)) * l, Color(0.7, 0.55, 0.35, 0.8), 3.0)
	_glow(Vector2(640, 420), 110.0 + 40.0 * sin(total_t * 3.0), Color(0.5, 1.0, 0.4), 0.45 * p + 0.15)
	_spud(Vector2(640, 420), 5.0)

func _a_war(p: float) -> void:
	_grad(Color(0.02, 0.0, 0.05), Color(0.1, 0.02, 0.1))
	_stars(80, Vector2(-4.0, 0.0) * total_t, 0.8)
	_glow(Vector2(0, 340), 420.0, Color(1.0, 0.2, 0.05), 0.45)
	_glow(Vector2(Cfg.W, 340), 420.0, Color(1.0, 0.9, 0.5), 0.45)
	for i in 6:
		_demon(Vector2(120.0 + 70.0 * (i % 3) + 40.0 * sin(total_t + i), 170.0 + 90.0 * (i / 2) + 18.0 * sin(total_t * 2.0 + i)), 1.6, 1.0)
	for i in 6:
		_angel(Vector2(Cfg.W - 120.0 - 70.0 * (i % 3) - 40.0 * sin(total_t + i), 170.0 + 90.0 * (i / 2) + 18.0 * sin(total_t * 2.0 + i)), 1.6, -1.0)
	for i in 10:
		var k := fposmod(total_t * 0.7 + float(i) * 0.1, 1.0)
		var y := 150.0 + 40.0 * float(i)
		draw_line(Vector2(260.0 + k * 380.0, y), Vector2(300.0 + k * 380.0, y + 4.0), Color(1, 0.35, 0.1), 5.0)
		draw_line(Vector2(Cfg.W - 260.0 - k * 380.0, y + 20.0), Vector2(Cfg.W - 300.0 - k * 380.0, y + 24.0), Color(1, 0.95, 0.6), 5.0)
	_earth(Vector2(640, 600), 70.0, clampf(p * 1.4, 0.0, 1.0))

func _a_march(p: float) -> void:
	_grad(Color(0.35, 0.12, 0.2), Color(0.95, 0.55, 0.25))
	_stars(40, Vector2.ZERO, 0.4)
	draw_circle(Vector2(900, 320), 70.0, Color(1.0, 0.85, 0.5, 0.35))
	for k in 3:
		var base := 520.0 + k * 50.0
		var pts := PackedVector2Array([Vector2(0, Cfg.H)])
		for i in 14:
			pts.append(Vector2(float(i) * 100.0, base - 60.0 * sin(float(i) * 0.9 + k * 2.0) - 40.0 * k))
		pts.append(Vector2(Cfg.W + 100.0, Cfg.H))
		draw_colored_polygon(pts, Color(0.12 - 0.03 * k, 0.04, 0.08, 1.0))
	# golden gates far on the hill
	draw_rect(Rect2(960, 300, 14, 120), Color(1, 0.9, 0.5))
	draw_rect(Rect2(1020, 300, 14, 120), Color(1, 0.9, 0.5))
	draw_rect(Rect2(954, 290, 86, 14), Color(1, 0.95, 0.65))
	_glow(Vector2(997, 360), 90.0, Color(1, 0.9, 0.5), 0.5)
	_spud(Vector2(180.0 + 560.0 * p, 590.0 - absf(sin(total_t * 9.0)) * 8.0), 4.0)
	Art.blade(self, Vector2(180.0 + 560.0 * p + 40.0, 560.0), Vector2(180.0 + 560.0 * p + 70.0, 480.0), 4.0, Color(0.5, 0.7, 0.4), Color(0.8, 1.0, 0.6))

func _a_fall(p: float) -> void:
	_grad(Color(0.9, 0.9, 1.0), Color(0.5, 0.05, 0.05))
	draw_rect(Rect2(0, 0, Cfg.W, Cfg.H), Color(0.15, 0.02, 0.02, clampf(p * 1.4, 0.0, 0.85)))
	for i in 9:
		var y := fposmod(float(i) * 90.0 - total_t * 900.0, Cfg.H + 90.0) - 40.0
		draw_rect(Rect2(0, y, Cfg.W, 18), Color(0.9, 0.3, 0.08, 0.35))
	for i in 30:
		var x := _h(i, 41.0) * Cfg.W
		var y := fposmod(_h(i, 42.0) * Cfg.H - total_t * 1400.0 * (0.5 + _h(i, 43.0)), Cfg.H)
		draw_line(Vector2(x, y), Vector2(x, y + 40.0 + 40.0 * _h(i, 44.0)), Color(1, 0.6, 0.2, 0.7), 3.0)
	_embers(40, Color(1, 0.5, 0.1), 400.0)
	_spud(Vector2(640 + 20.0 * sin(total_t * 3.0), 300), 5.0, total_t * 3.0)

func _a_pit(p: float) -> void:
	_grad(Color(0.04, 0.0, 0.02), Color(0.35, 0.06, 0.02))
	for i in 7:
		var x := 90.0 + i * 180.0
		draw_line(Vector2(x, 0), Vector2(x + 14.0 * sin(total_t + i), 150.0 + 70.0 * _h(i, 51.0)), Color(0.35, 0.35, 0.4), 4.0)
	_embers(60, Color(0.9, 0.4, 0.1), 60.0, false)
	draw_rect(Rect2(0, 560, Cfg.W, 160), Color(0.08, 0.03, 0.03))
	for i in 18:
		draw_circle(Vector2(_h(i, 52.0) * Cfg.W, 560.0 + _h(i, 53.0) * 30.0), 8.0 + 8.0 * _h(i, 54.0), Color(0.15, 0.1, 0.1))
	var rise := clampf((p - 0.35) / 0.4, 0.0, 1.0)
	_glow(Vector2(640, 520), 120.0 * rise + 30.0, Color(1.0, 0.5, 0.15), 0.4 * rise + 0.1)
	_spud(Vector2(640, 540.0 - 10.0 * rise), 5.0, lerpf(PI * 0.5, 0.0, rise))

func _a_area(p: float, b: Dictionary) -> void:
	var key: String = b.get("key", "")
	var heaven: bool = key in ["sanctuary", "throne"]
	if heaven:
		_grad(Color(0.12, 0.14, 0.3), Color(0.7, 0.6, 0.3) if key == "throne" else Color(0.35, 0.4, 0.6))
		_clouds(total_t * 20.0, Color(1, 1, 1, 0.18), 12)
		_embers(40, Color(1, 0.95, 0.6), 50.0)
	else:
		_grad(Color(0.05, 0.0, 0.03), Color(0.5, 0.1, 0.03))
		for i in 8:
			var x := 80.0 + i * 160.0
			draw_rect(Rect2(x, 0, 16, 160 + 60.0 * _h(i, 61.0)), Color(0.08, 0.04, 0.05))
		_embers(80, Color(1, 0.5, 0.1), 160.0)
	# horizontal scan line sweep
	var sw := p * Cfg.W
	draw_rect(Rect2(sw - 2, 0, 3, Cfg.H), Color(1, 1, 1, 0.08))

func _a_satan(p: float, speak: bool) -> void:
	_grad(Color(0.08, 0.0, 0.0), Color(0.55, 0.08, 0.02))
	_embers(80, Color(1, 0.4, 0.05), 200.0)
	# throne
	Art.shape(self, Art.P([420, 720, 460, 300, 520, 200, 760, 200, 820, 300, 860, 720]), Color(0.12, 0.03, 0.04), 0.0, 3.0)
	for s in [-1.0, 1.0]:
		Art.shape(self, Art.P([640 + s * 230, 720, 640 + s * 250, 330, 640 + s * 320, 160, 640 + s * 340, 330, 640 + s * 340, 720]), Color(0.1, 0.02, 0.03), 0.0, 3.0)
	_glow(Vector2(640, 300), 260.0, Color(1, 0.3, 0.05), 0.3 + 0.2 * p)
	var rise := 0.6 + 0.4 * (1.0 if speak else p)
	# silhouette & horns
	Art.shape(self, Art.P([560, 520, 580, 300, 620, 250, 660, 250, 700, 300, 720, 520]), Color(0.18, 0.04, 0.05), 0.0, 3.0)
	Art.horn(self, Vector2(590, 270), -2.4, 150.0 * rise, 18.0, -1.1, Color(0.22, 0.1, 0.08))
	Art.horn(self, Vector2(690, 270), -0.74, 150.0 * rise, 18.0, 1.1, Color(0.22, 0.1, 0.08))
	var open := clampf((p - 0.3) * 3.0, 0.0, 1.0) if not speak else 1.0
	if open > 0.0:
		Art.eye(self, Vector2(618, 310), 8.0 * open, Color(1, 0.8, 0.1))
		Art.eye(self, Vector2(662, 310), 8.0 * open, Color(1, 0.8, 0.1))
	_spud(Vector2(250.0 + (60.0 if speak else 120.0 * p), 640), 4.0)

func _a_ascent(p: float, second: bool) -> void:
	var gold := 0.5 if not second else 1.0
	_grad(Color(0.15, 0.03, 0.03).lerp(Color(0.35, 0.5, 0.85), gold * 0.6), Color(0.6, 0.12, 0.04).lerp(Color(1.0, 0.85, 0.5), gold * 0.8))
	_clouds(total_t * 220.0, Color(1, 0.9, 0.85, 0.35), 14)
	_embers(60, Color(1, 0.5, 0.1), 500.0, true)
	var sy := 460.0 - 80.0 * p
	# hellfire wings
	for s in [-1.0, 1.0]:
		var fl := sin(total_t * 12.0) * 14.0
		Art.bat_wing(self, Vector2(640 + s * 18.0, sy - 10.0), s, 150.0, 110.0, fl, Color(1.0, 0.4, 0.08))
		Art.bat_wing(self, Vector2(640 + s * 18.0, sy - 10.0), s, 100.0, 70.0, -fl, Color(1.0, 0.7, 0.2))
	_glow(Vector2(640, sy), 130.0, Color(1.0, 0.5, 0.1), 0.45)
	_spud(Vector2(640, sy), 5.0)
	if second:
		var gy := 120.0 + 80.0 * (1.0 - p)
		draw_rect(Rect2(480, gy, 24, 250), Color(1, 0.92, 0.55))
		draw_rect(Rect2(776, gy, 24, 250), Color(1, 0.92, 0.55))
		draw_rect(Rect2(470, gy - 20.0, 340, 24), Color(1, 0.96, 0.7))
		_glow(Vector2(640, gy + 100.0), 200.0, Color(1, 0.95, 0.7), 0.5)

func _a_god(p: float, speak: bool) -> void:
	_grad(Color(0.9, 0.78, 0.4), Color(1.0, 0.97, 0.85))
	for i in 18:
		var a := total_t * 0.15 + TAU * float(i) / 18.0
		draw_line(Vector2(640, 90), Vector2(640, 90) + Vector2.from_angle(a) * 1400.0, Color(1, 1, 1, 0.12), 26.0)
	_clouds(total_t * 25.0, Color(1, 1, 1, 0.3), 12)
	var gy := lerpf(-120.0, 150.0, 1.0 if speak else p)
	_glow(Vector2(640, gy), 260.0, Color(1, 1, 0.9), 0.6)
	Art.shape(self, Art.P([540, gy + 40.0, 740, gy + 40.0, 840, gy + 560.0, 440, gy + 560.0]), Color(1, 0.98, 0.9), 0.0, 3.0)
	Art.shape(self, Art.P([600, gy - 60.0, 680, gy - 60.0, 690, gy + 50.0, 640, gy + 90.0, 590, gy + 50.0]), Color(0.9, 0.78, 0.62), 0.0, 3.0)
	Art.shape(self, Art.P([596, gy, 684, gy, 670, gy + 110.0, 640, gy + 140.0, 610, gy + 110.0]), Color(1, 1, 1), 0.0, 2.0)
	Art.eye(self, Vector2(622, gy - 14.0), 6.0, Color(0.55, 0.85, 1.0))
	Art.eye(self, Vector2(658, gy - 14.0), 6.0, Color(0.55, 0.85, 1.0))
	draw_arc(Vector2(640, gy - 80.0), 52.0, 0, TAU, 36, Color(1, 0.85, 0.3), 5.0)
	draw_rect(Rect2(0, 640, Cfg.W, 80), Color(0.85, 0.7, 0.35))
	_spud(Vector2(300.0 + (40.0 if speak else 100.0 * p), 640), 4.0)

func _a_fin(p: float, n: int) -> void:
	if n == 1:
		_grad(Color(0.1, 0.1, 0.2), Color(0.8, 0.65, 0.3))
		for i in 14:
			var x := 240.0 + _h(i, 71.0) * 800.0
			var y := fposmod(_h(i, 72.0) * 600.0 + total_t * 120.0 * (0.4 + _h(i, 73.0)), 700.0)
			Art.shape(self, Art.P([x, y, x + 24, y + 8, x + 12, y + 40]), Color(1, 0.92, 0.55), 0.0, 2.0)
		Art.shape(self, Art.P([540, 640, 560, 380, 720, 380, 740, 640]), Color(0.75, 0.62, 0.3), 0.0, 3.0)
		draw_line(Vector2(560, 380), Vector2(640, 470), Art.INK, 4.0)
		_glow(Vector2(640, 420), 160.0 * (1.0 - p * 0.5), Color(1, 1, 0.8), 0.5 * (1.0 - p))
		_spud(Vector2(300, 640), 4.0)
	elif n == 2:
		_grad(Color(0.25, 0.3, 0.5), Color(0.9, 0.7, 0.4))
		for i in 80:
			var x := _h(i, 81.0) * Cfg.W
			var y := fposmod(_h(i, 82.0) * Cfg.H + total_t * 160.0 * (0.4 + _h(i, 83.0)), Cfg.H)
			draw_rect(Rect2(x, y, 4, 4), Color(0.5, 1.0, 0.45, 0.8))
		draw_rect(Rect2(0, 600, Cfg.W, 120), Color(0.2, 0.12, 0.07))
		draw_rect(Rect2(0, 596, Cfg.W, 10), Color(0.2, 0.45, 0.18))
		_spud(Vector2(640, 596), 5.0)
	else:
		_grad(Color(0.95, 0.6, 0.3), Color(1.0, 0.9, 0.6))
		draw_circle(Vector2(900, 360), 110.0, Color(1.0, 0.95, 0.7, 0.8))
		draw_rect(Rect2(0, 600, Cfg.W, 120), Color(0.22, 0.4, 0.15))
		for i in 40:
			var x := _h(i, 91.0) * Cfg.W
			draw_line(Vector2(x, 600), Vector2(x + 4.0 * sin(total_t * 2.0 + float(i)), 584.0 - 10.0 * _h(i, 92.0)), Color(0.3, 0.6, 0.2), 3.0)
		var x := 200.0 + 760.0 * p
		_spud(Vector2(x, 596.0 - absf(sin(total_t * 8.0)) * 6.0), 4.0)
		# little sprout left behind
		draw_line(Vector2(180, 600), Vector2(180, 560), Color(0.3, 0.7, 0.2), 4.0)
		draw_circle(Vector2(172, 556), 8.0, Color(0.3, 0.75, 0.25))
		draw_circle(Vector2(188, 552), 8.0, Color(0.35, 0.8, 0.3))

func _a_elite(p: float, close: bool) -> void:
	draw_rect(Rect2(0, 0, Cfg.W, Cfg.H), Color(0, 0, 0))
	_stars(30, Vector2.ZERO, 0.25)
	var cx := Vector2(640, 330)
	# a slow descending blue-white slash and a lone heart
	var e := 0.4 + 0.6 * p
	for i in 6:
		var a := total_t * 0.5 + float(i) * 1.05
		draw_line(cx + Vector2.from_angle(a) * 500.0 * (1.2 - e * 0.5), cx + Vector2.from_angle(a) * 900.0, Color(0.5, 0.7, 1.0, 0.18), 6.0)
	if close:
		# looming silhouette with wide white grin and pinprick eyes
		var s := 1.0 + 0.2 * p
		Art.shape(self, Art.P([cx.x - 150 * s, 720, cx.x - 120 * s, cx.y - 40, cx.x - 40 * s, cx.y - 130 * s, cx.x + 40 * s, cx.y - 130 * s, cx.x + 120 * s, cx.y - 40, cx.x + 150 * s, 720]), Color(0.05, 0.05, 0.08), 0.0, 3.0)
		draw_rect(Rect2(cx.x - 56 * s, cx.y - 40 * s, 112 * s, 10 * s), Color(1, 1, 1))
		for k in 8:
			draw_rect(Rect2(cx.x - 56 * s + k * 14 * s, cx.y - 44 * s, 4 * s, 18 * s), Color(0.05, 0.05, 0.08))
		draw_circle(Vector2(cx.x - 22 * s, cx.y - 78 * s), 3.0 * s, Color(1, 1, 1))
		draw_circle(Vector2(cx.x + 22 * s, cx.y - 78 * s), 3.0 * s, Color(1, 1, 1))
	var hy := 560.0 - 20.0 * sin(total_t * 2.0)
	Art.glow(self, Vector2(640, hy), 40.0, Color(1, 0.1, 0.15), 0.4)
	draw_circle(Vector2(640, hy), 7.0, Color(1, 0.12, 0.18))
