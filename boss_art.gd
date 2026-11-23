class_name BossArt
extends RefCounted
## Dark-fantasy boss portraits. Art is authored facing LEFT, origin = body centre.

const BONE := Color(0.82, 0.76, 0.62)
const IRON := Color(0.30, 0.31, 0.36)
const GOLD := Color(0.86, 0.68, 0.24)

static func draw(b) -> void:
	if b.prologue:
		god(b)
		return
	match b.fam:
		"imp": imp(b)
		"wraith": wraith(b)
		"hound": hound(b)
		"slime": slime(b)
		"duke": duke(b)
		"torturer": torturer(b)
		"golem": golem(b)
		"seraph": seraph(b)
		"cherub": cherub(b)
		"knight": knight(b)
		"pillar": pillar(b)
		"ophanim": ophanim(b)
		"archangel": archangel(b)
		"satan": satan(b)
		"god": god(b)

static func P(a: Array) -> PackedVector2Array:
	return Art.P(a)

# ------------------------------------------------------------------ HELL
static func imp(b) -> void:
	var t: float = b.t
	var f: float = b.flash
	var wy := sin(t * 12.0) * 12.0
	var c: Color = b.col.darkened(0.25)
	Art.bat_wing(b, Vector2(-8, -4), -1.0, 62, 40, wy, c.darkened(0.25), f)
	Art.bat_wing(b, Vector2(8, -4), 1.0, 62, 40, wy, c.darkened(0.25), f)
	# tail
	b.draw_polyline(P([14, 20, 34, 30, 44, 24, 52, 34]), Art.INK, 7.0)
	b.draw_polyline(P([14, 20, 34, 30, 44, 24, 52, 34]), c, 4.0)
	Art.shape(b, P([52, 34, 62, 26, 60, 40]), Color(0.3, 0.05, 0.05), f, 1.6)
	# legs & claws
	Art.shape(b, P([-14, 22, -8, 38, -16, 40, -22, 30]), c.darkened(0.2), f, 2.0)
	Art.shape(b, P([14, 22, 8, 38, 16, 40, 22, 30]), c.darkened(0.2), f, 2.0)
	# torso
	Art.sym(b, P([-6, -16, -16, -6, -20, 14, -10, 28]), c, f)
	for k in 3:
		b.draw_line(Vector2(-9, -2 + k * 8), Vector2(9, -2 + k * 8), Art.INK, 1.5)
	# head
	Art.horn(b, Vector2(-12, -26), -2.2, 30, 6, -0.9, Color(0.16, 0.06, 0.05), f)
	Art.horn(b, Vector2(12, -26), -0.94, 30, 6, 0.9, Color(0.16, 0.06, 0.05), f)
	Art.sym(b, P([-4, -40, -15, -34, -17, -20, -8, -12]), c.lightened(0.05), f)
	Art.eye(b, Vector2(-8, -28), 3.2, Color(1, 0.8, 0.1))
	Art.eye(b, Vector2(8, -28), 3.2, Color(1, 0.8, 0.1))
	b.draw_colored_polygon(P([-7, -17, -3, -12, 0, -17, 3, -12, 7, -17, 0, -20]), Color(0.95, 0.9, 0.75))

static func wraith(b) -> void:
	var t: float = b.t
	var f: float = b.flash
	var sw := sin(t * 2.5) * 6.0
	Art.glow(b, Vector2(0, -20), 90, b.acc, 0.18)
	# cloak
	Art.cloth(b, Vector2(0, -40), 24, 100, 40, t, b.col.darkened(0.45), f, 0.0, 7)
	Art.cloth(b, Vector2(sw, -34), 20, 84, 30, t + 1.0, b.col.darkened(0.1), f, 1.0, 6)
	# hood
	Art.sym(b, P([0, -64, -16, -58, -26, -36, -22, -14, -10, -4]), b.col.darkened(0.55), f)
	Art.ellipse(b, Vector2(0, -34), 14, 17, Color(0.01, 0.0, 0.02), 0.0, 1.8)
	Art.eye(b, Vector2(-6, -36), 2.6, b.acc)
	Art.eye(b, Vector2(6, -36), 2.6, b.acc)
	# bony hands
	for s in [-1.0, 1.0]:
		var hp := Vector2(s * 36 + sw * 0.5, 0 + sin(t * 2.0 + s) * 5.0)
		b.draw_line(Vector2(s * 16, -18), hp, Art.INK, 8.0)
		b.draw_line(Vector2(s * 16, -18), hp, b.col.darkened(0.3), 5.0)
		for k in 4:
			var tp := hp + Vector2(s * (6 + k * 2), 8 + k * 5)
			Art.line(b, hp, tp, BONE.darkened(0.2), 2.0)
	# hanging chains
	Art.chain(b, Vector2(-20, -10), Vector2(-34, 30), 6.0, Color(0.4, 0.4, 0.45))
	Art.chain(b, Vector2(20, -10), Vector2(34, 34), 6.0, Color(0.4, 0.4, 0.45))

