class_name GameUI
extends Node2D
## All HUD / menu / cutscene overlay drawing. Reads state from Main (g).

var g
var font: Font

func _ready() -> void:
	font = PixFont.get_font()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

# ------------------------------------------------------------ helpers
func txt(s: String, pos: Vector2, size: int, col: Color = Color.WHITE, align: int = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1.0, outline: int = 5) -> void:
	size = _fs(size)
	if outline > 0:
		var k := float(size / 7)
		var oc := Color(0, 0, 0, col.a)
		for o in [Vector2(-k, 0), Vector2(k, 0), Vector2(0, -k), Vector2(0, k), Vector2(-k, -k), Vector2(k, k), Vector2(-k, k), Vector2(k, -k)]:
			draw_string(font, pos + o, s, align, width, size, oc)
	draw_string(font, pos, s, align, width, size, col)

func _fs(size: int) -> int:
	return maxi(14, int(size * 1.05) / 7 * 7)

func ctxt(s: String, y: float, size: int, col: Color = Color.WHITE, outline: int = 5) -> void:
	txt(s, Vector2(0, y), size, col, HORIZONTAL_ALIGNMENT_CENTER, Cfg.W, outline)

func wrap_lines(s: String, width: float, size: int) -> Array:
	var lines: Array = []
	for para in s.split("\n"):
		var cur := ""
		for word in para.split(" "):
			var test := word if cur == "" else cur + " " + word
			if font.get_string_size(test, HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(size)).x > width and cur != "":
				lines.append(cur)
				cur = word
			else:
				cur = test
		lines.append(cur)
	return lines

func wtxt(s: String, cx: float, y: float, width: float, size: int, col: Color = Color.WHITE, lh: float = 1.35) -> float:
	var lines: Array = wrap_lines(s, width, size)
	for i in lines.size():
		txt(lines[i], Vector2(cx - width * 0.5, y + i * size * lh), size, col, HORIZONTAL_ALIGNMENT_CENTER, width)
	return y + lines.size() * size * lh

func typed(s: String, speed: float = 42.0) -> String:
	return s.substr(0, int(g.st_t * speed))

func panel(rc: Rect2, a: float = 0.78, border: Color = Color(1, 1, 1, 0.25)) -> void:
	draw_rect(rc, Color(0.04, 0.03, 0.05, a))
	draw_rect(rc, border, false, 2.0)

# ------------------------------------------------------------ main draw
func _draw() -> void:
	if g == null:
		return
	var S = g.S
	match g.state:
		S.TITLE: _title()
		S.PROLOGUE: _hud(); _prologue_text()
		S.BEAM: _beam()
		S.CARD: _card()
		S.SHRINE: _shrine()
		S.INTRO: _hud(); _intro()
		S.FIGHT:
			if g.battle.active:
				_battle_ui()
			else:
				_hud()
		S.DYING: _hud()
		S.OUTRO: _outro()
		S.ACT_BREAK: _act_break()
		S.DEAD: _dead()
		S.ENDING: _ending()
		S.CINE: _cine()
	if g.special_banner_t > 0.0:
		var sa := clampf(g.special_banner_t, 0.0, 1.0)
		ctxt(g.special_banner, 118.0, 28, Color(1.0, 0.55, 0.3, sa), 4)
	if g.dark_t > 0.0 and g.state == g.S.FIGHT:
		draw_rect(Rect2(0, 0, Cfg.W, Cfg.H), Color(0, 0, 0, clampf(g.dark_t, 0.0, 1.0) * 0.55))
	if g.phase_banner_t > 0.0:
		var a := clampf(g.phase_banner_t, 0.0, 1.0)
		ctxt(g.phase_banner, 300.0, 54, Color(1, 0.85, 0.3, a))
	if g.msg_t > 0.0:
		ctxt(g.msg, 560.0, 22, Color(1, 0.9, 0.6, clampf(g.msg_t * 2.0, 0.0, 1.0)))
	if g.red_flash > 0.0:
		draw_rect(Rect2(0, 0, Cfg.W, Cfg.H), Color(0.8, 0.0, 0.0, g.red_flash * 0.35))
	if g.white_flash > 0.0:
		draw_rect(Rect2(0, 0, Cfg.W, Cfg.H), Color(1, 1, 1, clampf(g.white_flash, 0.0, 1.0)))
	if g.fade > 0.0:
		draw_rect(Rect2(0, 0, Cfg.W, Cfg.H), Color(0, 0, 0, clampf(g.fade, 0.0, 1.0)))
	if g.paused:
		draw_rect(Rect2(0, 0, Cfg.W, Cfg.H), Color(0, 0, 0, 0.6))
		ctxt("PAUSED", 300.0, 60)
		ctxt("ESC — resume        Q — return to title", 360.0, 24, Color(0.9, 0.9, 0.9))
		ctxt("Move A/D or arrows  •  Jump SPACE/W  •  Roll SHIFT/K  •  Slash J/Z/click  •  Runes 1-4  •  Drop through platform: S + jump", 420.0, 16, Color(0.8, 0.8, 0.8), 3)

