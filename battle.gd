class_name Battle
extends Node2D
## Undertale-style turn battle: menu -> timing attack -> bullet-hell dodge phase.
## Draws box / soul / bullets in the pixel world; menu text is drawn by GameUI.

var g
var active := false
var mode := "enter"
var mode_t := 0.0
var turn := 0
var menu_i := 0
var sub_i := 0
var sub_n := 0
var text := ""
var speech := ""
var speech_t := 0.0
var bt := 0.0

# box + soul
var box := Rect2(440, 360, 400, 180)
var box_goal := Rect2(440, 360, 400, 180)
var sp := Vector2(640, 450)
var sv := Vector2.ZERO
var blue := false
var gdir := Vector2.DOWN
var moving := false
var inv := 0.0
var soul_vis := true
var slam_t := 0.0

# fight bar
var bar_x := 0.0
var bar_dir := 1.0
var bar_speed := 1.5
var last_acc := 0.0

# boss info
var idx := 1
var D := 1.0
var elite := false
var kit: Array = []
var tired := false
var boss_name := ""
var max_hits := 0
var atk_mult := 1.0
var brace := 0
var taunt := 0
var items := 4
var rune_cd := [0, 0, 0, 0]
var skin := false
var thorns := false
var spare_ok := false
var spared := false

# bullets
var bl: Array = []
var plats: Array = []
var pats: Array = []
var pat_t := 0.0
var pat_len := 8.0
var lava := false
var boss_home := Vector2(640, 215)
var boss_k := 1.0
var hit_shake := 0.0
var dodge_t := 0.0
var end_t := 0.0
var force_pat: Array = []

const SPEECH := [
	"Is that all there is to you, little root?",
	"Hold still. This will only burn forever.",
	"You dig deep for a potato.",
	"Every seed I've buried stayed buried.",
	"Dodge. Dodge. Dodge. How tiring.",
	"Soil does not fight back.",
	"You should have rotted quietly.",
	"I have all the time in the world. You do not.",
]
const SPEECH_HURT := [
	"...Hm. You hit harder than a root should.",
	"Impressive. Irritating, but impressive.",
	"Stop. Stop smiling like that.",
]
const FLAVOR := [
	"The air is heavy with ash.",
	"%s watches your every move.",
	"You feel your roots tremble.",
	"Smells like burnt soil.",
	"%s tenses.",
	"* The potato glares back.",
]

const KITS := {
	"imp": ["rain", "aimed", "cross"],
	"wraith": ["homing", "spiral", "lasers"],
	"hound": ["cross", "sweep", "aimed"],
	"slime": ["rain", "ring", "blue_plat"],
	"duke": ["ring", "blasters", "sweep"],
	"torturer": ["blue_bones", "lasers", "cross"],
	"golem": ["sweep", "blue_plat", "ring"],
	"seraph": ["spiral", "lasers", "blasters"],
	"cherub": ["homing", "ring", "rain"],
	"knight": ["sweep", "blue_bones", "aimed"],
	"pillar": ["lasers", "blue_plat", "rain"],
	"ophanim": ["spiral", "ring", "orange_blue"],
	"archangel": ["blasters", "gravity_flip", "lasers", "spiral"],
	"satan": ["blasters", "gravity_flip", "lasers", "orange_blue", "spiral"],
	"god": ["blasters", "gravity_flip", "lasers", "orange_blue", "spiral"],
}
const COMBOS := [["blasters", "ring"], ["gravity_flip", "blasters"], ["lasers", "sweep", "homing"], ["spiral", "blue_bones"], ["orange_blue", "blasters"]]

# ---------------------------------------------------------------- setup
func place_boss(b) -> void:
	var s: Vector2 = b.size
	boss_k = clampf(240.0 / maxf(s.y, s.x * 0.85), 0.9, 2.4)
	b.scale = Vector2(boss_k, boss_k)
	b.position = boss_home
	b.face = -1
	b.modulate.a = 1.0

func start(b) -> void:
	idx = int(b.d.get("index", 1))
	boss_name = String(b.d["name"]).split(",")[0]
	D = lerpf(0.75, 1.5, clampf(float(idx - 1) / 49.0, 0.0, 1.0))
	elite = (idx % 5 == 0) or idx == 25 or idx == 50
	if elite:
		D *= 1.12
	var fam: String = String(b.fam)
	kit = (KITS.get(fam, ["rain", "aimed", "cross"]) as Array).duplicate()
	if idx >= 8 and not kit.has("orange_blue"):
		kit.append("orange_blue")
	if idx >= 15 and not kit.has("blasters"):
		kit.append("blasters")
	if idx >= 22 and not kit.has("blue_bones"):
		kit.append("blue_bones")
	if idx >= 32 and not kit.has("gravity_flip"):
		kit.append("gravity_flip")
	# boss hp scaled to the timing-bar damage
	var hp := 90.0 + 23.0 * idx
	if elite:
		hp *= 1.25
	b.max_hp = hp
	b.hp = hp
	b.twists.clear()
	place_boss(b)
	active = true
	turn = 0
	tired = false
	spared = false
	atk_mult = 1.0
	brace = 0
	taunt = 0
	items = 4
	rune_cd = [0, 0, 0, 0]
	skin = false
	thorns = false
	bl.clear()
	plats.clear()
	pats.clear()
	blue = false
	gdir = Vector2.DOWN
	inv = 0.0
	end_t = 0.0
	menu_i = 0
	box = Rect2(640, 450, 2, 2)
	box_goal = Rect2(440, 360, 400, 180)
	sp = Vector2(640, 450)
	sv = Vector2.ZERO
	g.player.visible = false
	g.player.locked = true
	g.player.iframes = 0.0
	_mode("enter")
	text = "* %s draws near!" % boss_name
	g.sfx.play("roar", -6.0, 1.3)

