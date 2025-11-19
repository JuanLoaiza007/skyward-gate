class_name PlayerStateMachine
extends Node

enum State {
	WALKING_BACKWARD,
	DANCING,
	IDLE,
	WALKING_FORWARD,
	FALLING_IDLE,
	JUMPING_UP,
	FALLING_TO_LANDING,
	DEATH_FORWARD,
	DEATH_BACKWARD,
	WALKING_LEFT,
	WALKING_RIGHT,
	ATTACKING,
	RUNNING_FORWARD,
}

var animation_names = {
	State.WALKING_BACKWARD: "WALKING_BACKWARD",
	State.DANCING: "DANCING",
	State.IDLE: "IDLE",
	State.WALKING_FORWARD: "WALKING_FORWARD",
	State.FALLING_IDLE: "FALLING_IDLE",
	State.JUMPING_UP: "JUMPING_UP",
	State.FALLING_TO_LANDING: "FALLING_TO_LANDING",
	State.DEATH_FORWARD: "DEATH_FORWARD",
	State.DEATH_BACKWARD: "DEATH_BACKWARD",
	State.WALKING_LEFT: "WALKING_LEFT",
	State.WALKING_RIGHT: "WALKING_RIGHT",
	State.ATTACKING: "ATTACKING",
	State.RUNNING_FORWARD: "RUNNING_FORWARD",
}

var current_state: State = State.IDLE

@onready var animation_player: AnimationPlayer = get_parent().get_node("Cat").get_node("AnimationPlayer")

func _ready():
	animation_player.connect("animation_finished", Callable(self, "_on_animation_finished"))

func _on_animation_finished(anim_name: String):
	if current_state == State.ATTACKING and anim_name == animation_names[State.ATTACKING]:
		update_state_forced(State.IDLE)

func update_state(on_floor: bool, velocity_y: float, input_dir: Vector2, is_run_pressed: bool, was_falling: bool) -> void:
	if current_state == State.DANCING:
		return

	var new_state: State

	if on_floor:
		if was_falling:
			new_state = State.FALLING_TO_LANDING
		elif input_dir.length() > 0:
			if is_run_pressed:
				new_state = State.RUNNING_FORWARD
			elif abs(input_dir.x) > abs(input_dir.y):
				if input_dir.x > 0:
					new_state = State.WALKING_RIGHT
				else:
					new_state = State.WALKING_LEFT
			else:
				if input_dir.y < 0:
					new_state = State.WALKING_FORWARD
				else:
					new_state = State.WALKING_BACKWARD
		else:
			new_state = State.IDLE
	else:
		if velocity_y > 0:
			new_state = State.JUMPING_UP
		else:
			new_state = State.FALLING_IDLE

	if new_state != current_state:
		current_state = new_state
		var anim_name = animation_names[new_state]
		if animation_player.has_animation(anim_name):
			animation_player.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR
			animation_player.play(anim_name, 0.2)

func update_state_forced(new_state: State) -> void:
	current_state = new_state
	var anim_name = animation_names[new_state]
	if animation_player.has_animation(anim_name):
		if new_state == State.ATTACKING or new_state == State.DEATH_FORWARD or new_state == State.DEATH_BACKWARD:
			animation_player.stop()
			animation_player.get_animation(anim_name).loop_mode = Animation.LOOP_NONE
			if new_state == State.ATTACKING:
				animation_player.play(anim_name, 0.2, 2.0)
			else:
				animation_player.play(anim_name, 0.2)
		else:
			animation_player.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR
			animation_player.play(anim_name, 0.2)
