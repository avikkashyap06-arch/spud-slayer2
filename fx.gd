class_name Fx
extends Node2D
## Lightweight particle / ring / floating-text effects.

var parts: Array = []
var rings: Array = []
var texts: Array = []

func burst(pos: Vector2, n: int, col: Color, speed: float = 220.0, size: float = 4.0, life: float = 0.6, grav: float = 500.0) -> void:
	if parts.size() > 700:
		return
	for i in n:
		var a := randf() * TAU
		var s := randf_range(0.25, 1.0) * speed
		parts.append({"p": pos, "v": Vector2.from_angle(a) * s, "l": life * randf_range(0.6, 1.0), "m": life,
			"c": col, "s": size * randf_range(0.6, 1.3), "g": grav})

func dust(pos: Vector2, n: int = 6) -> void:
	for i in n:
		parts.append({"p": pos + Vector2(randf_range(-10, 10), 0), "v": Vector2(randf_range(-90, 90), randf_range(-60, -10)),
			"l": 0.4, "m": 0.4, "c": Color(0.62, 0.5, 0.36, 0.8), "s": randf_range(3, 6), "g": 60.0})

func ring(pos: Vector2, r1: float, col: Color, life: float = 0.5, r0: float = 4.0) -> void:
	rings.append({"p": pos, "r0": r0, "r1": r1, "l": life, "m": life, "c": col})

func popup(pos: Vector2, text: String, col: Color) -> void:
	if texts.size() > 40:
		texts.pop_front()
	texts.append({"p": pos, "t": text, "l": 0.7, "m": 0.7, "c": col})

func clear() -> void:
	parts.clear(); rings.clear(); texts.clear()

func tick(dt: float) -> void:
	for p in parts:
		p["l"] -= dt
		p["v"].y += p["g"] * dt
		p["p"] += p["v"] * dt
	parts = parts.filter(func(p): return p["l"] > 0.0)
	for r in rings:
		r["l"] -= dt
	rings = rings.filter(func(r): return r["l"] > 0.0)
	for tx in texts:
		tx["l"] -= dt
		tx["p"].y -= 55.0 * dt
	texts = texts.filter(func(x): return x["l"] > 0.0)
	queue_redraw()

func _draw() -> void:
	for p in parts:
		var k: float = clampf(p["l"] / p["m"], 0.0, 1.0)
		var c: Color = p["c"]
		draw_circle(p["p"], p["s"] * (0.4 + 0.6 * k), Color(c.r, c.g, c.b, c.a * k))
	for r in rings:
		var k: float = 1.0 - r["l"] / r["m"]
		var c: Color = r["c"]
		draw_arc(r["p"], lerpf(r["r0"], r["r1"], k), 0.0, TAU, 40, Color(c.r, c.g, c.b, c.a * (1.0 - k)), 4.0)
	var font := ThemeDB.fallback_font
	for tx in texts:
		var k: float = clampf(tx["l"] / tx["m"], 0.0, 1.0)
		var c: Color = tx["c"]
		draw_string_outline(font, tx["p"], tx["t"], HORIZONTAL_ALIGNMENT_CENTER, 120.0, 22, 5, Color(0, 0, 0, k))
		draw_string(font, tx["p"], tx["t"], HORIZONTAL_ALIGNMENT_CENTER, 120.0, 22, Color(c.r, c.g, c.b, k))
