extends CharacterBody3D


const SPEED = 5.0
const RUN_SPEED = 10.0
const JUMP_VELOCITY = 4.5
const CAMERA_SENSIBILITY = 0.4
const FALL_DEATH_HEIGHT = -20.0

@onready var camera = $CameraPivot
@onready var foot_raycast = $FootRayCast
@onready var footsteps_audio = $FootstepsAudio
@onready var actions_audio = $ActionsAudio
var state_machine: PlayerStateMachine
var initial_position: Vector3
@onready var grass_sound = load("res://assets/audio/sfx/gravel_footsteps.mp3")
@onready var concrete_sound = load("res://assets/audio/sfx/concrete_footsteps.mp3")
@onready var attacking = load("res://assets/audio/sfx/cat_attack.wav")

func _ready() -> void:
	add_to_group("player")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	initial_position = global_position
	state_machine = PlayerStateMachine.new()
	add_child(state_machine)
	state_machine.name = "StateMachine"

func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("KEY_A", "KEY_D", "KEY_W", "KEY_S")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var is_run_pressed = Input.is_action_pressed("KEY_SHIFT")
	var was_falling = velocity.y < 0 and not is_on_floor()

	if Input.is_action_pressed("KEY_Q"):
		if state_machine.current_state != PlayerStateMachine.State.DANCING:
			state_machine.update_state_forced(PlayerStateMachine.State.DANCING)
		return

	movement(delta, direction, is_run_pressed)
	move_and_slide()

	var on_floor_now = is_on_floor()
	state_machine.update_state(on_floor_now, velocity.y, input_dir, is_run_pressed, was_falling)
	
	update_footsteps_sound()
	
	if global_position.y < FALL_DEATH_HEIGHT:
		global_position = initial_position + Vector3(0, 10, 0)
		velocity = Vector3.ZERO

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * CAMERA_SENSIBILITY)) # X: on the screen horizontal
		camera.rotate_x(deg_to_rad(-event.relative.y * CAMERA_SENSIBILITY)) # Y: on the screen vertical
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-20), deg_to_rad(45)) # Prevent complete flip

	# Detección de ataque
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		state_machine.update_state_forced(PlayerStateMachine.State.ATTACKING)
		actions_audio.stream = attacking
		actions_audio.play()

func movement(delta: float, direction: Vector3, is_run_pressed: bool) -> void:
	if state_machine.current_state == PlayerStateMachine.State.ATTACKING or \
	   state_machine.current_state == PlayerStateMachine.State.DANCING:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		if not is_on_floor():
			velocity += get_gravity() * delta
		return
		
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var speed = SPEED
	if is_run_pressed:
		speed = RUN_SPEED
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

func is_player_moving_horizontally() -> bool:
	var horizontal_velocity_squared = velocity.x * velocity.x + velocity.z * velocity.z
	return horizontal_velocity_squared > 0.1 * 0.1 # Umbral pequeño

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
		
		var pitch = 1.0

		if state_machine.current_state == PlayerStateMachine.State.RUNNING_FORWARD:
			pitch = 1.2
		else:
			pitch = 0.8
			
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
