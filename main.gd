extends Node2D
## SPUD: WRATH OF THE SOIL — game flow / state machine.

enum S { TITLE, PROLOGUE, BEAM, CARD, SHRINE, INTRO, FIGHT, DYING, OUTRO, ACT_BREAK, DEAD, ENDING, CINE }

const SAVE_PATH := "user://spud_save.json"
const START_ASH := 140

var state: int = S.TITLE
var st_t := 0.0

var world: Node2D
var arena: Arena
var hazards: Node2D
var boss_layer: Node2D
var minions: Node2D
var pickups: Node2D
var player: Player
var boss: Boss = null
var fx: Fx
var sfx: Sfx
var ui: GameUI
var cine: Cine
var battle: Battle
var spared := false
var cine_seen := {}

var boss_index := 1
var ash := 0
var hp_lvl := 0
var sta_lvl := 0
var atk_lvl := 0
var runes := [true, false, false, false]
var wings := false
var deaths := 0
var play_time := 0.0

const PIX := 3
var shake := 0.0
var hitstop_t := 0.0
var red_flash := 0.0
var white_flash := 0.0
var fade := 0.0
var paused := false
var menu_sel := 0
var shrine_sel := 0
var has_save := false
var msg := ""
var msg_t := 0.0
var phase_banner := ""
var phase_banner_t := 0.0
var heal_drop_t := 20.0
var cam_x := 0.0
var special_banner := ""
var special_banner_t := 0.0
var dark_t := 0.0
const ARMOR_SLOTS_HELL := ["Horned Helm", "Spiked Pauldrons", "Cinder Cuirass", "Brand Gauntlets", "Ash Greaves"]
const ARMOR_SLOTS_HEAVEN := ["Halo Helm", "Gilded Pauldrons", "Radiant Cuirass", "Seraph Gauntlets", "Cloud Greaves"]
const ARMOR_MAX_TIER := 9
var armor_tiers: Array = [0, 0, 0, 0, 0]
var drop_note := ""

func show_special(nm: String) -> void:
	special_banner = nm
	special_banner_t = 1.6

func armor_points() -> int:
	var s := 0
	for v in armor_tiers:
		s += int(v)
	return s

func armor_shield_max() -> int:
	return mini(5, armor_points() / 4)

func _award_armor() -> void:
	var slot := (boss_index - 1) % 5
	var hell: bool = bool(Lore.boss(boss_index)["hell"])
	var piece: String = (ARMOR_SLOTS_HELL if hell else ARMOR_SLOTS_HEAVEN)[slot]
	armor_tiers[slot] = mini(ARMOR_MAX_TIER, int(armor_tiers[slot]) + 1)
	var short_name: String = String(Lore.boss(boss_index)["name"]).split(",")[0]
	drop_note = "ARMOUR DROP: %s's %s  (Tier %d)" % [short_name, piece, int(armor_tiers[slot])]

var pro_hits := 0
var pro_t := 0.0
var fall_v := 0.0
var beam_fired := false
var card_lines: Array = []
var card_next := "shrine"
var card_dur := 4.5
var reward := 0
var consolation := 0
var unlock_note := ""
var slow := 1.0
var ending_theme_set := false

# automated self-test (headless): godot --headless --path . -- --autotest
var autotest := false
var at_log: Array = []
var at_timer := 0.0
var at_dmg_mult := 40.0
var at_died_once := false

func _ready() -> void:
	_setup_inputs()
	RenderingServer.set_default_clear_color(Color.BLACK)
	# pixel-art look: the whole world renders at 1/3 resolution and is upscaled with nearest filtering
	var svp := SubViewport.new()
	svp.size = Vector2i(Cfg.W / PIX, Cfg.H / PIX)
	svp.size_2d_override = Vector2i(Cfg.W, Cfg.H)
	svp.size_2d_override_stretch = true
	svp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	svp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	add_child(svp)
	var tr := TextureRect.new()
	tr.texture = svp.get_texture()
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.size = Vector2(Cfg.W, Cfg.H)
	var sh := Shader.new()
	sh.code = """shader_type canvas_item;
uniform vec2 px = vec2(427.0, 240.0);
uniform float levels = 12.0;
void fragment() {
	vec2 e = 1.0 / px;
	vec3 c = texture(TEXTURE, UV).rgb;
	vec3 r = texture(TEXTURE, UV + vec2(e.x, 0.0)).rgb;
	vec3 l = texture(TEXTURE, UV - vec2(e.x, 0.0)).rgb;
	vec3 u = texture(TEXTURE, UV - vec2(0.0, e.y)).rgb;
	vec3 d = texture(TEXTURE, UV + vec2(0.0, e.y)).rgb;
	float lc = dot(c, vec3(0.3, 0.59, 0.11));
	float g = abs(dot(r, vec3(0.3,0.59,0.11)) - lc) + abs(dot(l, vec3(0.3,0.59,0.11)) - lc) + abs(dot(u, vec3(0.3,0.59,0.11)) - lc) + abs(dot(d, vec3(0.3,0.59,0.11)) - lc);
	// ordered dither + posterize
	vec2 p = floor(UV * px);
	float b = mod(p.x + 2.0 * p.y, 4.0) / 4.0 - 0.375;
	vec3 q = floor(c * levels + 0.5 + b * 0.12) / levels;
	q = mix(q, q * 0.5, smoothstep(0.3, 0.6, g));
	COLOR = vec4(q, 1.0);
}
"""
	var sm := ShaderMaterial.new()
	sm.shader = sh
	sm.set_shader_parameter("px", Vector2(Cfg.W / PIX, Cfg.H / PIX))
	tr.material = sm
	add_child(tr)
	world = Node2D.new(); svp.add_child(world)
	arena = Arena.new(); world.add_child(arena)
	hazards = Node2D.new(); world.add_child(hazards)
	minions = Node2D.new(); world.add_child(minions)
	boss_layer = Node2D.new(); world.add_child(boss_layer)
	pickups = Node2D.new(); world.add_child(pickups)
	player = Player.new(); player.game = self; world.add_child(player)
	fx = Fx.new(); world.add_child(fx)
	battle = Battle.new(); battle.g = self; world.add_child(battle)
	cine = Cine.new(); cine.g = self; cine.visible = false; world.add_child(cine)
	sfx = Sfx.new(); add_child(sfx)
	var cl := CanvasLayer.new(); add_child(cl)
	ui = GameUI.new(); ui.g = self; cl.add_child(ui)
	var tl := CanvasLayer.new(); tl.layer = 20; add_child(tl)
	var tc := Touch.new(); tc.g = self; tl.add_child(tc)
	has_save = FileAccess.file_exists(SAVE_PATH)
	autotest = OS.get_cmdline_user_args().has("--autotest")
	if autotest:
		sfx.enabled = false
	if OS.get_cmdline_user_args().has("--battleshots"):
		_battleshots()
		return
	if OS.get_cmdline_user_args().has("--cines"):
		_cineshots()
		return
	if OS.get_cmdline_user_args().has("--shots"):
		_shots()
		return
	if OS.get_cmdline_user_args().has("--drawtest"):
		_drawtest()
		return
	goto_title()