static func hound(b) -> void:
	var t: float = b.t
	var f: float = b.flash
	var run := sin(t * 10.0) * (6.0 if b.mode == "act" else 2.0)
	Art.floor_shadow(b, Vector2(0, 40), 70)
	var dk: Color = b.col.darkened(0.15)
	# far legs
	Art.shape(b, P([-36, 14, -26, 16, -24, 40, -34, 40]), dk.darkened(0.3), f, 2.0)
	Art.shape(b, P([40, 14, 52, 16, 52 + run, 40, 40 + run, 40]), dk.darkened(0.3), f, 2.0)
	# tail
	b.draw_polyline(P([56, -12, 74, -24, 80, -42]), Art.INK, 9.0)
	b.draw_polyline(P([56, -12, 74, -24, 80, -42]), dk, 6.0)
	Art.flame(b, Vector2(80, -42), 18, 7, t, b.acc, 0.0)
	# body
	Art.shape(b, P([-44, -18, -10, -30, 30, -26, 60, -10, 58, 20, 30, 28, -20, 26, -46, 14]), b.col, f)
	# ember cracks
	for k in 4:
		var x := -20.0 + k * 20.0
		b.draw_line(Vector2(x, -22), Vector2(x + 8, 4 + sin(t * 4 + k) * 2), Color(b.acc.r, b.acc.g, b.acc.b, 0.8), 2.0)
	# spikes along back
	for k in 6:
		var x := -28.0 + k * 14.0
		Art.shape(b, P([x, -26 + k * 0.5, x + 5, -42 + k, x + 11, -26 + k * 0.5]), Color(0.12, 0.08, 0.08), f, 1.6)
	# near legs
	Art.shape(b, P([-40, 10, -26, 14, -22 + run, 42, -38 + run, 42]), dk, f, 2.2)
	Art.shape(b, P([34, 12, 50, 12, 52 - run, 42, 36 - run, 42]), dk, f, 2.2)
	# neck + head (left)
	Art.shape(b, P([-40, -22, -58, -20, -62, 6, -40, 12]), b.col, f)
	Art.shape(b, P([-52, -34, -40, -34, -34, -14, -56, -8, -74, -10, -76, -22]), b.col.lightened(0.04), f)
	# jaw
	Art.shape(b, P([-76, -8, -52, -4, -50, 8, -70, 12]), b.col.darkened(0.2), f, 2.0)
	for k in 4:
		b.draw_colored_polygon(P([-72 + k * 6, -8, -69 + k * 6, -1, -66 + k * 6, -8]), Color(0.95, 0.9, 0.8))
	b.draw_circle(Vector2(-70, -16), 2.2, Art.INK)
	# ears + eye
	Art.shape(b, P([-46, -34, -40, -52, -32, -34]), Color(0.14, 0.08, 0.08), f, 1.8)
	Art.eye(b, Vector2(-56, -22), 3.0, b.acc)
	Art.glow(b, Vector2(-68, 0), 18, b.acc, 0.35)

static func slime(b) -> void:
	var t: float = b.t
	var f: float = b.flash
	var sq := sin(t * 3.0) * 4.0
	Art.floor_shadow(b, Vector2(0, 44), 64)
	Art.glow(b, Vector2(0, 10), 80, b.acc, 0.22)
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * float(i) / 24.0
		var r := 1.0 + 0.07 * sin(a * 4.0 + t * 3.0)
		pts.append(Vector2(cos(a) * 58.0 * r, 6.0 + sin(a) * (42.0 + sq) * r * (1.0 if sin(a) < 0 else 0.95)))
	Art.shape(b, pts, b.col.darkened(0.2), f, 3.0, 0.4, 0.4)
	# cooled crust plates
	for k in 5:
		var x := -40.0 + k * 20.0
		Art.shape(b, P([x, -30 + abs(k - 2) * 6, x + 14, -34 + abs(k - 2) * 6, x + 18, -18, x + 2, -14]), Color(0.16, 0.1, 0.1), f, 1.8)
	# molten cracks
	for k in 4:
		var x := -34.0 + k * 22.0
		b.draw_polyline(P([x, -14, x + 6, 0, x - 2, 12, x + 8, 26]), Color(1.0, 0.85, 0.3, 0.9), 2.2)
	# trapped skull
	Art.skull(b, Vector2(0, 2), 15, Color(0.9, 0.82, 0.65, 1.0), Color(1, 0.4, 0.1))
	# bubbles
	for k in 3:
		var bp := Vector2(-30 + k * 30 + sin(t * 2 + k) * 4, -20 - fmod(t * 20.0 + k * 20.0, 36.0))
		b.draw_circle(bp, 4.5, Color(1, 0.8, 0.3, 0.7))
		b.draw_arc(bp, 4.5, 0, TAU, 10, Art.INK, 1.2)

