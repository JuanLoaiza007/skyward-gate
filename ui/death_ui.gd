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
	visible = false
	var game_world = get_node("/root/Main/GameWorld")
	print("GameWorld encontrado: ", game_world)
	
	var checkpoint_data = CheckpointManager.get_checkpoint_data()
	print("Datos del checkpoint: ", checkpoint_data)
	print("Nivel actual: ", game_world.current_level_path)
	
	if checkpoint_data and checkpoint_data.get("level_path", "") == game_world.current_level_path:
		print("Restaurando desde checkpoint...")
		game_world.restore_from_checkpoint()
	else: 
		print("Reiniciando nivel normalmente...")
		if GameStateManager:
			GameStateManager.game_data[GameStateManager.GAME_DATA.PLAYER_HEALTH] = 3
			GameStateManager.save()
		game_world.load_level(game_world.current_level_path)

func _on_main_menu_pressed():
	get_node("/root/Main/GameWorld").go_to_main_menu()