# --------------------------------------------------------------- input map
func _key(action: String, code: int) -> void:
	var e := InputEventKey.new()
	e.physical_keycode = code as Key
	InputMap.action_add_event(action, e)

func _setup_inputs() -> void:
	var acts := ["move_left", "move_right", "move_down", "jump", "roll", "attack", "rune1", "rune2", "rune3", "rune4"]
	for a in acts:
		if not InputMap.has_action(a):
			InputMap.add_action(a, 0.3)
	_key("move_left", KEY_A); _key("move_left", KEY_LEFT)
	_key("move_right", KEY_D); _key("move_right", KEY_RIGHT)
	_key("move_down", KEY_S); _key("move_down", KEY_DOWN)
	_key("jump", KEY_SPACE); _key("jump", KEY_W); _key("jump", KEY_UP)
	_key("roll", KEY_SHIFT); _key("roll", KEY_K)
	_key("attack", KEY_J); _key("attack", KEY_Z)
	var mb := InputEventMouseButton.new()
	mb.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("attack", mb)
	_key("rune1", KEY_1); _key("rune2", KEY_2); _key("rune3", KEY_3); _key("rune4", KEY_4)
	_key("rune1", KEY_U); _key("rune2", KEY_I); _key("rune3", KEY_O); _key("rune4", KEY_L)
	var jm := InputEventJoypadMotion.new(); jm.axis = JOY_AXIS_LEFT_X; jm.axis_value = -1.0
	InputMap.action_add_event("move_left", jm)
	var jm2 := InputEventJoypadMotion.new(); jm2.axis = JOY_AXIS_LEFT_X; jm2.axis_value = 1.0
	InputMap.action_add_event("move_right", jm2)
	var jb := {"jump": JOY_BUTTON_A, "attack": JOY_BUTTON_X, "roll": JOY_BUTTON_B, "rune1": JOY_BUTTON_Y,
		"rune2": JOY_BUTTON_LEFT_SHOULDER, "rune3": JOY_BUTTON_RIGHT_SHOULDER, "rune4": JOY_BUTTON_RIGHT_STICK}
	for k in jb:
		var e := InputEventJoypadButton.new()
		e.button_index = jb[k]
		InputMap.action_add_event(k, e)

# --------------------------------------------------------------- helpers used by other nodes
func add_hazard(h: Hazard) -> void:
	hazards.add_child(h)

func clear_hostile() -> void:
	for h in hazards.get_children():
		if h is Hazard and not h.friendly:
			h.dead = true
			h.queue_free()

func clear_all_hazards() -> void:
	for h in hazards.get_children():
		h.queue_free()
	for mn in minions.get_children():
		mn.queue_free()
	for pk in pickups.get_children():
		pk.queue_free()

# --- minions
func minion_count() -> int:
	var n := 0
	for mn in minions.get_children():
		if not mn.dead:
			n += 1
	return n

func add_minion(kind: String, pos: Vector2, tier: float) -> void:
	var mn := Minion.new()
	mn.setup(self, kind, pos, tier)
	minions.add_child(mn)
	fx.burst(pos, 8, mn.info["col"], 160.0, 4.0, 0.4)

func on_minion_killed(mn: Minion) -> void:
	var pk := Pickup.new()
	pk.setup(self, "ash", mn.position, 2 + int(mn.tier * 4.0))
	pickups.add_child(pk)
	var chance := 0.2 + (0.35 if player.hp <= int(player.max_hp * 0.5) else 0.0)
	if randf() < chance:
		var hk := Pickup.new()
		hk.setup(self, "heal", mn.position, 1)
		pickups.add_child(hk)
	player.energy = minf(player.max_energy, player.energy + 4.0)

