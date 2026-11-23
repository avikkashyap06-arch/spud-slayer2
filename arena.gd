class_name Arena
extends Node2D
## Procedural backgrounds, floor, platforms and the Roots of Renewal shrine.

var theme := "title"      # title, hell, abyss, heaven, storm, sanctuary, throne
var depth := 0.5          # hell: 1 = deepest/darkest
var platforms: Array = []
var shrine := false
var t := 0.0
var motes: Array = []
var deco: Array = []
var lightning := 0.0
var next_bolt := 4.0
var rng := RandomNumberGenerator.new()

func set_theme(th: String, dep: float, layout: int, show_shrine: bool = false) -> void:
	theme = th
	depth = dep
	shrine = show_shrine
	rng.seed = 1000 + layout * 17 + int(dep * 100.0) + th.hash() % 1000
	match layout % 3:
		0: platforms = [Rect2(180, 470, 240, 14), Rect2(860, 470, 240, 14)]
		1: platforms = [Rect2(480, 450, 320, 14)]
		_: platforms = [Rect2(110, 500, 170, 14), Rect2(555, 400, 170, 14), Rect2(1000, 500, 170, 14)]
	if th == "title" or show_shrine:
		platforms = []
	# static decoration lists
	deco.clear()
	for i in 22:
		deco.append({"x": rng.randf_range(0, Cfg.W), "a": rng.randf_range(20, 110), "b": rng.randf_range(40, 190), "c": rng.randf()})
	motes.clear()
	for i in 70:
		motes.append({"p": Vector2(rng.randf_range(0, Cfg.W), rng.randf_range(0, Cfg.H)), "s": rng.randf_range(0.3, 1.0), "z": rng.randf_range(1.5, 4.0)})
	queue_redraw()

func tick(dt: float) -> void:
	t += dt
	lightning = maxf(0.0, lightning - dt * 3.0)
	if theme == "storm":
		next_bolt -= dt
		if next_bolt <= 0.0:
			lightning = 1.0
			next_bolt = randf_range(3.0, 7.0)
	for m in motes:
		match theme:
			"hell", "abyss":
				m["p"].y -= (20.0 + 40.0 * m["s"]) * dt
				m["p"].x += (30.0 + 70.0 * m["s"]) * dt
			"title":
				m["p"].y -= 10.0 * m["s"] * dt
			_:
				m["p"].y += 12.0 * m["s"] * dt
				m["p"].x += 8.0 * m["s"] * dt
		if m["p"].y < -10.0: m["p"].y = Cfg.H + 10.0
		if m["p"].y > Cfg.H + 10.0: m["p"].y = -10.0
		if m["p"].x > Cfg.W + 10.0: m["p"].x = -10.0
	queue_redraw()

func _grad(top: Color, bot: Color) -> void:
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(Cfg.W, 0), Vector2(Cfg.W, Cfg.H), Vector2(0, Cfg.H)]),
		PackedColorArray([top, top, bot, bot]))

func _draw() -> void:
	match theme:
		"hell", "abyss": _draw_hell()
		"heaven", "storm": _draw_heaven()
		"sanctuary": _draw_sanctuary()
		"throne": _draw_throne()
		_: _draw_title()
	if theme in ["heaven", "storm", "sanctuary", "throne"]:
		var dk := 0.62 if theme != "throne" else 0.5
		draw_rect(Rect2(0, 0, Cfg.W, Cfg.H), Color(0.05, 0.04, 0.1, dk))
	_draw_floor()
	for pr in platforms:
		_draw_platform(pr)
	if shrine:
		_draw_shrine()
	_draw_motes()
	_draw_vignette()

