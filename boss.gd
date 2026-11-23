class_name Boss
extends Node2D
## A boss. Position is the CENTER of the body. Behaviour is data-driven by Lore.boss(i).

const WIND := {"fan": 0.5, "ring": 0.7, "rain": 0.5, "homing": 0.5, "wave": 0.5, "pillars": 0.6,
	"judgment": 1.0, "spears": 0.6, "charge": 0.6, "leap": 0.45, "dive": 0.6, "special": 1.1}

var game
var d: Dictionary = {}
var hp := 100.0
var max_hp := 100.0
var size := Vector2(100, 100)
var fly := false
var col := Color.RED
var acc := Color.ORANGE
var fam := "imp"
var arch := ""
var prologue := false
var phase := 1
var t := 0.0
var flash := 0.0
var face := -1
var mode := "move"          # move, wind, act, rest
var atk := ""
var last_atk := ""
var mode_t := 0.0
var wind_total := 0.5
var cd := 1.2
var vel := Vector2.ZERO
var dying := false
var die_t := 0.0
var queue: Array = []
var active := false         # false while the intro card is up
var contact := false
var act_dir := 1
var act_target := Vector2.ZERO
var dive_stage := 0
var tier := 0.0
var dmg := 1
var raise := 0.0            # God raising a hand (prologue beam)
var frozen := false
var p_spear_t := 1.0
var p_wave_t := 3.0
var bolt_col := Color.ORANGE
var minion_t := 5.0
var sp_cd := 14.0
var guard_t := 0.0
var sp_heal_cd := 0.0
var twists: Array = []
var melee_hits := 0
var blink_pending := false
var volley := 1.0

const TWISTS := {
	"enrage": "ENRAGED: attacks twice as fast below 30% health",
	"regen": "REGENERATING: slowly heals over time",
	"blink": "BLINKING: teleports after every attack",
	"thorns": "THORNED: every 5th melee hit burns you",
	"rapid_special": "ARCANE: special ability comes much sooner",
	"bulwark": "BULWARK: takes 15% less damage",
	"fleet": "FLEET: moves much faster",
	"volley": "BARRAGE: fires 40% more projectiles",
	"vampire": "VAMPIRIC: heals when you are hurt",
	"summoner": "SUMMONER: calls minions twice as often",
	"frenzy": "FRENZIED: shorter wind-ups in later phases",
}
const TWIST_KEYS := ["enrage", "regen", "blink", "thorns", "rapid_special", "bulwark", "fleet", "volley", "vampire", "summoner", "frenzy"]

func _roll_twists(i: int) -> void:
	twists = []
	if i < 6:
		volley = 0.6 + 0.4 * float(d.get("ease", 1.0))
		return
	var keys: Array = TWIST_KEYS if i >= 20 else ["fleet", "volley", "summoner", "blink", "frenzy", "rapid_special"]
	var first: String = keys[(i * 7 + 3) % keys.size()]
	twists.append(first)
	if i >= 30:
		var second: String = TWIST_KEYS[(i * 5 + 1) % TWIST_KEYS.size()]
		if second == first:
			second = TWIST_KEYS[(i * 5 + 2) % TWIST_KEYS.size()]
		twists.append(second)
	if i == 25 or i == 50:
		twists = ["enrage", "summoner", "volley"]
	volley = (1.4 if "volley" in twists else 1.0) * (0.6 + 0.4 * float(d.get("ease", 1.0)))

func has_twist(k: String) -> bool:
	return k in twists

func twist_text() -> String:
	var out := ""
	for k in twists:
		out += String(TWISTS[k]) + "\n"
	return out.strip_edges()

func on_player_hurt() -> void:
	if has_twist("vampire") and not dying and active:
		hp = minf(max_hp, hp + max_hp * 0.03)
		game.fx.popup(position + Vector2(0, -size.y * 0.5 - 10.0), "DRAIN", Color(0.9, 0.3, 0.4))

