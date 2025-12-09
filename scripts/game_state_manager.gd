extends Node

# --- Constantes para Acceso a Datos ---
enum GAME_DATA {
	PLAYER_HEALTH, # La vida del jugador (estado consolidado)
	SCORE, # La puntuación del jugador (estado consolidado)
	COLLECTED_ITEMS, # Los items colectados por el jugador (estado consolidado)
	LAST_CHECKPOINT_DATA, # Metadatos del último checkpoint
}

enum CHECKPOINT_DATA {
	LEVEL, # El ID del nivel para asegurar consistencia
	POSITION, # La posición de resurrección del jugador
	PLAYER_HEALTH, # La vida del jugador en un momento dado en el nivel actual
	SESSION_COLLECTED_ITEMS, # Los items que el jugador tiene temporalmente (si no ha pisado checkpoint)
	DIAMOND_COUNT, # Contador de diamantes recolectados en la sesión actual
}

# --- Variables de Ruta y Estado ---
var game_data_path: String = "user://game_data.dat"

# El estado por defecto para un nuevo juego o inicio de nivel limpio.
const DEFAULT_INITIAL_HEALTH: int = 3
const DEFAULT_SCORE: int = 0
const DEFAULT_CHECKPOINT_LEVEL: String = "" # Level ID vacío para inicio limpio
const DIAMONDS_FOR_LIFE: int = 3  # Diamantes necesarios para obtener una vida extra

# Estado inicial que se usará para cualquier inicio limpio (nuevo juego o nuevo nivel sin checkpoint)
var _initial_game_data: Dictionary = {
	GAME_DATA.PLAYER_HEALTH : DEFAULT_INITIAL_HEALTH,
	GAME_DATA.SCORE : DEFAULT_SCORE,
	GAME_DATA.COLLECTED_ITEMS : {},
	GAME_DATA.LAST_CHECKPOINT_DATA : {
		CHECKPOINT_DATA.LEVEL : DEFAULT_CHECKPOINT_LEVEL,
		CHECKPOINT_DATA.POSITION : Vector3.ZERO, # Usamos Vector3.ZERO como posición nula/segura
		CHECKPOINT_DATA.PLAYER_HEALTH : DEFAULT_INITIAL_HEALTH,
		CHECKPOINT_DATA.SESSION_COLLECTED_ITEMS : {},
		CHECKPOINT_DATA.DIAMOND_COUNT : 0,  # Inicializar contador de diamantes en 0
	}
}

# El estado actual del juego. Inicializado con los datos de inicio por defecto.
var game_data: Dictionary = _initial_game_data.duplicate(true)

# --- Señales ---
signal diamond_collected(diamond_count: int, diamonds_needed: int)  # Se emite cuando se recolecta un diamante
signal extra_life_earned  # Se emite cuando se alcanzan 3 diamantes

# --- Funciones de Persistencia ---
# Carga el estado del juego desde el disco. Si el archivo no existe, usa el estado inicial.
func load() -> void:
	if FileAccess.file_exists(game_data_path):
		var game_data_file = FileAccess.open(game_data_path, FileAccess.READ)
		game_data = game_data_file.get_var()
		game_data_file = null
	else:
		# Si no hay archivo guardado, inicializa con los datos por defecto
		game_data = _initial_game_data.duplicate(true)

# Guarda el estado actual del juego en el disco.
func save() -> void:
	var game_data_file = FileAccess.open(game_data_path, FileAccess.WRITE)
	game_data_file.store_var(game_data)
	game_data_file.close()

# --- Funciones de Lógica de Juego ---
# Reinicia el progreso del juego a los valores por defecto y lo guarda.
func reset_all_progress() -> void:
	game_data = _initial_game_data.duplicate(true)
	save()

# Prepara el estado para la carga de un nuevo nivel/escena (o respawn).
# Esto se llama al cargar una escena para obtener el punto de inicio o respawn.
func get_spawn_state(current_level_path: String) -> Dictionary:
	var checkpoint_data = game_data[GAME_DATA.LAST_CHECKPOINT_DATA]

	# Resetea el buffer de sesión antes de decidir el punto de aparición
	checkpoint_data[CHECKPOINT_DATA.SESSION_COLLECTED_ITEMS] = {}

	# Verifica si hay un checkpoint válido en el nivel actual
	if checkpoint_data[CHECKPOINT_DATA.LEVEL] == current_level_path:
		# Caso A: Respawn desde Checkpoint válido en este nivel
		return {
			"is_checkpoint_active": true,
			"position": checkpoint_data[CHECKPOINT_DATA.POSITION],
			"health": checkpoint_data[CHECKPOINT_DATA.PLAYER_HEALTH],
			"score_base": game_data[GAME_DATA.SCORE],
			"collected_items": game_data[GAME_DATA.COLLECTED_ITEMS],
			}
	else:
		# Caso B: Inicio de Nivel Limpio o Carga de Juego Nuevo
		# La posición debe ser establecida por el 'SpawnPoint' de la escena.
		return {
			"is_checkpoint_active": false,
			"position": Vector3.ZERO, # El LevelManager debe ignorar esto y usar SpawnPoint
			"health": _initial_game_data[GAME_DATA.PLAYER_HEALTH],
			"score_base": game_data[GAME_DATA.SCORE], # Mantiene el score acumulado de niveles anteriores
			"collected_items": game_data[GAME_DATA.COLLECTED_ITEMS],
			}