# ------------------------------------------------------------ HUD
func _hud() -> void:
	var p: Player = g.player
	# HP
	for i in p.max_hp:
		var c := Vector2(28.0 + i * 21.0, 36.0)
		var full: bool = i < p.hp
		draw_circle(c, 9.0, Color("c9a062") if full else Color(0.15, 0.12, 0.1, 0.8))
		draw_arc(c, 9.0, 0, TAU, 16, Color("7d5a30") if full else Color(0.4, 0.3, 0.2), 2.0)
		if full:
			draw_circle(c + Vector2(-3, -2), 1.8, Color("8a6a3a"))
	# armour shield pips
	for i in p.armor_shield:
		var ac := Vector2(262.0 + i * 20.0, 38.0)
		draw_colored_polygon(PackedVector2Array([ac + Vector2(-8, -9), ac + Vector2(8, -9), ac + Vector2(8, 3), ac + Vector2(0, 10), ac + Vector2(-8, 3)]), Color(0.75, 0.8, 0.9))
		draw_polyline(PackedVector2Array([ac + Vector2(-8, -9), ac + Vector2(8, -9), ac + Vector2(8, 3), ac + Vector2(0, 10), ac + Vector2(-8, 3), ac + Vector2(-8, -9)]), Color(0.1, 0.1, 0.15), 2.0)
	# Stamina / energy
	_bar(Rect2(24, 58, 220, 10), p.stamina / p.max_stamina, Color(0.45, 0.85, 0.35), "")
	if not p.prologue:
		_bar(Rect2(24, 74, 220, 8), p.energy / p.max_energy, Color(0.55, 0.45, 1.0), "")
		txt("Soul Ash  %d" % g.ash, Vector2(Cfg.W - 284.0, 36), 20, Color(0.85, 0.85, 0.9), HORIZONTAL_ALIGNMENT_RIGHT, 260.0)
		_runes()
	# Boss bar
	var b = g.boss
	if b != null and not b.prologue:
		var w := 720.0
		var x := (Cfg.W - w) * 0.5
		ctxt(String(b.d["name"]), 40.0, 26)
		_bar(Rect2(x, 52, w, 16), b.hp / b.max_hp, Color(0.85, 0.2, 0.2), "")
		if int(b.d["phases"]) == 3:
			draw_line(Vector2(x + w * 0.66, 50), Vector2(x + w * 0.66, 70), Color.WHITE, 2.0)
			draw_line(Vector2(x + w * 0.33, 50), Vector2(x + w * 0.33, 70), Color.WHITE, 2.0)
		else:
			draw_line(Vector2(x + w * 0.5, 50), Vector2(x + w * 0.5, 70), Color.WHITE, 2.0)
		ctxt("%s  •  Boss %d / 50" % [Lore.area_name(g.boss_index), g.boss_index], 90.0, 15, Color(0.85, 0.85, 0.85), 3)

func _bar(rc: Rect2, frac: float, col: Color, _label: String) -> void:
	draw_rect(rc, Color(0, 0, 0, 0.6))
	draw_rect(Rect2(rc.position, Vector2(rc.size.x * clampf(frac, 0.0, 1.0), rc.size.y)), col)
	draw_rect(rc, Color(1, 1, 1, 0.4), false, 1.5)