static func duke(b) -> void:
	var t: float = b.t
	var f: float = b.flash
	Art.floor_shadow(b, Vector2(0, 84), 56)
	# cape
	Art.cloth(b, Vector2(0, -52), 38, 128, 50, t, Color(0.28, 0.04, 0.08), f, 0.0, 6)
	# legs
	Art.shape(b, P([-24, 30, -6, 30, -8, 84, -28, 84]), b.col.darkened(0.45), f, 2.2)
	Art.shape(b, P([6, 30, 24, 30, 28, 84, 8, 84]), b.col.darkened(0.45), f, 2.2)
	Art.shape(b, P([-34, 78, -6, 78, -6, 86, -40, 86]), Color(0.1, 0.07, 0.08), f, 1.8)
	Art.shape(b, P([6, 78, 36, 78, 40, 86, 6, 86]), Color(0.1, 0.07, 0.08), f, 1.8)
	# torso (plate)
	Art.sym(b, P([-14, -58, -30, -50, -34, -10, -26, 34]), b.col.darkened(0.2), f)
	Art.sym(b, P([-6, -48, -18, -40, -20, -6, -12, 20]), b.col.lightened(0.05), f)
	b.draw_line(Vector2(0, -50), Vector2(0, 30), Art.INK, 2.0)
	# belt + sigil
	Art.shape(b, P([-28, 18, 28, 18, 28, 28, -28, 28]), Color(0.12, 0.08, 0.06), f, 1.8)
	Art.glow(b, Vector2(0, 23), 10, b.acc, 0.4)
	b.draw_circle(Vector2(0, 23), 3.5, b.acc)
	# pauldrons with spikes
	for s in [-1.0, 1.0]:
		Art.shape(b, P([s * 22, -58, s * 50, -58, s * 54, -34, s * 28, -30]), IRON.darkened(0.3), f)
		for k in 3:
			Art.shape(b, P([s * (28 + k * 8), -58, s * (30 + k * 8), -78 + k * 3, s * (35 + k * 8), -58]), Color(0.14, 0.14, 0.17), f, 1.6)
	# off arm + sword (held forward left)
	b.draw_line(Vector2(-34, -44), Vector2(-52, -10), Art.INK, 14.0)
	b.draw_line(Vector2(-34, -44), Vector2(-52, -10), IRON, 10.0)
	Art.blade(b, Vector2(-52, -2), Vector2(-62, -120), 6.0, Color(0.7, 0.72, 0.8), b.acc, f)
	Art.shape(b, P([-66, -4, -38, -4, -38, 2, -66, 2]), GOLD.darkened(0.3), f, 1.8)
	b.draw_line(Vector2(34, -44), Vector2(46, -4), Art.INK, 12.0)
	b.draw_line(Vector2(34, -44), Vector2(46, -4), IRON, 8.0)
	# head & helm
	Art.sym(b, P([0, -102, -14, -96, -18, -72, -12, -58, 0, -54]), Color(0.18, 0.17, 0.2), f)
	b.draw_rect(Rect2(-12, -82, 24, 7), Color(0.01, 0, 0.01))
	Art.eye(b, Vector2(-6, -78.5), 2.4, b.acc)
	Art.eye(b, Vector2(6, -78.5), 2.4, b.acc)
	Art.horn(b, Vector2(-14, -92), -2.4, 44, 7, -0.8, BONE.darkened(0.45), f)
	Art.horn(b, Vector2(14, -92), -0.74, 44, 7, 0.8, BONE.darkened(0.45), f)

static func torturer(b) -> void:
	var t: float = b.t
	var f: float = b.flash
	Art.floor_shadow(b, Vector2(0, 84), 70)
	# legs
	Art.shape(b, P([-36, 30, -6, 30, -8, 84, -40, 84]), Color(0.18, 0.14, 0.14), f, 2.4)
	Art.shape(b, P([6, 30, 36, 30, 40, 84, 8, 84]), Color(0.18, 0.14, 0.14), f, 2.4)
	# massive torso (flesh)
	Art.sym(b, P([-18, -56, -50, -44, -58, -8, -40, 36]), Color(0.52, 0.34, 0.3), f)
	for k in 3:
		b.draw_line(Vector2(-30, -20 + k * 14), Vector2(30, -20 + k * 14 + 4), Color(0.25, 0.1, 0.1), 2.0)
	# apron
	Art.shape(b, P([-30, -14, 30, -14, 40, 70, -40, 70]), Color(0.16, 0.12, 0.1), f)
	for k in 5:
		b.draw_circle(Vector2(-22 + k * 11, 10 + (k % 2) * 14), 2.6, Color(0.5, 0.05, 0.05))
	# shoulder plates + chains
	for s in [-1.0, 1.0]:
		Art.shape(b, P([s * 36, -56, s * 66, -50, s * 68, -28, s * 40, -30]), IRON, f)
	Art.chain(b, Vector2(-50, -40), Vector2(40, -20), 22.0)
	Art.chain(b, Vector2(50, -40), Vector2(-40, -20), 22.0)
	# hood + iron mask
	Art.sym(b, P([0, -96, -22, -88, -26, -62, -16, -50]), Color(0.1, 0.08, 0.08), f)
	Art.shape(b, P([-14, -84, 14, -84, 12, -62, 0, -54, -12, -62]), IRON.lightened(0.1), f, 2.0)
	b.draw_rect(Rect2(-10, -76, 20, 4), Color(0, 0, 0))
	Art.eye(b, Vector2(-5, -74), 2.0, b.acc)
	Art.eye(b, Vector2(5, -74), 2.0, b.acc)
	for k in 3:
		b.draw_line(Vector2(-6 + k * 6, -66), Vector2(-6 + k * 6, -58), Art.INK, 1.4)
	# big cleaver (left, raised)
	var sw := sin(t * 2.0) * 3.0
	b.draw_line(Vector2(-54, -30), Vector2(-76, -2 + sw), Art.INK, 15.0)
	b.draw_line(Vector2(-54, -30), Vector2(-76, -2 + sw), Color(0.52, 0.34, 0.3), 11.0)
	b.draw_line(Vector2(-76, 6 + sw), Vector2(-76, -40 + sw), Color(0.3, 0.2, 0.12), 6.0)
	Art.shape(b, P([-110, -86 + sw, -78, -92 + sw, -76, -44 + sw, -112, -50 + sw]), Color(0.55, 0.57, 0.62), f, 2.4, 0.3, 0.45)
	b.draw_line(Vector2(-110, -84 + sw), Vector2(-112, -52 + sw), b.acc, 2.0)
	b.draw_line(Vector2(54, -30), Vector2(64, 10), Art.INK, 15.0)
	b.draw_line(Vector2(54, -30), Vector2(64, 10), Color(0.52, 0.34, 0.3), 11.0)