# Consolida el estado de la sesión actual en el estado permanente y actualiza el checkpoint.
func save_checkpoint(new_position: Vector3, new_level_path: String, current_player_health: int) -> void:
	# 1. Consolida la Puntuación y los Items
	var session_items = game_data[GAME_DATA.LAST_CHECKPOINT_DATA][CHECKPOINT_DATA.SESSION_COLLECTED_ITEMS]
	# Fusiona los ítems de la sesión al permanente
	for id in session_items:
		game_data[GAME_DATA.COLLECTED_ITEMS][id] = true
		
		# 2. Prepara nuevos datos de Checkpoint (Punto de Respawn)
		var checkpoint_data = game_data[GAME_DATA.LAST_CHECKPOINT_DATA]
		
		checkpoint_data[CHECKPOINT_DATA.LEVEL] = new_level_path
		checkpoint_data[CHECKPOINT_DATA.POSITION] = new_position
		checkpoint_data[CHECKPOINT_DATA.PLAYER_HEALTH] = current_player_health
		
		# 3. Limpia el Buffer de Sesión para el próximo tramo
		checkpoint_data[CHECKPOINT_DATA.SESSION_COLLECTED_ITEMS] = {}
		
	# 4. Actualiza la vida base del jugador (opcional, si la vida se guarda)
	game_data[GAME_DATA.PLAYER_HEALTH] = current_player_health
	
	save()

# --- Funciones de Sesión (El Buffer) ---
# Añade un item al buffer temporal de la sesión
func add_session_item(item_puid: String) -> void:
	game_data[GAME_DATA.LAST_CHECKPOINT_DATA][CHECKPOINT_DATA.SESSION_COLLECTED_ITEMS][item_puid] = true

func add_diamond() -> void:
	# Obtener o crear checkpoint_data
	var checkpoint_data = game_data.get(GAME_DATA.LAST_CHECKPOINT_DATA, {})
	
	# Obtener o inicializar contador de diamantes
	var current_count = checkpoint_data.get(CHECKPOINT_DATA.DIAMOND_COUNT, 0)
	current_count += 1
	
	# Actualizar en el diccionario
	checkpoint_data[CHECKPOINT_DATA.DIAMOND_COUNT] = current_count
	
	# Asegurar que game_data tenga el checkpoint_data actualizado
	game_data[GAME_DATA.LAST_CHECKPOINT_DATA] = checkpoint_data
	
	print("Diamante recolectado! Total: ", current_count, "/", DIAMONDS_FOR_LIFE)
	
	# Emitir señal para actualizar UI
	diamond_collected.emit(current_count, DIAMONDS_FOR_LIFE)
	
	# Verificar si se alcanzaron 3 diamantes
	if current_count >= DIAMONDS_FOR_LIFE:
		# Otorgar vida extra
		extra_life_earned.emit()
		print("¡Vida extra obtenida por recolectar 3 diamantes!")
		
		# Resetear contador (puede haber excedentes si se recolectan más de 3 seguidos)
		checkpoint_data[CHECKPOINT_DATA.DIAMOND_COUNT] = 0
		game_data[GAME_DATA.LAST_CHECKPOINT_DATA] = checkpoint_data
		# Emitir señal con contador actualizado
		diamond_collected.emit(0, DIAMONDS_FOR_LIFE)

# Obtiene el contador actual de diamantes
func get_diamond_count() -> int:
	var checkpoint_data = game_data.get(GAME_DATA.LAST_CHECKPOINT_DATA, {})
	return checkpoint_data.get(CHECKPOINT_DATA.DIAMOND_COUNT, 0)

# Obtiene la salud del jugador
func get_player_health() -> int:
	return game_data.get(GAME_DATA.PLAYER_HEALTH, DEFAULT_INITIAL_HEALTH)

# Establece la salud del jugador
func set_player_health(health: int) -> void:
	game_data[GAME_DATA.PLAYER_HEALTH] = health
	print("GameStateManager: Salud actualizada a ", health)

# Obtiene diamantes necesarios para vida extra
func get_diamonds_needed() -> int:
	return DIAMONDS_FOR_LIFE
