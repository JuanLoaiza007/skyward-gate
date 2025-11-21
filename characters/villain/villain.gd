@tool
extends CharacterBody3D

enum VillainType { RAT, DOG, COC }

enum State { IDLE, WALKING, RETURNING, ATTACKING, ATTACKING_DELAY }

const VILLAIN_SCENES = {
	VillainType.RAT: preload("res://characters/villain/rat.tscn"),
	VillainType.DOG: preload("res://characters/villain/dog.tscn"),
	VillainType.COC: preload("res://characters/villain/coc.tscn")
}

@export var villain_type: VillainType = VillainType.RAT:
	set(value):
		villain_type = value
		if Engine.is_editor_hint():
			_update_villain()
@export var speed: float = 5

func _update_villain() -> void:
	# Remove existing villain instance
	for child in get_children():
		if child != $AttackDelayTimmer:
			child.queue_free()
	# Instance the new villain
	var villain_scene = VILLAIN_SCENES[villain_type].instantiate()
	add_child(villain_scene)

	# Reparent collision shape to the root for physics, or add default
	if villain_scene.has_node("CollisionShape3D"):
		var collision_shape = villain_scene.get_node("CollisionShape3D")
		villain_scene.remove_child(collision_shape)
		add_child(collision_shape)
	else:
		# Add default collision for villains without one (e.g., COC)
		var default_shape = CapsuleShape3D.new()
		default_shape.radius = 0.5
		default_shape.height = 1.0
		var default_collision = CollisionShape3D.new()
		default_collision.shape = default_shape
		add_child(default_collision)

var vision_area: Area3D
var attack_area: Area3D
var damage_area: Area3D
var vision_range: float
var attack_range: float

var current_state: State = State.IDLE
var initial_position: Vector3
var target: Node3D = null
var player_attack_area: Area3D = null
var in_player_attack_area: bool = false
var player_in_vision: bool = false
var can_attack: bool = true
const ATTACK_DELAY = 2.0
var attack_delay_timer = null
var is_attacking_delay: bool = false

signal villain_attacked(damage: int, target: Node3D)

func _ready() -> void:
	if Engine.is_editor_hint():
		_update_villain()
		return

	add_to_group("villain")
	initial_position = global_position

	# Instance the villain scene
	var villain_scene = VILLAIN_SCENES[villain_type].instantiate()
	add_child(villain_scene)

	# Verify required nodes in the instanced scene
	if not villain_scene.has_node("VisionArea"):
		push_error("Villain must have a VisionArea node")
		return
	if not villain_scene.has_node("AttackArea"):
		push_error("Villain must have an AttackArea node")
		return
	if not villain_scene.has_node("DamageArea"):
		push_error("Villain must have a DamageArea node")
		return
	# Note: COC doesn't have collision, will add default

	# Assign areas
	vision_area = villain_scene.get_node("VisionArea")
	attack_area = villain_scene.get_node("AttackArea")
	damage_area = villain_scene.get_node("DamageArea")

	vision_area.body_entered.connect(_on_vision_body_entered)
	vision_area.body_exited.connect(_on_vision_body_exited)
	damage_area.body_entered.connect(_on_damage_body_entered)

	# Reparent collision shape to the root for physics, or add default
	if villain_scene.has_node("CollisionShape3D"):
		var collision_shape = villain_scene.get_node("CollisionShape3D")
		villain_scene.remove_child(collision_shape)
		add_child(collision_shape)
	else:
		# Add default collision for villains without one (e.g., COC)
		var default_shape = CapsuleShape3D.new()
		default_shape.radius = 0.5
		default_shape.height = 1.0
		var default_collision = CollisionShape3D.new()
		default_collision.shape = default_shape
		add_child(default_collision)

	# Get ranges
	var vision_shape = vision_area.get_child(0) as CollisionShape3D
	if vision_shape and vision_shape.shape is SphereShape3D:
		vision_range = vision_shape.shape.radius

	var attack_shape = attack_area.get_child(0) as CollisionShape3D
	if attack_shape and attack_shape.shape is SphereShape3D:
		attack_range = attack_shape.shape.radius