func end_battle() -> void:
	active = false
	bl.clear()
	plats.clear()
	pats.clear()
	g.player.visible = true
	g.player.locked = true
	if g.boss != null:
		g.boss.scale = Vector2.ONE

func _mode(m: String) -> void:
	mode = m
	mode_t = 0.0

# ---------------------------------------------------------------- helpers
func _cx() -> Vector2:
	return box.get_center()

func _tgt_box(w: float, h: float) -> void:
	box_goal = Rect2(640.0 - w * 0.5, 540.0 - h, w, h)

func _fl(x) -> float:
	return float(x)

func orb(p: Vector2, v: Vector2, r: float = 7.0, col: String = "w", extra: Dictionary = {}) -> void:
	var d := {"k": "c", "p": p, "v": v, "r": r, "c": col, "life": 9.0, "a": Vector2.ZERO}
	for k in extra:
		d[k] = extra[k]
	bl.append(d)

func bone(c: Vector2, sz: Vector2, v: Vector2, col: String = "w", extra: Dictionary = {}) -> void:
	var d := {"k": "r", "p": c, "v": v, "s": sz, "c": col, "life": 9.0, "a": Vector2.ZERO}
	for k in extra:
		d[k] = extra[k]
	bl.append(d)

func beam(a: Vector2, b: Vector2, w: float, tele: float, dur: float) -> void:
	bl.append({"k": "s", "p": a, "q": b, "w": w, "tele": tele, "dur": dur, "t": 0.0, "c": "w", "v": Vector2.ZERO, "life": tele + dur + 0.1})

func skull(p: Vector2, target: Vector2, tele: float, dur: float, w: float) -> void:
	var dir := (target - p).normalized()
	bl.append({"k": "sk", "p": p, "dir": dir, "w": w, "tele": tele, "dur": dur, "t": 0.0, "c": "w", "v": Vector2.ZERO, "life": tele + dur + 0.2})

func _lp(l: Vector2) -> Vector2:
	var ang := gdir.angle() - PI * 0.5
	return _cx() + l.rotated(ang)

func _lv(l: Vector2) -> Vector2:
	return l.rotated(gdir.angle() - PI * 0.5)

func _lsz(s: Vector2) -> Vector2:
	if absf(gdir.x) > 0.5:
		return Vector2(s.y, s.x)
	return s

func _say(s: String, dur: float = 2.2) -> void:
	speech = s
	speech_t = dur

# ---------------------------------------------------------------- main tick
func tick(dt: float) -> void:
	if not active:
		return
	bt += dt
	mode_t += dt
	queue_redraw()
	if speech_t > 0.0:
		speech_t -= dt
	hit_shake = maxf(0.0, hit_shake - dt * 3.0)
	dodge_t = maxf(0.0, dodge_t - dt)
	inv = maxf(0.0, inv - dt)
	for i in 4:
		rune_cd[i] = maxi(0, int(rune_cd[i]))
	box.position = box.position.lerp(box_goal.position, 1.0 - exp(-14.0 * dt))
	box.size = box.size.lerp(box_goal.size, 1.0 - exp(-14.0 * dt))
	var b = g.boss
	if b != null:
		b.position = boss_home + Vector2(sin(bt * 1.4) * 10.0 + (hit_shake * randf_range(-10.0, 10.0)), sin(bt * 2.1) * 5.0 + dodge_t * 0.0)
		if dodge_t > 0.0:
			b.position.x += sin(dodge_t * 9.0) * 90.0 * minf(dodge_t, 1.0)
		b.face = -1
		b.tick(dt)
	match mode:
		"enter": _m_enter(dt)
		"menu": _m_menu()
		"fightbar": _m_fightbar(dt)
		"hit": _m_hit()
		"act": _m_sub(false)
		"item": _m_sub(false)
		"mercy": _m_sub(false)
		"result": _m_result()
		"speech": _m_speech()
		"attack": _m_attack(dt)
		"win": _m_win(dt)

func _p():
	return g.player

func _acc_pressed() -> bool:
	return Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("ui_accept")

func _cancel_pressed() -> bool:
	return Input.is_action_just_pressed("roll") or Input.is_action_just_pressed("ui_cancel")

func _left() -> bool:
	return Input.is_action_just_pressed("move_left")

func _right() -> bool:
	return Input.is_action_just_pressed("move_right")

func _up() -> bool:
	return Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("ui_up")

func _down() -> bool:
	return Input.is_action_just_pressed("move_down") or Input.is_action_just_pressed("ui_down")

func _m_enter(dt: float) -> void:
	sp = sp.lerp(_cx(), 1.0 - exp(-8.0 * dt))
	if mode_t > 1.5:
		_to_menu()

