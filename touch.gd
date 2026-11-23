class_name Touch
extends Control
## On-screen controls for phones/tablets. Injects the same input actions as keyboard/gamepad.

var g
var active := false
var pts := {}        # touch index -> action name
var btns := {}       # action -> {c: Vector2, r: float, label: String}
var pause_btn := Rect2(1190, 90, 80, 64)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var args := OS.get_cmdline_user_args()
	active = DisplayServer.is_touchscreen_available() or OS.has_feature("web_android") or OS.has_feature("web_ios") or OS.has_feature("android") or OS.has_feature("ios") or args.has("--touch")
	btns = {
		"move_left": {"c": Vector2(120, 600), "r": 76.0, "label": "<"},
		"move_right": {"c": Vector2(300, 600), "r": 76.0, "label": ">"},
		"move_down": {"c": Vector2(210, 676), "r": 34.0, "label": "v"},
		"attack": {"c": Vector2(1150, 570), "r": 80.0, "label": "ATK"},
		"jump": {"c": Vector2(955, 640), "r": 58.0, "label": "JUMP"},
		"roll": {"c": Vector2(1150, 420), "r": 54.0, "label": "ROLL"},
		"ui_up": {"c": Vector2(1148, 400), "r": 52.0, "label": "UP"},
		"ui_down": {"c": Vector2(1148, 500), "r": 52.0, "label": "DOWN"},
		"ui_accept": {"c": Vector2(1000, 600), "r": 80.0, "label": "OK"},
	}
	for i in 4:
		btns["rune%d" % (i + 1)] = {"c": Vector2(Cfg.W * 0.5 - 150.0 + i * 78.0 + 34.0, 676), "r": 40.0, "label": ""}
	set_process_input(true)

func _in_fight() -> bool:
	return g != null and (g.state == g.S.FIGHT or g.state == g.S.PROLOGUE)

func _visible_buttons() -> Array:
	var out: Array = []
	if _in_fight():
		for k in ["move_left", "move_right", "move_down", "attack", "jump", "roll", "rune1", "rune2", "rune3", "rune4"]:
			out.append(k)
	else:
		out = ["ui_up", "ui_down", "ui_accept"]
	return out

func _hit(pos: Vector2):
	if _in_fight() and pause_btn.has_point(pos):
		return "pause"
	var best = null
	var bd := 1e9
	for k in _visible_buttons():
		var b: Dictionary = btns[k]
		var d := pos.distance_to(b["c"])
		if d <= float(b["r"]) * 1.15 and d < bd:
			bd = d
			best = k
	return best

func _press(idx: int, act, down: bool) -> void:
	if act == null:
		return
	if act == "pause":
		if down:
			g.paused = not g.paused
		return
	if down:
		pts[idx] = act
		Input.action_press(act)
	else:
		pts.erase(idx)
		if not pts.values().has(act):
			Input.action_release(act)

func _input(ev: InputEvent) -> void:
	if g == null:
		return
	if ev is InputEventScreenTouch:
		if not active:
			active = true
		if ev.pressed:
			if g.paused:
				g.paused = false
				return
			_press(ev.index, _hit(ev.position), true)
		else:
			if pts.has(ev.index):
				var a = pts[ev.index]
				pts.erase(ev.index)
				if not pts.values().has(a):
					Input.action_release(a)
	elif ev is InputEventScreenDrag:
		var a2 = _hit(ev.position)
		var old = pts.get(ev.index, null)
		if a2 != old and (old in ["move_left", "move_right"] or a2 in ["move_left", "move_right"]):
			if old != null:
				pts.erase(ev.index)
				if not pts.values().has(old):
					Input.action_release(old)
			if a2 != null and a2 != "pause":
				pts[ev.index] = a2
				Input.action_press(a2)

func _process(_dt: float) -> void:
	visible = active
	if active:
		queue_redraw()

func _draw() -> void:
	if not active or g == null:
		return
	var down := pts.values()
	for k in _visible_buttons():
		var b: Dictionary = btns[k]
		var on: bool = down.has(k)
		var c: Vector2 = b["c"]
		if String(k).begins_with("rune"):
			var idx := int(String(k).substr(4)) - 1
			if not g.runes[idx]:
				continue
			draw_circle(c, float(b["r"]), Color(1, 1, 1, 0.22 if on else 0.08))
			continue
		draw_circle(c, float(b["r"]), Color(0, 0, 0, 0.35))
		draw_circle(c, float(b["r"]) - 4.0, Color(1, 1, 1, 0.32 if on else 0.14))
		draw_arc(c, float(b["r"]) - 2.0, 0, TAU, 32, Color(1, 1, 1, 0.55), 3.0)
		var f := PixFont.get_font()
		var fs := 28 if float(b["r"]) > 60.0 else 14
		var s: String = b["label"]
		var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(f, c + Vector2(-w * 0.5, fs * 0.4), s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, 0.85))
	if _in_fight():
		draw_rect(pause_btn, Color(0, 0, 0, 0.35))
		draw_rect(pause_btn, Color(1, 1, 1, 0.5), false, 2.0)
		draw_rect(Rect2(1218, 106, 8, 32), Color(1, 1, 1, 0.8))
		draw_rect(Rect2(1234, 106, 8, 32), Color(1, 1, 1, 0.8))
