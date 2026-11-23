class_name Minion
extends Node2D
## Weak creatures that bosses summon. 16 kinds (8 Hell, 8 Heaven), each with its own behaviour.

# beh: shooter zigzag runner hopper swooper orbiter walker bomber homing dasher bell puff bouncer
const TYPES := {
	# ------------------------------------------------ Hell
	"ember_imp": {"name": "Ember Imp", "hp": 30.0, "spd": 120.0, "w": 34.0, "h": 34.0, "beh": "shooter", "fly": true, "col": Color("e0452a"), "hell": true},
	"ash_moth": {"name": "Ash Moth", "hp": 16.0, "spd": 190.0, "w": 30.0, "h": 24.0, "beh": "zigzag", "fly": true, "col": Color("9a8f88"), "hell": true},
	"cinder_rat": {"name": "Cinder Rat", "hp": 22.0, "spd": 230.0, "w": 40.0, "h": 24.0, "beh": "runner", "fly": false, "col": Color("5a3a2a"), "hell": true},
	"magma_blob": {"name": "Magma Blob", "hp": 40.0, "spd": 200.0, "w": 40.0, "h": 34.0, "beh": "hopper", "fly": false, "col": Color("f06a1c"), "hell": true},
	"bone_bat": {"name": "Bone Bat", "hp": 20.0, "spd": 150.0, "w": 40.0, "h": 24.0, "beh": "swooper", "fly": true, "col": Color("d8d0c0"), "hell": true},
	"soot_sprite": {"name": "Soot Sprite", "hp": 12.0, "spd": 140.0, "w": 22.0, "h": 22.0, "beh": "orbiter", "fly": true, "col": Color("2a2226"), "hell": true},
	"hell_beetle": {"name": "Hell Beetle", "hp": 75.0, "spd": 62.0, "w": 52.0, "h": 30.0, "beh": "walker", "fly": false, "col": Color("3b2f4a"), "hell": true},
	"brimstone_wisp": {"name": "Brimstone Wisp", "hp": 15.0, "spd": 85.0, "w": 28.0, "h": 28.0, "beh": "bomber", "fly": true, "col": Color("ffb02e"), "hell": true},
	# ------------------------------------------------ Heaven
	"halo_sprite": {"name": "Halo Sprite", "hp": 26.0, "spd": 110.0, "w": 30.0, "h": 30.0, "beh": "shooter", "fly": true, "col": Color("fff1a8"), "hell": false},
	"feather_wisp": {"name": "Feather Wisp", "hp": 16.0, "spd": 120.0, "w": 28.0, "h": 24.0, "beh": "homing", "fly": true, "col": Color("f4f4ff"), "hell": false},
	"choir_lamb": {"name": "Choir Lamb", "hp": 38.0, "spd": 90.0, "w": 44.0, "h": 34.0, "beh": "dasher", "fly": false, "col": Color("f2ede0"), "hell": false},
	"bell_cherub": {"name": "Bell Cherub", "hp": 30.0, "spd": 70.0, "w": 34.0, "h": 34.0, "beh": "bell", "fly": true, "col": Color("ffd75e"), "hell": false},
	"cloud_puff": {"name": "Cloud Puff", "hp": 22.0, "spd": 60.0, "w": 44.0, "h": 32.0, "beh": "puff", "fly": true, "col": Color("c9d4e8"), "hell": false},
	"gilded_moth": {"name": "Gilded Moth", "hp": 16.0, "spd": 200.0, "w": 30.0, "h": 24.0, "beh": "zigzag", "fly": true, "col": Color("f0c850"), "hell": false},
	"dove_scout": {"name": "Dove Scout", "hp": 20.0, "spd": 160.0, "w": 38.0, "h": 24.0, "beh": "swooper", "fly": true, "col": Color("ffffff"), "hell": false},
	"star_shard": {"name": "Star Shard", "hp": 32.0, "spd": 270.0, "w": 28.0, "h": 28.0, "beh": "bouncer", "fly": true, "col": Color("ffe27a"), "hell": false},
}

static func pool(hell: bool) -> Array:
	var out: Array = []
	for k in TYPES:
		if TYPES[k]["hell"] == hell:
			out.append(k)
	return out