func _to_menu() -> void:
	bl.clear()
	plats.clear()
	blue = false
	gdir = Vector2.DOWN
	_tgt_box(520, 170)
	var b = g.boss
	var fl: String = FLAVOR[randi() % FLAVOR.size()]
	if fl.contains("%s"):
		fl = fl % boss_name
	if not fl.begins_with("*"):
		fl = "* " + fl
	if b != null and b.hp < b.max_hp * 0.4:
		fl = "* %s is weakening. Mercy is possible." % boss_name
	if tired:
		fl = "* %s is exhausted. Now's your chance." % boss_name
	text = fl
	spare_ok = b != null and b.hp <= b.max_hp * 0.4
	_mode("menu")

func _m_menu() -> void:
	if g.autotest:
		if mode_t > 0.1:
			_start_fightbar()
		return
	if _left():
		menu_i = (menu_i + 3) % 4
		g.sfx.play("select")
	if _right():
		menu_i = (menu_i + 1) % 4
		g.sfx.play("select")
	if _acc_pressed():
		g.sfx.play("pickup")
		match menu_i:
			0: _start_fightbar()
			1:
				sub_i = 0
				sub_n = 1 + 2 + _unlocked_runes().size()
				_mode("act")
			2:
				sub_i = 0
				sub_n = 1
				_mode("item")
			3:
				sub_i = 0
				sub_n = 2
				_mode("mercy")

func _unlocked_runes() -> Array:
	var out: Array = []
	for r in range(0, 4):
		if g.runes[r]:
			out.append(r)
	return out

func act_labels() -> Array:
	var l: Array = ["CHECK", "TAUNT", "BRACE"]
	for r in _unlocked_runes():
		var nm: String = ["BRAMBLE", "BRIMSTONE", "SMITE", "STONESKIN"][r]
		var cd: int = int(rune_cd[r])
		l.append(nm + ("  (%d)" % cd if cd > 0 else ""))
	return l

func item_labels() -> Array:
	return ["ROOT POULTICE x%d  (+3 HP)" % items]

func mercy_labels() -> Array:
	return ["SPARE" + ("" if spare_ok else "  (not ready)"), "FLEE  (impossible)"]

func _m_sub(_x: bool) -> void:
	if g.autotest:
		_start_fightbar()
		return
	if _cancel_pressed():
		_mode("menu")
		return
	if _up():
		sub_i = (sub_i + sub_n - 1) % sub_n
		g.sfx.play("select")
	if _down():
		sub_i = (sub_i + 1) % sub_n
		g.sfx.play("select")
	if not _acc_pressed():
		return
	g.sfx.play("pickup")
	var b = g.boss
	var p = _p()
	if mode == "act":
		match sub_i:
			0:
				text = "* %s — ATK %d  DEF %d\n* %s" % [String(b.d["label"]).to_upper(), 4 + idx * 2, idx, String(b.d["intro"]).substr(0, 90)]
				_after_action()
			1:
				taunt = 2
				atk_mult = 1.0
				text = "* You taunt %s. Its attacks quicken... but your next strike lands harder." % boss_name
				_after_action()
			2:
				brace = 3
				text = "* You brace. The next hit you take is halved."
				_after_action()
			_:
				var r: int = _unlocked_runes()[sub_i - 3]
				if int(rune_cd[r]) > 0:
					g.sfx.play("hurt", -8.0)
					return
				_use_rune(r)
				rune_cd[r] = [1, 2, 3, 3][r]
				_after_action()
	elif mode == "item":
		if items <= 0:
			text = "* No poultices left."
			g.sfx.play("hurt", -8.0)
			_after_action()
			return
		items -= 1
		p.hp = mini(p.max_hp, p.hp + 3)
		text = "* You apply a Root Poultice. HP restored."
		g.sfx.play("pickup", 0.0, 1.4)
		_after_action()
	elif mode == "mercy":
		if sub_i == 0 and spare_ok:
			_do_spare()
		elif sub_i == 0:
			text = "* %s isn't ready to yield." % boss_name
			_after_action()
		else:
			text = "* There is nowhere to run."
			_after_action()

func _use_rune(r: int) -> void:
	var b = g.boss
	var p = _p()
	match r:
		0:
			var dmg: float = p.damage * 1.2
			_damage_boss(dmg, "BRAMBLE")
			text = "* Roots erupt beneath %s!" % boss_name
		1:
			atk_mult = 2.0
			text = "* Brimstone Wrath ignites your blade. Next strike x2."
		2:
			p.hp = mini(p.max_hp, p.hp + 2)
			_damage_boss(p.damage * 0.8, "SMITE")
			text = "* Golden lightning! HP restored."
		3:
			skin = true
			text = "* Your skin turns to stone. Block the next hit."

func _after_action() -> void:
	if mode != "win":
		_mode("result")

func _m_result() -> void:
	if g.autotest:
		_begin_speech()
		return
	if mode_t > 1.6 or (mode_t > 0.4 and _acc_pressed()):
		_begin_speech()

func _begin_speech() -> void:
	if g.boss != null and g.boss.dying:
		return
	var s: String = SPEECH[(turn + idx) % SPEECH.size()]
	if g.boss != null and g.boss.hp < g.boss.max_hp * 0.5:
		s = SPEECH_HURT[(turn + idx) % SPEECH_HURT.size()]
	if tired:
		s = "...heh. You're persistent."
	_say(s, 2.0)
	_mode("speech")

func _m_speech() -> void:
	if mode_t > 2.0 or g.autotest:
		_begin_pattern()

