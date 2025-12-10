extends Area3D

@export var checkpoint_id: String = "checkpoint_1"
@export var activated: bool = false

@onready var mesh_instance: Node3D = $CheckpointMesh
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready():
	body_entered.connect(_on_body_entered)
	# Inicializar apariencia según estado
	update_visual_state()

func _on_body_entered(body: Node3D):
	if body.is_in_group("player") and not activated:
		activate_checkpoint(body)

func activate_checkpoint(player: Node3D):
	activated = true
	
	# Guardar datos del checkpoint
	var player_health = 3
	if GameStateManager:
		player_health = player.health_component.get_current_health()
	else:
		if GameStateManager:
			player_health = GameStateManager.game_data[GameStateManager.GAME_DATA.PLAYER_HEALTH]
	
	# Obtener el nivel actual desde GameWorld
	var game_world = get_node("/root/Main/GameWorld")
	var current_level_path = game_world.current_level_path
	
	# Guardar datos del checkpoint CON level_path
	CheckpointManager.set_checkpoint(checkpoint_id, global_position, player_health, current_level_path)
	
	# Actualizar apariencia
	update_visual_state()
	
	# Reproducir sonido/animación
	if animation_player.has_animation("activate"):
		animation_player.play("activate")
	
	print("Checkpoint activado: ", checkpoint_id, " en nivel: ", current_level_path)

func update_visual_state():
	pass

func reset():
	activated = false
	update_visual_state()