func setup(g, data: Dictionary) -> void:
	game = g
	d = data
	fam = data["family"]
	arch = data["arch"]
	size = data["size"]
	fly = data["fly"]
	col = data["col"]
	acc = data["acc"]
	tier = data["tier"]
	dmg = data["dmg"]
	max_hp = data["hp"]
	hp = max_hp
	prologue = data.get("prologue", false)
	if prologue:
		size = Vector2(260, 640)
		fly = false
	bolt_col = acc if not (fam == "archangel") else acc.lerp(col, 0.4)
	position = Vector2(1000.0, Cfg.FLOOR - size.y * 0.5)
	if fly:
		position = Vector2(1000.0, 330.0)
	if prologue:
		position = Vector2(1010.0, Cfg.FLOOR - size.y * 0.5)
	cd = 1.2
	_roll_twists(int(d.get("index", 1)))
	if has_twist("rapid_special"):
		sp_cd = 8.0

func can_be_hit() -> bool:
	return not dying and (active or prologue)

func hurt_rect() -> Rect2:
	if prologue:
		return Rect2(position.x - 120.0, Cfg.FLOOR - 110.0, 240.0, 110.0)
	return Rect2(position.x - size.x * 0.5, position.y - size.y * 0.5, size.x, size.y)

func take_damage(amount: float, _melee: bool = false) -> void:
	if dying or not (active or prologue):
		return
	flash = 1.0
	if prologue:
		return
	if has_twist("bulwark"):
		amount *= 0.85
	if _melee and has_twist("thorns"):
		melee_hits += 1
		if melee_hits % 5 == 0:
			game.player.take_hit(1, position.x)
	if guard_t > 0.0:
		amount *= 0.15
		game.fx.burst(position + Vector2(-face * size.x * 0.4, -10), 4, Color(0.9, 0.9, 1.0), 200.0, 3.0, 0.3)
	hp -= amount
	game.fx.popup(position + Vector2(randf_range(-30, 30), -size.y * 0.5 - 6.0), str(int(amount)), Color(1, 1, 0.8))
	if hp <= 0.0:
		hp = 0.0
		dying = true
		die_t = 0.0
		queue.clear()
		game.on_boss_dead()

# ------------------------------------------------------------------ tick
func tick(dt: float) -> void:
	t += dt
	flash = maxf(0.0, flash - dt * 5.0)
	sp_cd -= dt
	guard_t = maxf(0.0, guard_t - dt)
	sp_heal_cd -= dt
	if has_twist("regen") and active and not dying:
		hp = minf(max_hp, hp + max_hp * 0.0008 * dt)
	if dying:
		die_t += dt
		modulate.a = clampf(1.0 - maxf(0.0, die_t - 1.0) / 1.2, 0.0, 1.0)
		if int(die_t * 20.0) % 3 == 0:
			game.fx.burst(position + Vector2(randf_range(-size.x, size.x) * 0.4, randf_range(-size.y, size.y) * 0.4), 3, acc, 220.0, 5.0, 0.5)
		queue_redraw()
		return
	if prologue:
		_tick_prologue(dt)
		queue_redraw()
		return
	if not active:
		queue_redraw()
		return
	_run_queue(dt)
	_check_phase()
	minion_t -= dt
	if minion_t <= 0.0 and mode != "act":
		minion_t = maxf(4.5, 10.0 - 5.0 * tier) * randf_range(0.8, 1.2) * (0.5 if has_twist("summoner") else 1.0) / float(d.get("ease", 1.0))
		_spawn_minion_wave()
	var p = game.player
	if mode != "act" or atk == "leap":
		face = 1 if p.position.x > position.x else -1
	match mode:
		"move": _move(dt, p)
		"wind":
			_drift(dt)
			mode_t -= dt
			if mode_t <= 0.0:
				_execute()
		"act": _act(dt, p)
		"rest":
			_drift(dt)
			mode_t -= dt
			if mode_t <= 0.0:
				mode = "move"
				cd = float(d["cd"]) * (1.0 - 0.12 * (phase - 1)) * randf_range(0.8, 1.1) * (0.5 if (has_twist("enrage") and hp / max_hp < 0.3) else 1.0)
				if has_twist("blink"):
					_blink()
	queue_redraw()