func damage_minions_rect(rect: Rect2, dmg: float, id: int) -> bool:
	var hit := false
	for mn in minions.get_children():
		if mn is Minion and not mn.dead and not mn.hit_ids.has(id) and rect.intersects(mn.hurt_rect()):
			mn.hit_ids[id] = true
			mn.take_damage(dmg)
			hit = true
	return hit

func damage_minions_circle(pos: Vector2, r: float, dmg: float) -> bool:
	for mn in minions.get_children():
		if mn is Minion and not mn.dead and Hazard.circ_rect(pos, r, mn.hurt_rect()):
			mn.take_damage(dmg)
			return true
	return false

func shake_add(a: float) -> void:
	shake = minf(28.0, shake + a)

func hitstop(sec: float) -> void:
	hitstop_t = maxf(hitstop_t, sec)

func ui_flash_msg(s: String) -> void:
	msg = s
	msg_t = 1.2

func fmt_time(sec: float) -> String:
	var s := int(sec)
	return "%d:%02d:%02d" % [s / 3600, (s % 3600) / 60, s % 60]

func _set_state(s: int) -> void:
	state = s
	st_t = 0.0

# --------------------------------------------------------------- save / load
func save_game() -> void:
	var data := {"boss_index": boss_index, "ash": ash, "hp_lvl": hp_lvl, "sta_lvl": sta_lvl, "atk_lvl": atk_lvl,
		"runes": runes, "wings": wings, "armor": armor_tiers, "deaths": deaths, "time": play_time}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))
		f.close()
		has_save = true

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	boss_index = clampi(int(parsed.get("boss_index", 1)), 1, 50)
	ash = int(parsed.get("ash", 0))
	hp_lvl = int(parsed.get("hp_lvl", 0))
	sta_lvl = int(parsed.get("sta_lvl", 0))
	atk_lvl = int(parsed.get("atk_lvl", 0))
	var r = parsed.get("runes", [true, false, false, false])
	runes = [bool(r[0]), bool(r[1]), bool(r[2]), bool(r[3])]
	wings = bool(parsed.get("wings", false))
	var ar = parsed.get("armor", [0, 0, 0, 0, 0])
	armor_tiers = []
	for i in 5:
		armor_tiers.append(int(ar[i]) if ar is Array and i < ar.size() else 0)
	deaths = int(parsed.get("deaths", 0))
	play_time = float(parsed.get("time", 0.0))
	return true

# --------------------------------------------------------------- state entry points
func _clear_boss() -> void:
	if boss != null:
		boss.queue_free()
		boss = null

func _spawn_boss(data: Dictionary) -> void:
	_clear_boss()
	boss = Boss.new()
	boss.setup(self, data)
	boss_layer.add_child(boss)

func goto_title() -> void:
	battle.active = false
	player.visible = true
	Engine.time_scale = 1.0
	_clear_boss()
	clear_all_hazards()
	fx.clear()
	arena.set_theme("title", 0.5, 0, false)
	player.prologue = false
	player.armor = false
	player.hidden_body = false
	player.max_hp = 1; player.hp = 1
	player.spawn_at(200.0)
	player.locked = true
	player.rotation = 0.0
	player.modulate.a = 1.0
	paused = false
	fade = 0.0
	menu_sel = 1 if has_save else 0
	_set_state(S.TITLE)

func start_new_game() -> void:
	ash = START_ASH
	hp_lvl = 0; sta_lvl = 0; atk_lvl = 0
	armor_tiers = [0, 0, 0, 0, 0]
	runes = [true, false, false, false]
	wings = false
	deaths = 0
	play_time = 0.0
	boss_index = 1
	cine_seen = {}
	play_cine("intro", start_prologue)

func continue_game() -> void:
	if load_game():
		enter_shrine()

func start_prologue() -> void:
	_clear_boss()
	clear_all_hazards()
	fx.clear()
	arena.set_theme("throne", 0.0, 0, false)
	player.game = self
	player.prologue = true
	player.armor = true
	player.has_wings = false
	player.max_hp = 5; player.hp = 5
	player.max_stamina = 100.0; player.stamina = 100.0
	player.damage = 10.0
	player.spawn_at(260.0)
	player.hidden_body = false
	player.rotation = 0.0
	var gd := Lore.god_prologue()
	_spawn_boss(gd)
	boss.active = true
	boss.face = -1
	pro_hits = 0
	pro_t = 0.0
	beam_fired = false
	fall_v = 0.0
	fade = 0.0
	_set_state(S.PROLOGUE)

func on_prologue_hit() -> void:
	pro_hits += 1

func _begin_beam() -> void:
	clear_all_hazards()
	player.locked = true
	player.vel = Vector2.ZERO
	boss.frozen = true
	boss.raise = 0.0
	beam_fired = false
	_set_state(S.BEAM)

