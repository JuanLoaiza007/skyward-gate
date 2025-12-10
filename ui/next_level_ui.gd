extends Control

@onready var next_level_button = $VBoxContainerNextLevel/NextLevelButton
@onready var main_menu_button = $VBoxContainerNextLevel/MainMenuButton

var selected_index = 0
var buttons = []

# Señales que emitirá este componente
signal next_level_pressed
signal main_menu_pressed

func _ready():
	buttons = [next_level_button, main_menu_button]
	update_selection()
	next_level_button.connect("pressed", Callable(self, "_on_next_level_pressed"))
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

func _on_next_level_pressed():
	next_level_pressed.emit()
	print("presione en enext level el siguiente nivel")

func _on_main_menu_pressed():
	main_menu_pressed.emit()
	print("presione en enext level el volver al menu")

# Función para mostrar la UI
func show_ui():
	visible = true
	selected_index = 0
	update_selection()

# Función para ocultar la UI
func hide_ui():
	visible = false