func _run_queue(dt: float) -> void:
	if queue.is_empty():
		return
	var keep: Array = []
	for q in queue:
		q["t"] -= dt
		if q["t"] <= 0.0:
			q["f"].call()
		else:
			keep.append(q)
	queue = keep

func _later(delay: float, f: Callable) -> void:
	queue.append({"t": delay, "f": f})

func _check_phase() -> void:
	var ratio := hp / max_hp
	var np := 1
	if int(d["phases"]) == 2:
		np = 2 if ratio < 0.5 else 1
	else:
		np = 3 if ratio < 0.33 else (2 if ratio < 0.66 else 1)
	if np > phase:
		phase = np
		queue.clear()
		game.clear_hostile()
		game.on_boss_phase(phase)
		game.player.hp = mini(game.player.max_hp, game.player.hp + 2)
		game.fx.popup(game.player.position + Vector2(0, -100), "+HP", Color(0.5, 1.0, 0.5))
		mode = "rest"
		contact = false
		mode_t = 1.1
		flash = 1.0
		minion_t = 0.8

func _spawn_minion_wave() -> void:
	var cap := 3 + int(tier * 6.0)
	if game.minion_count() >= cap:
		return
	var pool: Array = Minion.pool(bool(d["hell"]))
	var kinds: Array = [pool.pick_random(), pool.pick_random()]
	var n := mini(2 + int(tier * 3.0) + (phase - 1), cap - game.minion_count())
	game.sfx.play("roar", -10.0, 1.8)
	for i in n:
		var kind: String = kinds[i % 2]
		var fl: bool = Minion.TYPES[kind]["fly"]
		var left := (i % 2 == 0)
		var pos := Vector2(70.0 if left else Cfg.W - 70.0, 70.0 if fl else Cfg.FLOOR - 20.0)
		_later(0.01 + i * 0.35, func(): game.add_minion(kind, pos, tier))

func _drift(dt: float) -> void:
	if fly:
		position.y += sin(t * 3.0) * 10.0 * dt
	if mode == "rest" and not fly:
		position.y = Cfg.FLOOR - size.y * 0.5

func _move(dt: float, p) -> void:
	var spd := float(d["speed"]) * (1.0 + 0.2 * (phase - 1)) * (1.35 if has_twist("fleet") else 1.0)
	if fly:
		var tx := clampf(p.position.x + sin(t * 0.7) * 300.0, 120.0, 1160.0)
		var ty := 300.0 + sin(t * 1.3) * 45.0
		position.x = move_toward(position.x, tx, spd * 1.3 * dt)
		position.y = move_toward(position.y, ty, 140.0 * dt)
	else:
		var dx: float = p.position.x - position.x
		if absf(dx) > 150.0:
			position.x += signf(dx) * spd * dt
		position.y = Cfg.FLOOR - size.y * 0.5
	position.x = clampf(position.x, 80.0, Cfg.W - 80.0)
	cd -= dt
	if cd <= 0.0:
		_choose()

func _choose() -> void:
	var pool: Array = (d["pool"] as Array).duplicate()
	if phase >= 2:
		pool.append_array(d["p2"])
	if pool.size() > 1:
		pool = pool.filter(func(a): return a != last_atk)
	var a: String = pool.pick_random()
	if sp_cd <= 0.0 and not prologue:
		a = "special"
		sp_cd = maxf(8.0, 17.0 - 6.0 * tier - 1.5 * (phase - 1)) * (0.55 if has_twist("rapid_special") else 1.0)
		game.show_special(special_name())
	last_atk = a
	if fly and (a == "charge" or a == "leap"):
		a = "dive"
	elif (not fly) and a == "dive":
		a = "charge"
	if fly and a == "wave":
		a = "rain"
	atk = a
	mode = "wind"
	wind_total = float(WIND[a]) * (1.0 - 0.15 * (phase - 1)) * (0.7 if (has_twist("frenzy") and phase >= 2) else 1.0)
	mode_t = wind_total
	game.sfx.play("roar", -14.0, 1.6)