var game
var type := "ember_imp"
var info: Dictionary = {}
var hp := 20.0
var max_hp := 20.0
var vel := Vector2.ZERO
var t := 0.0
var dead := false
var flash := 0.0
var tier := 0.0
var timer := 1.0
var state := 0
var dir := 1
var angle := 0.0
var target := Vector2.ZERO
var hit_ids := {}
var boss_ref = null

func setup(g, kind: String, pos: Vector2, tier_v: float) -> void:
	game = g
	type = kind
	info = TYPES[kind]
	tier = tier_v
	max_hp = float(info["hp"]) * (1.0 + 1.6 * tier)
	hp = max_hp
	position = pos
	timer = randf_range(0.5, 1.6)
	angle = randf() * TAU
	dir = 1 if randf() < 0.5 else -1
	vel = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * float(info["spd"])
	boss_ref = g.boss

func hurt_rect() -> Rect2:
	var w: float = info["w"]
	var h: float = info["h"]
	return Rect2(position.x - w * 0.5, position.y - h * 0.5, w, h)

func take_damage(amount: float) -> void:
	if dead:
		return
	hp -= amount
	flash = 1.0
	game.fx.popup(position + Vector2(0, -22), str(int(amount)), Color(1, 1, 0.85))
	if hp <= 0.0:
		die(true)

func die(drops: bool) -> void:
	if dead:
		return
	dead = true
	var c: Color = info["col"]
	game.fx.burst(position, 14, c, 240.0, 4.0, 0.5)
	game.sfx.play("hit", -8.0, 1.4)
	var beh: String = info["beh"]
	if drops:
		if beh == "bomber":
			_ring(8)
		elif beh == "puff":
			Hazard.pillar(game, position.x, 70.0, 0.65, 0.3, 1, Color(1.0, 0.92, 0.5), "holy")
		game.on_minion_killed(self)

func _ring(n: int) -> void:
	for i in n:
		var a := TAU * float(i) / float(n)
		Hazard.bolt(game, position, Vector2.from_angle(a) * (170.0 + 60.0 * tier), 8.0, 1, info["col"])
	game.fx.ring(position, 90.0, info["col"], 0.4)

func _shoot(speed: float) -> void:
	var dirv: Vector2 = (game.player.center() - position).normalized()
	Hazard.bolt(game, position, dirv * speed, 8.0, 1, info["col"])
	game.sfx.play("shoot", -14.0, 1.5)