# ---- fight bar
func _start_fightbar() -> void:
	bar_x = 0.0
	bar_dir = 1.0
	bar_speed = 1.35 + 0.4 * D if not tired else 0.9
	_tgt_box(520, 170)
	_mode("fightbar")

func _m_fightbar(dt: float) -> void:
	bar_x += bar_dir * bar_speed * dt
	if g.autotest:
		bar_x = 0.5
		last_acc = 1.0
		_do_attack()
		return
	if bar_x >= 1.0:
		bar_x = 1.0
		bar_dir = -1.0
	if bar_x <= 0.0 and mode_t > 0.1:
		bar_x = 0.0
		bar_dir = 1.0
	if mode_t > 4.5 or (_acc_pressed() and mode_t > 0.15):
		last_acc = clampf(1.0 - absf(bar_x - 0.5) * 2.0, 0.0, 1.0)
		if mode_t > 4.5:
			last_acc = 0.0
		_do_attack()

func _do_attack() -> void:
	var b = g.boss
	var p = _p()
	var dmg: float = p.damage * 2.5 * (0.25 + 0.75 * last_acc) * atk_mult
	if last_acc > 0.9:
		dmg *= 1.4
	if tired:
		dmg *= 2.0
	if taunt > 0:
		dmg *= 1.25
	atk_mult = 1.0
	# elite bosses dodge the first strikes until they tire
	if elite and not tired and turn < 3 and not g.autotest:
		dodge_t = 1.2
		g.fx.popup(b.position + Vector2(0, -120), "MISS", Color(0.8, 0.8, 0.9))
		g.sfx.play("select", -4.0, 0.6)
		text = "* %s casually steps aside." % boss_name
		_mode("hit")
		return
	_damage_boss(dmg, "CRIT" if last_acc > 0.9 else "")
	g.sfx.play("hurt", -3.0, 1.5)
	if mode != "win":
		_mode("hit")

func _damage_boss(dmg: float, tag: String) -> void:
	var b = g.boss
	b.hp -= dmg
	b.flash = 1.0
	hit_shake = 1.0
	g.shake_add(8.0)
	g.fx.popup(b.position + Vector2(randf_range(-30, 30), -130), str(int(dmg)) + (" " + tag if tag != "" else ""), Color(1, 1, 0.6))
	g.fx.burst(b.position, 12, b.acc, 260.0, 5.0, 0.5)
	if b.hp <= 0.0:
		b.hp = 0.0
		_victory(false)

func _m_hit() -> void:
	if g.autotest:
		if mode_t > 0.1:
			_begin_speech()
		return
	if mode_t > 1.1:
		_begin_speech()

func _do_spare() -> void:
	spared = true
	_victory(true)

func _victory(was_spared: bool) -> void:
	if mode == "win":
		return
	spared = was_spared
	g.spared = was_spared
	bl.clear()
	_mode("win")
	var b = g.boss
	if was_spared:
		text = "* You spared %s." % boss_name
		g.fx.ring(b.position, 200.0, Color(1, 1, 0.8), 0.9)
		g.sfx.play("pickup", 0.0, 0.8)
	else:
		text = "* %s is defeated." % boss_name
	end_t = 0.0

func _m_win(dt: float) -> void:
	end_t += dt
	if end_t > 1.4 and active:
		var b = g.boss
		end_battle()
		b.dying = true
		b.die_t = 0.0
		b.queue.clear()
		g.on_boss_dead()

# ---------------------------------------------------------------- bullet phase
func _begin_pattern() -> void:
	turn += 1
	bl.clear()
	plats.clear()
	pats.clear()
	var names: Array = []
	var special := elite and turn >= 5 and turn % 3 == 0
	if special:
		names = (COMBOS[(idx + turn) % COMBOS.size()] as Array).duplicate()
		_say("Time to end this.", 1.6)
	elif tired:
		names = [kit[randi() % kit.size()]]
	else:
		var pick: String = kit[(turn + idx) % kit.size()]
		if randf() < 0.5:
			pick = kit[randi() % kit.size()]
		names = [pick]
		if idx >= 30 and randf() < 0.35 and not special:
			var second: String = kit[randi() % kit.size()]
			if second != pick and not _blue_name(second) and not _blue_name(pick):
				names.append(second)
	if force_pat.size() > 0:
		names = force_pat.duplicate()
	blue = false
	gdir = Vector2.DOWN
	var w := lerpf(440.0, 300.0, clampf(float(idx) / 50.0, 0.0, 1.0))
	var h := 170.0
	for n in names:
		pats.append({"n": n, "t": 0.0, "a": 0.0, "b": 0.0, "i": 0, "x": 0.0})
		if _blue_name(n):
			blue = true
			w = maxf(w, 500.0)
		if n == "sweep" or n == "cross" or n == "orange_blue":
			w = maxf(w, 480.0)
		if n == "blue_plat":
			h = 200.0
		if n == "blasters" or n == "lasers":
			w = maxf(w, 380.0)
	if special:
		w = 340.0
	_tgt_box(w, h)
	if tired:
		w += 80.0
	if g.autotest:
		pat_len = 0.6
	else:
		pat_len = (7.0 + 4.0 * clampf(float(idx) / 50.0, 0.0, 1.0)) * (0.6 if tired else 1.0) + (4.0 if special else 0.0)
	pat_t = 0.0
	box = box_goal
	sp = _cx()
	sv = Vector2.ZERO
	if blue:
		sp = _cx() + Vector2(0, box.size.y * 0.5 - 8.0)
	if pats.size() > 0 and pats[0]["n"] == "blue_plat":
		lava = true
		plats.append({"r": Rect2(sp.x - 42.0, sp.y - 30.0, 84.0, 8.0), "v": 60.0})
	else:
		lava = false
	text = ""
	_mode("attack")
	g.sfx.play("select", -3.0, 0.5)