func wind_ratio() -> float:
	if mode != "wind":
		return 0.0
	return clampf(1.0 - mode_t / maxf(wind_total, 0.01), 0.0, 1.0)

func _end_attack(rest: float = 0.6) -> void:
	mode = "rest"
	mode_t = rest
	contact = false

func _execute() -> void:
	var p = game.player
	match atk:
		"fan": _fan()
		"ring": _ring()
		"rain": _rain(p)
		"homing": _homing()
		"wave": _wave()
		"pillars": _pillars(p)
		"judgment": _judgment()
		"spears": _spears()
		"special": _special(p)
		"charge":
			mode = "act"
			mode_t = 1.6
			act_dir = face
			contact = true
			game.sfx.play("roar", -6.0, 1.3)
			return
		"leap":
			mode = "act"
			contact = true
			vel = Vector2(clampf((p.position.x - position.x) / 0.73, -850.0, 850.0), -880.0)
			game.sfx.play("jump", -2.0, 0.5)
			return
		"dive":
			mode = "act"
			contact = true
			dive_stage = 0
			mode_t = 1.2
			act_target = p.center()
			game.sfx.play("roar", -6.0, 1.5)
			return
	_end_attack(0.55 + 0.05 * (phase - 1))

func _dmg() -> int:
	return dmg

func _bspeed() -> float:
	return float(d["bolt_speed"]) * (1.0 + 0.1 * (phase - 1))

func _origin() -> Vector2:
	return position + Vector2(face * size.x * 0.25, -size.y * 0.1)

# ---------------------------------------------------------------- attacks
func _fan() -> void:
	var n := int((3 + int(tier * 6.0) + (phase - 1)) * volley)
	var vols := 1 + (1 if phase >= 2 else 0) + (1 if (phase == 3 and bool(d["final"])) else 0)
	for v in vols:
		_later(0.01 + v * 0.4, func(): _fan_once(n))

func _fan_once(n: int) -> void:
	var o := _origin()
	var base: float = (game.player.center() - o).angle()
	var spread := deg_to_rad(11.0)
	for i in n:
		var a := base + (float(i) - float(n - 1) * 0.5) * spread
		Hazard.bolt(game, o, Vector2.from_angle(a) * _bspeed(), 12.0, _dmg(), bolt_col)
	game.sfx.play("shoot", -8.0)

func _ring() -> void:
	var n := int((10 + int(tier * 10.0)) * volley)
	var vols := 1 + (1 if phase >= 2 else 0)
	for v in vols:
		_later(0.01 + v * 0.55, func(): _ring_once(n, v))

func _ring_once(n: int, v: int) -> void:
	var off := (0.5 if v % 2 == 1 else 0.0) * TAU / float(n)
	for i in n:
		var a := off + TAU * float(i) / float(n)
		Hazard.bolt(game, position, Vector2.from_angle(a) * _bspeed() * 0.78, 12.0, _dmg(), bolt_col)
	game.fx.ring(position, 120.0, bolt_col, 0.4)
	game.sfx.play("shoot", -6.0, 0.7)

func _rain(p) -> void:
	var n := 8 + int(tier * 8.0) + 2 * (phase - 1)
	for i in n:
		_later(0.01 + i * 0.14, func():
			var x: float = clampf(game.player.position.x + randf_range(-110.0, 110.0), 50.0, Cfg.W - 50.0) if i % 3 == 0 else randf_range(60.0, Cfg.W - 60.0)
			Hazard.bolt(game, Vector2(x, -20.0), Vector2(0.0, _bspeed() * 0.9), 14.0, _dmg(), bolt_col, {"grav": 650.0, "warn": true}))

func _homing() -> void:
	var n := 1 + (1 if phase >= 2 else 0) + (1 if phase == 3 else 0)
	for i in n:
		_later(0.01 + i * 0.5, func():
			var ang: float = (game.player.center() - _origin()).angle() + randf_range(-0.5, 0.5)
			Hazard.bolt(game, _origin(), Vector2.from_angle(ang) * (190.0 + 80.0 * tier), 20.0, _dmg(), bolt_col, {"turn": 1.5, "life": 6.0, "breakable": true})
			game.sfx.play("shoot", -8.0, 0.6))

