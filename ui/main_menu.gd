extends Control

@onready var play_button = $VBoxContainer/PlayButton
@onready var quit_button = $VBoxContainer/QuitButton

var selected_index = 0
var buttons = []

func _ready():
	AudioManager.change_music(AudioManager.TRACKS.LOOP_GUITAR)
	buttons = [play_button, quit_button]
	update_selection()
	play_button.connect("pressed", Callable(self, "_on_play_pressed"))
	quit_button.connect("pressed", Callable(self, "_on_quit_pressed"))

func _input(event):
	if event.is_action_pressed("ui_up"):
		selected_index = (selected_index - 1 + buttons.size()) % buttons.size()
		update_selection()
	elif event.is_action_pressed("ui_down"):
		selected_index = (selected_index + 1) % buttons.size()
		update_selection()
	elif Input.is_action_just_pressed("ui_accept"):
		buttons[selected_index].emit_signal("pressed")

func update_selection():
	for i in range(buttons.size()):
		if i == selected_index:
			buttons[i].grab_focus()
		else:
			buttons[i].release_focus()

func _on_play_pressed():
	get_node("/root/Main/GameWorld").start_game()

func _on_quit_pressed():
	get_tree().quit()
