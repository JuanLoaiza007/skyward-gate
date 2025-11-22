extends Control

@onready var restart_button = $VBoxContainer/RestartButton
@onready var main_menu_button = $VBoxContainer/MainMenuButton

var selected_index = 0
var buttons = []

func _ready():
	buttons = [restart_button, main_menu_button]
	update_selection()
	restart_button.connect("pressed", Callable(self, "_on_restart_pressed"))
	main_menu_button.connect("pressed", Callable(self, "_on_main_menu_pressed"))
	visible = false

func _input(event):
	if not visible:
		return
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

func _on_restart_pressed():
	if GameStateManager:
		GameStateManager.game_data[GameStateManager.GAME_DATA.PLAYER_HEALTH] = 3
	var game_world = get_node("/root/Main/GameWorld")
	game_world.load_level(game_world.current_level_path)

func _on_main_menu_pressed():
	get_node("/root/Main/GameWorld").go_to_main_menu()