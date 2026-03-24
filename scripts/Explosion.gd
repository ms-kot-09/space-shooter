extends Node3D

var particles: Array[MeshInstance3D] = []
var velocities: Array[Vector3] = []
var lifetimes: Array[float] = []
var time: float = 0.0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	_spawn_particles()
	# Auto-destroy after 1.5 seconds
	var timer = get_tree().create_timer(1.5)
	timer.connect("timeout", queue_free)

func _spawn_particles() -> void:
	var count = rng.randi_range(15, 30)
	for i in count:
		var p   = MeshInstance3D.new()
		var sm  = SphereMesh.new()
		var sz  = rng.randf_range(0.06, 0.28)
		sm.radius = sz
		sm.height = sz * 2
		p.mesh  = sm
		var mat = StandardMaterial3D.new()
		var hue = rng.randf_range(0.0, 0.12)  # orange-red spectrum
		mat.albedo_color            = Color.from_hsv(hue, 1.0, 1.0)
		mat.emission_enabled        = true
		mat.emission                = mat.albedo_color
		mat.emission_energy_multiplier = rng.randf_range(3.0, 6.0)
		p.material_override = mat
		add_child(p)
		particles.append(p)
		# Random outward velocity
		var vel = Vector3(
			rng.randf_range(-1, 1),
			rng.randf_range(-1, 1),
			rng.randf_range(-1, 1)
		).normalized() * rng.randf_range(3.0, 10.0)
		velocities.append(vel)
		lifetimes.append(rng.randf_range(0.4, 1.2))

func _process(delta: float) -> void:
	time += delta
	for i in particles.size():
		if not is_instance_valid(particles[i]):
			continue
		# Physics
		velocities[i] *= pow(0.92, delta * 60)
		particles[i].position += velocities[i] * delta
		# Fade out
		var age_ratio = time / lifetimes[i]
		var alpha = clamp(1.0 - age_ratio, 0.0, 1.0)
		particles[i].modulate.a = alpha
		# Shrink
		var scale_v = lerp(1.0, 0.0, age_ratio)
		particles[i].scale = Vector3.ONE * scale_v