func enter_shrine() -> void:
	battle.active = false
	player.visible = true
	Engine.time_scale = 1.0
	slow = 1.0
	_clear_boss()
	clear_all_hazards()
	fx.clear()
	player.prologue = false
	player.armor = false
	player.hidden_body = false
	player.rotation = 0.0
	player.apply_upgrades()
	_test_boost()
	player.full_heal()
	player.spawn_at(Cfg.W * 0.5 - 230.0)
	player.locked = true
	var dep := 0.5
	var th := "hell"
	_theme_for(boss_index)
	th = _theme
	dep = _depth
	arena.set_theme(th, dep, boss_index, true)
	shrine_sel = 0
	fade = 0.0
	save_game()
	_set_state(S.SHRINE)

var _theme := "hell"
var _depth := 0.5
func _theme_for(i: int) -> void:
	if i == 25:
		_theme = "abyss"; _depth = 0.0
	elif i <= 24:
		_theme = "hell"; _depth = clampf(float(Lore.layer_for(i)) / 9.0, 0.0, 1.0)
	elif i <= 39:
		_theme = "storm" if i % 2 == 0 else "heaven"; _depth = 0.0
	elif i <= 49:
		_theme = "sanctuary"; _depth = 0.0
	else:
		_theme = "throne"; _depth = 0.0

func begin_intro() -> void:
	if (boss_index == 25 or boss_index == 50) and not cine_seen.has(boss_index):
		cine_seen[boss_index] = true
		play_cine("satan" if boss_index == 25 else "god", begin_intro)
		return
	if boss_index % 5 == 0 and boss_index != 25 and boss_index != 50 and not cine_seen.has(boss_index):
		cine_seen[boss_index] = true
		play_cine("elite", begin_intro)
		return
	clear_all_hazards()
	fx.clear()
	_theme_for(boss_index)
	arena.set_theme(_theme, _depth, boss_index, false)
	var data := Lore.boss(boss_index)
	_spawn_boss(data)
	boss.active = false
	boss.modulate.a = 0.0
	spared = false
	if not boss.prologue:
		boss.twists.clear()
		battle.place_boss(boss)
		boss.modulate.a = 0.0
	player.apply_upgrades()
	_test_boost()
	player.full_heal()
	player.spawn_at(220.0)
	player.locked = true
	_set_state(S.INTRO)

func begin_fight() -> void:
	player.armor_shield = armor_shield_max()
	dark_t = 0.0
	boss.modulate.a = 1.0
	if boss.prologue:
		boss.active = true
		boss.cd = 1.0
		player.locked = false
		sfx.play("roar", -4.0)
	else:
		battle.start(boss)
	_set_state(S.FIGHT)

func on_boss_phase(p: int) -> void:
	phase_banner = "PHASE " + ["I", "II", "III"][p - 1]
	phase_banner_t = 2.0
	sfx.play("roar")
	shake_add(14.0)
	white_flash = maxf(white_flash, 0.25)
	fx.ring(boss.position, 260.0, boss.acc, 0.7)

func on_boss_dead() -> void:
	clear_all_hazards()
	player.locked = true
	player.iframes = 99.0
	player.vel.x = 0.0
	sfx.play("die")
	shake_add(20.0)
	white_flash = 0.5
	slow = 0.35
	_set_state(S.DYING)

func on_player_dead() -> void:
	deaths += 1
	sfx.play("die")
	player.hidden_body = false
	consolation = int(Lore.ash_reward(boss_index) * 0.4)
	ash += consolation
	if autotest:
		at_died_once = true
	_set_state(S.DEAD)

func _begin_outro() -> void:
	reward = Lore.ash_reward(boss_index)
	if spared:
		reward = reward / 2
		drop_note = "You showed mercy. No armour drops."
	ash += reward
	if not spared:
		_award_armor()
	fx.burst(boss.position, 30, Color(1, 0.85, 0.4), 340.0, 6.0, 1.0)
	player.armor_shield = armor_shield_max()
	unlock_note = ""
	for r in range(1, 4):
		if not runes[r] and boss_index >= int(Lore.RUNE_UNLOCK_AFTER[r]):
			runes[r] = true
			unlock_note += "RUNE UNLOCKED: %s (%s — %s)\n" % [Lore.RUNES[r]["name"], Lore.RUNES[r]["school"], Lore.RUNES[r]["desc"]]
	Engine.time_scale = 1.0
	slow = 1.0
	_set_state(S.OUTRO)

func _after_outro() -> void:
	if boss_index == 25:
		_set_state(S.ACT_BREAK)
	elif boss_index == 50:
		_begin_ending()
	else:
		boss_index += 1
		var key := ""
		if boss_index == 40:
			key = "sanctuary"
		elif boss_index <= 24 and Lore.layer_for(boss_index) != Lore.layer_for(boss_index - 1):
			key = "layer%d" % Lore.layer_for(boss_index)
		if key != "":
			play_cine("area", enter_shrine, Lore.area_name(boss_index), key)
		else:
			enter_shrine()

func _after_act_break() -> void:
	wings = true
	boss_index = 26
	play_cine("ascent", func():
		show_card([
			{"text": Lore.ACT2_NAME, "size": 46, "col": Color(1, 0.9, 0.5)},
		], "shrine", 3.0))

func show_card(lines: Array, next: String, dur: float = 4.5) -> void:
	card_lines = lines
	card_next = next
	card_dur = dur
	_set_state(S.CARD)