# ---------------------------------------------------------------- themes
func _draw_hell() -> void:
	var bot := Color(0.34, 0.08, 0.03).lerp(Color(0.14, 0.03, 0.05), depth)
	if theme == "abyss":
		bot = Color(0.42, 0.04, 0.05)
	_grad(Color(bot.r * 0.28, bot.g * 0.28, bot.b * 0.28), bot)
	# distant cliffs
	var far := PackedVector2Array([Vector2(0, 560)])
	var x := 0.0
	while x <= Cfg.W + 60.0:
		far.append(Vector2(x, 400.0 + 90.0 * sin(x * 0.011 + depth * 5.0) + 40.0 * sin(x * 0.037)))
		x += 60.0
	far.append(Vector2(Cfg.W, 620)); far.append(Vector2(0, 620))
	draw_colored_polygon(far, Color(0.05, 0.02, 0.03, 0.85))
	# magma glow along the horizon
	draw_polygon(PackedVector2Array([Vector2(0, 470), Vector2(Cfg.W, 470), Vector2(Cfg.W, 620), Vector2(0, 620)]),
		PackedColorArray([Color(1, 0.35, 0.05, 0.0), Color(1, 0.35, 0.05, 0.0), Color(1, 0.4, 0.08, 0.32), Color(1, 0.4, 0.08, 0.32)]))
	# stalactites
	for d in deco:
		var tri := PackedVector2Array([Vector2(d["x"] - d["a"] * 0.5, 0), Vector2(d["x"] + d["a"] * 0.5, 0), Vector2(d["x"] + (d["c"] - 0.5) * 20.0, d["b"])])
		draw_colored_polygon(tri, Color(0.04, 0.02, 0.03))
	# hanging iron cages
	for i in 4:
		var d: Dictionary = deco[i]
		var cx: float = 120.0 + i * 340.0 + d["c"] * 80.0
		var sway := sin(t * 0.8 + i) * 6.0
		var top: float = 60.0 + d["c"] * 60.0
		draw_line(Vector2(cx, 0), Vector2(cx + sway, top), Color(0.15, 0.1, 0.1), 3.0)
		var rc := Rect2(cx + sway - 26, top, 52, 70)
		draw_rect(rc, Color(0.1, 0.07, 0.07, 0.8), false, 3.0)
		for k in 4:
			draw_line(Vector2(rc.position.x + 10 + k * 11, rc.position.y), Vector2(rc.position.x + 10 + k * 11, rc.end.y), Color(0.16, 0.1, 0.09), 2.0)
		draw_arc(Vector2(cx + sway, top), 26, PI, TAU, 10, Color(0.16, 0.1, 0.09), 3.0)
	# lava river
	var lava := PackedVector2Array()
	lava.append(Vector2(0, Cfg.H))
	var lx := 0.0
	while lx <= Cfg.W + 20.0:
		lava.append(Vector2(lx, 690.0 + 5.0 * sin(lx * 0.03 + t * 2.0)))
		lx += 20.0
	lava.append(Vector2(Cfg.W, Cfg.H))
	draw_colored_polygon(lava, Color(1.0, 0.45, 0.08))

func _draw_heaven() -> void:
	var is_storm := theme == "storm"
	var top: Color = Color(0.2, 0.24, 0.38) if is_storm else Color(0.45, 0.65, 0.95)
	var bot: Color = Color(0.62, 0.66, 0.78) if is_storm else Color(0.95, 0.96, 1.0)
	_grad(top, bot)
	# god-rays
	for i in 5:
		var rx := 150.0 + i * 250.0
		draw_colored_polygon(PackedVector2Array([Vector2(rx, 0), Vector2(rx + 60, 0), Vector2(rx + 220 + sin(t * 0.3 + i) * 20.0, Cfg.FLOOR), Vector2(rx + 100, Cfg.FLOOR)]),
			Color(1, 0.95, 0.7, 0.07))
	# floating golden pillars
	for i in 6:
		var d: Dictionary = deco[i]
		var px: float = 90.0 + i * 220.0 + d["c"] * 60.0
		var py: float = 120.0 + d["c"] * 180.0 + sin(t * 0.5 + i) * 12.0
		var ph: float = 150.0 + d["a"]
		draw_rect(Rect2(px, py, 38, ph), Color(0.95, 0.82, 0.42, 0.75))
		draw_rect(Rect2(px - 8, py - 10, 54, 12), Color(1.0, 0.9, 0.55, 0.85))
		draw_rect(Rect2(px - 8, py + ph, 54, 10), Color(1.0, 0.9, 0.55, 0.85))
		for k in 3:
			draw_line(Vector2(px + 9 + k * 10, py), Vector2(px + 9 + k * 10, py + ph), Color(0.8, 0.65, 0.3, 0.6), 2.0)
	# clouds
	for i in 14:
		var d: Dictionary = deco[i]
		var cx := fmod(d["x"] + t * (6.0 + d["c"] * 14.0), Cfg.W + 300.0) - 150.0
		var cy: float = 380.0 + d["c"] * 260.0
		var cc := Color(1, 1, 1, 0.55) if not is_storm else Color(0.55, 0.58, 0.7, 0.6)
		for k in 4:
			draw_circle(Vector2(cx + k * 38.0, cy + sin(k * 2.0) * 10.0), 40.0 + k % 2 * 12.0, cc)
	if lightning > 0.0:
		draw_rect(Rect2(0, 0, Cfg.W, Cfg.H), Color(1, 1, 0.9, 0.35 * lightning))