func _blue_name(n: String) -> bool:
	return n == "blue_bones" or n == "blue_plat" or n == "gravity_flip"

func _m_attack(dt: float) -> void:
	pat_t += dt
	_soul_step(dt)
	for pp in pats:
		_pat_tick(pp, dt)
	_bullets_step(dt)
	if g.autotest:
		_p().iframes = 99.0
	if pat_t >= pat_len:
		bl.clear()
		plats.clear()
		if taunt > 0:
			taunt -= 1
		if elite and not tired and turn >= 6 and turn % 3 == 0:
			tired = true
			g.fx.ring(g.boss.position, 260.0, g.boss.acc, 0.8)
			g.sfx.play("roar", -4.0, 0.6)
		_to_menu()

# soul physics ---------------------------------------------------------
func _soul_step(dt: float) -> void:
	var ang := gdir.angle() - PI * 0.5
	var ix := Input.get_axis("move_left", "move_right")
	var iy := (1.0 if Input.is_action_pressed("move_down") else 0.0) - (1.0 if Input.is_action_pressed("jump") else 0.0)
	var iv := Vector2(ix, iy)
	var spd := 250.0 * (0.45 if Input.is_action_pressed("roll") else 1.0)
	var half := box.size * 0.5
	if absf(gdir.x) > 0.5:
		half = Vector2(half.y, half.x)
	var loc := (sp - _cx()).rotated(-ang)
	var li := iv.rotated(-ang)
	if not blue:
		loc += li * spd * dt
		sv = Vector2.ZERO
		moving = iv.length() > 0.1
	else:
		loc.x += li.x * spd * dt
		var floor_y := half.y - 7.0
		var on_floor := loc.y >= floor_y - 0.5
		var on_plat := false
		for pl in plats:
			var r: Rect2 = pl["r"]
			var lr := Rect2((r.position - _cx()).rotated(-ang) if ang == 0.0 else r.position - _cx(), r.size)
			if ang == 0.0 and loc.y <= lr.position.y + 2.0 and loc.y + sv.y * dt >= lr.position.y - 1.0 and loc.x > lr.position.x - 4.0 and loc.x < lr.end.x + 4.0 and sv.y >= 0.0:
				loc.y = lr.position.y - 1.0
				sv.y = 0.0
				on_plat = true
				loc.x += float(pl["v"]) * dt
		var grounded := on_floor or on_plat
		if lava:
			grounded = on_plat
		if grounded and li.y < -0.5 and (on_plat or on_floor):
			sv.y = -540.0
		if sv.y < 0.0 and li.y > -0.5:
			sv.y *= 0.55 if sv.y < -140.0 else 1.0
		sv.y += 1500.0 * dt
		loc.y += sv.y * dt
		if loc.y >= floor_y and not lava:
			loc.y = floor_y
			sv.y = 0.0
		if lava and loc.y >= floor_y:
			loc.y = floor_y
			sv.y = 0.0
		moving = absf(li.x) > 0.1 or absf(sv.y) > 20.0
	loc.x = clampf(loc.x, -half.x + 8.0, half.x - 8.0)
	loc.y = clampf(loc.y, -half.y + 8.0, half.y - 8.0)
	sp = _cx() + loc.rotated(ang)

func hurt_soul(d: int) -> void:
	if inv > 0.0 or mode != "attack":
		return
	var p = _p()
	if skin:
		skin = false
		inv = 1.0
		g.fx.popup(sp + Vector2(0, -24), "BLOCKED", Color(0.8, 0.85, 0.95))
		g.sfx.play("stone", 0.0, 0.7)
		return
	if p.armor_shield > 0:
		p.armor_shield -= 1
		inv = 1.0
		g.fx.popup(sp + Vector2(0, -24), "ARMOUR", Color(0.85, 0.9, 1.0))
		g.sfx.play("stone", 0.0, 1.1)
		return
	if brace > 0:
		brace = 0
		d = maxi(1, d / 2)
	d = int(maxf(1.0, float(d)))
	p.hp -= d
	inv = 1.1
	g.sfx.play("hurt")
	g.shake_add(7.0)
	g.red_flash = 0.35
	g.fx.burst(sp, 10, Color(1, 0.2, 0.2), 200.0, 4.0, 0.4, 100.0)
	if p.hp <= 0:
		p.hp = 0
		p.dead = true
		p.visible = true
		end_battle()
		g.fx.burst(sp, 30, Color(1, 0.2, 0.25), 360.0, 6.0, 0.8, 400.0)
		g.on_player_dead()

