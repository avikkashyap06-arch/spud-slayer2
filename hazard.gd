class_name Hazard
extends Node2D
## One class for every projectile / zone in the game, hostile or friendly.
## kinds: bolt, wave, pillar, spike

var game
var kind := "bolt"
var vel := Vector2.ZERO
var r := 12.0
var w := 60.0
var h := 40.0
var dmg := 1
var life := 6.0
var t := 0.0
var tele := 0.8
var active_t := 0.35
var col := Color(1.0, 0.5, 0.1)
var friendly := false
var hit_done := false
var breakable := false
var turn := 0.0
var grav := 0.0
var warn := false
var style := "fire"
var dead := false
var started := false
var zig: PackedVector2Array = PackedVector2Array()

# ---------------------------------------------------------------- factories
static func bolt(g, p: Vector2, v: Vector2, radius: float, damage: int, color: Color, opts: Dictionary = {}) -> Hazard:
	var hz := Hazard.new()
	hz.game = g
	hz.kind = "bolt"
	hz.position = p
	hz.vel = v
	hz.r = radius
	hz.dmg = damage
	hz.col = color
	hz.life = opts.get("life", 7.0)
	hz.turn = opts.get("turn", 0.0)
	hz.grav = opts.get("grav", 0.0)
	hz.breakable = opts.get("breakable", false)
	hz.friendly = opts.get("friendly", false)
	hz.warn = opts.get("warn", false)
	g.add_hazard(hz)
	return hz

static func wave(g, x: float, speed: float, height: float, damage: int, color: Color, width: float = 64.0) -> Hazard:
	var hz := Hazard.new()
	hz.game = g
	hz.kind = "wave"
	hz.position = Vector2(x, Cfg.FLOOR)
	hz.vel = Vector2(speed, 0)
	hz.h = height
	hz.w = width
	hz.dmg = damage
	hz.col = color
	g.add_hazard(hz)
	return hz

static func pillar(g, x: float, width: float, tele_t: float, active: float, damage: int, color: Color, sty: String = "fire") -> Hazard:
	var hz := Hazard.new()
	hz.game = g
	hz.kind = "pillar"
	hz.position = Vector2(x, 0)
	hz.w = width
	hz.tele = tele_t
	hz.active_t = active
	hz.dmg = damage
	hz.col = color
	hz.style = sty
	g.add_hazard(hz)
	return hz

static func smite(g, x: float, damage: int) -> Hazard:
	var hz := pillar(g, x, 96.0, 0.22, 0.30, damage, Color(1.0, 0.9, 0.4), "smite")
	hz.friendly = true
	var y := 0.0
	var pts := PackedVector2Array()
	while y < Cfg.FLOOR:
		pts.append(Vector2(randf_range(-26.0, 26.0) if y > 0.0 else 0.0, y))
		y += 46.0
	pts.append(Vector2(0, Cfg.FLOOR))
	hz.zig = pts
	return hz

static func spike(g, x: float, delay_t: float, damage: int) -> Hazard:
	var hz := Hazard.new()
	hz.game = g
	hz.kind = "spike"
	hz.position = Vector2(x, Cfg.FLOOR)
	hz.w = 74.0
	hz.h = 300.0
	hz.tele = delay_t
	hz.active_t = 0.35
	hz.dmg = damage
	hz.friendly = true
	hz.col = Color(0.5, 0.75, 0.3)
	g.add_hazard(hz)
	return hz

static func circ_rect(c: Vector2, rad: float, rc: Rect2) -> bool:
	var cx := clampf(c.x, rc.position.x, rc.end.x)
	var cy := clampf(c.y, rc.position.y, rc.end.y)
	return c.distance_squared_to(Vector2(cx, cy)) <= rad * rad

# ---------------------------------------------------------------- update
func update(dt: float) -> void:
	t += dt
	match kind:
		"bolt": _upd_bolt(dt)
		"wave": _upd_wave(dt)
		"pillar": _upd_pillar(dt)
		"spike": _upd_spike(dt)
	queue_redraw()

func _hit_player(rect_hit: bool) -> bool:
	if not rect_hit:
		return false
	return game.player.take_hit(dmg, position.x)