func _wave() -> void:
	var h := 46.0 + 10.0 * (phase - 1)
	var spd := 340.0 + 180.0 * tier
	var rounds := 1 + (1 if phase >= 2 else 0)
	for r_i in rounds:
		_later(0.01 + r_i * 0.8, func():
			for s in [-1, 1]:
				Hazard.wave(game, position.x + s * 40.0, s * spd, h, _dmg(), bolt_col)
			game.sfx.play("boom", -8.0, 1.2)
			game.shake_add(5.0))

func _pillars(p) -> void:
	var n := 2 + int(tier * 3.0) + (phase - 1)
	for i in n:
		var x: float = p.position.x if i == 0 else p.position.x + (float(i) - float(n) * 0.5) * randf_range(120.0, 190.0)
		x = clampf(x, 50.0, Cfg.W - 50.0)
		_later(0.01 + i * 0.12, func():
			Hazard.pillar(game, x, 80.0, 0.95 - 0.1 * tier, 0.35, _dmg(), bolt_col, String(d["style"])))

func _judgment() -> void:
	var cols := 13
	var gap := randi_range(2, cols - 3)
	for i in cols:
		if i == gap or i == gap + 1:
			continue
		Hazard.pillar(game, 10.0 + i * 100.0, 100.0, 1.35, 0.5, _dmg(), bolt_col, String(d["style"]))
	game.sfx.play("roar", -8.0, 0.8)

func _spears() -> void:
	var n := 5 + int(tier * 4.0) + (phase - 1)
	for i in n:
		_later(0.01 + i * 0.22, func():
			Hazard.pillar(game, clampf(game.player.position.x + randf_range(-50.0, 50.0), 40.0, Cfg.W - 40.0), 26.0, 0.55, 0.22, _dmg(), Color(1.0, 0.92, 0.5), "spear"))


# ---------------------------------------------------------------- special abilities
func _sid() -> String:
	return arch if fam == "archangel" else fam

const SPECIALS := {
	"imp": "SWARM CALL", "wraith": "VEILSTEP", "hound": "HELLHOWL", "slime": "MOLTEN SPLIT",
	"duke": "GATE OF EMBERS", "torturer": "IRON CHAINS", "golem": "EARTHSHATTER", "seraph": "WHEEL OF FIRE",
	"cherub": "CHOIR SUMMON", "knight": "SHIELD WALL", "pillar": "COLLAPSE", "ophanim": "ALL-SEEING",
	"michael": "BLADE OF HEAVEN", "gabriel": "TRUMPET OF DOOM", "uriel": "SOLAR FLARE", "raphael": "MENDING LIGHT",
	"metatron": "CUBE OF TRUTH", "raguel": "SCALES OF JUDGMENT", "sariel": "ECLIPSE", "satan": "HELLSTORM", "god": "DIVINE WRATH",
}

func special_name() -> String:
	return String(SPECIALS.get(_sid(), "WRATH"))

func _spawn_adds(kind: String, n: int) -> void:
	if game.minion_count() >= 9:
		return
	for i in n:
		var off := Vector2(randf_range(-120.0, 120.0), randf_range(-60.0, 20.0))
		var fl: bool = Minion.TYPES[kind]["fly"]
		var pos := position + off
		if not fl:
			pos.y = Cfg.FLOOR - 20.0
		pos.x = clampf(pos.x, 60.0, Cfg.W - 60.0)
		_later(0.05 + i * 0.25, func(): game.add_minion(kind, pos, tier))

func _sweep_pillars(from_left: bool, n: int, gap: float) -> void:
	for i in n:
		var x := 60.0 + float(i if from_left else n - 1 - i) * gap
		_later(0.01 + i * 0.11, func():
			Hazard.pillar(game, clampf(x, 40.0, Cfg.W - 40.0), 70.0, 0.85, 0.35, _dmg(), bolt_col, String(d["style"])))