# ------------------------------------------------------------------ update
func update(dt: float) -> void:
	t += dt
	flash = maxf(0.0, flash - dt * 6.0)
	var p: Player = game.player
	var spd: float = float(info["spd"]) * (1.0 + 0.5 * tier)
	var fly: bool = info["fly"]
	var to_p: Vector2 = p.center() - position
	match info["beh"]:
		"shooter":
			var side := signf(position.x - p.position.x)
			if side == 0.0:
				side = 1.0
			var tx := clampf(p.position.x + side * 300.0, 60.0, Cfg.W - 60.0)
			position.x = move_toward(position.x, tx, spd * dt)
			position.y = move_toward(position.y, 250.0 + sin(t * 2.0) * 50.0, spd * dt)
			timer -= dt
			if timer <= 0.0:
				timer = 2.6 - 0.8 * tier
				_shoot(230.0 + 120.0 * tier)
		"zigzag":
			var d := to_p.normalized()
			position += (d * spd + Vector2(0, cos(t * 7.0) * 150.0)) * dt * 0.8
			position.y = clampf(position.y, 90.0, Cfg.FLOOR - 24.0)
		"runner":
			position.x += signf(to_p.x) * spd * dt
			position.y = Cfg.FLOOR - float(info["h"]) * 0.5
		"hopper":
			timer -= dt
			if position.y >= Cfg.FLOOR - float(info["h"]) * 0.5 and vel.y >= 0.0:
				position.y = Cfg.FLOOR - float(info["h"]) * 0.5
				vel = Vector2.ZERO
				if timer <= 0.0:
					timer = 1.3
					vel = Vector2(signf(to_p.x) * spd, -560.0)
			else:
				vel.y += 1800.0 * dt
			position += vel * dt
			position.x = clampf(position.x, 30.0, Cfg.W - 30.0)
		"swooper":
			timer -= dt
			if state == 0:
				position.x = move_toward(position.x, p.position.x, spd * dt)
				position.y = move_toward(position.y, 190.0, spd * dt)
				if timer <= 0.0:
					state = 1
					timer = 0.45
			elif state == 1:
				if timer <= 0.0:
					state = 2
					target = p.center()
					vel = (target - position).normalized() * 520.0
					timer = 0.9
			elif state == 2:
				position += vel * dt
				if timer <= 0.0 or position.y >= Cfg.FLOOR - 20.0:
					state = 0
					timer = randf_range(1.4, 2.4)
		"orbiter":
			timer -= dt
			if state == 0:
				angle += dt * 2.4
				var c := position
				if boss_ref != null and is_instance_valid(boss_ref):
					c = boss_ref.position
				position = position.lerp(c + Vector2.from_angle(angle) * 130.0, 0.15)
				if timer <= -2.2:
					state = 1
					vel = (p.center() - position).normalized() * 380.0
					timer = 1.2
			else:
				position += vel * dt
				if timer <= 0.0:
					state = 0
					timer = 0.0
		"walker":
			position.x += signf(to_p.x) * spd * dt
			position.y = Cfg.FLOOR - float(info["h"]) * 0.5
		"bomber":
			position += to_p.normalized() * spd * dt
			if to_p.length() < 40.0:
				_ring(8)
				die(false)
		"homing":
			var want := to_p.normalized() * spd
			vel = vel.lerp(want, minf(1.0, dt * 2.0))
			position += vel * dt
		"dasher":
			timer -= dt
			if state == 0:
				position.x += signf(to_p.x) * spd * dt
				if timer <= 0.0:
					state = 1
					timer = 0.5
					dir = int(signf(to_p.x)) if to_p.x != 0.0 else 1
			elif state == 1:
				if timer <= 0.0:
					state = 2
					timer = 0.5
			else:
				position.x += dir * 520.0 * dt
				if timer <= 0.0:
					state = 0
					timer = randf_range(1.6, 2.6)
			position.y = Cfg.FLOOR - float(info["h"]) * 0.5
		"bell":
			position.x += sin(t * 0.9 + angle) * 60.0 * dt
			position.y = move_toward(position.y, 220.0 + sin(t * 1.4 + angle) * 40.0, 90.0 * dt)
			timer -= dt
			if timer <= 0.0:
				timer = 3.2
				for i in 6:
					var a := TAU * float(i) / 6.0 + t
					Hazard.bolt(game, position, Vector2.from_angle(a) * (150.0 + 40.0 * tier), 7.0, 1, info["col"])
				game.sfx.play("rune", -12.0, 2.0)
		"puff":
			position.x += sin(t * 0.7 + angle) * spd * dt * 2.0
			position.y = move_toward(position.y, 300.0 + sin(t * 1.1 + angle) * 90.0, 60.0 * dt)
		"bouncer":
			position += vel.normalized() * spd * dt if vel.length() > 0.0 else Vector2.ZERO
			if position.x < 30.0 or position.x > Cfg.W - 30.0:
				vel.x = -vel.x
				position.x = clampf(position.x, 30.0, Cfg.W - 30.0)
			if position.y < 100.0 or position.y > Cfg.FLOOR - 20.0:
				vel.y = -vel.y
				position.y = clampf(position.y, 100.0, Cfg.FLOOR - 20.0)
	if not fly:
		position.y = minf(position.y, Cfg.FLOOR - float(info["h"]) * 0.5)
	position.x = clampf(position.x, 10.0, Cfg.W - 10.0)
	if hurt_rect().intersects(p.hurt_rect()):
		p.take_hit(1, position.x)
	queue_redraw()

# ------------------------------------------------------------------ draw
func _c(base: Color) -> Color:
	return base.lerp(Color.WHITE, flash * 0.8)

