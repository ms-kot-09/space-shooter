extends Node3D

# ─── Game State ───────────────────────────────────────────────────────────────
var score: int = 0
var lives: int = 3
var wave: int = 1
var game_over: bool = false
var paused: bool = false
var enemies_killed_this_wave: int = 0
var enemies_per_wave: int = 5

# ─── Scene References ─────────────────────────────────────────────────────────
var player_scene = preload("res://scenes/Player.tscn")
var enemy_scene  = preload("res://scenes/Enemy.tscn")

var player_node: Node3D = null

# ─── Cached UI Nodes ──────────────────────────────────────────────────────────
@onready var score_label     = $UI/HUD/ScoreLabel
@onready var lives_label     = $UI/HUD/LivesLabel
@onready var wave_label      = $UI/HUD/WaveLabel
@onready var game_over_screen = $UI/GameOverScreen
@onready var final_score_label = $UI/GameOverScreen/Panel/FinalScore
@onready var pause_screen    = $UI/PauseScreen
@onready var enemies_node    = $Enemies
@onready var bullets_node    = $Bullets
@onready var explosions_node = $Explosions
@onready var spawn_timer     = $SpawnTimer
@onready var starfield_node  = $Starfield

# ─── Init ─────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_create_starfield()
	_spawn_player()
	_update_ui()
	spawn_timer.wait_time = _spawn_interval()

func _create_starfield() -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	for i in 300:
		var star = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = rng.randf_range(0.03, 0.12)
		sphere.height = sphere.radius * 2
		star.mesh = sphere
		var mat = StandardMaterial3D.new()
		var brightness = rng.randf_range(0.6, 1.0)
		mat.albedo_color = Color(brightness, brightness, brightness * rng.randf_range(0.8, 1.0))
		mat.emission_enabled = true
		mat.emission = mat.albedo_color
		mat.emission_energy_multiplier = rng.randf_range(0.5, 2.0)
		star.material_override = mat
		star.position = Vector3(
			rng.randf_range(-50, 50),
			rng.randf_range(-30, 30),
			rng.randf_range(-80, -10)
		)
		starfield_node.add_child(star)

func _spawn_player() -> void:
	player_node = player_scene.instantiate()
	add_child(player_node)
	player_node.position = Vector3(0, 0, 5)
	player_node.connect("shoot", _on_player_shoot)
	player_node.connect("hit", _on_player_hit)

# ─── Input ────────────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not game_over:
		_toggle_pause()

func _toggle_pause() -> void:
	paused = !paused
	get_tree().paused = paused
	pause_screen.visible = paused

# ─── Spawning ─────────────────────────────────────────────────────────────────
func _on_spawn_timer_timeout() -> void:
	if game_over or paused:
		return
	_spawn_enemy()

func _spawn_enemy() -> void:
	var enemy = enemy_scene.instantiate()
	enemies_node.add_child(enemy)
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	enemy.position = Vector3(rng.randf_range(-10, 10), rng.randf_range(-4, 4), -30)
	enemy.speed = 4.0 + wave * 0.5
	enemy.connect("died", _on_enemy_died)
	enemy.connect("shoot", _on_enemy_shoot)

func _spawn_interval() -> float:
	return max(0.5, 2.0 - wave * 0.15)

# ─── Bullets ──────────────────────────────────────────────────────────────────
func _on_player_shoot(pos: Vector3, dir: Vector3) -> void:
	_create_bullet(pos, dir, true)

func _on_enemy_shoot(pos: Vector3, dir: Vector3) -> void:
	_create_bullet(pos, dir, false)

func _create_bullet(pos: Vector3, dir: Vector3, is_player: bool) -> void:
	var bullet_scene = preload("res://scenes/Bullet.tscn")
	var bullet = bullet_scene.instantiate()
	bullets_node.add_child(bullet)
	bullet.position = pos
	bullet.direction = dir
	bullet.is_player_bullet = is_player
	if is_player:
		bullet.connect("hit_enemy", _on_bullet_hit_enemy)
	else:
		bullet.connect("hit_player", _on_bullet_hit_player)

func _on_bullet_hit_enemy(enemy: Node3D, bullet: Node3D) -> void:
	_spawn_explosion(enemy.position)
	enemy.take_damage(1)
	bullet.queue_free()

func _on_bullet_hit_player(bullet: Node3D) -> void:
	if player_node:
		player_node.take_damage(1)
	bullet.queue_free()

# ─── Enemy Events ─────────────────────────────────────────────────────────────
func _on_enemy_died(enemy: Node3D) -> void:
	score += 100 + wave * 10
	enemies_killed_this_wave += 1
	_spawn_explosion(enemy.position)
	_update_ui()
	if enemies_killed_this_wave >= enemies_per_wave:
		_next_wave()

# ─── Player Events ────────────────────────────────────────────────────────────
func _on_player_hit() -> void:
	lives -= 1
	_update_ui()
	if lives <= 0:
		_trigger_game_over()

# ─── Wave ─────────────────────────────────────────────────────────────────────
func _next_wave() -> void:
	wave += 1
	enemies_killed_this_wave = 0
	enemies_per_wave = 5 + wave * 2
	spawn_timer.wait_time = _spawn_interval()
	wave_label.text = "WAVE %d" % wave
	# Flash wave label
	var tween = create_tween()
	tween.tween_property(wave_label, "modulate", Color(1, 1, 0), 0.2)
	tween.tween_property(wave_label, "modulate", Color(1, 1, 1), 0.5)

# ─── Explosion ────────────────────────────────────────────────────────────────
func _spawn_explosion(pos: Vector3) -> void:
	var exp_scene = preload("res://scenes/Explosion.tscn")
	var exp = exp_scene.instantiate()
	explosions_node.add_child(exp)
	exp.position = pos

# ─── Game Over ────────────────────────────────────────────────────────────────
func _trigger_game_over() -> void:
	game_over = true
	if player_node:
		_spawn_explosion(player_node.position)
		player_node.queue_free()
		player_node = null
	final_score_label.text = "SCORE: %d" % score
	game_over_screen.visible = true

func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()

func _on_resume_pressed() -> void:
	_toggle_pause()

# ─── UI ───────────────────────────────────────────────────────────────────────
func _update_ui() -> void:
	score_label.text = "SCORE: %d" % score
	var hearts = ""
	for i in lives:
		hearts += "❤️"
	lives_label.text = "LIVES: " + hearts
	wave_label.text = "WAVE %d" % wave
