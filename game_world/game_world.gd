extends Node3D

enum LEVELS {
  MAIN_MENU,
  #LEVEL_0,
  LEVEL_1,
}

const LEVEL_PATHS: Dictionary = {
  LEVELS.MAIN_MENU: "res://ui/main_menu.tscn",
  #LEVELS.LEVEL_0: "res://levels/level_0/level_0.tscn",
  LEVELS.LEVEL_1: "res://levels/level_1/level_1.tscn",
}

const LEVEL_TRANSITIONS: Dictionary = {
  #LEVELS.LEVEL_0: LEVELS.LEVEL_1,
  LEVELS.LEVEL_1: null, # Fin del juego
}

@onready var current_level_node = $CurrentLevel

@onready var victory_ui = $CanvasLayer/VictoryControl
@onready var death_ui = $CanvasLayer/DeathUI
@onready var next_level_ui = $CanvasLayer/NextLevelUI

var game_finished = false

var current_level_path: String = LEVEL_PATHS[LEVELS.MAIN_MENU]
var current_level_id: LEVELS = LEVELS.MAIN_MENU

signal level_loaded

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
	
	# Ocultar todas las UIs
	hide_all_ui()
	
	# Reiniciar estado del juego
	game_finished = false
	
	# Verificar si estamos restaurando desde un checkpoint
	var checkpoint_data = CheckpointManager.get_checkpoint_data()
	var is_checkpoint_restore = checkpoint_data and checkpoint_data.get("level_path", "") == level_path
	
	# Si NO es una restauración desde checkpoint del mismo nivel, limpiar checkpoint
	if not is_checkpoint_restore:
		CheckpointManager.clear_checkpoint()
	
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

		# Actualizar checkpoint data con nivel actual (si hay checkpoint)
		if checkpoint_data:
			checkpoint_data["level_path"] = current_level_path
			print("Checkpoint data actualizada con nivel: ", current_level_path)

		# Conectar señales
		var treasure_chest = level_instance.get_node_or_null("TreasureChest")
		if treasure_chest:
			treasure_chest.connect("victory", Callable(self, "victory"))
		var player = level_instance.get_node_or_null("Player")
		if player:
			player.player_died.connect(Callable(self, "on_player_died"))
		
		level_loaded.emit()
		
		# Restaurar estado si es una restauración desde checkpoint
		if is_checkpoint_restore:
			print("Restaurando desde checkpoint para nivel: ", level_path)
			# Usar call_deferred para asegurar que todos los nodos estén completamente cargados
			call_deferred("restore_game_state_deferred", level_instance)
		else:
			print("Carga normal del nivel: ", level_path)
	else:
		push_error("No se pudo cargar el nivel: " + level_path)

