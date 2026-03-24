extends CharacterBody3D

signal died(enemy: Node3D)
signal shoot(pos: Vector3, dir: Vector3)

@export var speed: float = 5.0
@export var max_health: int = 2
var health: int = max_health
var rng := RandomNumberGenerator.new()
var time_alive: float = 0.0
var wave_amplitude: float = 0.0

@onready var shoot_timer = $ShootTimer
@onready var enemy_mesh  = $EnemyMesh
@onready var gun_point   = $GunPoint

func _ready() -> void:
	rng.randomize()
	wave_amplitude = rng.randf_range(1.5, 4.0)
	shoot_timer.wait_time = rng.randf_range(1.5, 3.5)
	_build_enemy_mesh()
	shoot_timer.connect("timeout", _on_shoot_timer_timeout)

func _build_enemy_mesh() -> void:
	# Main body
	var body = MeshInstance3D.new()
	var bm   = CylinderMesh.new()
	bm.top_radius    = 0.3
	bm.bottom_radius = 0.8
	bm.height        = 0.4
	body.mesh = bm
	var mat  = StandardMaterial3D.new()
	mat.albedo_color            = Color(1.0, 0.2, 0.1)
	mat.emission_enabled        = true
	mat.emission                = Color(0.8, 0.1, 0.05)
	mat.emission_energy_multiplier = 0.6
	mat.metallic = 0.5
	body.material_override = mat
	enemy_mesh.add_child(body)

	# Eye / core glow
	var core = MeshInstance3D.new()
	var sm   = SphereMesh.new()
	sm.radius = 0.22
	sm.height = 0.44
	core.mesh = sm
	var cmat = StandardMaterial3D.new()
	cmat.albedo_color            = Color(1.0, 0.5, 0.0)
	cmat.emission_enabled        = true
	cmat.emission                = Color(1.0, 0.5, 0.0)
	cmat.emission_energy_multiplier = 4.0
	core.material_override = cmat
	core.position = Vector3(0, 0.3, 0)
	enemy_mesh.add_child(core)

	# Side arms
	for side in [-1, 1]:
		var arm = MeshInstance3D.new()
		var am  = BoxMesh.new()
		am.size = Vector3(0.9, 0.12, 0.35)
		arm.mesh = am
		var amat = StandardMaterial3D.new()
		amat.albedo_color = Color(0.7, 0.1, 0.05)
		amat.metallic     = 0.7
		arm.material_override = amat
		arm.position = Vector3(side * 0.85, 0, 0)
		enemy_mesh.add_child(arm)

func _physics_process(delta: float) -> void:
	time_alive += delta
	# Sinusoidal weaving movement + forward
	velocity.z = speed
	velocity.x = sin(time_alive * 1.5) * wave_amplitude
	velocity.y = cos(time_alive * 0.8) * (wave_amplitude * 0.4)
	move_and_slide()

	# Slowly rotate for visual flair
	enemy_mesh.rotation.y += delta * 1.2

	# Auto-destroy when it passes the player zone
	if position.z > 15:
		queue_free()

func take_damage(amount: int) -> void:
	health -= amount
	# Flash white
	var tween = create_tween()
	tween.tween_property(enemy_mesh, "modulate", Color(2, 2, 2), 0.05)
	tween.tween_property(enemy_mesh, "modulate", Color(1, 1, 1), 0.15)
	if health <= 0:
		emit_signal("died", self)
		queue_free()

func _on_shoot_timer_timeout() -> void:
	emit_signal("shoot", gun_point.global_position, Vector3(0, 0, 1))
	shoot_timer.wait_time = rng.randf_range(1.5, 3.5)
	shoot_timer.start()