static func golem(b) -> void:
	var t: float = b.t
	var f: float = b.flash
	Art.floor_shadow(b, Vector2(0, 98), 96)
	Art.glow(b, Vector2(0, 0), 120, b.acc, 0.15)
	var rock: Color = b.col.lightened(0.05)
	# legs
	Art.shape(b, P([-56, 44, -12, 44, -14, 100, -62, 100]), rock.darkened(0.2), f, 3.0)
	Art.shape(b, P([12, 44, 56, 44, 62, 100, 14, 100]), rock.darkened(0.2), f, 3.0)
	# torso
	Art.sym(b, P([-20, -70, -64, -56, -80, -4, -56, 54]), rock, f, 3.0)
	# lava core
	var pul := 0.7 + 0.3 * sin(t * 3.0)
	Art.glow(b, Vector2(0, -6), 44, b.acc, 0.5 * pul)
	Art.shape(b, P([-14, -26, 0, -38, 14, -26, 18, -4, 0, 12, -18, -4]), Color(1.0, 0.55, 0.12), f, 2.0, 0.2, 0.2)
	# cracks
	for k in 6:
		var x := -60.0 + k * 24.0
		b.draw_polyline(P([x, -50 + (k % 2) * 30, x + 10, -20, x - 4, 8 + (k % 3) * 6, x + 8, 40]), Color(b.acc.r, b.acc.g, b.acc.b, 0.75), 2.0)
	# arms
	for s in [-1.0, 1.0]:
		var sway := sin(t * 1.6 + s) * 5.0
		Art.shape(b, P([s * 64, -60, s * 96, -52, s * 104, 6 + sway, s * 84, 22 + sway, s * 66, -6]), rock.darkened(0.08), f, 3.0)
		Art.shape(b, P([s * 78, 14 + sway, s * 116, 18 + sway, s * 126, 62 + sway, s * 94, 78 + sway, s * 70, 50 + sway]), rock.darkened(0.25), f, 3.0)
		Art.glow(b, Vector2(s * 98, 56 + sway), 16, b.acc, 0.4)
	# head (small skull-like)
	Art.shape(b, P([-22, -96, 22, -96, 28, -66, 0, -58, -28, -66]), rock.darkened(0.15), f, 3.0)
	b.draw_rect(Rect2(-18, -84, 36, 6), Color(0, 0, 0))
	Art.eye(b, Vector2(-8, -81), 3.2, Color(1, 0.7, 0.2))
	Art.eye(b, Vector2(8, -81), 3.2, Color(1, 0.7, 0.2))
	# spikes
	for s in [-1.0, 1.0]:
		Art.shape(b, P([s * 40, -64, s * 56, -96, s * 58, -62]), Color(0.1, 0.08, 0.08), f, 2.0)

static func seraph(b) -> void:
	var t: float = b.t
	var f: float = b.flash
	var fl := sin(t * 2.6) * 8.0
	Art.glow(b, Vector2(0, -60), 80, b.acc, 0.18)
	# three pairs of burnt wings
	for s in [-1.0, 1.0]:
		Art.feather_wing(b, Vector2(s * 8, -40), s, 120, 1.15, fl, Color(0.12, 0.08, 0.14), f, 8)
		Art.feather_wing(b, Vector2(s * 8, -30), s, 96, 0.6, -fl, Color(0.2, 0.12, 0.2), f, 7)
	# tattered robe
	Art.cloth(b, Vector2(0, -50), 22, 120, 30, t, Color(0.18, 0.1, 0.2), f, 0.0, 6)
	Art.sym(b, P([0, -54, -16, -48, -20, -10, -12, 20]), Color(0.28, 0.2, 0.3), f)
	# gaunt face & hood
	Art.sym(b, P([0, -86, -20, -80, -24, -56, -12, -42]), Color(0.1, 0.06, 0.12), f)
	Art.ellipse(b, Vector2(0, -62), 12, 15, Color(0.7, 0.62, 0.58), 0.0, 1.8)
	b.draw_rect(Rect2(-9, -68, 18, 4), Color(0, 0, 0))
	Art.eye(b, Vector2(-5, -66), 2.2, b.acc)
	Art.eye(b, Vector2(5, -66), 2.2, b.acc)
	# broken halo
	b.draw_arc(Vector2(0, -92), 22, 0.4, 3.6, 22, Color(b.acc.r, b.acc.g, b.acc.b, 0.9), 3.0)
	b.draw_arc(Vector2(0, -92), 22, 4.0, 5.6, 8, Color(b.acc.r, b.acc.g, b.acc.b, 0.5), 2.0)
	# flaming sword in hand
	Art.blade(b, Vector2(-30, 10), Vector2(-46, -92), 5.0, Color(0.25, 0.25, 0.3), b.acc, f)
	Art.flame(b, Vector2(-46, -92), 26, 8, t, b.acc, 1.0)
	Art.line(b, Vector2(-16, -30), Vector2(-30, 10), Color(0.4, 0.3, 0.35), 5.0)

