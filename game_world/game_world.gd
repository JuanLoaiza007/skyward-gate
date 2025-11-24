extends Node3D

enum LEVELS {
  MAIN_MENU,
  LEVEL_0,
  LEVEL_1,
}

const LEVEL_PATHS: Dictionary = {
  LEVELS.MAIN_MENU: "res://ui/main_menu.tscn",
  LEVELS.LEVEL_0: "res://levels/level_0/level_0.tscn",
  LEVELS.LEVEL_1: "res://levels/level_1/level_1.tscn",
}

const LEVEL_TRANSITIONS: Dictionary = {
  LEVELS.LEVEL_0: LEVELS.LEVEL_1,
  LEVELS.LEVEL_1: null, # Fin del juego
}

@onready var current_level_node = $CurrentLevel

@onready var victory_ui = $CanvasLayer/VictoryControl
@onready var death_ui = $CanvasLayer/DeathUI
@onready var next_level_ui = $CanvasLayer/NextLevelUI

var game_finished = false

var current_level_path: String = LEVEL_PATHS[LEVELS.MAIN_MENU]
var current_level_id: LEVELS = LEVELS.MAIN_MENU

func _ready():
	if not current_level_node:
		push_error("current_level_node is null")
		return
	hide_all_ui()
	if next_level_ui:
		next_level_ui.next_level_pressed.connect(_on_next_level_ui_pressed)
		next_level_ui.main_menu_pressed.connect(_on_next_level_main_menu_pressed)
	# Verificar si hay checkpoint para restaurar
	var checkpoint_data = CheckpointManager.get_checkpoint_data()
	if checkpoint_data and checkpoint_data.get("level_path", "") == current_level_path:
		restore_from_checkpoint()
	else:
		load_level(current_level_path)

func hide_all_ui():
	if death_ui:
		death_ui.visible = false
	if victory_ui:
		victory_ui.visible = false
	if next_level_ui:
		next_level_ui.hide_ui()

func load_level(level_path: String):
	print("Cargando nivel: ", level_path)
	# Ocultar UIs
	hide_all_ui()
	game_finished = false
	# Remover nivel actual si existe
	for child in current_level_node.get_children():
		child.queue_free()
		
	# Cargar y instanciar nuevo nivel
	var level_scene = load(level_path)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if level_scene:
		var level_instance = level_scene.instantiate()
		current_level_node.add_child(level_instance)
		current_level_path = level_path

		# Actualizar current_level_id
		for id in LEVEL_PATHS.keys():
			if LEVEL_PATHS[id] == level_path:
				current_level_id = id
				break

		# Actualizar checkpoint data con nivel actual
		var checkpoint_data = CheckpointManager.get_checkpoint_data()
		if checkpoint_data:
			checkpoint_data["level_path"] = current_level_path

		# Conectar señales
		var treasure_chest = level_instance.get_node_or_null("TreasureChest")
		if treasure_chest:
			treasure_chest.connect("victory", Callable(self, "victory"))
		var player = level_instance.get_node_or_null("Player")
		if player:
			player.player_died.connect(Callable(self, "on_player_died"))
			
		# Restaurar estado si hay checkpoint
		if checkpoint_data and checkpoint_data.get("level_path", "") == current_level_path:
			restore_game_state(level_instance)			
	else:
		push_error("No se pudo cargar el nivel: " + level_path)


func restore_from_checkpoint():
	var checkpoint_data = CheckpointManager.get_checkpoint_data()
	if checkpoint_data and checkpoint_data.has("level_path"):
		print("Restaurando desde checkpoint: ", checkpoint_data["level_path"])
		
		# Reiniciar estado del juego antes de cargar
		game_finished = false
		
		# Ocultar UIs
		hide_all_ui()
		
		# Cargar el nivel desde el checkpoint
		load_level(checkpoint_data["level_path"])
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		print("No hay datos de checkpoint válidos")