# Función auxiliar para restaurar el estado de manera deferida
func restore_game_state_deferred(level_instance: Node):
	# Esperar un frame para asegurar que todos los nodos estén listos
	await get_tree().process_frame
	await get_tree().process_frame  # Doble espera para mayor seguridad
	
	# Ahora restaurar el estado
	restore_game_state(level_instance)


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
		print("No hay datos de checkpoint para restaurar")
		return
	
	print("=== INICIANDO RESTAURACIÓN DE ESTADO ===")
	print("Datos del checkpoint: ", checkpoint_data)
	
	# Restaurar jugador
	var player = level_instance.get_node_or_null("Player")
	if player:
		# Ajustar posición: 2 unidades arriba y 2 unidades a la izquierda
		var spawn_position = checkpoint_data["player_position"]
		spawn_position.y += 2.0
		spawn_position.x -= 2.0  # 2 unidades a la izquierda
		
		print("Posición original del checkpoint: ", checkpoint_data["player_position"])
		print("Posición ajustada del spawn: ", spawn_position)
		
		player.global_position = spawn_position
		
		# Restaurar salud del checkpoint
		if player.health_component.has_method("set_health"):
			player.health_component.set_health(checkpoint_data["player_health"])
			print("Salud restaurada: ", checkpoint_data["player_health"])
		
		# Reactivar completamente al jugador
		player.is_dead = false
		player.game_finished = false
		player.set_physics_process(true)
		player.state_machine.update_state_forced(PlayerStateMachine.State.IDLE)
	
	# RESTAURAR COLECTABLES
	print("=== RESTAURANDO COLECTABLES ===")
	var collected_items = checkpoint_data.get("collected_items", [])
	print("Colectables en checkpoint: ", collected_items)
	print("Total colectables en checkpoint: ", collected_items.size())
	
	# Opción 1: Buscar por rutas exactas del checkpoint
	var colectables_restaurados = 0
	for collectable_path_str in collected_items:
		# Convertir string a NodePath
		var collectable_path = NodePath(collectable_path_str)
		print("Buscando colectable con path: ", collectable_path)
		
		# Intentar obtener el nodo
		var collectable_node = level_instance.get_node_or_null(collectable_path)
		if collectable_node:
			print("  -> Encontrado: ", collectable_node.name)
			if collectable_node.has_method("mark_as_collected"):
				collectable_node.mark_as_collected()
				colectables_restaurados += 1
				print("  -> Marcado como recolectado")
			else:
				print("  -> ERROR: No tiene método mark_as_collected")
		else:
			print("  -> NO encontrado por path directo")
	
	# Opción 2: Búsqueda por grupo como respaldo
	print("--- Búsqueda por grupo 'collectables' ---")
	var collectables_in_group = get_tree().get_nodes_in_group("collectables")
	print("Colectables en grupo: ", collectables_in_group.size())
	
	for collectable in collectables_in_group:
		# Verificar si este collectable está en la lista del checkpoint
		var collectable_unique_id = ""
		if collectable.has_method("get_unique_id"):
			collectable_unique_id = collectable.get_unique_id()
		else:
			# Fallback: usar nombre y posición
			collectable_unique_id = collectable.name + "_" + str(collectable.global_transform.origin)
		
		# Buscar si este ID está en los collectables del checkpoint
		var found_in_checkpoint = false
		for checkpoint_item in collected_items:
			if checkpoint_item.contains(collectable.name) or checkpoint_item == collectable_unique_id:
				found_in_checkpoint = true
				break
		
		if found_in_checkpoint and not collectable.collected:
			print("Marcando collectable por grupo: ", collectable.name)
			if collectable.has_method("mark_as_collected"):
				collectable.mark_as_collected()
				colectables_restaurados += 1
	
	print("Total colectables restaurados: ", colectables_restaurados)
	
	# RESTAURAR INTERACTUABLES
	print("=== RESTAURANDO INTERACTUABLES ===")
	var interactables_state = checkpoint_data.get("interactables_state", {})
	print("Interactuables en checkpoint: ", interactables_state.keys())
	
	for interactable_path_str in interactables_state.keys():
		var interactable_path = NodePath(interactable_path_str)
		print("Buscando interactuable: ", interactable_path)
		
		var interactable_node = level_instance.get_node_or_null(interactable_path)
		if interactable_node:
			var state = interactables_state[interactable_path_str]
			print("  -> Encontrado, estado: ", state)
			
			if interactable_node.has_method("load_state"):
				interactable_node.load_state(state)
				print("  -> Estado cargado")
			else:
				print("  -> ERROR: No tiene método load_state")
		else:
			print("  -> NO encontrado")
	
	# RESTAURAR CHECKPOINTS VISUALMENTE
	print("=== RESTAURANDO CHECKPOINTS VISUALES ===")
	for checkpoint in get_tree().get_nodes_in_group("checkpoints"):
		if checkpoint.checkpoint_id == checkpoint_data.get("checkpoint_id", ""):
			checkpoint.activated = true
			checkpoint.update_visual_state()
			print("Checkpoint visual activado: ", checkpoint.checkpoint_id)
		else:
			checkpoint.reset()
	
	print("=== RESTAURACIÓN COMPLETADA ===")

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
	load_level(LEVEL_PATHS[LEVELS.LEVEL_1])



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