func _runes() -> void:
	var p: Player = g.player
	for i in 4:
		var info: Dictionary = Lore.RUNES[i]
		var x := Cfg.W * 0.5 - 150.0 + i * 78.0
		var rc := Rect2(x, 644, 68, 64)
		var unlocked: bool = g.runes[i]
		var col: Color = info["col"]
		panel(rc, 0.7, Color(col.r, col.g, col.b, 0.8 if unlocked else 0.2))
		if unlocked:
			draw_circle(rc.position + Vector2(34, 28), 14.0, Color(col.r, col.g, col.b, 0.85 if p.energy >= float(info["cost"]) else 0.3))
			var cdk: float = p.rune_cd[i] / float(info["cd"])
			if cdk > 0.0:
				draw_rect(Rect2(rc.position.x, rc.position.y + rc.size.y * (1.0 - cdk), rc.size.x, rc.size.y * cdk), Color(0, 0, 0, 0.6))
			if i == 3 and p.skin_t > 0.0:
				draw_arc(rc.position + Vector2(34, 28), 20.0, 0, TAU, 20, Color.WHITE, 3.0)
			txt(String(info["name"]).split(" ")[0], rc.position + Vector2(0, 56), 11, Color(0.9, 0.9, 0.9), HORIZONTAL_ALIGNMENT_CENTER, rc.size.x, 3)
		else:
			txt("LOCK", rc.position + Vector2(0, 38), 12, Color(0.5, 0.5, 0.5), HORIZONTAL_ALIGNMENT_CENTER, rc.size.x, 3)
		txt(str(i + 1), rc.position + Vector2(5, 14), 13, Color(1, 1, 1, 0.8), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 3)

# ------------------------------------------------------------ screens
func _prologue_text() -> void:
	ctxt("THE THRONE OF LIGHT", 130.0, 30, Color(1, 0.9, 0.5, clampf(2.5 - g.st_t * 0.6, 0.0, 1.0)))
	if g.pro_t < 5.5:
		var a := clampf(5.5 - g.pro_t, 0.0, 1.0)
		ctxt("GOD, THE CREATOR", 560.0, 18, Color(1, 0.85, 0.4, a), 4)
		wtxt("\"" + Lore.GOD_PROLOGUE_INTRO + "\"", Cfg.W * 0.5, 590.0, 900.0, 22, Color(1, 1, 1, a))
	else:
		txt("Hit God's ankles!   Hits: %d / 3" % g.pro_hits, Vector2(0, 700), 16, Color(1, 1, 1, 0.7), HORIZONTAL_ALIGNMENT_CENTER, Cfg.W, 3)

func _title() -> void:
	ctxt("SPUD", 220.0, 120, Color("e8c07a"), 10)
	ctxt("WRATH OF THE SOIL", 290.0, 46, Color(1, 0.55, 0.2), 8)
	ctxt("a boss rush in fifty burials", 330.0, 20, Color(0.8, 0.75, 0.7), 3)
	var items := ["NEW GAME", "CONTINUE", "QUIT"]
	for i in items.size():
		var sel: bool = i == g.menu_sel
		var dis: bool = i == 1 and not g.has_save
		var c := Color(1, 1, 1) if sel else Color(0.65, 0.6, 0.55)
		if dis:
			c = Color(0.35, 0.33, 0.3)
		ctxt(("> " + items[i] + " <") if sel else items[i], 420.0 + i * 52.0, 34, c)
	var y := 548.0
	for ln in wrap_lines(Lore.PREMISE[0], 960.0, 15):
		ctxt(ln, y, 15, Color(0.75, 0.72, 0.68), 3)
		y += 20.0
	ctxt("A/D move  •  SPACE jump  •  SHIFT roll  •  J slash  •  1-4 runes  •  ENTER select", 690.0, 14, Color(0.6, 0.6, 0.6), 3)

func _beam() -> void:
	var p: Player = g.player
	var sx: float = p.position.x + g.world.position.x
	var t: float = g.st_t
	if t > 1.4 and t < 2.2:
		var k := (t - 1.4) / 0.8
		draw_rect(Rect2(sx - 3.0, 0, 6.0, Cfg.H), Color(1, 1, 0.8, 0.4 + 0.5 * k))
	elif t >= 2.2 and t < 3.4:
		var k2 := 1.0 - (t - 2.2) / 1.2 * 0.4
		draw_rect(Rect2(sx - 120.0 * k2, 0, 240.0 * k2, Cfg.H), Color(1, 0.97, 0.75, 0.55))
		draw_rect(Rect2(sx - 60.0 * k2, 0, 120.0 * k2, Cfg.H), Color(1, 1, 1, 0.95))
	if t > 2.0 and t < 4.0:
		ctxt("JUDGMENT", 330.0, 64, Color(1, 1, 1, clampf(4.0 - t, 0.0, 1.0) * clampf(t - 2.0, 0.0, 1.0)))