func restore_game_state(level_instance: Node):
	var checkpoint_data = CheckpointManager.get_checkpoint_data()
	if not checkpoint_data:
		return
	
	# Restaurar jugador
	var player = level_instance.get_node_or_null("Player")
	if player:
		# Ajustar la posición Y para spawnear 2 unidades arriba del checkpoint
		var original_position = checkpoint_data["player_position"]
		var spawn_position = original_position
		spawn_position.y += 2.0  # Añadir 2 unidades en el eje Y
		print("Posición original del checkpoint: ", original_position)
		print("Posición ajustada del spawn: ", spawn_position)
		player.global_position = spawn_position
		
		# Establecer la salud
		if player.health_component.has_method("set_health"):
			player.health_component.set_health(checkpoint_data["player_health"])
		
		# Reactivar completamente al jugador
		player.is_dead = false
		player.game_finished = false
		player.set_physics_process(true)
		
		# Restaurar estado de la máquina de estados
		player.state_machine.update_state_forced(PlayerStateMachine.State.IDLE)
	
	# Restaurar collectables
	for collectable in get_tree().get_nodes_in_group("collectables"):
		var collectable_id = collectable.get_path()
		if CheckpointManager.is_item_collected(collectable_id):
			collectable.mark_as_collected()
	
	# Restaurar interactuables
	for interactable in get_tree().get_nodes_in_group("interactables"):
		var interactable_id = interactable.get_path()
		var state = CheckpointManager.get_interactable_state(interactable_id)
		if state:
			interactable.load_state(state)
	
	# Restaurar checkpoints
	for checkpoint in get_tree().get_nodes_in_group("checkpoints"):
		var checkpoint_data2 = CheckpointManager.get_checkpoint_data()
		if checkpoint.checkpoint_id == checkpoint_data2.get("checkpoint_id", ""):
			checkpoint.activated = true
			checkpoint.update_visual_state()
		else:
			checkpoint.reset()

func on_player_died(last_damage: Vector3):
	var player = get_tree().get_nodes_in_group("player")[0]
	player.is_dead = true
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# SIEMPRE mostrar la UI de muerte, independientemente del checkpoint
	hide_all_ui()
	if death_ui:
		death_ui.visible = true
		
	var death_state = PlayerStateMachine.State.DEATH_FORWARD
	if last_damage.x < player.global_position.x:
		death_state = PlayerStateMachine.State.DEATH_BACKWARD
	player.state_machine.update_state_forced(death_state)
	AudioManager.change_music(AudioManager.TRACKS.LOOP_TECHNO_2)

func change_to_level(level_id: LEVELS):
	load_level(LEVEL_PATHS[level_id])

# Funciones para menús, asumiendo escenas en ui/
func go_to_main_menu():
	load_level(LEVEL_PATHS[LEVELS.MAIN_MENU])

func start_game():
	load_level(LEVEL_PATHS[LEVELS.LEVEL_0])



# Crea una señal que reciba con argumento del proximo nivel
signal next_level(level_id)

func victory():
	if game_finished: return
	game_finished = true
	var next_level = LEVEL_TRANSITIONS.get(current_level_id, null)
	hide_all_ui()
	
	if next_level != null:
		# Mostrar UI de siguiente nivel (nivel intermedio)
		if next_level_ui:
			next_level_ui.show_ui()  # Usar método del componente
	else:
		# Mostrar UI de victoria final
		if victory_ui:
			victory_ui.visible = true
			
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var player = get_tree().get_nodes_in_group("player")[0]
	player.game_finished = true
	player.set_physics_process(false)
	player.state_machine.update_state_forced(PlayerStateMachine.State.IDLE)


func _on_next_level_ui_pressed():
	var next_level = LEVEL_TRANSITIONS.get(current_level_id, null)
	if next_level != null:
		# Ocultar UI y cambiar nivel
		if next_level_ui:
			next_level_ui.hide_ui()
		change_to_level(next_level)

func _on_next_level_main_menu_pressed():
	if next_level_ui:
		next_level_ui.hide_ui()
	go_to_main_menu()
	game_finished = false
