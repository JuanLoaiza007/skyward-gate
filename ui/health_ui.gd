extends CanvasLayer

@onready var health_label = $HealthLabel

var player: Node = null
var current_health_component: Node = null
var current_health: int = 0
var diamond_count: int = 0
var diamonds_needed: int = 3

func _ready():
	# Intentar encontrar el jugador inicial
	find_and_connect_player()
	
	# Conectar para cuando cambie el nivel
	var game_world = get_node("/root/Main/GameWorld")
	if game_world and game_world.has_signal("level_loaded"):
		game_world.connect("level_loaded", Callable(self, "_on_level_loaded"))
	
	# Conectar señales de GameStateManager
	if GameStateManager:
		GameStateManager.diamond_collected.connect(_on_diamond_collected)
		# CONECTAR SEÑAL DE VIDA EXTRA
		if GameStateManager.has_signal("extra_life_earned"):
			GameStateManager.extra_life_earned.connect(_on_extra_life_earned)
		
		# Obtener contador inicial
		diamond_count = GameStateManager.get_diamond_count()
		diamonds_needed = GameStateManager.get_diamonds_needed()
		
		# OBTENER SALUD INICIAL DESDE GAMESTATEMANAGER
		current_health = GameStateManager.get_player_health()
		
		print("HealthUI: Contador inicial de diamantes: ", diamond_count)
		print("HealthUI: Salud inicial: ", current_health)
	
	# Actualizar display inicial
	update_display()

func find_and_connect_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var new_player = players[0]
		
		# Si ya estamos conectados a este jugador, no hacer nada
		if new_player == player:
			return
		
		# Desconectar del jugador anterior si existe
		disconnect_from_current_player()
		
		# Conectar al nuevo jugador
		player = new_player
		if player.has_node("HealthComponent"):
			current_health_component = player.get_node("HealthComponent")
			if current_health_component.has_signal("health_changed"):
				current_health_component.connect("health_changed", Callable(self, "_on_health_changed"))
			
			# SINCRONIZAR SALUD CON GAMESTATEMANAGER
			if GameStateManager:
				current_health = GameStateManager.get_player_health()
			else:
				# Obtener salud inicial del componente como respaldo
				if current_health_component.has_method("get_current_health"):
					current_health = current_health_component.get_current_health()
				elif current_health_component.has_method("get_health"):
					current_health = current_health_component.get_health()
			
			print("HealthUI conectado a jugador: ", player.name, " con salud: ", current_health)
			
			# Actualizar display
			update_display()
		else:
			print("HealthUI: El jugador no tiene HealthComponent")
	else:
		print("HealthUI: No se encontraron jugadores en el grupo 'player'")

func disconnect_from_current_player():
	if player and current_health_component:
		if current_health_component.is_connected("health_changed", Callable(self, "_on_health_changed")):
			current_health_component.disconnect("health_changed", Callable(self, "_on_health_changed"))
	player = null
	current_health_component = null

# AÑADIR ESTE MÉTODO PARA ACTUALIZAR SALUD DESDE EL COMPONENTE
func _on_health_changed(new_health: int):
	current_health = new_health
	update_display()
	print("HealthUI: Salud cambiada a ", new_health)
	
	# ACTUALIZAR GAMESTATEMANAGER CON LA NUEVA SALUD
	if GameStateManager:
		GameStateManager.set_player_health(new_health)

func _on_diamond_collected(count: int, needed: int):
	diamond_count = count
	diamonds_needed = needed
	update_display()
	print("HealthUI: Diamantes actualizados: ", count, "/", needed)

# AÑADIR ESTE MÉTODO PARA MANEJAR VIDA EXTRA
func _on_extra_life_earned():
	# Incrementar salud localmente
	current_health += 1
	update_display()
	print("HealthUI: ¡Vida extra obtenida! Salud ahora: ", current_health)
	
	# Actualizar GameStateManager
	if GameStateManager:
		GameStateManager.set_player_health(current_health)
		# También actualizar el HealthComponent del jugador si existe
		if player and player.has_node("HealthComponent"):
			var health_component = player.get_node("HealthComponent")
			if health_component.has_method("increase_health"):
				health_component.increase_health(1)
			elif health_component.has_method("set_health"):
				health_component.set_health(current_health)

func update_display():
	health_label.text = "Vidas: " + str(current_health) + " | Diamantes: " + str(diamond_count) + "/" + str(diamonds_needed)

func _on_level_loaded():
	# Cuando se carga un nuevo nivel, reconectar al jugador
	print("HealthUI: Nivel cargado, reconectando al jugador...")
	# Esperar un momento para que el jugador se instancie completamente
	await get_tree().create_timer(0.1).timeout
	find_and_connect_player()

func _process(_delta):
	# Verificar periódicamente si el jugador ha cambiado
	if not player or not is_instance_valid(player):
		find_and_connect_player()
	
	# ACTUALIZAR SALUD DESDE GAMESTATEMANAGER COMO RESPLALDO
	# Esto asegura que si el GameStateManager cambia la salud por otro medio, se refleje
	if GameStateManager and GameStateManager.has_method("get_player_health"):
		var new_health = GameStateManager.get_player_health()
		if new_health != current_health:
			current_health = new_health
			update_display()