func _cine() -> void:
	var c = g.cine
	if not c.active:
		return
	var b: Dictionary = c.cur()
	var bh: float = 60.0 * float(c.bar)
	draw_rect(Rect2(0, 0, Cfg.W, bh), Color(0, 0, 0))
	draw_rect(Rect2(0, Cfg.H - 44.0 * float(c.bar), Cfg.W, 44.0 * float(c.bar)), Color(0, 0, 0))
	draw_rect(Rect2(0, Cfg.H - 44.0 - 140.0, Cfg.W, 140.0), Color(0, 0, 0, 0.55 * float(c.bar)))
	var dur := float(b.get("dur", 4.0))
	var fa := clampf(c.bt / 0.6, 0.0, 1.0) * clampf((dur - c.bt) / 0.5, 0.0, 1.0)
	if b.get("art", "") == "area":
		ctxt(String(b.get("title", "")).to_upper(), 300.0, 46, Color(1, 0.9, 0.6, fa), 6)
	var who := String(b.get("who", ""))
	var full := String(b.get("text", ""))
	var shown := full.substr(0, c.chars_shown())
	var y := Cfg.H - 176.0
	if who != "":
		ctxt(who, y - 6.0, 20, Color(1, 0.7, 0.3, fa), 4)
		y += 24.0
	if b.get("art", "") == "area":
		y = 420.0
	if who != "":
		wtxt("\"" + shown + "\"", Cfg.W * 0.5, y, 980.0, 22, Color(1, 1, 1, fa))
	else:
		wtxt(shown, Cfg.W * 0.5, y, 980.0, 22, Color(0.95, 0.93, 0.85, fa))
	ctxt("ENTER — next     ESC — skip", Cfg.H - 20.0, 14, Color(1, 1, 1, 0.35 + 0.2 * sin(g.st_t * 4.0)), 2)

func _card() -> void:
	draw_rect(Rect2(0, 0, Cfg.W, Cfg.H), Color(0.02, 0.01, 0.02))
	var a := clampf(g.st_t * 0.8, 0.0, 1.0) * clampf((g.card_dur - g.st_t) * 1.2, 0.0, 1.0)
	var y := 280.0
	for i in g.card_lines.size():
		var ln: Dictionary = g.card_lines[i]
		var sz: int = ln["size"]
		var col: Color = ln["col"]
		col.a = a
		if ln.get("wrap", false):
			y = wtxt(ln["text"], Cfg.W * 0.5, y, 900.0, sz, col) + 10.0
		else:
			ctxt(ln["text"], y, sz, col, 6)
			y += sz * 1.5
	if g.st_t > 1.5:
		ctxt("ENTER", 680.0, 14, Color(1, 1, 1, 0.4 + 0.3 * sin(g.st_t * 4.0)), 2)

func _intro() -> void:
	var b = g.boss
	draw_rect(Rect2(0, 0, Cfg.W, 110), Color(0, 0, 0, 0.88))
	draw_rect(Rect2(0, Cfg.H - 190, Cfg.W, 190), Color(0, 0, 0, 0.88))
	var a := clampf(g.st_t * 2.0, 0.0, 1.0)
	ctxt(Lore.area_name(g.boss_index) + "   •   Boss %d / 50" % g.boss_index, 40.0, 16, Color(0.8, 0.8, 0.8, a), 3)
	ctxt(String(b.d["name"]).to_upper(), 90.0, 40, Color(1, 0.9, 0.6, a))
	ctxt(String(b.d["label"]), Cfg.H - 150.0, 18, Color(b.acc.r, b.acc.g, b.acc.b, a), 4)
	if not b.prologue:
		var kn: Array = Battle.KITS.get(b.fam, ["rain"])
		var up: Array = []
		for k in kn:
			up.append(String(k).replace("_", " ").to_upper())
		ctxt("ATTACKS:  " + "  •  ".join(up), Cfg.H - 190.0 - 26.0, 14, Color(1, 0.6, 0.35, a), 2)
	wtxt("\"" + typed(String(b.d["intro"])) + "\"", Cfg.W * 0.5, Cfg.H - 118.0, 980.0, 26, Color(1, 1, 1, a))
	if g.st_t > 1.0:
		ctxt("ENTER — fight", Cfg.H - 20.0, 14, Color(1, 1, 1, 0.4 + 0.3 * sin(g.st_t * 4.0)), 2)