func _special(p) -> void:
	var ph := phase
	game.shake_add(6.0)
	game.sfx.play("roar", -4.0, 0.7)
	match _sid():
		"imp":
			_spawn_adds("ember_imp", 3 + ph)
			_ring_once(8 + ph * 2, 0)
		"wraith":
			var tx := clampf(p.position.x + (260.0 if p.position.x < Cfg.W * 0.5 else -260.0), 120.0, Cfg.W - 120.0)
			game.fx.burst(position, 16, acc, 220.0, 5.0, 0.5)
			position.x = tx
			game.fx.burst(position, 16, acc, 220.0, 5.0, 0.5)
			for k in 2:
				_later(0.2 + k * 0.5, func(): _ring_once(12 + 4 * ph, k))
		"hound":
			for k in 2 + ph:
				_later(0.01 + k * 0.55, func():
					for s in [-1, 1]:
						Hazard.wave(game, position.x + s * 40.0, s * (420.0 + 70.0 * k), 50.0, _dmg(), bolt_col)
					game.shake_add(8.0)
					game.sfx.play("boom", -6.0, 0.8))
		"slime":
			_spawn_adds("magma_blob", 3 + ph)
			_wave()
		"duke":
			_sweep_pillars(p.position.x > Cfg.W * 0.5, 12, 100.0)
			if ph >= 2:
				_later(0.9, func(): _sweep_pillars(p.position.x <= Cfg.W * 0.5, 12, 100.0))
		"torturer":
			for k in 9:
				_later(0.05 + k * 0.07, func():
					var dir := signf(position.x - game.player.position.x)
					game.player.position.x = clampf(game.player.position.x + dir * 26.0, 30.0, Cfg.W - 30.0)
					game.fx.burst(game.player.center(), 2, Color(0.6, 0.6, 0.65), 100.0, 3.0, 0.25))
			_later(0.8, func(): _wave())
			_later(1.3, func(): _pillars(game.player))
		"golem":
			for s in [-1, 1]:
				Hazard.wave(game, position.x + s * 60.0, s * 300.0, 60.0, _dmg(), bolt_col)
			game.shake_add(16.0)
			_rain(p)
			_rain(p)
		"seraph":
			var arms := 3
			var steps := 16
			for k in steps:
				_later(0.01 + k * 0.12, func():
					for a in arms:
						var ang := float(k) * 0.35 + TAU * float(a) / float(arms)
						Hazard.bolt(game, position, Vector2.from_angle(ang) * _bspeed() * 0.75, 11.0, _dmg(), bolt_col))
		"cherub":
			_spawn_adds("halo_sprite", 3)
			_fan()
		"knight":
			guard_t = 3.5
			game.fx.ring(position, 140.0, Color(0.8, 0.85, 1.0), 0.6)
			_later(1.5, func(): _fan_once(7 + ph))
			_later(2.6, func(): _wave())
		"pillar":
			for k in 9:
				_later(0.01 + k * 0.16, func():
					Hazard.pillar(game, randf_range(50.0, Cfg.W - 50.0), 70.0, 0.9, 0.4, _dmg(), bolt_col, String(d["style"])))
			_later(1.6, func(): _judgment())
		"ophanim":
			for k in 8:
				_later(0.01 + k * 0.14, func():
					var ang := TAU * float(k) / 8.0 + t
					Hazard.bolt(game, position + Vector2.from_angle(ang) * 60.0, Vector2.from_angle(ang) * 170.0, 15.0, _dmg(), bolt_col, {"turn": 1.6, "life": 6.0, "breakable": true}))
		"michael":
			for k in 14 + 2 * ph:
				_later(0.01 + k * 0.13, func():
					Hazard.pillar(game, clampf(game.player.position.x + randf_range(-160.0, 160.0), 40.0, Cfg.W - 40.0), 26.0, 0.5, 0.22, _dmg(), Color(1.0, 0.92, 0.5), "spear"))
		"gabriel":
			for k in 3:
				_later(0.01 + k * 0.5, func():
					for s in [-1, 1]:
						Hazard.wave(game, position.x + s * 40.0, s * (380.0 + 60.0 * k), 48.0, _dmg(), bolt_col)
					game.shake_add(6.0)
					game.sfx.play("boom", -8.0, 1.3))
		"uriel":
			for k in 6:
				_later(0.01 + k * 0.2, func():
					Hazard.pillar(game, 100.0 + k * 200.0, 120.0, 1.2, 0.6, _dmg(), bolt_col, "fire"))
		"raphael":
			if sp_heal_cd <= 0.0:
				sp_heal_cd = 22.0
				hp = minf(max_hp, hp + max_hp * 0.05)
				game.fx.popup(position + Vector2(0, -size.y * 0.5 - 10.0), "HEAL", Color(0.5, 1.0, 0.6))
			game.fx.ring(position, 160.0, Color(0.5, 1.0, 0.6), 0.6)
			_ring_once(14, 0)
			_later(0.6, func(): _ring_once(14, 1))
		"metatron":
			_ring_once(16, 0)
			_later(0.5, func(): _homing())
			_later(1.0, func(): _homing())
		"raguel":
			_judgment()
			_later(1.0, func(): _judgment())
		"sariel":
			game.dark_t = 3.0
			for k in 14:
				_later(0.01 + k * 0.12, func():
					Hazard.bolt(game, Vector2(randf_range(60.0, Cfg.W - 60.0), -20.0), Vector2(0.0, _bspeed()), 14.0, _dmg(), bolt_col, {"grav": 650.0}))
		"satan":
			for k in 16 + 4 * ph:
				_later(0.01 + k * 0.11, func():
					Hazard.bolt(game, Vector2(randf_range(60.0, Cfg.W - 60.0), -20.0), Vector2(randf_range(-80.0, 80.0), _bspeed() * 0.9), 16.0, _dmg(), Color(1.0, 0.4, 0.1), {"grav": 700.0, "warn": true}))
			_later(1.0, func(): _wave())
			_later(1.8, func(): _pillars(game.player))
		"god":
			_judgment()
			_later(0.9, func(): _spears())
			_later(1.6, func(): _ring_once(18 + 4 * ph, 0))
		_:
			_ring_once(12, 0)