func _bullets_step(dt: float) -> void:
	var dmg: int = 2 if idx >= 44 else 1
	var keep: Array = []
	for b in bl:
		b["life"] = float(b["life"]) - dt
		var k: String = b["k"]
		if b.get("delay", 0.0) > 0.0:
			b["delay"] = float(b["delay"]) - dt
			keep.append(b)
			continue
		if k == "s" or k == "sk":
			b["t"] = float(b["t"]) + dt
			var t: float = b["t"]
			if t > float(b["tele"]) and t < float(b["tele"]) + float(b["dur"]):
				if _hit_beam(b):
					_hurt_by(b, dmg)
			if float(b["life"]) > 0.0:
				keep.append(b)
			continue
		var v: Vector2 = b["v"]
		if b.get("home", 0.0) > 0.0:
			var to := (sp - Vector2(b["p"])).normalized()
			v = v.normalized().slerp(to, clampf(float(b["home"]) * dt, 0.0, 1.0)) * v.length()
		v += Vector2(b["a"]) * dt
		b["v"] = v
		b["p"] = Vector2(b["p"]) + v * dt
		var pp: Vector2 = b["p"]
		if float(b["life"]) <= 0.0 or pp.x < -160.0 or pp.x > Cfg.W + 160.0 or pp.y < -160.0 or pp.y > Cfg.H + 160.0:
			continue
		if _hit_bullet(b):
			_hurt_by(b, dmg)
		keep.append(b)
	bl = keep
	for pl in plats:
		var r: Rect2 = pl["r"]
		r.position.x += float(pl["v"]) * dt
		if r.position.x > box.end.x:
			r.position.x = box.position.x - r.size.x
		pl["r"] = r
	if lava and sp.y >= box.end.y - 14.0:
		hurt_soul(dmg)

func _hurt_by(b: Dictionary, d: int) -> void:
	var c: String = b["c"]
	if c == "b" and not moving:
		return
	if c == "o" and moving:
		return
	hurt_soul(d)

func _hit_bullet(b: Dictionary) -> bool:
	var c: String = b["c"]
	if c == "b" and not moving:
		return false
	if c == "o" and moving:
		return false
	var p: Vector2 = b["p"]
	if b["k"] == "c":
		return p.distance_to(sp) < float(b["r"]) + 4.0
	var s: Vector2 = b["s"]
	var r := Rect2(p - s * 0.5, s).grow(-1.0)
	var q := Vector2(clampf(sp.x, r.position.x, r.end.x), clampf(sp.y, r.position.y, r.end.y))
	return q.distance_to(sp) < 4.5

func _hit_beam(b: Dictionary) -> bool:
	var a: Vector2
	var e: Vector2
	if b["k"] == "s":
		a = b["p"]
		e = b["q"]
	else:
		a = b["p"]
		e = a + Vector2(b["dir"]) * 1800.0
	var ab := e - a
	var tt := clampf((sp - a).dot(ab) / maxf(ab.length_squared(), 1.0), 0.0, 1.0)
	return (a + ab * tt).distance_to(sp) < float(b["w"]) * 0.5 + 3.0

# ---------------------------------------------------------------- patterns
func _rx() -> float:
	return randf_range(box.position.x + 14.0, box.end.x - 14.0)

