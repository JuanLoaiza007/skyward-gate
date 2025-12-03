extends CharacterBody3D

# ====== CAMERA ======
const CAMERA_SENSIBILITY = 0.4
const CAMERA_PITCH_MIN = -20.0
const CAMERA_PITCH_MAX = 45.0

# ====== PLAYER ======
# ===> MOVEMENT
const SPEED = 5.0
const RUN_SPEED = 10.0
const JUMP_VELOCITY = 6.0
const JUMP_HORIZONTAL_BOOST = 5.0
const AIR_CONTROL_ACCEL = 5
# RigidBody Effects
const PUSH_FORCE_GROUND = 1.0
const MOVEMENT_THRESHOLD = 0.1
# Footsteps Audio
const FOOTSTEP_PITCH_DEFAULT = 1.0
const FOOTSTEP_PITCH_RUN = 1.2
const FOOTSTEP_PITCH_WALK = 0.8

# ===> COMBAT AND DAMAGE
# On receive damage
const KNOCKBACK_Y = 6.0
const KNOCKBACK_HORIZONTAL = 30.0
# On attack
const ATTACK_DAMAGE = 1
const ATTACK_RANGE = 1.5
const ATTACK_COOLDOWN = 0.5


@onready var camera = $CameraPivot
@onready var foot_raycast = $FootRayCast
@onready var footsteps_audio = $FootstepsAudio
@onready var actions_audio = $ActionsAudio
@onready var health_component = $HealthComponent
@onready var attack_hitbox = $AttackHitbox
@onready var attack_cooldown_timer = $AttackCooldownTimer
# var victory_ui: Control
var game_finished = false
signal player_died(last_damage_source: Vector3)
var state_machine: PlayerStateMachine
var initial_position: Vector3
var is_dead = false
var last_damage_source: Vector3
@onready var grass_sound = load("res://assets/audio/sfx/gravel_footsteps.mp3")
@onready var concrete_sound = load("res://assets/audio/sfx/concrete_footsteps.mp3")
@onready var attacking = load("res://assets/audio/sfx/sword-slice-distorted.wav")

var push_direction: Vector3 = Vector3.ZERO
var can_attack: bool = true

func _ready() -> void:
	add_to_group("player")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	initial_position = global_position
	state_machine = PlayerStateMachine.new()
	add_child(state_machine)
	state_machine.name = "StateMachine"
	# victory_ui = get_node("/root/Main/GameWorld/CanvasLayer/VictoryControl")
	# Load health from game state
	
	if attack_hitbox:
		attack_hitbox.body_entered.connect(_on_attack_hitbox_body_entered)
		attack_hitbox.monitoring = false
		
	if attack_cooldown_timer:
		attack_cooldown_timer.timeout.connect(_on_attack_cooldown_timeout)
	
	if GameStateManager:
		GameStateManager.load()
		var health = GameStateManager.game_data[GameStateManager.GAME_DATA.PLAYER_HEALTH]
		if health <= 0:
			health = 3
			GameStateManager.game_data[GameStateManager.GAME_DATA.PLAYER_HEALTH] = health
		health_component.set_health(health)
	# Connect signals
	health_component.health_changed.connect(_on_health_changed)
	health_component.damaged.connect(_on_damaged)
	health_component.died.connect(_on_died)

func _physics_process(delta: float) -> void:
	# Apply gravity always
	if not is_on_floor():
		velocity += get_gravity() * delta

	if not is_dead:
		var input_dir := Input.get_vector("KEY_A", "KEY_D", "KEY_W", "KEY_S")
		var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		var is_run_pressed = Input.is_action_pressed("KEY_SHIFT")
		var is_q_pressed = Input.is_action_pressed("KEY_Q")
		var was_falling = velocity.y < 0 and not is_on_floor()

		movement(delta, direction, is_run_pressed)

		var on_floor_now = is_on_floor()
		state_machine.update_state(on_floor_now, velocity.y, input_dir, is_run_pressed, was_falling, is_q_pressed)

		update_footsteps_sound()

		move_and_slide()

		push_rigid_objects()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * CAMERA_SENSIBILITY)) # X: on the screen horizontal
		camera.rotate_x(deg_to_rad(-event.relative.y * CAMERA_SENSIBILITY)) # Y: on the screen vertical
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(CAMERA_PITCH_MIN), deg_to_rad(CAMERA_PITCH_MAX)) # Prevent complete flip

	# Detección de ataque
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if can_attack:
			perform_attack()

func perform_attack():
	if not can_attack:
		return
		
	can_attack = false
	state_machine.update_state_forced(PlayerStateMachine.State.ATTACKING)
	actions_audio.stream = attacking
	actions_audio.play()
	
	if attack_hitbox:
		attack_hitbox.monitoring = true
		
	if attack_cooldown_timer:
		attack_cooldown_timer.start(ATTACK_COOLDOWN)
		
	print("Ataque realizado")
	
