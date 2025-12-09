extends CanvasLayer

@onready var health_label = $HealthLabel

var player: Node = null
var current_health_component: Node = null

func _ready():
	# Intentar encontrar el jugador inicial
	find_and_connect_player()
	
	# Conectar para cuando cambie el nivel
	var game_world = get_node("/root/Main/GameWorld")
	if game_world:
		# Escuchar cuando se carga un nuevo nivel (que incluye un nuevo jugador)
		game_world.connect("level_loaded", Callable(self, "_on_level_loaded"))

func find_and_connect_player():
	# Buscar al jugador actual
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
			current_health_component.connect("health_changed", Callable(self, "_on_health_changed"))
			
			# Actualizar inmediatamente con la salud actual
			_on_health_changed(current_health_component.get_current_health())
			
			print("HealthUI conectado a jugador: ", player.name, " con salud: ", current_health_component.get_current_health())

func disconnect_from_current_player():
	if player and current_health_component:
		if current_health_component.is_connected("health_changed", Callable(self, "_on_health_changed")):
			current_health_component.disconnect("health_changed", Callable(self, "_on_health_changed"))
	player = null
	current_health_component = null

func _on_health_changed(new_health: int):
	health_label.text = "Vidas: " + str(new_health)
	print("HealthUI actualizado: ", new_health, " vidas")

func _on_level_loaded():
	# Cuando se carga un nuevo nivel, reconectar al jugador
	print("HealthUI: Nivel cargado, reconectando al jugador...")
	# Esperar un momento para que el jugador se instancie completamente
	await get_tree().create_timer(0.1).timeout
	find_and_connect_player()

func _process(_delta):
	# Verificar periódicamente si el jugador ha cambiado
	# Esto es útil para cuando el jugador muere y se reinicia
	if not player or not is_instance_valid(player):
		find_and_connect_player()