func _pat_tick(pp: Dictionary, dt: float) -> void:
	pp["t"] = float(pp["t"]) + dt
	pp["a"] = float(pp["a"]) - dt
	var n: String = pp["n"]
	var t: float = pp["t"]
	var ready: bool = pp["a"] <= 0.0
	var top := box.position.y - 28.0
	var left := box.position.x
	var right := box.end.x
	var bot := box.end.y
	var hh := box.size.y
	match n:
		"rain":
			if ready:
				pp["a"] = 0.26 / D
				orb(Vector2(_rx(), top), Vector2(0, 200.0 * D), 7.0)
				if randf() < 0.25:
					orb(Vector2(_rx(), top), Vector2(0, 150.0 * D), 7.0, "o" if randf() < 0.5 else "b")
		"aimed":
			if ready:
				pp["a"] = 0.95 / D
				var from := Vector2(boss_home.x + randf_range(-80, 80), boss_home.y + 40.0)
				var base := (sp - from).angle()
				var cnt := 3 + int(D * 2.0)
				for i in cnt:
					var ang := base + (float(i) - float(cnt - 1) * 0.5) * 0.28
					orb(from, Vector2.from_angle(ang) * 270.0 * D, 6.0)
		"ring":
			if ready:
				pp["a"] = 1.25 / D
				var c := Vector2(_cx().x + randf_range(-130, 130), top - 10.0)
				var cnt := 16 + int(D * 6.0)
				pp["b"] = float(pp["b"]) + 0.37
				for i in cnt:
					var ang := float(pp["b"]) + TAU * float(i) / float(cnt)
					orb(c, Vector2.from_angle(ang) * 150.0 * D, 6.0)
		"spiral":
			if ready:
				pp["a"] = 0.07 / D
				pp["b"] = float(pp["b"]) + 0.31
				var c := Vector2(_cx().x, top - 14.0)
				for arm in 3:
					var ang := float(pp["b"]) + TAU * float(arm) / 3.0
					orb(c, Vector2.from_angle(ang) * 175.0 * D, 5.0)
		"sweep":
			if ready:
				pp["a"] = 1.6 / D
				var from_left: bool = int(pp["i"]) % 2 == 0
				pp["i"] = int(pp["i"]) + 1
				var gap := randf_range(box.position.y + 40.0, bot - 40.0)
				var y := box.position.y + 6.0
				while y < bot - 4.0:
					if absf(y - gap) > 34.0:
						orb(Vector2(left - 24.0 if from_left else right + 24.0, y), Vector2((1.0 if from_left else -1.0) * 175.0 * D, 0), 7.0)
					y += 20.0
		"cross":
			if ready:
				pp["a"] = 0.33 / D
				var side := 1.0 if randf() < 0.5 else -1.0
				var col := "w"
				var r := randf()
				if r < 0.2:
					col = "o"
				elif r < 0.35:
					col = "b"
				orb(Vector2(left - 24.0 if side > 0.0 else right + 24.0, randf_range(box.position.y + 14.0, bot - 14.0)), Vector2(side * 240.0 * D, 0), 7.0, col)
		"lasers":
			if ready:
				pp["a"] = 1.5 / D
				var kind := randi() % 3
				var tl := 0.8 / (0.8 + 0.2 * D)
				if kind == 0:
					beam(Vector2(left - 300.0, sp.y), Vector2(right + 300.0, sp.y), 30.0, tl, 0.32)
				elif kind == 1:
					beam(Vector2(sp.x, top - 200.0), Vector2(sp.x, bot + 200.0), 30.0, tl, 0.32)
				else:
					var d2 := Vector2.from_angle(randf_range(0.3, 1.2) * (1.0 if randf() < 0.5 else -1.0))
					beam(sp - d2 * 600.0, sp + d2 * 600.0, 28.0, tl, 0.32)
		"homing":
			if ready:
				pp["a"] = 1.3 / D
				orb(Vector2(_rx(), top), Vector2(0, 110.0 * D), 8.0, "w", {"home": 1.5, "life": 4.2})
			if float(pp["x"]) <= 0.0:
				pp["x"] = 0.55
				orb(Vector2(_rx(), top), Vector2(0, 170.0 * D), 5.0)
			pp["x"] = float(pp["x"]) - dt
		"blasters":
			if ready:
				pp["a"] = 1.55 / D
				var ang := randf() * TAU
				var from := _cx() + Vector2.from_angle(ang) * randf_range(260.0, 330.0)
				from.x = clampf(from.x, 60.0, Cfg.W - 60.0)
				from.y = clampf(from.y, 60.0, Cfg.H - 120.0)
				skull(from, sp, 0.85 / (0.85 + 0.15 * D), 0.38, 46.0)
		"orange_blue":
			if ready:
				pp["a"] = 1.15 / D
				var from_left2: bool = int(pp["i"]) % 2 == 0
				pp["i"] = int(pp["i"]) + 1
				var col2 := "b" if (int(pp["i"]) / 2) % 2 == 0 else "o"
				bone(Vector2(left - 20.0 if from_left2 else right + 20.0, box.get_center().y), Vector2(22.0, hh), Vector2((1.0 if from_left2 else -1.0) * 150.0 * D, 0), col2)
				if randf() < 0.6:
					orb(Vector2(_rx(), top), Vector2(0, 170.0 * D), 6.0)
		"blue_bones":
			if ready:
				pp["a"] = 0.95 / D
				var hgt := randf_range(34.0, 78.0)
				var r2 := randf()
				if r2 < 0.65:
					bone(_lp(Vector2(box.size.x * 0.5 + 24.0, box.size.y * 0.5 - hgt * 0.5)), _lsz(Vector2(18.0, hgt)), _lv(Vector2(-250.0 * D, 0)))
				else:
					var gap2 := 66.0
					var ch := box.size.y - gap2 - 4.0
					bone(_lp(Vector2(box.size.x * 0.5 + 24.0, -box.size.y * 0.5 + ch * 0.5)), _lsz(Vector2(18.0, ch)), _lv(Vector2(-250.0 * D, 0)))
		"blue_plat":
			if ready:
				pp["a"] = 1.9 / D
				var yy := randf_range(box.position.y + 50.0, bot - 40.0)
				plats.append({"r": Rect2(left - 80.0, yy, 80.0, 8.0), "v": 70.0 + 20.0 * D})
				orb(Vector2(right + 20.0, randf_range(box.position.y + 20.0, bot - 50.0)), Vector2(-210.0 * D, 0), 7.0)
		"gravity_flip":
			if pp["i"] == 0 or t > float(pp["i"]) * 2.6:
				pp["i"] = int(pp["i"]) + 1
				if int(pp["i"]) > 1:
					var dirs := [Vector2.DOWN, Vector2.LEFT, Vector2.UP, Vector2.RIGHT]
					var nd: Vector2 = dirs[randi() % 4]
					if nd == gdir:
						nd = Vector2.DOWN if gdir != Vector2.DOWN else Vector2.UP
					gdir = nd
					sv = Vector2(0, 700.0)
					g.sfx.play("stone", 0.0, 0.8)
					g.shake_add(6.0)
					bl.clear()
				else:
					gdir = Vector2.DOWN
			if ready:
				pp["a"] = 0.9 / D
				var hg := randf_range(36.0, 70.0)
				bone(_lp(Vector2(_wide() * 0.5 + 24.0, _high() * 0.5 - hg * 0.5)), _lsz(Vector2(18.0, hg)), _lv(Vector2(-240.0 * D, 0)))

func _wide() -> float:
	return box.size.y if absf(gdir.x) > 0.5 else box.size.x