func _upd_bolt(dt: float) -> void:
	life -= dt
	if turn > 0.0 and not friendly:
		var want: Vector2 = game.player.center() - position
		var spd := vel.length()
		var ang := vel.angle()
		ang += clampf(angle_difference(ang, want.angle()), -turn * dt, turn * dt)
		vel = Vector2.from_angle(ang) * spd
	vel.y += grav * dt
	position += vel * dt
	if life <= 0.0 or position.x < -100.0 or position.x > Cfg.W + 100.0 or position.y < -300.0 or position.y > Cfg.FLOOR:
		if position.y >= Cfg.FLOOR:
			game.fx.burst(Vector2(position.x, Cfg.FLOOR), 8, col, 150.0, 4.0, 0.4)
		dead = true
		return
	if friendly:
		var b = game.boss
		if b != null and b.can_be_hit() and circ_rect(position, r, b.hurt_rect()):
			b.take_damage(dmg)
			game.fx.burst(position, 26, col, 300.0, 5.0, 0.6)
			game.fx.ring(position, 90.0, col, 0.4)
			game.sfx.play("boom", -6.0)
			game.shake_add(5.0)
			dead = true
		elif game.damage_minions_circle(position, r + 6.0, float(dmg)):
			game.fx.burst(position, 16, col, 240.0, 5.0, 0.5)
			game.fx.ring(position, 60.0, col, 0.3)
			dead = true
	else:
		if _hit_player(circ_rect(position, r, game.player.hurt_rect())):
			game.fx.burst(position, 10, col, 200.0, 4.0, 0.4)
			dead = true

func _wave_rect() -> Rect2:
	return Rect2(position.x - w * 0.5, Cfg.FLOOR - h, w, h)

func _upd_wave(dt: float) -> void:
	position.x += vel.x * dt
	if int(t * 30.0) % 2 == 0:
		game.fx.burst(Vector2(position.x, Cfg.FLOOR - randf_range(0, h)), 1, col, 40.0, 4.0, 0.35, -80.0)
	if position.x < -120.0 or position.x > Cfg.W + 120.0:
		dead = true
		return
	_hit_player(_wave_rect().intersects(game.player.hurt_rect()))

func _pillar_rect() -> Rect2:
	return Rect2(position.x - w * 0.5, 0.0, w, Cfg.FLOOR)

func _upd_pillar(_dt: float) -> void:
	if t >= tele and not started:
		started = true
		if style == "smite":
			game.sfx.play("rune", -2.0, 1.4)
		else:
			game.sfx.play("spear", -8.0)
		game.shake_add(3.0)
		game.fx.burst(Vector2(position.x, Cfg.FLOOR), 14, col, 260.0, 5.0, 0.5)
	if t > tele + active_t:
		dead = true
		return
	if t >= tele:
		if friendly:
			game.damage_minions_rect(_pillar_rect(), float(dmg), get_instance_id())
			var b = game.boss
			if not hit_done and b != null and b.can_be_hit() and _pillar_rect().intersects(b.hurt_rect()):
				hit_done = true
				b.take_damage(dmg)
				game.fx.burst(b.position, 30, col, 320.0, 5.0, 0.6)
				game.shake_add(7.0)
		else:
			_hit_player(_pillar_rect().intersects(game.player.hurt_rect()))

func _spike_rect() -> Rect2:
	var k := clampf((t - tele) / 0.12, 0.0, 1.0)
	return Rect2(position.x - w * 0.5, Cfg.FLOOR - h * k, w, h * k)

func _upd_spike(_dt: float) -> void:
	if t >= tele and not started:
		started = true
		game.sfx.play("stone", -4.0, 0.8)
		game.fx.burst(Vector2(position.x, Cfg.FLOOR), 14, Color(0.45, 0.35, 0.2), 220.0, 5.0, 0.5)
	if t > tele + active_t:
		dead = true
		return
	if t >= tele:
		game.damage_minions_rect(_spike_rect(), float(dmg), get_instance_id())
	if t >= tele and not hit_done:
		var b = game.boss
		if b != null and b.can_be_hit() and _spike_rect().intersects(b.hurt_rect()):
			hit_done = true
			b.take_damage(dmg)
			game.fx.burst(b.position, 18, Color(0.5, 0.8, 0.3), 260.0, 5.0, 0.5)
			game.shake_add(5.0)

# ---------------------------------------------------------------- draw
func _draw() -> void:
	match kind:
		"bolt": _draw_bolt()
		"wave": _draw_wave()
		"pillar": _draw_pillar()
		"spike": _draw_spike()

func _draw_bolt() -> void:
	if warn and vel.y > 0.0:
		draw_line(Vector2.ZERO, Vector2(0, Cfg.FLOOR - position.y), Color(col.r, col.g, col.b, 0.14), 3.0)
	var back := -vel.normalized() * r * 2.8
	draw_line(Vector2.ZERO, back, Color(col.r, col.g, col.b, 0.45), r * 0.9)
	draw_circle(Vector2.ZERO, r * 1.7, Color(col.r, col.g, col.b, 0.22))
	draw_circle(Vector2.ZERO, r, col)
	draw_circle(Vector2.ZERO, r * 0.55, Color(1.0, 1.0, 0.85, 0.95))
	if breakable:
		draw_arc(Vector2.ZERO, r * 1.35, 0.0, TAU, 20, Color(1, 1, 1, 0.7), 2.0)

