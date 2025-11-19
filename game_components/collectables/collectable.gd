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
		collected = true
		# Ocultar el mesh visible
		diamond_mesh.visible = false
		# Actualizar estado del juego
		GameStateManager.add_session_item(name + "_" + str(get_instance_id()))
		# Reproducir sonido de recolección
		audio_player.play()
		# Esperar a que termine el sonido
		await audio_player.finished
		# Eliminar el objeto
		queue_free()
