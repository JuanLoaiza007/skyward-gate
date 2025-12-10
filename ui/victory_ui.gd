extends Control
class_name VictoryUI

# Solo una señal para volver al menú principal
signal main_menu_pressed

@onready var main_menu_button: Button = $VBoxContainer/MainMenuButton

func _ready():
	# Cambio: Conectar el botón de menú principal
	if main_menu_button:
		main_menu_button.pressed.connect(_on_main_menu_pressed)
	else:
		push_error("VictoryUI: No se encontró el MainMenuButton")
		# Intentar encontrar cualquier botón como fallback
		for child in $VBoxContainer.get_children():
			if child is Button:
				main_menu_button = child
				main_menu_button.pressed.connect(_on_main_menu_pressed)
				print("VictoryUI: Usando botón encontrado como MainMenuButton: ", child.name)
				break
	
	# Asegurarse de que está oculto al inicio
	hide()

func show_ui():
	"""Muestra la interfaz de victoria"""
	visible = true
	# Asegurar que la UI esté en primer plano
	z_index = 100
	# Capturar el mouse para interactuar con la UI
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func hide_ui():
	"""Oculta la interfaz de victoria"""
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_main_menu_pressed():
	"""Emite señal cuando se presiona el botón de menú principal"""
	print("VictoryUI: Botón de menú principal presionado")
	main_menu_pressed.emit()
