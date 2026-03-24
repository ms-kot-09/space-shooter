extends CharacterBody3D

# ─── Signals ──────────────────────────────────────────────────────────────────
signal shoot(pos: Vector3, dir: Vector3)
signal hit()

# ─── Stats ────────────────────────────────────────────────────────────────────
@export var speed: float = 10.0
@export var max_health: int = 3
var health: int = max_health
var invincible: bool = false
var can_shoot: bool = true

# ─── Boundaries ───────────────────────────────────────────────────────────────
const BOUNDS_X := 12.0
const BOUNDS_Y := 7.0

# ─── Cached nodes ─────────────────────────────────────────────────────────────
@onready var shoot_cooldown     = $ShootCooldown
@onready var invincibility_timer = $InvincibilityTimer
@onready var gun_point          = $GunPoint
@onready var ship_mesh          = $ShipMesh

# ─── Init ─────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_build_ship_mesh()

func _build_ship_mesh() -> void:
	# Build a simple procedural spaceship from primitives
	var body_mesh  = MeshInstance3D.new()
	var prism      = PrismMesh.new()
	prism.size     = Vector3(1.4, 0.35, 2.2)
	body_mesh.mesh = prism
	var body_mat   = StandardMaterial3D.new()
	body_mat.albedo_color    = Color(0.2, 0.6, 1.0)
	body_mat.emission_enabled = true
	body_mat.emission         = Color(0.1, 0.3, 0.8)
	body_mat.emission_energy_multiplier = 0.4
	body_mat.metallic        = 0.8
	body_mat.roughness       = 0.2
	body_mesh.material_override = body_mat
	body_mesh.rotation_degrees = Vector3(0, 180, 0)
	ship_mesh.add_child(body_mesh)

	# Wings
	for side in [-1, 1]:
		var wing = MeshInstance3D.new()
		var wm   = BoxMesh.new()
		wm.size  = Vector3(1.2, 0.08, 0.8)
		wing.mesh = wm
		var wmat = StandardMaterial3D.new()
		wmat.albedo_color = Color(0.15, 0.45, 0.9)
		wmat.metallic     = 0.6
		wing.material_override = wmat
		wing.position = Vector3(side * 1.1, 0, 0.2)
		ship_mesh.add_child(wing)

	# Engine glow
	var glow = MeshInstance3D.new()
	var sm   = SphereMesh.new()
	sm.radius = 0.18
	sm.height = 0.36
	glow.mesh = sm
	var gmat = StandardMaterial3D.new()
	gmat.albedo_color            = Color(0, 0.8, 1.0)
	gmat.emission_enabled        = true
	gmat.emission                = Color(0, 0.8, 1.0)
	gmat.emission_energy_multiplier = 3.0
	glow.material_override = gmat
	glow.position = Vector3(0, 0, 1.2)
	ship_mesh.add_child(glow)

# ─── Per-frame ────────────────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	_handle_movement(delta)
	_handle_shooting()
	_tilt_ship()

func _handle_movement(delta: float) -> void:
	var dir = Vector3.ZERO
	dir.x = Input.get_axis("move_left",    "move_right")
	dir.z = Input.get_axis("move_forward", "move_backward")
	velocity = dir.normalized() * speed
	move_and_slide()
	# Clamp to bounds
	position.x = clamp(position.x, -BOUNDS_X, BOUNDS_X)
	position.y = clamp(position.y, -BOUNDS_Y, BOUNDS_Y)
	position.z = clamp(position.z, -2.0, 8.0)

func _handle_shooting() -> void:
	if Input.is_action_pressed("shoot") and can_shoot:
		can_shoot = false
		shoot_cooldown.start()
		emit_signal("shoot", gun_point.global_position, Vector3(0, 0, -1))

func _tilt_ship() -> void:
	var tilt_x = -velocity.z * 0.03
	var tilt_z = -velocity.x * 0.05
	ship_mesh.rotation.x = lerp(ship_mesh.rotation.x, tilt_x, 0.15)
	ship_mesh.rotation.z = lerp(ship_mesh.rotation.z, tilt_z, 0.15)

# ─── Damage ───────────────────────────────────────────────────────────────────
func take_damage(amount: int) -> void:
	if invincible:
		return
	health -= amount
	invincible = true
	invincibility_timer.start()
	emit_signal("hit")
	# Flash red
	var tween = create_tween()
	tween.tween_property(ship_mesh, "modulate", Color(1, 0.2, 0.2), 0.1)
	tween.tween_property(ship_mesh, "modulate", Color(1, 1, 1), 0.3)

# ─── Timer callbacks ──────────────────────────────────────────────────────────
func _on_shoot_cooldown_timeout() -> void:
	can_shoot = true

func _on_invincibility_timer_timeout() -> void:
	invincible = false