# ---------------------------------------------------------------- movement attacks
func _act(dt: float, p) -> void:
	match atk:
		"charge":
			var spd := (520.0 + 250.0 * tier) * (1.0 + 0.2 * (phase - 1))
			position.x += act_dir * spd * dt
			mode_t -= dt
			if position.x < 90.0 or position.x > Cfg.W - 90.0:
				position.x = clampf(position.x, 90.0, Cfg.W - 90.0)
				game.shake_add(9.0)
				game.sfx.play("boom", -6.0)
				game.fx.burst(Vector2(position.x, Cfg.FLOOR), 14, acc, 260.0, 5.0, 0.5)
				_end_attack(1.0)
				return
			if mode_t <= 0.0:
				_end_attack(0.9)
		"leap":
			vel.y += 2400.0 * dt
			position += vel * dt
			position.x = clampf(position.x, 80.0, Cfg.W - 80.0)
			if vel.y > 0.0 and position.y >= Cfg.FLOOR - size.y * 0.5:
				position.y = Cfg.FLOOR - size.y * 0.5
				game.shake_add(12.0)
				game.sfx.play("boom")
				game.fx.burst(Vector2(position.x, Cfg.FLOOR), 20, acc, 300.0, 6.0, 0.6)
				for s in [-1, 1]:
					Hazard.wave(game, position.x + s * 50.0, s * (300.0 + 150.0 * tier), 42.0, _dmg(), bolt_col)
				_end_attack(0.8)
		"dive":
			mode_t -= dt
			if dive_stage == 0:
				var to := act_target - position
				var step := (760.0 + 200.0 * tier) * dt
				if to.length() <= step or mode_t <= 0.0:
					dive_stage = 1
					game.fx.burst(position, 12, acc, 240.0, 5.0, 0.4)
				else:
					position += to.normalized() * step
			else:
				position.y = move_toward(position.y, 320.0, 520.0 * dt)
				if position.y <= 330.0:
					_end_attack(0.6)
	if contact and hurt_rect().intersects(p.hurt_rect()):
		p.take_hit(_dmg(), position.x)

