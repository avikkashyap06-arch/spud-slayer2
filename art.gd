class_name Art
extends RefCounted
## Drawing toolkit for the dark-fantasy look: shaded polygons with ink outlines,
## glows, flames, horns, wings, skulls. Every function draws onto `ci` (a CanvasItem inside _draw).

const INK := Color(0.02, 0.012, 0.02)

static func P(a: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	var i := 0
	while i + 1 < a.size():
		out.append(Vector2(a[i], a[i + 1]))
		i += 2
	return out

static func mir(pts: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(pts.size() - 1, -1, -1):
		out.append(Vector2(-pts[i].x, pts[i].y))
	return out

static func tone(c: Color, fl: float) -> Color:
	return c.lerp(Color.WHITE, clampf(fl, 0.0, 1.0) * 0.7)

## Filled polygon: vertical gradient (lit top, dark bottom) + ink outline.
static func shape(ci: CanvasItem, pts: PackedVector2Array, col: Color, fl: float = 0.0, ol: float = 2.5, hi: float = 0.22, lo: float = 0.5) -> void:
	if pts.size() < 3:
		return
	var miny := 1e9
	var maxy := -1e9
	for p in pts:
		miny = minf(miny, p.y)
		maxy = maxf(maxy, p.y)
	var span := maxf(maxy - miny, 1.0)
	var base := tone(col, fl)
	var cols := PackedColorArray()
	for p in pts:
		var k := (p.y - miny) / span
		cols.append(base.lightened(hi * (1.0 - k)).darkened(lo * k))
	ci.draw_polygon(pts, cols)
	if ol > 0.0:
		var c := pts.duplicate()
		c.append(pts[0])
		ci.draw_polyline(c, INK, ol)

## Both halves of a symmetric shape (pts is the LEFT half, listed top to bottom).
static func sym(ci: CanvasItem, left: PackedVector2Array, col: Color, fl: float = 0.0, ol: float = 2.5) -> void:
	var full := PackedVector2Array(left)
	for i in range(left.size() - 1, -1, -1):
		full.append(Vector2(-left[i].x, left[i].y))
	shape(ci, full, col, fl, ol)

static func ellipse(ci: CanvasItem, c: Vector2, rx: float, ry: float, col: Color, fl: float = 0.0, ol: float = 2.5, n: int = 22) -> void:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * float(i) / float(n)
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	shape(ci, pts, col, fl, ol)

static func line(ci: CanvasItem, a: Vector2, b: Vector2, col: Color, w: float) -> void:
	ci.draw_line(a, b, INK, w + 3.0)
	ci.draw_line(a, b, col, w)

static func glow(ci: CanvasItem, p: Vector2, r: float, col: Color, a: float = 0.35) -> void:
	for k in 5:
		ci.draw_circle(p, r * (1.0 - float(k) * 0.18), Color(col.r, col.g, col.b, a * 0.22))

static func eye(ci: CanvasItem, p: Vector2, s: float, col: Color) -> void:
	glow(ci, p, s * 3.2, col, 0.45)
	var d := PackedVector2Array([p + Vector2(-s * 1.5, s * 0.25), p + Vector2(0, -s * 0.8), p + Vector2(s * 1.5, -s * 0.2), p + Vector2(0, s * 0.6)])
	ci.draw_colored_polygon(d, col.lightened(0.35))
	ci.draw_circle(p + Vector2(0, -s * 0.1), s * 0.35, Color.WHITE)

static func flame(ci: CanvasItem, base: Vector2, h: float, w: float, t: float, col: Color, ph: float = 0.0) -> void:
	for layer in 3:
		var k := 1.0 - float(layer) * 0.28
		var c := col.lightened(float(layer) * 0.28)
		c.a = 0.85 if layer < 2 else 0.95
		var sway := sin(t * 9.0 + ph + layer) * w * 0.35
		var pts := PackedVector2Array([
			base + Vector2(-w * k, 0), base + Vector2(-w * 0.55 * k, -h * 0.45 * k),
			base + Vector2(sway, -h * k), base + Vector2(w * 0.5 * k, -h * 0.45 * k), base + Vector2(w * k, 0)])
		ci.draw_colored_polygon(pts, c)

## Curved horn from `base`, initially pointing at `ang` (radians), bending by `bend`.
static func horn(ci: CanvasItem, base: Vector2, ang: float, length: float, w: float, bend: float, col: Color, fl: float = 0.0) -> void:
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	var steps := 9
	var p := base
	var a := ang
	for i in steps + 1:
		var k := float(i) / float(steps)
		var ww := w * (1.0 - k)
		var nrm := Vector2.from_angle(a + PI * 0.5)
		left.append(p + nrm * ww)
		right.append(p - nrm * ww)
		p += Vector2.from_angle(a) * (length / float(steps))
		a += bend / float(steps)
	var pts := PackedVector2Array(left)
	for i in range(right.size() - 1, -1, -1):
		pts.append(right[i])
	shape(ci, pts, col, fl, 2.0, 0.3, 0.55)

static func skull(ci: CanvasItem, p: Vector2, s: float, col: Color, eye_col: Color = Color(1, 0.5, 0.1)) -> void:
	ellipse(ci, p, s, s * 0.9, col, 0.0, 1.8, 14)
	shape(ci, P([p.x - s * 0.55, p.y + s * 0.6, p.x + s * 0.55, p.y + s * 0.6, p.x + s * 0.4, p.y + s * 1.25, p.x - s * 0.4, p.y + s * 1.25]), col.darkened(0.15), 0.0, 1.6)
	ci.draw_circle(p + Vector2(-s * 0.4, 0), s * 0.26, INK)
	ci.draw_circle(p + Vector2(s * 0.4, 0), s * 0.26, INK)
	ci.draw_circle(p + Vector2(-s * 0.4, 0), s * 0.1, eye_col)
	ci.draw_circle(p + Vector2(s * 0.4, 0), s * 0.1, eye_col)
	ci.draw_colored_polygon(P([p.x, p.y + s * 0.2, p.x - s * 0.12, p.y + s * 0.5, p.x + s * 0.12, p.y + s * 0.5]), INK)

## Leathery bat wing. side = -1 (left) or 1 (right). span/height in px.
static func bat_wing(ci: CanvasItem, root: Vector2, side: float, span: float, height: float, flap: float, col: Color, fl: float = 0.0) -> void:
	var tips: Array = []
	for i in 4:
		var k := float(i) / 3.0
		tips.append(root + Vector2(side * span * (0.55 + 0.45 * sin(k * 1.4 + 0.3)), -height * (1.0 - k * 1.25) + flap * (1.0 - k * 0.4)))
	var pts := PackedVector2Array([root])
	for i in 4:
		pts.append(tips[i])
		if i < 3:
			var mid: Vector2 = (tips[i] + tips[i + 1]) * 0.5
			pts.append(mid.lerp(root, 0.28))
	shape(ci, pts, col, fl, 2.2, 0.15, 0.55)
	for i in 4:
		line(ci, root, tips[i], col.lightened(0.15), 2.2)

## Layered feathered wing (angelic). side = -1 / 1.
static func feather_wing(ci: CanvasItem, root: Vector2, side: float, length: float, spread: float, flap: float, col: Color, fl: float = 0.0, n: int = 9) -> void:
	for layer in 2:
		for i in n:
			var k := float(i) / float(n - 1)
			var a := -PI * 0.5 + side * (0.25 + spread * k) + flap * 0.02 * (1.0 - k)
			var l := length * (0.55 + 0.45 * sin(k * PI * 0.85 + 0.35)) * (1.0 - 0.25 * float(layer))
			var wdt := length * 0.075 * (1.0 - 0.2 * float(layer))
			var p0 := root + Vector2.from_angle(a) * (6.0 + 8.0 * float(layer))
			var dirv := Vector2.from_angle(a)
			var nrm := Vector2(-dirv.y, dirv.x)
			var tip := p0 + dirv * l
			var pts := PackedVector2Array([p0 + nrm * wdt * 0.4, p0 + dirv * l * 0.55 + nrm * wdt, tip, p0 + dirv * l * 0.55 - nrm * wdt, p0 - nrm * wdt * 0.4])
			var cc := col.darkened(0.12 * float(layer)).lerp(col.lightened(0.25), k * 0.6)
			shape(ci, pts, cc, fl, 1.6, 0.2, 0.35)

static func chain(ci: CanvasItem, a: Vector2, b: Vector2, sag: float, col: Color = Color(0.5, 0.5, 0.55)) -> void:
	var prev := a
	for i in 1 + 8:
		var k := float(i) / 8.0
		var p := a.lerp(b, k) + Vector2(0, sin(k * PI) * sag)
		ci.draw_line(prev, p, INK, 4.5)
		ci.draw_line(prev, p, col, 2.5)
		prev = p

static func blade(ci: CanvasItem, base: Vector2, tip: Vector2, w: float, col: Color, edge: Color, fl: float = 0.0) -> void:
	var dirv := (tip - base).normalized()
	var nrm := Vector2(-dirv.y, dirv.x)
	var pts := PackedVector2Array([base + nrm * w, base + dirv * (tip - base).length() * 0.85 + nrm * w * 0.9, tip, base + dirv * (tip - base).length() * 0.85 - nrm * w * 0.9, base - nrm * w])
	shape(ci, pts, col, fl, 2.0, 0.35, 0.35)
	ci.draw_line(base, tip, edge, 1.6)

## Tattered hanging cloth: top width tw, hang length, animated bottom edge.
static func cloth(ci: CanvasItem, top: Vector2, tw: float, hang: float, bw: float, t: float, col: Color, fl: float = 0.0, ph: float = 0.0, teeth: int = 6) -> void:
	var pts := PackedVector2Array([top + Vector2(-tw, 0), top + Vector2(tw, 0)])
	for i in teeth + 1:
		var k := float(i) / float(teeth)
		var x := bw - 2.0 * bw * k
		var yy := hang * (1.0 - 0.18 * float(i % 2)) + sin(t * 2.2 + k * 5.0 + ph) * 5.0
		pts.append(top + Vector2(x + sin(t * 1.6 + k * 4.0 + ph) * 6.0, yy))
	shape(ci, pts, col, fl, 2.2, 0.15, 0.6)

## Soft shadow ellipse on the floor under ground bosses.
static func floor_shadow(ci: CanvasItem, p: Vector2, rx: float) -> void:
	for k in 3:
		ci.draw_set_transform(p, 0.0, Vector2(1.0, 0.16))
		ci.draw_circle(Vector2.ZERO, rx * (1.0 - float(k) * 0.25), Color(0, 0, 0, 0.18))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