func _outro() -> void:
	var b = g.boss
	draw_rect(Rect2(0, 0, Cfg.W, Cfg.H), Color(0, 0, 0, 0.72))
	ctxt("VANQUISHED", 150.0, 56, Color(1, 0.85, 0.4))
	ctxt(String(b.d["name"]), 205.0, 28, Color(0.9, 0.9, 0.9))
	wtxt("\"" + typed(String(b.d["outro"])) + "\"", Cfg.W * 0.5, 300.0, 900.0, 28, Color(1, 1, 1))
	ctxt("+ %d Soul Ash" % g.reward, 440.0, 30, Color(0.8, 0.9, 1.0))
	ctxt(g.drop_note, 478.0, 24, Color(0.6, 0.95, 1.0))
	if g.unlock_note != "":
		wtxt(g.unlock_note, Cfg.W * 0.5, 520.0, 900.0, 24, Color(1, 0.8, 0.4))
	if g.st_t > 1.2:
		ctxt("ENTER", 680.0, 14, Color(1, 1, 1, 0.4 + 0.3 * sin(g.st_t * 4.0)), 2)

func _act_break() -> void:
	draw_rect(Rect2(0, 0, Cfg.W, Cfg.H), Color(0.05, 0.0, 0.0, 0.9))
	ctxt("SATAN FALLS", 160.0, 60, Color(1, 0.4, 0.15), 8)
	wtxt(Lore.WINGS_TEXT, Cfg.W * 0.5, 280.0, 900.0, 30, Color(1, 0.85, 0.5))
	wtxt("Controls: SPACE again in mid-air = Double Jump.   SHIFT in mid-air = Air Dash.", Cfg.W * 0.5, 470.0, 900.0, 20, Color(0.9, 0.9, 0.9))
	if g.st_t > 1.2:
		ctxt("ENTER", 680.0, 14, Color(1, 1, 1, 0.4 + 0.3 * sin(g.st_t * 4.0)), 2)

func _dead() -> void:
	draw_rect(Rect2(0, 0, Cfg.W, Cfg.H), Color(0.15, 0.0, 0.0, clampf(g.st_t * 0.8, 0.0, 0.85)))
	var a := clampf(g.st_t - 0.6, 0.0, 1.0)
	ctxt("THE SOIL REMEMBERS", 280.0, 62, Color(0.9, 0.3, 0.2, a), 8)
	ctxt("Slain by " + String(g.boss.d["name"]) + ".   The earth returns %d Soul Ash." % g.consolation, 350.0, 22, Color(0.9, 0.85, 0.8, a))
	if g.st_t > 1.4:
		ctxt("ENTER — rise again at the Roots of Renewal", 440.0, 26, Color(1, 1, 1, 0.6 + 0.4 * sin(g.st_t * 4.0)))