func _physics_process(delta: float) -> void:
	# Aplicar gravedad
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Forzar estado ATTACKING_DELAY si está en delay
	if is_attacking_delay:
		current_state = State.ATTACKING_DELAY
		velocity = Vector3.ZERO
		if attack_delay_timer:
			print("Attack delay time left: ", attack_delay_timer.time_left)
		return

	match current_state:
		State.IDLE:
			_idle_behavior(delta)
		State.WALKING:
			_walking_behavior(delta)
		State.RETURNING:
			_returning_behavior(delta)
		State.ATTACKING:
			_attacking_behavior(delta)
		State.ATTACKING_DELAY:
			pass  # Handled above

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
	if can_attack and target and in_player_attack_area and target.has_node("HealthComponent") and target.get_node("HealthComponent").is_alive():
		target.get_node("HealthComponent").take_damage(1, global_position)
		villain_attacked.emit(1, target)
		can_attack = false

		# Cortar visión durante el delay
		vision_area.body_entered.disconnect(_on_vision_body_entered)
		vision_area.body_exited.disconnect(_on_vision_body_exited)
		player_in_vision = false
		target = null

		is_attacking_delay = true
		attack_delay_timer = $AttackDelayTimmer
		attack_delay_timer.start(ATTACK_DELAY)
		attack_delay_timer.timeout.connect(_on_attack_delay_timeout)
		current_state = State.ATTACKING_DELAY
	elif target and not target.get_node("HealthComponent").is_alive():
		current_state = State.RETURNING

func _on_vision_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		target = body
		player_attack_area = target.get_node("AttackArea") as Area3D
		if player_attack_area:
			player_attack_area.body_entered.connect(_on_player_attack_area_body_entered)
			player_attack_area.body_exited.connect(_on_player_attack_area_body_exited)
		player_in_vision = true
		current_state = State.WALKING

func _on_vision_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_vision = false
		target = null
		if player_attack_area:
			player_attack_area.body_entered.disconnect(_on_player_attack_area_body_entered)
			player_attack_area.body_exited.disconnect(_on_player_attack_area_body_exited)
		player_attack_area = null
		in_player_attack_area = false
		current_state = State.RETURNING

func _on_player_attack_area_body_entered(body: Node3D) -> void:
	if body == self:
		in_player_attack_area = true

func _on_player_attack_area_body_exited(body: Node3D) -> void:
	if body == self:
		in_player_attack_area = false

func _on_damage_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and body.has_node("HealthComponent"):
		body.get_node("HealthComponent").take_damage(1, global_position)

func _on_attack_delay_timeout() -> void:
	is_attacking_delay = false
	can_attack = true
	attack_delay_timer = null
	# Restaurar visión
	vision_area.body_entered.connect(_on_vision_body_entered)
	vision_area.body_exited.connect(_on_vision_body_exited)
	# Verificar si el jugador está aún en visión
	var player_found = false
	for body in vision_area.get_overlapping_bodies():
		if body.is_in_group("player"):
			player_found = true
			target = body
			player_attack_area = target.get_node("AttackArea") as Area3D
			if player_attack_area:
				player_attack_area.body_entered.connect(_on_player_attack_area_body_entered)
				player_attack_area.body_exited.connect(_on_player_attack_area_body_exited)
				# Verificar si estamos en el AttackArea
				for b in player_attack_area.get_overlapping_bodies():
					if b == self:
						in_player_attack_area = true
						break
			player_in_vision = true
			break
	if player_found and target and target.has_node("HealthComponent") and target.get_node("HealthComponent").is_alive():
		current_state = State.WALKING
	else:
		current_state = State.RETURNING
