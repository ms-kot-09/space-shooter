extends Area3D

signal hit_enemy(enemy: Node3D, bullet: Node3D)
signal hit_player(bullet: Node3D)

@export var speed: float = 30.0
var direction: Vector3 = Vector3(0, 0, -1)
var is_player_bullet: bool = true

@onready var bullet_mesh = $BulletMesh

func _ready() -> void:
	_build_mesh()
	# Align to direction
	if direction.z > 0:
		rotation_degrees.x = 180

func _build_mesh() -> void:
	var cm   = CapsuleMesh.new()
	cm.radius = 0.08
	cm.height = 0.5
	bullet_mesh.mesh = cm
	var mat  = StandardMaterial3D.new()
	if is_player_bullet:
		mat.albedo_color            = Color(0.0, 1.0, 0.8)
		mat.emission_enabled        = true
		mat.emission                = Color(0.0, 1.0, 0.8)
		mat.emission_energy_multiplier = 5.0
	else:
		mat.albedo_color            = Color(1.0, 0.4, 0.0)
		mat.emission_enabled        = true
		mat.emission                = Color(1.0, 0.4, 0.0)
		mat.emission_energy_multiplier = 4.0
	bullet_mesh.material_override = mat

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	if is_player_bullet and body.is_in_group("enemies"):
		emit_signal("hit_enemy", body, self)
	elif not is_player_bullet and body.is_in_group("players"):
		emit_signal("hit_player", self)

func _on_life_timer_timeout() -> void:
	queue_free()