func _end_card() -> void:
	match card_next:
		"newgame_shrine":
			ash = START_ASH
			hp_lvl = 0; sta_lvl = 0; atk_lvl = 0
			armor_tiers = [0, 0, 0, 0, 0]
			runes = [true, false, false, false]
			wings = false
			boss_index = 1
			enter_shrine()
		_:
			enter_shrine()

func _begin_ending() -> void:
	play_cine("finale", _begin_ending_real)

func play_cine(id: String, cb: Callable, title: String = "", key: String = "") -> void:
	fade = 0.0
	white_flash = 0.0
	cine.start(id, cb, title, key)
	_set_state(S.CINE)

func _s_cine(dt: float) -> void:
	fade = 0.0
	cine.tick(dt, _accept(), Input.is_action_just_pressed("ui_cancel"))

func _begin_ending_real() -> void:
	clear_all_hazards()
	player.locked = true
	player.iframes = 99.0
	ending_theme_set = false
	fade = 0.0
	player.position = Vector2(Cfg.W * 0.5, Cfg.FLOOR)
	player.vel = Vector2.ZERO
	player.modulate.a = 1.0
	_clear_boss()
	arena.set_theme("throne", 0.0, 0, false)
	white_flash = 1.0
	sfx.play("boom")
	_set_state(S.ENDING)

# --------------------------------------------------------------- frame loop
func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo:
		if ev.physical_keycode == KEY_ESCAPE and (state == S.FIGHT or state == S.PROLOGUE):
			paused = not paused
		elif ev.physical_keycode == KEY_Q and paused:
			paused = false
			goto_title()

func _process(delta: float) -> void:
	if autotest:
		_autotest_frame()
		return
	step(delta)

func step(delta: float) -> void:
	if paused:
		ui.queue_redraw()
		return
	var dt := minf(delta, 1.0 / 30.0)
	if hitstop_t > 0.0:
		hitstop_t -= delta
		dt = 0.0
	dt *= slow
	st_t += delta
	shake = move_toward(shake, 0.0, delta * 40.0)
	red_flash = maxf(0.0, red_flash - delta * 2.0)
	white_flash = maxf(0.0, white_flash - delta * 1.2)
	phase_banner_t = maxf(0.0, phase_banner_t - delta)
	special_banner_t = maxf(0.0, special_banner_t - delta)
	dark_t = maxf(0.0, dark_t - delta)
	msg_t = maxf(0.0, msg_t - delta)
	var cam_target := clampf((Cfg.W * 0.5 - player.position.x) * 0.03, -16.0, 16.0)
	cam_x = lerpf(cam_x, cam_target, 1.0 - exp(-5.0 * delta))
	world.position = Vector2(cam_x, 0.0) + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake
	arena.tick(dt)
	fx.tick(dt)
	match state:
		S.TITLE: _s_title()
		S.PROLOGUE: _s_prologue(dt)
		S.BEAM: _s_beam(dt)
		S.CARD: _s_card()
		S.SHRINE: _s_shrine(dt)
		S.INTRO: _s_intro(dt)
		S.FIGHT: _s_fight(dt)
		S.DYING: _s_dying(dt)
		S.OUTRO: _s_outro()
		S.ACT_BREAK: _s_act_break()
		S.DEAD: _s_dead()
		S.ENDING: _s_ending(dt)
		S.CINE: _s_cine(dt)
	ui.queue_redraw()

func _tick_world(dt: float) -> void:
	player.tick(dt)
	if boss != null:
		boss.tick(dt)
	for h in hazards.get_children():
		if h is Hazard:
			h.update(dt)
			if h.dead:
				h.queue_free()
	for mn in minions.get_children():
		if mn is Minion:
			mn.update(dt)
			if mn.dead:
				mn.queue_free()
	for pk in pickups.get_children():
		if pk is Pickup:
			pk.update(dt)
			if pk.dead:
				pk.queue_free()

func _accept() -> bool:
	return Input.is_action_just_pressed("ui_accept")

# --- title
func _s_title() -> void:
	player.tick(0.0)
	if Input.is_action_just_pressed("ui_down"):
		menu_sel = (menu_sel + 1) % 3
		sfx.play("select")
	if Input.is_action_just_pressed("ui_up"):
		menu_sel = (menu_sel + 2) % 3
		sfx.play("select")
	if _accept():
		sfx.play("pickup")
		match menu_sel:
			0: start_new_game()
			1:
				if has_save:
					continue_game()
			2: get_tree().quit()

# --- prologue
func _s_prologue(dt: float) -> void:
	pro_t += dt
	_tick_world(dt)
	if pro_t >= 20.0 or pro_hits >= 3:
		_begin_beam()

