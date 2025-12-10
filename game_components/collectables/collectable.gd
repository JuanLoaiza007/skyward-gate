@tool
extends Node3D

enum MESH { DIAMOND }

@export var selected_mesh: MESH = MESH.DIAMOND
@export var score_value: int = 10
@export var enable_rotation: bool = true
@export var enable_bobbing: bool = true
@export var rotation_speed: float = 1.0
@export var bob_frequency: float = 2.0
@export var bob_amplitude: float = 0.1

const MESH_SCENES = {
	MESH.DIAMOND: preload("res://game_components/collectables/diamond.tscn")
}

const MESH_SOUNDS = {
	MESH.DIAMOND: preload("res://assets/audio/sfx/diamond_collected.wav")
}

@onready var interaction_area: Area3D = $InteractionArea
@onready var collision_shape: CollisionShape3D = $InteractionArea/CollisionShape3D
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var debug_mesh: MeshInstance3D = $DebugMesh
@onready var diamond_mesh: Node3D = $DiamondMesh

var base_y: float
var time_elapsed: float = 0.0
var collected: bool = false

func _ready() -> void:
	interaction_area.body_entered.connect(_on_body_entered)
	base_y = position.y
	_update_mesh()
	
	# DEBUG: Mostrar información
	print("Collectable ", name , "cargado, collected = {collected}")
	
	# Verificar si ya fue recolectado desde checkpoint
	var checkpoint_data = CheckpointManager.get_checkpoint_data()
	if checkpoint_data:
		var current_level_path = get_node("/root/Main/GameWorld").current_level_path
		if checkpoint_data.get("level_path", "") == current_level_path:
			var unique_id = get_unique_id()
			if CheckpointManager.is_item_collected(unique_id):
				print("Collectable ", name , "debería estar recolectado según checkpoint")
				mark_as_collected()

func get_unique_id() -> String:
	# Obtener ruta relativa al nivel actual
	var game_world = get_node("/root/Main/GameWorld")
	if game_world and game_world.current_level_node.get_child_count() > 0:
		var current_level = game_world.current_level_node.get_child(0)
		var relative_path = current_level.get_path_to(self)
		return str(relative_path)
	# Fallback
	return name

func _process(delta: float) -> void:
	time_elapsed += delta
	if selected_mesh == MESH.DIAMOND:
		if enable_rotation:
			diamond_mesh.rotate_y(delta * rotation_speed)
		if enable_bobbing:
			diamond_mesh.position.y = sin(time_elapsed * bob_frequency) * bob_amplitude

func _update_mesh() -> void:
	# Ocultar todos los meshes
	diamond_mesh.visible = false

	# Mostrar el seleccionado y copiar configuración
	if selected_mesh == MESH.DIAMOND:
		diamond_mesh.visible = true

		# Copiar configuración del área del mesh
		var mesh_collision = diamond_mesh.get_node("InteractionArea/CollisionShape3D")
		if mesh_collision and mesh_collision.shape is BoxShape3D:
			collision_shape.shape.size = mesh_collision.shape.size
			collision_shape.transform = mesh_collision.transform

			# Configurar debug mesh (invisible, solo para ubicación)
			debug_mesh.transform = mesh_collision.transform

	# Asignar sonido automáticamente
	audio_player.stream = MESH_SOUNDS[selected_mesh]

func _on_body_entered(body: Node3D) -> void:
	if not collected and body.is_in_group("player"):
		collect()

func collect():
	collected = true
	
	# Ocultar el mesh visible
	diamond_mesh.visible = false
	
	# Desactivar colisión
	collision_shape.set_deferred("disabled", true)
	
	# Registrar en checkpoint manager
	CheckpointManager.add_collected_item(get_path())

	if selected_mesh == MESH.DIAMOND:
		GameStateManager.add_diamond()
	
	# Actualizar estado del juego
	GameStateManager.add_session_item(name + "_" + str(get_instance_id()))
	
	# Reproducir sonido de recolección
	audio_player.play()
	
	# No eliminar el objeto, solo desactivar
	# queue_free()

func mark_as_collected():
	collected = true
	diamond_mesh.visible = false
	# Asegurar que la colisión esté desactivada
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	# También desactivar el área de interacción
	if interaction_area:
		interaction_area.monitoring = false
		interaction_area.monitorable = false
	
	print("Collectable ", name , "marcado como recolectado")

# Añadir al grupo "collectables"
func _enter_tree():
	add_to_group("collectables")
