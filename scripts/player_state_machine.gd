class_name PlayerStateMachine
extends Node

enum State {
	IDLE,
	WALKING,
	RUNNING,
	JUMPING_UP,
	FALLING_IDLE,
	FALLING_TO_LANDING
}

var animation_names = {
	State.IDLE: "IDLE",
	State.WALKING: "WALKING",
	State.RUNNING: "RUNNING",
	State.JUMPING_UP: "JUMPING UP",
	State.FALLING_IDLE: "FALLING IDLE",
	State.FALLING_TO_LANDING: "FALLING TO LANDING"
}

var current_state: State = State.IDLE

# @onready var animation_player: AnimationPlayer = get_parent().get_node("AnimationPlayer")

func update_state(on_floor: bool, velocity_y: float, is_moving: bool, is_run_pressed: bool, was_falling: bool) -> void:
	var new_state: State
	
	if on_floor:
		if was_falling:
			new_state = State.FALLING_TO_LANDING
		elif is_moving:
			if is_run_pressed:
				new_state = State.RUNNING
			else:
				new_state = State.WALKING
		else:
			new_state = State.IDLE
	else:
		if velocity_y > 0:
			new_state = State.JUMPING_UP
		else:
			new_state = State.FALLING_IDLE
	
	if new_state != current_state:
		current_state = new_state
		print("Estado actual: ", State.keys()[current_state])
		# var anim_name = animation_names[new_state]
		# animation_player.play(anim_name, 0.2)