func _s_beam(dt: float) -> void:
	boss.tick(dt)
	boss.raise = clampf(st_t / 1.0, 0.0, 1.0)
	if st_t < 3.2:
		player.tick(dt)
	if st_t > 1.4 and st_t < 2.2 and int(st_t * 40.0) % 3 == 0:
		fx.burst(Vector2(player.position.x, 0), 2, Color(1, 1, 0.8), 80.0, 4.0, 0.4)
	if st_t >= 2.2 and not beam_fired:
		beam_fired = true
		white_flash = 1.0
		shake_add(26.0)
		sfx.play("beam")
		player.armor = false
		player.hp = 1
		player.max_hp = 1
		player.energy = 0.0
		fx.burst(player.center(), 50, Color(0.4, 0.6, 0.25), 520.0, 7.0, 1.0, 900.0)
		fx.burst(player.center(), 40, Color(1, 1, 0.8), 600.0, 5.0, 0.8, 200.0)
	if st_t >= 3.2:
		player.locked = true
		player.hidden_body = false
		fall_v += 1700.0 * dt
		player.position.y += fall_v * dt
		player.rotation += 6.0 * dt
		player.vel = Vector2.ZERO
		player.queue_redraw()
		fade = clampf((st_t - 3.6) / 1.0, 0.0, 1.0)
	if st_t >= 5.0:
		player.rotation = 0.0
		player.position.y = Cfg.FLOOR
		play_cine("descent", func():
			show_card([
				{"text": Lore.TITLE_CARD, "size": 44, "col": Color(1, 0.55, 0.2)},
				{"text": "Spud is cast down to the 9th Pit of Hell.", "size": 22, "col": Color(0.8, 0.75, 0.7), "wrap": true},
			], "newgame_shrine", 4.0))

func _s_card() -> void:
	fade = 0.0
	if (st_t > 1.5 and _accept()) or st_t >= card_dur:
		_end_card()

# --- shrine
func _s_shrine(dt: float) -> void:
	player.tick(dt)
	if Input.is_action_just_pressed("ui_down"):
		shrine_sel = (shrine_sel + 1) % 4
		sfx.play("select")
	if Input.is_action_just_pressed("ui_up"):
		shrine_sel = (shrine_sel + 3) % 4
		sfx.play("select")
	if _accept():
		if shrine_sel == 3:
			begin_intro()
			return
		var lvl: int = [hp_lvl, sta_lvl, atk_lvl][shrine_sel]
		var cost := Lore.upgrade_cost(shrine_sel, lvl)
		if lvl >= Lore.MAX_UPGRADE_LEVEL or ash < cost:
			ui_flash_msg("Not enough Soul Ash" if lvl < Lore.MAX_UPGRADE_LEVEL else "Already at maximum")
			sfx.play("hurt", -12.0)
			return
		ash -= cost
		match shrine_sel:
			0: hp_lvl += 1
			1: sta_lvl += 1
			2: atk_lvl += 1
		player.apply_upgrades()
		_test_boost()
		player.full_heal()
		sfx.play("pickup")
		fx.burst(player.center(), 24, Color(0.6, 1.0, 0.4), 260.0, 5.0, 0.7, -80.0)
		save_game()

# --- intro / fight
func _s_intro(dt: float) -> void:
	player.tick(dt)
	boss.tick(dt)
	boss.modulate.a = minf(1.0, st_t * 1.5)
	if st_t > 1.0 and _accept():
		begin_fight()
	elif st_t > 2.0 + String(boss.d["intro"]).length() / 42.0 + 2.0:
		begin_fight()

func _s_fight(dt: float) -> void:
	play_time += dt
	if battle.active:
		battle.tick(dt)
		player.tick(0.0)
		return
	heal_drop_t -= dt
	if heal_drop_t <= 0.0 and boss != null and not boss.prologue:
		heal_drop_t = 32.0
		if player.hp < player.max_hp:
			var hk := Pickup.new()
			hk.setup(self, "heal", Vector2(randf_range(160.0, Cfg.W - 160.0), 120.0), 1)
			pickups.add_child(hk)
	_tick_world(dt)

func _s_dying(dt: float) -> void:
	_tick_world(dt)
	if st_t > 0.7:
		slow = 1.0
	if boss != null and boss.die_t > 2.4:
		_begin_outro()

func _s_outro() -> void:
	player.tick(0.0)
	if st_t > 1.2 and _accept():
		_after_outro()

func _s_act_break() -> void:
	if st_t > 1.2 and _accept():
		_after_act_break()

func _s_dead() -> void:
	player.tick(0.0)
	if st_t > 1.4 and _accept():
		enter_shrine()

func _s_ending(dt: float) -> void:
	var t := st_t
	if t < 4.0 and int(t * 12.0) % 2 == 0:
		fx.burst(Vector2(randf_range(100, 1180), randf_range(80, 500)), 3, Color(1, 0.9, 0.5), 300.0, 6.0, 0.9, 500.0)
	if t > 4.0 and not ending_theme_set:
		ending_theme_set = true
		arena.set_theme("title", 0.0, 0, true)
		white_flash = 1.0
		sfx.play("boom")
		shake_add(20.0)
	if t > 4.5 and t < 12.0:
		fx.burst(Vector2(randf_range(0, 1280), -10), 1, Color(1, 0.9, 0.4), 40.0, 4.0, 3.0, 250.0)
	player.locked = true
	if t > 10.0 and t < 14.0:
		player.facing = 1
		player.position.x += 90.0 * dt
		player.modulate.a = clampf(1.0 - (t - 12.0) / 2.0, 0.0, 1.0)
	player.tick(dt)
	if t > 17.0 and _accept():
		player.rotation = 0.0
		player.modulate.a = 1.0
		goto_title()