func _draw_sanctuary() -> void:
	_grad(Color(0.1, 0.08, 0.2), Color(0.42, 0.34, 0.5))
	# stained-glass windows
	var cols := [Color(0.9, 0.3, 0.3), Color(0.95, 0.8, 0.3), Color(0.3, 0.6, 0.95), Color(0.5, 0.85, 0.5), Color(0.75, 0.45, 0.9)]
	for i in 5:
		var wx := 100.0 + i * 250.0
		var wy := 90.0
		var ww := 110.0
		var wh := 300.0
		draw_rect(Rect2(wx, wy + 55, ww, wh - 55), Color(0.05, 0.04, 0.1))
		draw_circle(Vector2(wx + ww * 0.5, wy + 55), ww * 0.5, Color(0.05, 0.04, 0.1))
		var gc: Color = cols[i % cols.size()]
		draw_rect(Rect2(wx + 8, wy + 55, ww - 16, wh - 63), Color(gc.r, gc.g, gc.b, 0.55 + 0.1 * sin(t + i)))
		draw_circle(Vector2(wx + ww * 0.5, wy + 55), ww * 0.5 - 8.0, Color(gc.r, gc.g, gc.b, 0.6))
		for k in 3:
			draw_line(Vector2(wx + 8, wy + 100 + k * 70), Vector2(wx + ww - 8, wy + 100 + k * 70), Color(0.05, 0.04, 0.1), 3.0)
		draw_line(Vector2(wx + ww * 0.5, wy + 10), Vector2(wx + ww * 0.5, wy + wh), Color(0.05, 0.04, 0.1), 3.0)
		draw_colored_polygon(PackedVector2Array([Vector2(wx + 10, wy + wh), Vector2(wx + ww - 10, wy + wh), Vector2(wx + ww + 140, Cfg.FLOOR), Vector2(wx + 60, Cfg.FLOOR)]),
			Color(gc.r, gc.g, gc.b, 0.07))
	for i in 3:
		var cx := 40.0 + i * 600.0
		draw_rect(Rect2(cx, 0, 40, Cfg.FLOOR), Color(0.2, 0.17, 0.3, 0.8))

func _draw_throne() -> void:
	_grad(Color(1.0, 0.97, 0.8), Color(1.0, 0.86, 0.45))
	# radiant rays
	for i in 14:
		var a := t * 0.06 + i * TAU / 14.0
		var c := Vector2(Cfg.W * 0.5, 120.0)
		draw_colored_polygon(PackedVector2Array([c, c + Vector2.from_angle(a - 0.07) * 1300.0, c + Vector2.from_angle(a + 0.07) * 1300.0]),
			Color(1, 1, 0.9, 0.18))
	draw_circle(Vector2(Cfg.W * 0.5, 120), 150, Color(1, 1, 0.92, 0.55))
	draw_circle(Vector2(Cfg.W * 0.5, 120), 90, Color(1, 1, 1, 0.8))
	# columns
	for i in 6:
		var cx := 40.0 + i * 235.0
		draw_rect(Rect2(cx, 80, 54, Cfg.FLOOR - 80), Color(0.98, 0.93, 0.78, 0.9))
		draw_rect(Rect2(cx - 10, 70, 74, 20), Color(1, 0.88, 0.5))
		draw_rect(Rect2(cx - 10, Cfg.FLOOR - 24, 74, 24), Color(1, 0.88, 0.5))
		for k in 3:
			draw_line(Vector2(cx + 12 + k * 14, 90), Vector2(cx + 12 + k * 14, Cfg.FLOOR - 24), Color(0.85, 0.75, 0.5, 0.7), 2.0)
	# sigil on the floor
	draw_arc(Vector2(Cfg.W * 0.5, Cfg.FLOOR), 260.0, PI, TAU, 40, Color(1, 0.8, 0.3, 0.7), 3.0)

func _draw_title() -> void:
	_grad(Color(0.04, 0.03, 0.05), Color(0.2, 0.13, 0.08))
	for i in 18:
		var d: Dictionary = deco[i]
		var sx: float = d["x"]
		var pts := PackedVector2Array()
		for k in 8:
			pts.append(Vector2(sx + sin(k * 0.8 + d["c"] * 6.0) * 40.0 * d["c"], Cfg.FLOOR + k * 14.0 - k * k * 14.0 * (0.4 + d["c"])))
		draw_polyline(pts, Color(0.35, 0.22, 0.12, 0.7), 2.0 + d["c"] * 4.0)

