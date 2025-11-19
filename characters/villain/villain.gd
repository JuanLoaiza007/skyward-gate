@tool
extends CharacterBody3D

enum VILLAIN { RAT }

enum State { IDLE, WALKING, RETURNING, ATTACKING }

@export var selected_villain: VILLAIN = VILLAIN.RAT
@export var speed: float = 2.0

const VILLAIN_SCENES = {
	VILLAIN.RAT: preload("res://characters/villain/rat.tscn")
}

var vision_area: Area3D
var attack_area: Area3D
var damage_area: Area3D
var rat_villain: Node3D
var vision_range: float
var attack_range: float

var current_state: State = State.IDLE
var initial_position: Vector3
var target: Node3D = null
var player_in_vision: bool = false
var can_attack: bool = true
const ATTACK_DELAY = 1.0

func _ready() -> void:
	add_to_group("villain")
	initial_position = global_position
	_update_villain()
	vision_area.body_entered.connect(_on_vision_body_entered)
	vision_area.body_exited.connect(_on_vision_body_exited)

func _update_villain() -> void:
	# Instanciar el villano seleccionado
	rat_villain = VILLAIN_SCENES[selected_villain].instantiate()
	add_child(rat_villain)

	# Asignar áreas
	vision_area = rat_villain.get_node("VisionArea")
	attack_area = rat_villain.get_node("AttackArea")
	damage_area = rat_villain.get_node("DamageArea")

	# Obtener rangos de las áreas
	var vision_shape = vision_area.get_child(0) as CollisionShape3D
	if vision_shape and vision_shape.shape is SphereShape3D:
		vision_range = vision_shape.shape.radius

	var attack_shape = attack_area.get_child(0) as CollisionShape3D
	if attack_shape and attack_shape.shape is SphereShape3D:
		attack_range = attack_shape.shape.radius

	# Copiar collider del body
	var body_collision = rat_villain.get_node("BodyCollision") as CollisionShape3D
	if body_collision:
		$CollisionShape3D.shape = body_collision.shape
		$CollisionShape3D.transform = body_collision.transform

func _physics_process(delta: float) -> void:
	# Aplicar gravedad
	if not is_on_floor():
		velocity += get_gravity() * delta

	match current_state:
		State.IDLE:
			_idle_behavior(delta)
		State.WALKING:
			_walking_behavior(delta)
		State.RETURNING:
			_returning_behavior(delta)
		State.ATTACKING:
			_attacking_behavior(delta)

	move_and_slide()

func _idle_behavior(delta: float) -> void:
	# Idle sin movimiento
	pass

func _walking_behavior(delta: float) -> void:
	if target and target.has_node("HealthComponent") and target.get_node("HealthComponent").is_alive():
		var direction = (target.global_position - global_position).normalized()
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		# Rotar solo en Y hacia el jugador
		rotation.y = atan2(direction.x, direction.z)
		# Check distance for attack
		if global_position.distance_to(target.global_position) < attack_range:
			current_state = State.ATTACKING
	else:
		current_state = State.RETURNING

func _returning_behavior(delta: float) -> void:
	var distance = global_position.distance_to(initial_position)
	if distance > 0.1:
		var direction = (initial_position - global_position).normalized()
		velocity.x = direction.x * min(speed, distance / delta)
		velocity.z = direction.z * min(speed, distance / delta)
		# Rotar solo en Y hacia la base
		rotation.y = atan2(direction.x, direction.z)
	else:
		global_position = initial_position
		velocity = Vector3.ZERO
		current_state = State.IDLE

func _attacking_behavior(delta: float) -> void:
	# Aquí lógica de ataque
	if can_attack and target and target.has_node("HealthComponent") and target.get_node("HealthComponent").is_alive():
		print("atacando a jugador")
		target.get_node("HealthComponent").take_damage(1, global_position)
		can_attack = false
		get_tree().create_timer(ATTACK_DELAY).timeout.connect(func(): can_attack = true)
		# Stay attacking
	elif target and not target.get_node("HealthComponent").is_alive():
		current_state = State.RETURNING

func _on_vision_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		target = body
		player_in_vision = true
		current_state = State.WALKING

func _on_vision_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_vision = false
		target = null
		current_state = State.RETURNING
