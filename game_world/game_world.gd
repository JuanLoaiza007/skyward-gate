extends Node3D

@onready var current_level_node = $CurrentLevel

var current_level_path: String = "res://ui/main_menu.tscn"

func _ready():
	load_level(current_level_path)
	victory_ui.visible = false

func load_level(level_path: String):
	# Remover nivel actual si existe
	for child in current_level_node.get_children():
		child.queue_free()
	
	# Cargar y instanciar nuevo nivel
	var level_scene = load(level_path)
	if level_scene:
		var level_instance = level_scene.instantiate()
		current_level_node.add_child(level_instance)
		current_level_path = level_path
	else:
		push_error("No se pudo cargar el nivel: " + level_path)

func change_to_level(level_path: String):
	load_level(level_path)

# Funciones para menús, asumiendo escenas en ui/
func go_to_main_menu():
	load_level("res://ui/main_menu.tscn")  # Asumir que existe

func start_game():
	load_level("res://levels/level_0/level_0.tscn")

# Para transiciones futuras, agregar señales o animaciones

@onready var victory_ui = $CanvasLayer/VictoryControl
var game_finished = false

func victory():
	if game_finished: return
	game_finished = true
	victory_ui.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var player = get_tree().get_nodes_in_group("player")[0]
	player.game_finished = true
	player.set_physics_process(false)
	player.state_machine.update_state_forced(PlayerStateMachine.State.IDLE)