func _battleshots() -> void:
	DirAccess.make_dir_recursive_absolute("/tmp/shots")
	sfx.enabled = false
	hp_lvl = 6
	runes = [true, true, true, true]
	boss_index = int(OS.get_environment("BI") if OS.get_environment("BI") != "" else "12")
	cine_seen = {25: true, 50: true}
	begin_intro()
	for i in 20:
		step(1.0 / 30.0)
	await _snap("bt_intro")
	begin_fight()
	for i in 60:
		step(1.0 / 30.0)
	await _snap("bt_enter")
	for i in 60:
		step(1.0 / 30.0)
	await _snap("bt_menu")
	battle.menu_i = 1
	battle.sub_n = 6
	battle._mode("act")
	step(1.0 / 30.0)
	await _snap("bt_act")
	battle._start_fightbar()
	battle.bar_x = 0.3
	step(1.0 / 30.0)
	await _snap("bt_bar")
	for pn in ["rain", "aimed", "ring", "spiral", "sweep", "cross", "lasers", "homing", "blasters", "orange_blue", "blue_bones", "blue_plat", "gravity_flip"]:
		battle.force_pat = [pn]
		battle.pat_len = 99.0
		battle._begin_pattern()
		battle.pat_len = 99.0
		player.hp = 99
		for i in 110:
			step(1.0 / 30.0)
			if battle.mode == "attack":
				battle.inv = 5.0
		await _snap("bp_" + pn)
	battle.force_pat = []
	get_tree().quit()

func _cineshots() -> void:
	DirAccess.make_dir_recursive_absolute("/tmp/shots")
	sfx.enabled = false
	arena.set_theme("hell", 0.5, 1, false)
	for id in ["elite", "area"]:
		play_cine(id, func(): pass, "THE FORGE OF AGONY", "layer6")
		paused = true
		var n := cine.beats.size()
		for b in n:
			cine.bi = b
			cine.bt = 0.0
			while cine.bt < float(cine.cur().get("dur", 4.0)) * 0.65:
				cine.tick(1.0 / 30.0, false, false)
				st_t += 1.0 / 30.0
			ui.queue_redraw()
			paused = false
			await _snap("c_%s_%d" % [id, b])
	await _snap("c_end")
	get_tree().quit()

