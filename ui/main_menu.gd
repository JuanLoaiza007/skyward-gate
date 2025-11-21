extends Control

@onready var play_button = $PlayButton

func _ready():
	play_button.connect("pressed", Callable(self, "_on_play_pressed"))

func _on_play_pressed():
	get_node("/root/Main/GameWorld").start_game()