func _high() -> float:
	return box.size.x if absf(gdir.x) > 0.5 else box.size.y

# ---------------------------------------------------------------- drawing
func _heart(c: Vector2, s: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * float(i) / 24.0
		var x := 16.0 * pow(sin(a), 3.0)
		var y := -(13.0 * cos(a) - 5.0 * cos(2.0 * a) - 2.0 * cos(3.0 * a) - cos(4.0 * a))
		pts.append(c + Vector2(x, y) * s * 0.42)
	draw_colored_polygon(pts, col)
	pts.append(pts[0])
	draw_polyline(pts, Color(0.05, 0.0, 0.0), 1.5)
	# potato: tan patch and eyes on the soul
	draw_circle(c + Vector2(0, -0.5 * s), 2.6 * s, Color(0.76, 0.6, 0.38))
	draw_rect(Rect2(c + Vector2(-1.8, -1.6) * s, Vector2(1.0, 1.0) * s), Color(0.1, 0.05, 0.03))
	draw_rect(Rect2(c + Vector2(0.9, -1.6) * s, Vector2(1.0, 1.0) * s), Color(0.1, 0.05, 0.03))

func heart_at(ci: CanvasItem, c: Vector2, s: float, col: Color) -> void:
	pass

func _col(c: String) -> Color:
	if c == "b":
		return Color(0.25, 0.6, 1.0)
	if c == "o":
		return Color(1.0, 0.6, 0.15)
	return Color(1, 1, 1)

func _draw() -> void:
	if not active:
		return
	# dim the arena behind the box
	draw_rect(Rect2(0, 340, Cfg.W, 220), Color(0, 0, 0, 0.35))
	draw_rect(box, Color(0, 0, 0))
	draw_rect(box, Color(1, 1, 1), false, 4.0)
	if lava:
		draw_rect(Rect2(box.position.x + 2.0, box.end.y - 16.0, box.size.x - 4.0, 14.0), Color(1.0, 0.35, 0.05, 0.9))
	for pl in plats:
		var r: Rect2 = pl["r"]
		draw_rect(r, Color(0.3, 0.9, 0.3))
	for b in bl:
		var k: String = b["k"]
		var col := _col(b["c"])
		if b.get("delay", 0.0) > 0.0:
			continue
		if k == "c":
			draw_circle(b["p"], float(b["r"]) + 2.0, Color(col.r, col.g, col.b, 0.3))
			draw_circle(b["p"], float(b["r"]), col)
			draw_circle(b["p"], float(b["r"]) * 0.45, Color(0.1, 0.1, 0.12))
		elif k == "r":
			var s: Vector2 = b["s"]
			var r := Rect2(Vector2(b["p"]) - s * 0.5, s)
			draw_rect(r, col)
			draw_rect(r, Color(0.1, 0.1, 0.12), false, 2.0)
		elif k == "s":
			var tt: float = b["t"]
			var tl: float = b["tele"]
			if tt < tl:
				var a := 0.35 + 0.35 * sin(tt * 40.0)
				draw_line(b["p"], b["q"], Color(1, 0.2, 0.2, a), 4.0)
			elif tt < tl + float(b["dur"]):
				draw_line(b["p"], b["q"], Color(1, 1, 1), float(b["w"]))
				draw_line(b["p"], b["q"], Color(1, 0.8, 0.6, 0.5), float(b["w"]) * 1.5)
		elif k == "sk":
			var p: Vector2 = b["p"]
			var dir: Vector2 = b["dir"]
			var tt2: float = b["t"]
			var tl2: float = b["tele"]
			_skull(p, dir)
			if tt2 < tl2:
				draw_line(p, p + dir * 1800.0, Color(1, 0.2, 0.2, 0.15 + 0.15 * sin(tt2 * 30.0)), 3.0)
			elif tt2 < tl2 + float(b["dur"]):
				draw_line(p + dir * 24.0, p + dir * 1800.0, Color(1, 1, 1), float(b["w"]))
				draw_line(p + dir * 24.0, p + dir * 1800.0, Color(0.6, 0.85, 1, 0.5), float(b["w"]) * 1.5)
	if mode == "enter" and mode_t < 0.7:
		var f := int(mode_t * 18.0) % 2
		draw_rect(Rect2(0, 0, Cfg.W, Cfg.H), Color(0, 0, 0, 0.85) if f == 0 else Color(1, 1, 1, 0.12))
	if mode == "attack" or mode == "enter":
		var vis := true
		if inv > 0.0 and int(inv * 14.0) % 2 == 0:
			vis = false
		if vis:
			_heart(sp, 1.7, Color(0.3, 0.6, 1.0) if blue else Color(0.95, 0.15, 0.2))

func _skull(p: Vector2, dir: Vector2) -> void:
	draw_set_transform(p, dir.angle() + PI, Vector2.ONE)
	draw_circle(Vector2.ZERO, 20.0, Color(0.95, 0.95, 0.95))
	draw_rect(Rect2(-18, -2, 20, 22), Color(0.95, 0.95, 0.95))
	draw_rect(Rect2(-8, -10, 8, 10), Color(0.05, 0.05, 0.08))
	draw_rect(Rect2(6, -10, 8, 10), Color(0.05, 0.05, 0.08))
	draw_rect(Rect2(-12, 10, 6, 10), Color(0.05, 0.05, 0.08))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