func _shrine() -> void:
	panel(Rect2(60, 90, 640, 470), 0.82, Color(0.5, 0.9, 0.3, 0.5))
	txt("ROOTS OF RENEWAL", Vector2(90, 140), 38, Color(0.6, 1.0, 0.4))
	txt("Spud buries himself in sacred soil...", Vector2(90, 168), 15, Color(0.75, 0.8, 0.7), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 3)
	txt("Soul Ash  %d" % g.ash, Vector2(90, 210), 28, Color(0.85, 0.9, 1.0))
	var lv := [g.hp_lvl, g.sta_lvl, g.atk_lvl]
	var stats := [
		"%d HP  →  %d" % [g.player.max_hp, g.player.max_hp + 1],
		"%d Stamina  →  %d" % [int(g.player.max_stamina), int(g.player.max_stamina) + 10],
		"%d Damage  →  %d" % [int(g.player.damage), int(g.player.damage) + 4],
	]
	for i in 3:
		var u: Dictionary = Lore.UPGRADES[i]
		var y := 250.0 + i * 78.0
		var sel: bool = g.shrine_sel == i
		var maxed: bool = lv[i] >= Lore.MAX_UPGRADE_LEVEL
		var cost := Lore.upgrade_cost(i, lv[i])
		var afford: bool = g.ash >= cost and not maxed
		if sel:
			draw_rect(Rect2(76, y - 28, 608, 68), Color(0.5, 0.9, 0.3, 0.14))
			draw_rect(Rect2(76, y - 28, 608, 68), Color(0.6, 1.0, 0.4, 0.7), false, 2.0)
		txt("%s   (Lv %d)" % [u["name"], lv[i]], Vector2(94, y), 26, Color.WHITE if afford or maxed else Color(0.6, 0.6, 0.6))
		txt(String(u["desc"]), Vector2(94, y + 22), 14, Color(0.8, 0.8, 0.8), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 3)
		var right := "MAX" if maxed else "%s   •   %d Ash" % [stats[i], cost]
		txt(right, Vector2(94, y + 42), 16, Color(0.7, 1.0, 0.5) if afford else Color(0.7, 0.5, 0.5), HORIZONTAL_ALIGNMENT_RIGHT, 580.0, 3)
	var cy := 250.0 + 3 * 78.0
	var csel: bool = g.shrine_sel == 3
	if csel:
		draw_rect(Rect2(76, cy - 28, 608, 56), Color(1.0, 0.6, 0.2, 0.15))
		draw_rect(Rect2(76, cy - 28, 608, 56), Color(1.0, 0.7, 0.3, 0.7), false, 2.0)
	txt("RISE: %d. %s" % [g.boss_index, Lore.boss(g.boss_index)["name"]], Vector2(94, cy + 6), 21, Color(1, 0.85, 0.5) if csel else Color(0.85, 0.75, 0.6), HORIZONTAL_ALIGNMENT_LEFT, -1.0)
	# rune list
	panel(Rect2(730, 90, 490, 470), 0.82)
	txt("ELEMENTAL RUNES", Vector2(756, 135), 26, Color(0.85, 0.8, 1.0))
	for i in 4:
		var info: Dictionary = Lore.RUNES[i]
		var y := 190.0 + i * 88.0
		var c: Color = info["col"]
		var un: bool = g.runes[i]
		draw_circle(Vector2(776, y - 6), 14.0, Color(c.r, c.g, c.b, 1.0 if un else 0.25))
		txt("%d. %s  (%s)" % [i + 1, info["name"], info["school"]] if un else "%d. ???  (%s — %s)" % [i + 1, info["school"], info["tag"]], Vector2(804, y), 18, Color.WHITE if un else Color(0.5, 0.5, 0.5), HORIZONTAL_ALIGNMENT_LEFT, 400.0, 4)
		if un:
			for k in wrap_lines(String(info["desc"]), 400.0, 13).size():
				txt(wrap_lines(String(info["desc"]), 400.0, 13)[k], Vector2(804, y + 18 + k * 16), 13, Color(0.8, 0.8, 0.8), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 3)
	ctxt("W/S or ↑/↓ select   •   ENTER buy / continue", 690.0, 15, Color(0.8, 0.8, 0.8), 3)

func _ending() -> void:
	var t: float = g.st_t
	if t < 5.0:
		pass
	if t > 3.0 and t < 12.0:
		var idx := clampi(int((t - 3.0) / 3.0), 0, Lore.ENDING_LINES.size() - 1)
		var local := fmod(t - 3.0, 3.0)
		var a := clampf(local, 0.0, 1.0) * clampf(3.0 - local, 0.0, 1.0) * 1.2
		wtxt(Lore.ENDING_LINES[idx], Cfg.W * 0.5, 160.0, 900.0, 32, Color(1, 0.95, 0.8, clampf(a, 0.0, 1.0)))
	if t >= 14.0:
		draw_rect(Rect2(0, 0, Cfg.W, Cfg.H), Color(0, 0, 0, clampf((t - 14.0) * 0.5, 0.0, 0.85)))
		var a2 := clampf((t - 15.0) * 0.6, 0.0, 1.0)
		ctxt("SPUD: WRATH OF THE SOIL", 250.0, 50, Color(0.95, 0.8, 0.45, a2), 8)
		ctxt("THE END", 320.0, 40, Color(1, 1, 1, a2), 6)
		ctxt("Time  %s   •   Deaths  %d" % [g.fmt_time(g.play_time), g.deaths], 390.0, 24, Color(0.85, 0.85, 0.9, a2))
		if t > 17.0:
			ctxt("ENTER — return to title", 620.0, 18, Color(1, 1, 1, 0.5 + 0.3 * sin(t * 4.0)), 3)