# ------------------------------------------------------------------ HEAVEN
static func cherub(b) -> void:
	var t: float = b.t
	var f: float = b.flash
	var fl := sin(t * 8.0) * 12.0
	Art.glow(b, Vector2.ZERO, 70, b.acc, 0.25)
	for s in [-1.0, 1.0]:
		Art.feather_wing(b, Vector2(s * 12, -6), s, 56, 1.2, fl, Color(0.88, 0.78, 0.5), f, 7)
		Art.feather_wing(b, Vector2(s * 12, 6), s, 40, 0.4, -fl, Color(0.78, 0.66, 0.4), f, 5)
	# stone-like face (porcelain mask)
	Art.ellipse(b, Vector2(0, 0), 24, 26, Color(0.9, 0.82, 0.62), f, 2.5)
	Art.shape(b, P([-18, -12, -4, -8, -6, 2, -18, 0]), Color(0.04, 0.03, 0.03), f, 1.6)
	Art.shape(b, P([18, -12, 4, -8, 6, 2, 18, 0]), Color(0.04, 0.03, 0.03), f, 1.6)
	Art.eye(b, Vector2(-11, -5), 2.2, Color(1, 0.95, 0.6))
	Art.eye(b, Vector2(11, -5), 2.2, Color(1, 0.95, 0.6))
	b.draw_line(Vector2(-8, 14), Vector2(8, 14), Art.INK, 2.0)
	b.draw_line(Vector2(0, 14), Vector2(0, 20), Art.INK, 1.5)
	# crown of thorns / halo
	b.draw_arc(Vector2(0, -34), 18, 0, TAU, 24, Color(1, 0.9, 0.5), 3.0)
	b.draw_arc(Vector2(0, -34), 18, 0, TAU, 24, Color(1, 0.9, 0.5, 0.3), 7.0)
	# cracks
	b.draw_polyline(P([10, -24, 6, -14, 12, -6]), Art.INK, 1.4)

static func knight(b) -> void:
	var t: float = b.t
	var f: float = b.flash
	Art.floor_shadow(b, Vector2(0, 84), 56)
	var plate: Color = b.col.darkened(0.12)
	Art.cloth(b, Vector2(0, -50), 26, 110, 34, t, Color(0.55, 0.07, 0.1), f, 0.0, 5)
	Art.shape(b, P([-22, 30, -4, 30, -6, 84, -26, 84]), plate.darkened(0.15), f, 2.2)
	Art.shape(b, P([4, 30, 22, 30, 26, 84, 6, 84]), plate.darkened(0.15), f, 2.2)
	Art.sym(b, P([-12, -56, -30, -48, -34, -6, -24, 34]), plate, f)
	Art.sym(b, P([-5, -48, -15, -38, -15, -4, -8, 18]), plate.lightened(0.15), f)
	# gold trim
	b.draw_line(Vector2(-26, 26), Vector2(26, 26), GOLD, 4.0)
	b.draw_line(Vector2(0, -50), Vector2(0, 26), GOLD.darkened(0.3), 2.0)
	for s in [-1.0, 1.0]:
		Art.shape(b, P([s * 20, -58, s * 46, -54, s * 46, -34, s * 24, -34]), plate.darkened(0.05), f)
		b.draw_line(Vector2(s * 20, -56), Vector2(s * 46, -52), GOLD, 3.0)
	# helm with plume
	Art.sym(b, P([0, -100, -14, -94, -16, -66, -8, -58]), plate.lightened(0.05), f)
	b.draw_rect(Rect2(-11, -82, 22, 5), Color(0, 0, 0))
	Art.eye(b, Vector2(-5, -79.5), 2.0, Color(1, 0.85, 0.4))
	Art.eye(b, Vector2(5, -79.5), 2.0, Color(1, 0.85, 0.4))
	Art.shape(b, P([-3, -100, 3, -100, 12 + sin(t * 3) * 3, -122, 0, -112, -12, -122]), Color(0.7, 0.1, 0.1), f, 1.8)
	# tower shield (left, front)
	Art.shape(b, P([-66, -48, -36, -48, -36, 30, -51, 52, -66, 30]), Color(0.5, 0.55, 0.6), f, 3.0)
	b.draw_rect(Rect2(-52.5, -40, 3, 66), Color(0.75, 0.15, 0.15))
	b.draw_rect(Rect2(-64, -14, 26, 3), GOLD)
	Art.glow(b, Vector2(-51, -12), 10, b.acc, 0.4)
	# sword (right)
	b.draw_line(Vector2(26, -42), Vector2(40, -6), Art.INK, 12.0)
	b.draw_line(Vector2(26, -42), Vector2(40, -6), plate, 8.0)
	Art.blade(b, Vector2(40, -4), Vector2(54, -112), 6.0, Color(0.88, 0.88, 0.95), b.acc, f)