func _draw() -> void:
	var face := 1.0 if (game != null and game.player.position.x > position.x) else -1.0
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(face, 1.0))
	var c: Color = (info["col"] as Color).darkened(0.32)
	c.s *= 0.8
	var w: float = info["w"]
	var h: float = info["h"]
	var r := minf(w, h) * 0.5
	var flap := sin(t * 18.0) * 6.0
	Art.glow(self, Vector2.ZERO, minf(info["w"], info["h"]) * 0.9, info["col"], 0.18)
	if PixSprite.MINIONS.has(type):
		var bob := 1.0 + 0.08 * sin(t * (16.0 if info["fly"] else 9.0))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(face, bob))
		PixSprite.draw(self, PixSprite.MINIONS[type], Vector2.ZERO, 3.0 if maxf(w, h) < 46.0 else 4.0, flash_amt())
		if state == 1:
			draw_circle(Vector2.ZERO, maxf(w, h) * 0.7, Color(1, 0.3, 0.2, 0.22))
		return
	match type:
		"ember_imp", "halo_sprite":
			draw_circle(Vector2.ZERO, r * 1.0, _c(c))
			draw_colored_polygon(PackedVector2Array([Vector2(-8, -r), Vector2(-14, -r - 12), Vector2(-2, -r)]), _c(c.darkened(0.5)) if type == "ember_imp" else _c(Color.WHITE))
			draw_colored_polygon(PackedVector2Array([Vector2(8, -r), Vector2(14, -r - 12), Vector2(2, -r)]), _c(c.darkened(0.5)) if type == "ember_imp" else _c(Color.WHITE))
			draw_circle(Vector2(-5, -2), 3.0, Color(1, 1, 0.3) if type == "ember_imp" else Color(0.3, 0.3, 0.6))
			draw_circle(Vector2(5, -2), 3.0, Color(1, 1, 0.3) if type == "ember_imp" else Color(0.3, 0.3, 0.6))
			if type == "halo_sprite":
				draw_arc(Vector2(0, -r - 8), 9.0, 0.0, TAU, 14, Color(1, 0.85, 0.3), 3.0)
		"ash_moth", "gilded_moth":
			draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(-w * 0.6, -10 - flap), Vector2(-w * 0.5, 8)]), _c(c))
			draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w * 0.6, -10 - flap), Vector2(w * 0.5, 8)]), _c(c))
			draw_circle(Vector2.ZERO, 5.0, _c(c.darkened(0.5)))
		"cinder_rat":
			draw_colored_polygon(PackedVector2Array([Vector2(-18, 8), Vector2(-14, -8), Vector2(10, -10), Vector2(20, 0), Vector2(12, 10)]), _c(c))
			draw_polyline(PackedVector2Array([Vector2(-18, 4), Vector2(-30, -2), Vector2(-34, 8)]), _c(c), 2.0)
			draw_circle(Vector2(14, -3), 2.5, Color(1, 0.5, 0.1))
			draw_circle(Vector2(-4, -12), 5.0, _c(c.lightened(0.1)))
		"magma_blob":
			draw_colored_polygon(PackedVector2Array([Vector2(-20, 15), Vector2(-18, -4), Vector2(0, -16), Vector2(18, -4), Vector2(20, 15)]), _c(c))
			draw_circle(Vector2(0, 2), 9.0, _c(Color(1, 0.85, 0.3)))
			draw_circle(Vector2(-6, -2), 2.5, Color.BLACK)
			draw_circle(Vector2(6, -2), 2.5, Color.BLACK)
		"bone_bat", "dove_scout":
			draw_colored_polygon(PackedVector2Array([Vector2(0, -2), Vector2(-w * 0.55, -14 - flap), Vector2(-w * 0.3, 6)]), _c(c))
			draw_colored_polygon(PackedVector2Array([Vector2(0, -2), Vector2(w * 0.55, -14 - flap), Vector2(w * 0.3, 6)]), _c(c))
			draw_circle(Vector2.ZERO, 8.0, _c(c.darkened(0.1)))
			if type == "bone_bat":
				draw_circle(Vector2(-3, -2), 2.0, Color(0.1, 0.0, 0.0))
				draw_circle(Vector2(3, -2), 2.0, Color(0.1, 0.0, 0.0))
			else:
				draw_colored_polygon(PackedVector2Array([Vector2(6, -2), Vector2(14, 1), Vector2(6, 3)]), Color(1, 0.7, 0.2))
			if state == 1:
				draw_circle(Vector2.ZERO, 22.0, Color(1, 0.3, 0.2, 0.25))
		"soot_sprite":
			for k in 8:
				var a := TAU * float(k) / 8.0 + t * 3.0
				draw_line(Vector2.from_angle(a) * 6.0, Vector2.from_angle(a) * 13.0, _c(c), 2.0)
			draw_circle(Vector2.ZERO, 9.0, _c(c))
			draw_circle(Vector2(-3, -1), 2.5, Color.WHITE)
			draw_circle(Vector2(3, -1), 2.5, Color.WHITE)
		"hell_beetle":
			draw_colored_polygon(PackedVector2Array([Vector2(-26, 14), Vector2(-22, -8), Vector2(0, -16), Vector2(22, -8), Vector2(26, 14)]), _c(c))
			draw_line(Vector2(0, -16), Vector2(0, 14), _c(c.lightened(0.2)), 2.0)
			draw_polyline(PackedVector2Array([Vector2(24, -4), Vector2(36, -10), Vector2(32, -2)]), _c(c.darkened(0.3)), 4.0)
			for k in 3:
				draw_line(Vector2(-14 + k * 14, 14), Vector2(-18 + k * 14, 22), _c(c.darkened(0.3)), 2.0)
		"brimstone_wisp":
			draw_circle(Vector2.ZERO, r * 1.5, Color(c.r, c.g, c.b, 0.25))
			draw_circle(Vector2.ZERO, r * (0.9 + 0.1 * sin(t * 10.0)), _c(c))
			draw_circle(Vector2.ZERO, r * 0.45, Color(1, 1, 0.8))
		"feather_wisp":
			draw_colored_polygon(PackedVector2Array([Vector2(-16, 4), Vector2(0, -12), Vector2(16, 4), Vector2(0, 12)]), _c(c))
			draw_line(Vector2(-14, 4), Vector2(14, 4), Color(0.7, 0.7, 0.9), 1.5)
		"choir_lamb":
			draw_circle(Vector2(0, 2), 16.0, _c(c))
			for k in 4:
				draw_circle(Vector2(-10 + k * 7, -8), 6.0, _c(c))
			draw_circle(Vector2(16, 0), 8.0, _c(c.darkened(0.15)))
			draw_circle(Vector2(18, -2), 1.8, Color.BLACK)
			draw_line(Vector2(-8, 16), Vector2(-8, 22), Color(0.4, 0.3, 0.2), 3.0)
			draw_line(Vector2(8, 16), Vector2(8, 22), Color(0.4, 0.3, 0.2), 3.0)
			if state == 1:
				draw_arc(Vector2(0, -22), 6.0, 0.0, TAU, 10, Color(1, 0.3, 0.2), 3.0)
		"bell_cherub":
			draw_circle(Vector2(0, 4), 13.0, _c(c))
			draw_colored_polygon(PackedVector2Array([Vector2(-12, 14), Vector2(-8, -6), Vector2(8, -6), Vector2(12, 14)]), _c(Color(1, 0.85, 0.3)))
			draw_circle(Vector2(0, 16), 3.0, Color(0.5, 0.4, 0.1))
			draw_circle(Vector2(-16 - flap * 0.3, -8), 7.0, Color(1, 1, 1, 0.85))
			draw_circle(Vector2(16 + flap * 0.3, -8), 7.0, Color(1, 1, 1, 0.85))
		"cloud_puff":
			for k in 4:
				draw_circle(Vector2(-14 + k * 9.0, sin(k * 2.0) * 4.0), 11.0, _c(c))
			draw_circle(Vector2(-4, -1), 2.2, Color(0.2, 0.2, 0.4))
			draw_circle(Vector2(6, -1), 2.2, Color(0.2, 0.2, 0.4))
		"star_shard":
			var pts := PackedVector2Array()
			for k in 10:
				var rr := 15.0 if k % 2 == 0 else 7.0
				pts.append(Vector2.from_angle(t * 4.0 + TAU * float(k) / 10.0) * rr)
			draw_colored_polygon(pts, _c(c))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if hp < max_hp:
		draw_rect(Rect2(-14, -h * 0.5 - 14, 28, 4), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(-14, -h * 0.5 - 14, 28.0 * hp / max_hp, 4), Color(0.9, 0.3, 0.3))

func flash_amt() -> float:
	return clampf(flash, 0.0, 1.0) if 'flash' in self else 0.0