# ---------------------------------------------------------------- ground
func _draw_floor() -> void:
	var holy := theme in ["heaven", "storm", "sanctuary", "throne"]
	if theme == "title":
		draw_rect(Rect2(0, Cfg.FLOOR, Cfg.W, Cfg.H - Cfg.FLOOR), Color(0.16, 0.1, 0.06))
		draw_rect(Rect2(0, Cfg.FLOOR, Cfg.W, 5), Color(0.3, 0.2, 0.1))
		return
	if holy:
		draw_rect(Rect2(0, Cfg.FLOOR, Cfg.W, Cfg.H - Cfg.FLOOR), Color(0.96, 0.93, 0.86))
		draw_rect(Rect2(0, Cfg.FLOOR, Cfg.W, 6), Color(1.0, 0.82, 0.35))
		for i in 11:
			draw_line(Vector2(i * 128.0, Cfg.FLOOR + 6), Vector2(i * 128.0 - 40.0, Cfg.H), Color(0.8, 0.74, 0.6, 0.6), 2.0)
	else:
		draw_rect(Rect2(0, Cfg.FLOOR, Cfg.W, Cfg.H - Cfg.FLOOR), Color(0.07, 0.05, 0.07))
		draw_rect(Rect2(0, Cfg.FLOOR, Cfg.W, 4), Color(1.0, 0.4, 0.1, 0.8))
		for i in 9:
			var d: Dictionary = deco[i]
			var x0: float = d["x"]
			draw_polyline(PackedVector2Array([Vector2(x0, Cfg.FLOOR + 4), Vector2(x0 + 18, Cfg.FLOOR + 30), Vector2(x0 - 6, Cfg.FLOOR + 52), Vector2(x0 + 20, Cfg.FLOOR + 80)]),
				Color(1.0, 0.4, 0.1, 0.5), 2.0)

func _draw_platform(pr: Rect2) -> void:
	var holy := theme in ["heaven", "storm", "sanctuary", "throne"]
	if holy:
		draw_rect(pr, Color(0.98, 0.95, 0.85))
		draw_rect(Rect2(pr.position.x, pr.position.y, pr.size.x, 4), Color(1.0, 0.82, 0.35))
		draw_rect(Rect2(pr.position.x + 8, pr.end.y, pr.size.x - 16, 8), Color(1, 1, 1, 0.5))
	else:
		draw_rect(pr, Color(0.12, 0.09, 0.1))
		draw_rect(Rect2(pr.position.x, pr.position.y, pr.size.x, 3), Color(0.55, 0.3, 0.15))
		for k in 5:
			draw_circle(Vector2(pr.position.x + 18 + k * (pr.size.x - 36) / 4.0, pr.position.y + 8), 2.0, Color(0.5, 0.25, 0.12))

func _draw_shrine() -> void:
	var cx := Cfg.W * 0.5
	var pts := PackedVector2Array()
	for i in 21:
		var a := PI + PI * float(i) / 20.0
		pts.append(Vector2(cx + cos(a) * 150.0, Cfg.FLOOR + sin(a) * 34.0))
	draw_colored_polygon(pts, Color(0.22, 0.14, 0.08))
	var glow := 0.5 + 0.5 * sin(t * 2.0)
	draw_circle(Vector2(cx, Cfg.FLOOR - 8), 120.0, Color(0.5, 0.9, 0.3, 0.06 + 0.05 * glow))
	for k in 7:
		var sx := cx - 100.0 + k * 33.0
		var sh := 16.0 + 10.0 * sin(t * 1.6 + k)
		draw_line(Vector2(sx, Cfg.FLOOR - 4), Vector2(sx + sin(k) * 6.0, Cfg.FLOOR - 4 - sh), Color(0.45, 0.85, 0.3), 3.0)
		draw_circle(Vector2(sx + sin(k) * 6.0, Cfg.FLOOR - 4 - sh), 4.0, Color(0.7, 1.0, 0.45))

func _draw_motes() -> void:
	for m in motes:
		var c := Color(1, 1, 1, 0.3)
		match theme:
			"hell", "abyss":
				c = Color(1.0, 0.5, 0.15, 0.7) if m["s"] > 0.55 else Color(0.5, 0.45, 0.45, 0.4)
			"title":
				c = Color(0.7, 0.9, 0.4, 0.35)
			"throne":
				c = Color(1, 0.9, 0.5, 0.6)
			"sanctuary":
				c = Color(1, 0.9, 0.7, 0.35)
			_:
				c = Color(1, 0.97, 0.8, 0.5)
		draw_circle(m["p"], m["z"] * 0.7, c)

func _draw_vignette() -> void:
	var edge := Color(0, 0, 0, 0.6)
	var clear := Color(0, 0, 0, 0.0)
	var w := float(Cfg.W)
	var h := float(Cfg.H)
	var m := 220.0
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(m, 0), Vector2(m, h), Vector2(0, h)]), PackedColorArray([edge, clear, clear, edge]))
	draw_polygon(PackedVector2Array([Vector2(w - m, 0), Vector2(w, 0), Vector2(w, h), Vector2(w - m, h)]), PackedColorArray([clear, edge, edge, clear]))
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, 140), Vector2(0, 140)]), PackedColorArray([edge, edge, clear, clear]))