# ------------------------------------------------------------ Undertale-style battle UI
func _uheart(c: Vector2, s: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * float(i) / 24.0
		var x := 16.0 * pow(sin(a), 3.0)
		var y := -(13.0 * cos(a) - 5.0 * cos(2.0 * a) - 2.0 * cos(3.0 * a) - cos(4.0 * a))
		pts.append(c + Vector2(x, y) * s * 0.42)
	draw_colored_polygon(pts, col)
	draw_circle(c + Vector2(0, -0.5 * s), 2.6 * s, Color(0.76, 0.6, 0.38))
	draw_rect(Rect2(c + Vector2(-1.8, -1.6) * s, Vector2(1.0, 1.0) * s), Color(0.1, 0.05, 0.03))
	draw_rect(Rect2(c + Vector2(0.9, -1.6) * s, Vector2(1.0, 1.0) * s), Color(0.1, 0.05, 0.03))

func _battle_ui() -> void:
	var bt = g.battle
	var b = g.boss
	var p: Player = g.player
	var white := Color(1, 1, 1)
	var yel := Color(1, 0.9, 0.2)
	# boss name + hp
	if b != null:
		txt(String(b.d["name"]).to_upper(), Vector2(36, 40), 21, Color(1, 0.9, 0.6), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 4)
		var frac := clampf(b.hp / maxf(b.max_hp, 1.0), 0.0, 1.0)
		draw_rect(Rect2(36, 52, 300, 14), Color(0.25, 0.0, 0.0))
		draw_rect(Rect2(36, 52, 300.0 * frac, 14), Color(0.2, 0.9, 0.3) if frac > 0.4 else Color(1.0, 0.8, 0.1))
		draw_rect(Rect2(36, 52, 300, 14), Color(1, 1, 1, 0.8), false, 2.0)
		if bt.tired:
			txt("EXHAUSTED", Vector2(350, 66), 14, Color(0.6, 0.9, 1.0), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 2)
	# speech bubble
	if bt.speech_t > 0.0 and bt.speech != "" and b != null:
		var bx: float = bt.boss_home.x + 130.0 + b.size.x * 0.4
		var bw := 330.0
		var lines: Array = wrap_lines(bt.speech, bw - 30.0, 18)
		var bh := 24.0 + lines.size() * 26.0
		var by := 120.0
		draw_rect(Rect2(bx, by, bw, bh), white)
		draw_colored_polygon(PackedVector2Array([Vector2(bx, by + 24), Vector2(bx - 18, by + 34), Vector2(bx, by + 44)]), white)
		for i in lines.size():
			txt(lines[i], Vector2(bx + 14, by + 12 + i * 26), 18, Color(0.05, 0.05, 0.08), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 0)
	var box: Rect2 = bt.box
	var m: String = bt.mode
	var tx := box.position.x + 24.0
	var ty := box.position.y + 18.0
	if m in ["menu", "result", "hit", "win", "enter", "speech"]:
		var s: String = bt.text
		if m == "speech":
			s = ""
		wtxt_left(s.substr(0, int(bt.mode_t * 45.0)), tx, ty, box.size.x - 48.0, 21, white)
	elif m == "act" or m == "item" or m == "mercy":
		var lab: Array = bt.act_labels() if m == "act" else (bt.item_labels() if m == "item" else bt.mercy_labels())
		var cols := 1 if lab.size() <= 4 else 2
		for i in lab.size():
			var cx2: float = tx + 30.0 + (i % cols) * 250.0 if cols == 2 else tx + 30.0
			var cy2: float = ty + (i / cols if cols == 2 else i) * 34.0
			var c := yel if i == bt.sub_i else white
			if m == "mercy" and i == 0 and bt.spare_ok:
				c = yel
			txt("* " + String(lab[i]), Vector2(cx2, cy2), 21, c, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 3)
			if i == bt.sub_i:
				_uheart(Vector2(cx2 - 14.0, cy2 + 10.0), 1.0, Color(0.95, 0.15, 0.2))
	elif m == "fightbar":
		var bx2 := box.position.x + 20.0
		var bw2 := box.size.x - 40.0
		var by2 := box.get_center().y - 28.0
		draw_rect(Rect2(bx2, by2, bw2, 56.0), Color(0.1, 0.1, 0.12))
		draw_rect(Rect2(bx2, by2, bw2, 56.0), Color(1, 1, 1), false, 3.0)
		for i in 5:
			var wv := bw2 * (0.5 - 0.1 * i)
			var col := Color(0.2, 0.7, 0.2, 0.5) if i < 4 else Color(1, 0.9, 0.2)
			draw_rect(Rect2(bx2 + bw2 * 0.5 - wv * 0.5, by2 + 6.0, wv, 44.0), Color(col.r, col.g, col.b, 0.25 + 0.15 * i))
		draw_rect(Rect2(bx2 + bw2 * 0.5 - 3.0, by2 - 4.0, 6.0, 64.0), Color(1, 1, 1, 0.6))
		var cxp: float = bx2 + bw2 * bt.bar_x
		draw_rect(Rect2(cxp - 5.0, by2 - 8.0, 10.0, 72.0), Color(1, 1, 1))
		draw_rect(Rect2(cxp - 5.0, by2 - 8.0, 10.0, 72.0), Color(0, 0, 0), false, 2.0)
		ctxt("PRESS  Z / J / ATK  AT THE CENTER", by2 + 80.0, 14, Color(1, 1, 1, 0.7), 2)
	# stat line
	var sy := 590.0
	var lv: int = 1 + (g.hp_lvl + g.sta_lvl + g.atk_lvl) / 3
	txt("SPUD   LV %d" % lv, Vector2(box.position.x, sy), 21, white, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 3)
	txt("HP", Vector2(box.position.x + 260.0, sy + 3.0), 14, white, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 2)
	var hw := 11.0 * p.max_hp
	draw_rect(Rect2(box.position.x + 300.0, sy - 2.0, hw, 22), Color(0.6, 0.0, 0.1))
	draw_rect(Rect2(box.position.x + 300.0, sy - 2.0, hw * float(maxi(p.hp, 0)) / float(maxi(p.max_hp, 1)), 22), Color(1, 0.9, 0.0))
	txt("%d / %d" % [maxi(p.hp, 0), p.max_hp], Vector2(box.position.x + 312.0 + hw, sy), 21, white, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 3)
	for i in p.armor_shield:
		var ac := Vector2(box.end.x - 20.0 - i * 22.0, sy + 10.0)
		draw_colored_polygon(PackedVector2Array([ac + Vector2(-8, -9), ac + Vector2(8, -9), ac + Vector2(8, 3), ac + Vector2(0, 10), ac + Vector2(-8, 3)]), Color(0.75, 0.8, 0.9))
	if bt.items > 0 or true:
		pass
	# buttons
	var names := ["FIGHT", "ACT", "ITEM", "MERCY"]
	var bwid := 190.0
	var gap := 50.0
	var x0 := (Cfg.W - (4.0 * bwid + 3.0 * gap)) * 0.5
	for i in 4:
		var rc := Rect2(x0 + i * (bwid + gap), 636.0, bwid, 54.0)
		var sel: bool = (bt.menu_i == i) and bt.mode in ["menu", "act", "item", "mercy"]
		var col := yel if sel else Color(1, 0.55, 0.15)
		draw_rect(rc, Color(0, 0, 0, 0.8))
		draw_rect(rc, col, false, 4.0)
		ctxt_in(names[i], rc, 21, col)
		if sel and bt.mode == "menu":
			_uheart(Vector2(rc.position.x + 26.0, rc.position.y + 27.0), 1.1, Color(0.95, 0.15, 0.2))

func ctxt_in(s: String, rc: Rect2, size: int, col: Color) -> void:
	txt(s, Vector2(rc.position.x, rc.position.y + rc.size.y * 0.5 - size * 0.35), size, col, HORIZONTAL_ALIGNMENT_CENTER, rc.size.x, 3)

func wtxt_left(s: String, x: float, y: float, width: float, size: int, col: Color) -> void:
	var lines: Array = wrap_lines(s, width, size)
	for i in lines.size():
		txt(lines[i], Vector2(x, y + i * size * 1.45), size, col, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 3)