func _on_attack_hitbox_body_entered(body: Node3D):
	if body.is_in_group("villain") and body.has_node("HealthComponent"):
		print("¡Golpeado villano: ", body.name, "!")
		body.get_node("HealthComponent").take_damage(ATTACK_DAMAGE, global_position)

func _on_attack_cooldown_timeout():
	can_attack = true
	# Desactivar hitbox después del ataque
	if attack_hitbox:
		attack_hitbox.monitoring = false
	print("Ataque listo nuevamente")	

func movement(delta: float, direction: Vector3, is_run_pressed: bool) -> void:
	if state_machine.current_state == PlayerStateMachine.State.DANCING:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		push_direction = Vector3.ZERO
		return

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		# Add horizontal boost for better jump momentum
		if direction:
			velocity.x += direction.x * JUMP_HORIZONTAL_BOOST
			velocity.z += direction.z * JUMP_HORIZONTAL_BOOST

	# Get the input direction and handle the movement/deceleration.
	var speed = SPEED
	if is_run_pressed and is_on_floor():
		speed = RUN_SPEED

	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
			push_direction = direction
		else:
			velocity.x = move_toward(velocity.x, 0, speed)
			velocity.z = move_toward(velocity.z, 0, speed)
			push_direction = Vector3.ZERO
	else:
		# In air: conserve momentum, with some air control
		if direction:
			var air_speed = SPEED  # Use walk speed for air control
			velocity.x = move_toward(velocity.x, direction.x * air_speed, air_speed * delta * AIR_CONTROL_ACCEL)
			velocity.z = move_toward(velocity.z, direction.z * air_speed, air_speed * delta * AIR_CONTROL_ACCEL)
			push_direction = direction
		else:
			push_direction = Vector3.ZERO

func is_player_moving_horizontally() -> bool:
	var horizontal_velocity_squared = velocity.x * velocity.x + velocity.z * velocity.z
	return horizontal_velocity_squared > MOVEMENT_THRESHOLD * MOVEMENT_THRESHOLD

func push_rigid_objects() -> void:
	if push_direction != Vector3.ZERO:
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			if collision.get_collider() is RigidBody3D:
				# Don't push if the collision is from below (player standing on top)
				if collision.get_normal().y > 0.5:
					continue
				var rigid = collision.get_collider()
				var push_strength = 0.0
				if velocity.y == 0:  # Only when on ground
					push_strength = PUSH_FORCE_GROUND
				var push_force = push_direction * push_strength
				rigid.apply_central_impulse(push_force)

func update_footsteps_sound() -> void:
	foot_raycast.force_raycast_update()
	var collider = foot_raycast.get_collider()
	var current_surface = ""
	
	var is_walking_state = [
		PlayerStateMachine.State.WALKING_FORWARD,
		PlayerStateMachine.State.WALKING_BACKWARD,
		PlayerStateMachine.State.WALKING_LEFT,
		PlayerStateMachine.State.WALKING_RIGHT,
		PlayerStateMachine.State.RUNNING_FORWARD
	].has(state_machine.current_state)

	if is_walking_state and is_on_floor():
		if collider:
			if collider.is_in_group("concrete_surface"):
				current_surface = "concrete"
			elif collider.is_in_group("grass_surface"):
				current_surface = "grass"
		
		var pitch = FOOTSTEP_PITCH_DEFAULT

		if state_machine.current_state == PlayerStateMachine.State.RUNNING_FORWARD:
			pitch = FOOTSTEP_PITCH_RUN
		else:
			pitch = FOOTSTEP_PITCH_WALK
			
		if current_surface == "grass":
			if footsteps_audio.stream != grass_sound:
				footsteps_audio.stream = grass_sound
				footsteps_audio.stream.loop = true
			footsteps_audio.pitch_scale = pitch
			if not footsteps_audio.playing:
				footsteps_audio.play()
		elif current_surface == "concrete":
			if footsteps_audio.stream != concrete_sound:
				footsteps_audio.stream = concrete_sound
				footsteps_audio.stream.loop = true
			footsteps_audio.pitch_scale = pitch
			if not footsteps_audio.playing:
				footsteps_audio.play()
		else:
			footsteps_audio.stop()
	else:
		footsteps_audio.stop()

func _on_health_changed(new_health: int) -> void:
	print("Player health: ", new_health)
	if GameStateManager:
		GameStateManager.game_data[GameStateManager.GAME_DATA.PLAYER_HEALTH] = new_health
		GameStateManager.save()

func _on_damaged(amount: int, source_point: Vector3) -> void:
	last_damage_source = source_point
	# Apply knockback
	var direction = (global_position - source_point).normalized()
	velocity.y = KNOCKBACK_Y
	velocity.x = direction.x * KNOCKBACK_HORIZONTAL
	velocity.z = direction.z * KNOCKBACK_HORIZONTAL

func _on_died() -> void:
	player_died.emit(last_damage_source)