static func pillar(b) -> void:
	var t: float = b.t
	var f: float = b.flash
	Art.floor_shadow(b, Vector2(0, 114), 66)
	Art.glow(b, Vector2(0, -30), 90, b.acc, 0.18)
	var st: Color = b.col.darkened(0.2)
	# base & shaft
	Art.shape(b, P([-50, 100, 50, 100, 50, 114, -50, 114]), st.darkened(0.25), f, 2.6)
	Art.shape(b, P([-40, -96, 40, -96, 44, 100, -44, 100]), st, f, 3.0)
	for k in 4:
		b.draw_line(Vector2(-22 + k * 14, -90), Vector2(-24 + k * 16, 96), Color(0, 0, 0, 0.3), 2.0)
	# capital
	Art.shape(b, P([-52, -112, 52, -112, 48, -92, -48, -92]), st.lightened(0.1), f, 2.6)
	# carved face
	Art.shape(b, P([-24, -70, 24, -70, 20, -22, 0, -10, -20, -22]), st.darkened(0.12), f, 2.2)
	b.draw_rect(Rect2(-18, -56, 36, 8), Color(0, 0, 0))
	Art.eye(b, Vector2(-8, -52), 3.0, b.acc)
	Art.eye(b, Vector2(8, -52), 3.0, b.acc)
	b.draw_line(Vector2(-8, -30), Vector2(8, -30), Art.INK, 2.5)
	# gold inlay bands
	b.draw_rect(Rect2(-43, -6, 86, 6), GOLD)
	b.draw_rect(Rect2(-45, 50, 90, 6), GOLD)
	# floating stone fists
	for s in [-1.0, 1.0]:
		var by := sin(t * 2.0 + s) * 8.0
		Art.shape(b, P([s * 66, -16 + by, s * 96, -22 + by, s * 102, 14 + by, s * 74, 24 + by]), st.lightened(0.05), f, 3.0)
		Art.glow(b, Vector2(s * 86, 4 + by), 14, b.acc, 0.35)

static func ophanim(b) -> void:
	var t: float = b.t
	var f: float = b.flash
	Art.glow(b, Vector2.ZERO, 110, b.acc, 0.2)
	var g := Color(0.88, 0.7, 0.28)
	for k in 3:
		var ang := t * (0.6 + k * 0.3) * (1.0 if k % 2 == 0 else -1.0)
		var r := 62.0 - k * 14.0
		b.draw_set_transform(Vector2.ZERO, ang, Vector2(-1.0 if b.face > 0 else 1.0, 1.0))
		b.draw_arc(Vector2.ZERO, r, 0, TAU, 40, Art.INK, 12.0)
		b.draw_arc(Vector2.ZERO, r, 0, TAU, 40, g.lightened(0.1 * k), 8.0)
		for e in 6:
			var a := TAU * float(e) / 6.0
			var ep := Vector2(cos(a), sin(a)) * r
			b.draw_circle(ep, 6.5, Art.INK)
			b.draw_circle(ep, 4.5, Color(1, 0.96, 0.8))
			b.draw_circle(ep, 2.2, Color(0.1, 0.05, 0.02))
		b.draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1.0 if b.face > 0 else 1.0, 1.0))
	# core eye
	Art.ellipse(b, Vector2.ZERO, 22, 16, Color(1, 0.97, 0.85), f, 2.5)
	Art.glow(b, Vector2.ZERO, 22, b.acc, 0.6)
	b.draw_circle(Vector2.ZERO, 9.5, Color(0.9, 0.55, 0.1))
	b.draw_circle(Vector2.ZERO, 4.5, Color(0, 0, 0))

static func archangel(b) -> void:
	var t: float = b.t
	var f: float = b.flash
	var fl := sin(t * 2.4) * 8.0
	var armor: Color = Color(0.82, 0.82, 0.9).lerp(b.col, 0.25)
	var accent: Color = b.acc
	Art.glow(b, Vector2(0, -10), 110, accent, 0.18)
	for s in [-1.0, 1.0]:
		Art.feather_wing(b, Vector2(s * 10, -50), s, 120, 1.2, fl, Color(0.88, 0.88, 0.96), f, 9)
	# robe/tabard
	Art.cloth(b, Vector2(0, -44), 24, 128, 36, t, Color(0.82, 0.8, 0.9), f, 0.0, 5)
	Art.shape(b, P([-12, -44, 12, -44, 16, 86, -16, 86]), accent.darkened(0.2), f, 2.0)
	# breastplate
	Art.sym(b, P([-6, -56, -26, -48, -28, -14, -18, 6]), armor, f)
	Art.sym(b, P([-2, -50, -12, -42, -12, -18, -6, 0]), armor.lightened(0.2), f)
	b.draw_line(Vector2(0, -56), Vector2(0, 4), accent, 2.0)
	# pauldrons
	for s in [-1.0, 1.0]:
		Art.shape(b, P([s * 18, -58, s * 44, -52, s * 44, -34, s * 22, -34]), armor.darkened(0.1), f)
		b.draw_line(Vector2(s * 18, -56), Vector2(s * 44, -50), accent, 3.0)
	# helm with visor + crest
	Art.sym(b, P([0, -96, -13, -90, -15, -66, -8, -56]), armor, f)
	b.draw_rect(Rect2(-10, -80, 20, 5), Color(0, 0, 0))
	Art.eye(b, Vector2(-5, -77.5), 2.0, accent)
	Art.eye(b, Vector2(5, -77.5), 2.0, accent)
	Art.shape(b, P([-2, -96, 2, -96, 3, -116, -3, -116]), accent, f, 1.8)
	# halo
	b.draw_arc(Vector2(0, -108), 20, 0, TAU, 26, Color(accent.r, accent.g, accent.b, 0.35), 8.0)
	b.draw_arc(Vector2(0, -108), 20, 0, TAU, 26, accent.lightened(0.3), 3.0)
	# arm + weapon (left, forward)
	b.draw_line(Vector2(-24, -42), Vector2(-46, -6), Art.INK, 12.0)
	b.draw_line(Vector2(-24, -42), Vector2(-46, -6), armor.darkened(0.2), 8.0)
	match b.arch:
		"michael":
			Art.blade(b, Vector2(-46, 2), Vector2(-52, -140), 7.0, Color(0.95, 0.95, 1.0), Color(1, 0.55, 0.3), f)
			Art.flame(b, Vector2(-52, -138), 26, 8, t, Color(1, 0.55, 0.2), 0.0)
			Art.shape(b, P([-62, 0, -30, 0, -30, 8, -62, 8]), GOLD, f, 1.8)
		"gabriel":
			Art.shape(b, P([-76, -26, -46, -34, -40, -6, -66, 6, -92, 18, -92, -20]), GOLD.lightened(0.1), f, 2.4)
			Art.glow(b, Vector2(-100, -4), 24, Color(1, 0.95, 0.6), 0.4)
		"uriel":
			Art.glow(b, Vector2(-54, -10), 34 + 5 * sin(t * 8.0), Color(1, 0.5, 0.1), 0.5)
			Art.flame(b, Vector2(-54, 4), 36, 14, t, Color(1, 0.5, 0.12), 0.0)
		"raphael":
			b.draw_line(Vector2(-48, 90), Vector2(-48, -70), Art.INK, 9.0)
			b.draw_line(Vector2(-48, 90), Vector2(-48, -70), Color(0.5, 0.36, 0.18), 5.0)
			Art.glow(b, Vector2(-48, -78), 16, Color(0.4, 1, 0.6), 0.55)
			b.draw_circle(Vector2(-48, -78), 7, Color(0.7, 1, 0.8))
		"metatron":
			for k in 4:
				var a := t * 1.4 + k * TAU / 4.0
				var pp := Vector2(cos(a) * 62.0, -24.0 + sin(a) * 30.0)
				Art.shape(b, P([pp.x, pp.y - 9, pp.x + 9, pp.y, pp.x, pp.y + 9, pp.x - 9, pp.y]), Color(1, 1, 1), f, 1.6)
		"raguel":
			b.draw_line(Vector2(-46, 4), Vector2(-46, -70), Art.INK, 7.0)
			b.draw_line(Vector2(-46, 4), Vector2(-46, -70), Color(0.6, 0.55, 0.4), 4.0)
			b.draw_line(Vector2(-66, -66), Vector2(-26, -66), accent, 3.0)
			b.draw_circle(Vector2(-66, -56), 9, accent)
			b.draw_circle(Vector2(-26, -56), 9, accent)
		_:
			Art.blade(b, Vector2(-46, 2), Vector2(-52, -110), 5.0, Color(0.9, 0.9, 1.0), accent, f)