func _snap(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("/tmp/shots/%s.png" % name)

func _shots() -> void:
	DirAccess.make_dir_recursive_absolute("/tmp/shots")
	sfx.enabled = false
	autotest = true
	goto_title()
	for i in 3:
		step(1.0 / 30.0)
	await _snap("01_title")
	start_new_game()
	for i in 60:
		step(1.0 / 30.0)
	await _snap("02_prologue")
	pro_hits = 3
	for i in 70:
		step(1.0 / 30.0)
	await _snap("03_beam")
	enter_shrine()
	for i in 10:
		step(1.0 / 30.0)
	await _snap("04_shrine")
	for bi in [1, 4, 13, 20, 25, 28, 31, 37, 42, 46, 50]:
		boss_index = bi
		hp_lvl = 6
		begin_intro()
		for i in 30:
			step(1.0 / 30.0)
		await _snap("b%02d_intro" % bi)
		begin_fight()
		boss.minion_t = 0.1
		for i in 140:
			step(1.0 / 30.0)
			if i % 20 == 0:
				player.position.x = 300.0 + i * 3.0
		await _snap("b%02d_fight" % bi)
	# movement poses
	boss_index = 3
	begin_intro()
	for i in 30:
		step(1.0 / 30.0)
	begin_fight()
	boss.active = false
	Input.action_press("move_right")
	for i in 14:
		step(1.0 / 30.0)
	await _snap("mv_run")
	Input.action_press("attack")
	for i in 3:
		step(1.0 / 30.0)
	await _snap("mv_attack")
	Input.action_release("attack")
	Input.action_release("move_right")
	Input.action_press("roll")
	for i in 5:
		step(1.0 / 30.0)
	Input.action_release("roll")
	await _snap("mv_roll")
	Input.action_press("jump")
	for i in 8:
		step(1.0 / 30.0)
	Input.action_release("jump")
	await _snap("mv_jump")
	# specials + armour screenshots
	armor_tiers = [3, 2, 4, 1, 2]
	boss_index = 20
	begin_intro()
	for i in 30:
		step(1.0 / 30.0)
	begin_fight()
	boss.sp_cd = 0.0
	boss.cd = 0.01
	player.armor_shield = 3
	for i in 75:
		step(1.0 / 30.0)
	await _snap("sp_fight")
	boss.hp = 1.0
	boss.take_damage(5.0)
	for i in 120:
		step(1.0 / 30.0)
	_begin_outro()
	for i in 50:
		step(1.0 / 30.0)
	await _snap("sp_outro")
	get_tree().quit()

func _drawtest() -> void:
	sfx.enabled = false
	player.game = self
	arena.set_theme("hell", 0.5, 0, false)
	for th in ["heaven", "storm", "sanctuary", "throne", "abyss", "title", "hell"]:
		arena.set_theme(th, 0.5, 1, th == "hell")
		printerr("ARENA ", th)
		await get_tree().process_frame
		await get_tree().process_frame
	var seen := {}
	for i in range(1, 51):
		var data := Lore.boss(i)
		var key := String(data["family"]) + String(data["arch"])
		if seen.has(key):
			continue
		seen[key] = true
		boss = Boss.new(); boss.setup(self, data); boss_layer.add_child(boss); boss.active = true
		for ph in [1, 2]:
			boss.phase = ph; boss.flash = 0.0
			printerr("BOSS ", i, " ", key, " phase ", ph)
			boss.tick(0.1)
			await get_tree().process_frame
			await get_tree().process_frame
		boss.queue_free(); boss = null
	for k in Minion.TYPES:
		var mn := Minion.new(); mn.setup(self, k, Vector2(600, 400), 0.5); minions.add_child(mn)
		printerr("MINION ", k)
		for r in 3:
			mn.update(0.1)
			mn.state = r
			await get_tree().process_frame
		mn.queue_free()
	var pd := Lore.god_prologue()
	boss = Boss.new(); boss.setup(self, pd); boss_layer.add_child(boss); boss.active = true
	printerr("PROLOGUE GOD")
	boss.raise = 1.0
	await get_tree().process_frame
	await get_tree().process_frame
	for sty in ["fire", "holy", "spear", "smite"]:
		var hz := Hazard.pillar(self, 400, 80, 0.0, 1.0, 1, Color.ORANGE, sty)
		hz.t = 0.1
		printerr("PILLAR ", sty)
		await get_tree().process_frame
		await get_tree().process_frame
		hz.queue_free()
	for kind in ["wave", "spike"]:
		printerr("HAZ ", kind)
		var hz2 := Hazard.wave(self, 300, 0, 50, 1, Color.ORANGE) if kind == "wave" else Hazard.spike(self, 300, 0.0, 1)
		hz2.t = 0.3
		await get_tree().process_frame
		await get_tree().process_frame
		hz2.queue_free()
	player.has_wings = true; player.armor = true; player.skin_t = 3.0; player.attack_t = 0.1
	player.locked = true
	printerr("PLAYER")
	await get_tree().process_frame
	await get_tree().process_frame
	printerr("DRAWTEST_DONE")
	get_tree().quit()

func _test_boost() -> void:
	if autotest:
		player.damage *= at_dmg_mult
		player.max_hp += 25
		player.hp = player.max_hp

# --------------------------------------------------------------- headless self-test
var _at_step := 0
var _at_boss_t := 0.0
var _at_state_seen := {}

func _autotest_frame() -> void:
	_at_tick(1.0 / 30.0)

func _at_press(action: String) -> void:
	Input.action_press(action)

func _at_tick(dt: float) -> void:
	at_timer += dt
	# release one-frame presses from last tick
	for a in ["ui_accept", "attack", "jump", "rune1", "rune2", "rune3", "rune4", "roll", "ui_down", "ui_up"]:
		Input.action_release(a)
	match state:
		S.TITLE:
			menu_sel = 0
			if at_timer > 0.3:
				_at_press("ui_accept")
		S.PROLOGUE:
			_at_fight_bot(true)
		S.SHRINE:
			# buy upgrades round robin then rise
			var lvl_sum := hp_lvl + sta_lvl + atk_lvl
			if at_timer > 0.2:
				at_timer = 0.0
				var cost := 9999
				var kind := 0
				if boss_index < 50:
					kind = 0 if hp_lvl < 12 else (2 if atk_lvl < 12 else 1)
				var lv: int = [hp_lvl, sta_lvl, atk_lvl][kind]
				cost = Lore.upgrade_cost(kind, lv)
				if ash >= cost and lv < Lore.MAX_UPGRADE_LEVEL and lvl_sum < 36:
					shrine_sel = kind
				else:
					shrine_sel = 3
				_at_press("ui_accept")
		S.CINE:
			if st_t > 0.5:
				_at_press("ui_accept")
		S.INTRO, S.OUTRO, S.ACT_BREAK, S.CARD:
			if st_t > 1.6:
				_at_press("ui_accept")
		S.FIGHT:
			_at_boss_t += dt
			if boss_index == 3 and not at_died_once and _at_boss_t > 1.0:
				player.hp = 0
				player.dead = true
				player.visible = true
				battle.end_battle()
				on_player_dead()
			if not battle.active and boss != null and boss.prologue:
				_at_fight_bot(false)
			if _at_boss_t > 240.0:
				at_log.append("TIMEOUT boss %d" % boss_index)
				boss.take_damage(1e9)
		S.DEAD:
			if st_t > 1.5:
				_at_press("ui_accept")
		S.ENDING:
			if st_t > 17.5:
				print("AUTOTEST_OK reached ending. deaths=%d time=%s log=%s" % [deaths, fmt_time(play_time), str(at_log)])
				get_tree().quit()
	if state != _at_step:
		_at_step = state
		_at_boss_t = 0.0
		if not _at_state_seen.has(state):
			_at_state_seen[state] = true
		if state == S.INTRO:
			print("autotest: boss %d %s" % [boss_index, Lore.boss(boss_index)["name"]])
	step(dt)

func _at_fight_bot(pro: bool) -> void:
	var b = boss
	if b == null:
		return
	var dx: float = b.position.x - player.position.x
	var want := 120.0 if not pro else 150.0
	Input.action_release("move_left"); Input.action_release("move_right")
	if absf(dx) > want:
		Input.action_press("move_right" if dx > 0 else "move_left")
	elif absf(dx) < want - 70.0:
		Input.action_press("move_left" if dx > 0 else "move_right")
	if int(at_timer * 2.0) % 3 == 0:
		Input.action_press("jump")
	Input.action_press("attack")
	if not pro:
		Input.action_press("rune%d" % (1 + int(at_timer * 3.0) % 4))
		if int(at_timer * 1.3) % 5 == 0:
			Input.action_press("roll")
