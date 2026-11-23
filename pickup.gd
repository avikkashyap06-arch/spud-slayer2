class_name Pickup
extends Node2D
## Dropped by slain creatures: "ash" (Soul Ash + rune energy) or "heal" (a green sprout, +1 HP).

var game
var kind := "ash"
var value := 2
var vel := Vector2.ZERO
var life := 12.0
var t := 0.0
var dead := false

func setup(g, k: String, pos: Vector2, v: int) -> void:
	game = g
	kind = k
	position = pos
	value = v
	vel = Vector2(randf_range(-120, 120), randf_range(-380, -220))

func update(dt: float) -> void:
	t += dt
	life -= dt
	vel.y += 1400.0 * dt
	position += vel * dt
	if position.y >= Cfg.FLOOR - 8.0:
		position.y = Cfg.FLOOR - 8.0
		vel = Vector2(vel.x * 0.5, 0.0)
	position.x = clampf(position.x, 20.0, Cfg.W - 20.0)
	var p: Player = game.player
	if not p.dead and p.center().distance_to(position) < 40.0:
		dead = true
		game.sfx.play("pickup", -8.0, 1.2 if kind == "ash" else 0.8)
		if kind == "ash":
			game.ash += value
			p.energy = minf(p.max_energy, p.energy + 6.0)
			game.fx.popup(position + Vector2(0, -16), "+%d" % value, Color(0.85, 0.9, 1.0))
		else:
			if p.hp < p.max_hp:
				p.hp += 1
				game.fx.popup(position + Vector2(0, -16), "+1 HP", Color(0.6, 1.0, 0.5))
			game.fx.burst(position, 12, Color(0.6, 1.0, 0.4), 160.0, 4.0, 0.5, -60.0)
	if life <= 0.0:
		dead = true
	queue_redraw()

func _draw() -> void:
	var a := 1.0 if life > 3.0 or int(t * 10.0) % 2 == 0 else 0.3
	if kind == "ash":
		draw_circle(Vector2.ZERO, 9.0, Color(1.0, 0.9, 0.5, 0.25 * a))
		draw_circle(Vector2.ZERO, 5.0, Color(0.9, 0.85, 0.7, a))
		draw_circle(Vector2(-1, -1), 2.0, Color(1, 1, 1, a))
	else:
		draw_circle(Vector2.ZERO, 12.0, Color(0.5, 1.0, 0.4, 0.25 * a))
		draw_line(Vector2(0, 6), Vector2(0, -4), Color(0.4, 0.8, 0.3, a), 3.0)
		draw_circle(Vector2(-4, -6), 4.0, Color(0.55, 1.0, 0.4, a))
		draw_circle(Vector2(4, -6), 4.0, Color(0.55, 1.0, 0.4, a))
