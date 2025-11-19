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
}

# --- Variables de Ruta y Estado ---
var game_data_path: String = "user://game_data.dat"

# El estado por defecto para un nuevo juego o inicio de nivel limpio.
const DEFAULT_INITIAL_HEALTH: int = 3
const DEFAULT_SCORE: int = 0
const DEFAULT_CHECKPOINT_LEVEL: String = "" # Level ID vacío para inicio limpio

# Estado inicial que se usará para cualquier inicio limpio (nuevo juego o nuevo nivel sin checkpoint)
var _initial_game_data: Dictionary = {
	GAME_DATA.PLAYER_HEALTH : DEFAULT_INITIAL_HEALTH,
	GAME_DATA.SCORE : DEFAULT_SCORE,
	GAME_DATA.COLLECTED_ITEMS : {},
	GAME_DATA.LAST_CHECKPOINT_DATA : {
		CHECKPOINT_DATA.LEVEL : DEFAULT_CHECKPOINT_LEVEL,
		CHECKPOINT_DATA.POSITION : Vector3.ZERO, # Usamos Vector3.ZERO como posición nula/segura
		CHECKPOINT_DATA.PLAYER_HEALTH : DEFAULT_INITIAL_HEALTH,
		CHECKPOINT_DATA.SESSION_COLLECTED_ITEMS : {}
	}
}

# El estado actual del juego. Inicializado con los datos de inicio por defecto.
var game_data: Dictionary = _initial_game_data.duplicate(true)

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