# ------------------------------------------------------------------ BOSSES OF BOSSES
static func satan(b) -> void:
	var t: float = b.t
	var f: float = b.flash
	var fl := sin(t * 2.0) * 10.0
	Art.floor_shadow(b, Vector2(0, 150), 120)
	Art.glow(b, Vector2(0, -20), 200, Color(1, 0.25, 0.05), 0.2)
	var skin: Color = b.col.lightened(0.02)
	# huge bat wings
	if not b.game.wings:
		for s in [-1.0, 1.0]:
			Art.bat_wing(b, Vector2(s * 40, -100), s, 190, 170, fl, b.col.darkened(0.5), f)
	# lower body: pillar of flame / robes
	Art.cloth(b, Vector2(0, 10), 70, 140, 90, t, Color(0.14, 0.02, 0.04), f, 0.0, 8)
	for k in 7:
		Art.flame(b, Vector2(-78 + k * 26, 150), 40 + 14 * sin(t * 6 + k), 17, t, Color(1, 0.35, 0.08), k * 1.3)
	# torso, muscular
	Art.sym(b, P([-16, -112, -64, -102, -92, -66, -80, -10, -48, 40, -30, 60]), skin.darkened(0.15), f, 3.2)
	Art.sym(b, P([-6, -100, -40, -90, -52, -56, -42, -10, -22, 24]), skin.lightened(0.05), f, 0)
	b.draw_line(Vector2(0, -104), Vector2(0, 44), Art.INK, 2.4)
	for k in 3:
		Art.line(b, Vector2(-34 + k * 4, -64 + k * 22), Vector2(34 - k * 4, -64 + k * 22), Art.INK, 1.6)
	# breastplate of bone & iron
	Art.shape(b, P([-36, -100, 36, -100, 40, -70, 0, -56, -40, -70]), Color(0.18, 0.12, 0.12), f, 2.6)
	Art.skull(b, Vector2(0, -78), 11, BONE.darkened(0.2), Color(1, 0.4, 0.1))
	# shoulder spikes
	for s in [-1.0, 1.0]:
		Art.shape(b, P([s * 52, -108, s * 100, -106, s * 106, -66, s * 70, -62]), IRON.darkened(0.35), f, 3.0)
		for k in 3:
			Art.shape(b, P([s * (58 + k * 14), -108, s * (62 + k * 14), -138 - k * 6, s * (70 + k * 14), -106]), Color(0.1, 0.08, 0.1), f, 2.0)
	# arms, claws (left forward)
	b.draw_line(Vector2(-84, -84), Vector2(-116, -20), Art.INK, 26.0)
	b.draw_line(Vector2(-84, -84), Vector2(-116, -20), skin.darkened(0.1), 21.0)
	for k in 4:
		Art.line(b, Vector2(-118, -18), Vector2(-132 + k * 6, 12 + k * 4), BONE.darkened(0.3), 3.0)
	b.draw_line(Vector2(84, -84), Vector2(110, -20), Art.INK, 26.0)
	b.draw_line(Vector2(84, -84), Vector2(110, -20), skin.darkened(0.1), 21.0)
	# head
	Art.sym(b, P([0, -176, -26, -166, -34, -140, -24, -112, -10, -100]), skin, f, 3.0)
	b.draw_rect(Rect2(-24, -146, 48, 8), Color(0.04, 0, 0))
	Art.eye(b, Vector2(-13, -142), 5.0, Color(1.0, 0.8, 0.15))
	Art.eye(b, Vector2(13, -142), 5.0, Color(1.0, 0.8, 0.15))
	b.draw_line(Vector2(-26, -154), Vector2(-6, -146), Art.INK, 3.5)
	b.draw_line(Vector2(26, -154), Vector2(6, -146), Art.INK, 3.5)
	# fangs / jaw
	Art.shape(b, P([-16, -122, 16, -122, 12, -106, 0, -100, -12, -106]), skin.darkened(0.25), f, 2.0)
	for k in 5:
		b.draw_colored_polygon(P([-12 + k * 6, -122, -9 + k * 6, -112, -6 + k * 6, -122]), Color(0.95, 0.9, 0.8))
	# crown of horns
	Art.horn(b, Vector2(-22, -170), -2.3, 82, 11, -1.1, Color(0.16, 0.08, 0.07), f)
	Art.horn(b, Vector2(22, -170), -0.84, 82, 11, 1.1, Color(0.16, 0.08, 0.07), f)
	Art.horn(b, Vector2(-12, -176), -1.9, 52, 7, -0.5, Color(0.2, 0.1, 0.08), f)
	Art.horn(b, Vector2(12, -176), -1.24, 52, 7, 0.5, Color(0.2, 0.1, 0.08), f)
	# chest furnace glow
	Art.glow(b, Vector2(0, -20), 26 + 3 * sin(t * 3.0), Color(1, 0.4, 0.1), 0.55)