# ---------------------------------------------------------------- prologue God
func _tick_prologue(dt: float) -> void:
	_run_queue(dt)
	if frozen:
		return
	var p = game.player
	p_spear_t -= dt
	if p_spear_t <= 0.0:
		p_spear_t = 1.5
		Hazard.pillar(game, p.position.x, 26.0, 0.8, 0.22, 1, Color(1.0, 0.92, 0.5), "spear")
		Hazard.pillar(game, clampf(p.position.x + randf_range(-240.0, 240.0), 40.0, 900.0), 26.0, 0.8, 0.22, 1, Color(1.0, 0.92, 0.5), "spear")
	p_wave_t -= dt
	if p_wave_t <= 0.0:
		p_wave_t = 4.6
		Hazard.wave(game, position.x - 100.0, -330.0, 46.0, 1, Color(1.0, 0.88, 0.4))
		game.sfx.play("boom", -8.0)
		game.shake_add(5.0)

# ---------------------------------------------------------------- drawing
func _c(base: Color) -> Color:
	return base.lerp(Color.WHITE, flash * 0.7)

func _poly(cx: float, cy: float, rx: float, ry: float, n: int = 20, wob: float = 0.0, ph: float = 0.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * float(i) / float(n)
		var k := 1.0 + wob * sin(a * 3.0 + ph)
		pts.append(Vector2(cx + cos(a) * rx * k, cy + sin(a) * ry * k))
	return pts

func _mirror(pts: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(pts.size() - 1, -1, -1):
		out.append(Vector2(-pts[i].x, pts[i].y))
	return out

func _eyes(y: float, gap: float, r: float, c: Color) -> void:
	draw_circle(Vector2(-gap, y), r * 1.7, Color(c.r, c.g, c.b, 0.3))
	draw_circle(Vector2(gap, y), r * 1.7, Color(c.r, c.g, c.b, 0.3))
	draw_circle(Vector2(-gap, y), r, c)
	draw_circle(Vector2(gap, y), r, c)
	draw_circle(Vector2(-gap, y), r * 0.4, Color.BLACK)
	draw_circle(Vector2(gap, y), r * 0.4, Color.BLACK)

func _draw() -> void:
	var wob := Vector2.ZERO
	if dying:
		wob = Vector2(randf_range(-6, 6), randf_range(-4, 4))
	var bob := sin(t * 2.2) * 4.0 if fly or prologue else 0.0
	# art is authored facing LEFT; flip when the player is on the right
	draw_set_transform(wob + Vector2(0, bob), 0.0, Vector2(-1.0 if face > 0 else 1.0, 1.0))
	var wr := wind_ratio()
	if wr > 0.0:
		var gr := maxf(size.x, size.y) * 0.62
		draw_circle(Vector2.ZERO, gr * (0.6 + 0.5 * wr), Color(acc.r, acc.g, acc.b, 0.22 * wr))
	if contact:
		draw_circle(Vector2.ZERO, maxf(size.x, size.y) * 0.58, Color(acc.r, acc.g, acc.b, 0.15))
	BossArt.draw(self)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if phase > 1 and not dying:
		draw_arc(Vector2.ZERO, maxf(size.x, size.y) * 0.62, 0.0, TAU, 40, Color(acc.r, acc.g, acc.b, 0.25 + 0.15 * sin(t * 6.0)), 3.0)

func _blink() -> void:
	var tx := clampf(game.player.position.x + (randf_range(220.0, 420.0) * (1.0 if randf() < 0.5 else -1.0)), 100.0, Cfg.W - 100.0)
	game.fx.burst(position, 14, acc, 220.0, 5.0, 0.4)
	position.x = tx
	game.fx.burst(position, 14, acc, 220.0, 5.0, 0.4)