func _draw_wave() -> void:
	var pts := PackedVector2Array()
	pts.append(Vector2(-w * 0.5, 0))
	var n := 6
	for i in n + 1:
		var fx := -w * 0.5 + w * float(i) / float(n)
		var fh := h * (0.55 + 0.45 * absf(sin(t * 12.0 + i * 1.7)))
		pts.append(Vector2(fx, -fh))
	pts.append(Vector2(w * 0.5, 0))
	draw_colored_polygon(pts, Color(col.r, col.g, col.b, 0.9))
	var inner := PackedVector2Array()
	inner.append(Vector2(-w * 0.3, 0))
	inner.append(Vector2(-w * 0.15, -h * 0.55))
	inner.append(Vector2(0, -h * 0.4))
	inner.append(Vector2(w * 0.15, -h * 0.6))
	inner.append(Vector2(w * 0.3, 0))
	draw_colored_polygon(inner, Color(1.0, 0.95, 0.7, 0.9))

func _draw_pillar() -> void:
	var x0 := -w * 0.5
	if t < tele:
		var k := t / tele
		var pulse := 0.5 + 0.5 * sin(t * 26.0)
		draw_rect(Rect2(x0, 0, w, Cfg.FLOOR), Color(col.r, col.g, col.b, 0.05 + 0.08 * pulse * k))
		draw_line(Vector2(x0, 0), Vector2(x0, Cfg.FLOOR), Color(col.r, col.g, col.b, 0.25 + 0.4 * k), 2.0)
		draw_line(Vector2(-x0, 0), Vector2(-x0, Cfg.FLOOR), Color(col.r, col.g, col.b, 0.25 + 0.4 * k), 2.0)
		draw_rect(Rect2(x0, Cfg.FLOOR - 10.0, w * k + 0.01, 10), Color(col.r, col.g, col.b, 0.5 + 0.4 * pulse))
		if style == "smite":
			draw_line(Vector2.ZERO, Vector2(0, Cfg.FLOOR), Color(1, 1, 0.8, 0.5), 2.0)
		return
	var k2 := clampf(1.0 - (t - tele) / active_t, 0.0, 1.0)
	if style == "smite":
		var pts := zig
		if pts.size() < 2:
			return
		draw_polyline(pts, Color(col.r, col.g, col.b, 0.35 * k2 + 0.1), 46.0 * k2 + 6.0)
		draw_polyline(pts, Color(1.0, 0.97, 0.75, k2), 14.0 * k2 + 2.0)
		draw_polyline(pts, Color(1, 1, 1, k2), 5.0)
		return
	if style == "spear":
		draw_rect(Rect2(x0, 0, w, Cfg.FLOOR), Color(1.0, 0.92, 0.5, 0.35 * k2))
		draw_rect(Rect2(-w * 0.2, 0, w * 0.4, Cfg.FLOOR), Color(1, 1, 0.9, k2))
		var tip := PackedVector2Array([Vector2(-w * 0.5, Cfg.FLOOR - 40), Vector2(w * 0.5, Cfg.FLOOR - 40), Vector2(0, Cfg.FLOOR + 4)])
		draw_colored_polygon(tip, Color(1, 0.95, 0.7, k2))
		return
	draw_rect(Rect2(x0, 0, w, Cfg.FLOOR), Color(col.r, col.g, col.b, 0.55 * k2 + 0.15))
	draw_rect(Rect2(-w * 0.28, 0, w * 0.56, Cfg.FLOOR), Color(1.0, 0.97, 0.8, 0.9 * k2))

func _draw_spike() -> void:
	if t < tele:
		var k := t / tele
		draw_rect(Rect2(-w * 0.5, -6.0, w, 6.0), Color(0.5, 0.8, 0.3, 0.3 + 0.5 * k))
		return
	var k2 := clampf((t - tele) / 0.12, 0.0, 1.0)
	var fade := clampf(1.0 - (t - tele - 0.2) / 0.15, 0.0, 1.0)
	for i in 3:
		var ox := (i - 1) * w * 0.28
		var hh := h * k2 * (1.0 if i == 1 else 0.72)
		var lean := (i - 1) * 16.0
		var pts := PackedVector2Array([Vector2(ox - 17, 0), Vector2(ox + 17, 0), Vector2(ox + lean, -hh)])
		draw_colored_polygon(pts, Color(0.36, 0.26, 0.14, fade))
		var pts2 := PackedVector2Array([Vector2(ox - 9, 0), Vector2(ox + 9, 0), Vector2(ox + lean, -hh)])
		draw_colored_polygon(pts2, Color(0.55, 0.8, 0.3, fade))