static func god(b) -> void:
	var t: float = b.t
	var f: float = b.flash
	var s: float = b.size.y / 330.0
	b.draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1.0 if b.face > 0 else 1.0, 1.0) * s)
	var raise: float = b.raise
	# radiance: long thin rays
	for k in 16:
		var a := t * 0.2 + TAU * float(k) / 16.0
		var o := Vector2(0, -120)
		b.draw_line(o + Vector2.from_angle(a) * 80.0, o + Vector2.from_angle(a) * (260.0 + 40.0 * sin(t + k)), Color(1, 0.92, 0.55, 0.22), 4.0)
	Art.glow(b, Vector2(0, -120), 150, Color(1, 0.95, 0.65), 0.35)
	# wings of burning light (many feathers)
	for sg in [-1.0, 1.0]:
		Art.feather_wing(b, Vector2(sg * 20, -70), sg, 210, 1.3, sin(t) * 6.0, Color(1, 0.96, 0.8), f, 10)
		Art.feather_wing(b, Vector2(sg * 20, -50), sg, 160, 0.5, 0.0, Color(0.95, 0.85, 0.55), f, 8)
	# robe, deep white-gold with dark folds
	Art.shape(b, P([-40, -92, 40, -92, 90, 170, -90, 170]), Color(0.96, 0.93, 0.82), f, 3.0)
	for k in 6:
		b.draw_line(Vector2(-30 + k * 12, -88), Vector2(-62 + k * 25, 166), Color(0.5, 0.42, 0.25, 0.4), 2.5)
	Art.shape(b, P([-14, -92, 14, -92, 22, 170, -22, 170]), GOLD, f, 2.4)
	# arms
	var la := Vector2(-116, -36 - 84.0 * raise)
	var ra := Vector2(116, -36)
	for pair in [[Vector2(-36, -80), la], [Vector2(36, -80), ra]]:
		Art.line(b, pair[0], pair[1], Color(0.96, 0.93, 0.82), 18.0)
	b.draw_circle(la, 11.0, Color(0.9, 0.78, 0.65))
	b.draw_circle(ra, 11.0, Color(0.9, 0.78, 0.65))
	if raise > 0.5:
		Art.glow(b, la, 44.0 + 8.0 * sin(t * 20.0), Color(1, 1, 0.8), 0.8)
	# head: stern, bearded, burning eyes
	Art.shape(b, P([-26, -150, 26, -150, 28, -112, 18, -72, 0, -58, -18, -72, -28, -112]), Color(0.86, 0.72, 0.58), f, 2.6)
	Art.shape(b, P([-26, -118, 26, -118, 20, -68, 0, -50, -20, -68]), Color(0.97, 0.97, 0.97), f, 2.0)
	Art.shape(b, P([-30, -150, 30, -150, 26, -166, 0, -170, -26, -166]), Color(0.97, 0.97, 0.97), f, 2.0)
	b.draw_line(Vector2(-20, -134), Vector2(-4, -128), Art.INK, 4.0)
	b.draw_line(Vector2(20, -134), Vector2(4, -128), Art.INK, 4.0)
	Art.eye(b, Vector2(-11, -125), 4.0, Color(0.55, 0.85, 1.0))
	Art.eye(b, Vector2(11, -125), 4.0, Color(0.55, 0.85, 1.0))
	# halo of blades
	for k in 10:
		var a := t * 0.5 + TAU * float(k) / 10.0
		var c := Vector2(0, -148)
		Art.blade(b, c + Vector2.from_angle(a) * 46.0, c + Vector2.from_angle(a) * 82.0, 4.0, Color(1, 0.97, 0.8), Color(1, 0.8, 0.3), 0.0)
	b.draw_arc(Vector2(0, -148), 46, 0, TAU, 36, Color(1, 0.9, 0.4), 4.0)
