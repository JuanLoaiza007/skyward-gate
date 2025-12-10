@tool
extends "res://scripts/base_interactable.gd"

enum InteractableType { BUTTON, DOOR }

const INTERACTABLE_SCENES = {
	InteractableType.BUTTON: preload("res://game_components/interactables/button.tscn"),
	InteractableType.DOOR: preload("res://game_components/interactables/door.tscn")
}

@export var interactable_type: InteractableType = InteractableType.BUTTON:
	set(value):
		interactable_type = value
		if Engine.is_editor_hint():
			_update_instance()
@export var target: Node

var interaction_area: Area3D
var player_in_area: bool = false
var instanced_scene: Node
var has_been_interacted: bool = false

func _ready() -> void:
	super._ready()
	_update_instance()
	
	# Cargar estado guardado si existe
	var saved_state = CheckpointManager.get_interactable_state(get_unique_id())
	if saved_state:
		load_state(saved_state)

func get_unique_id() -> String:
	# Usar nombre y posición global como identificador único
	return name + "_" + str(global_transform.origin)

func _update_instance() -> void:
	# Remove existing instance
	var placeholder = get_node_or_null("StaticBody3DPlaceholder")
	for child in get_children():
		if child != placeholder:
			child.queue_free()
	var scene = INTERACTABLE_SCENES[interactable_type]
	instanced_scene = scene.instantiate()
	add_child(instanced_scene)
	# Find InteractionArea in the instance
	interaction_area = find_interaction_area(instanced_scene)
	if interaction_area:
		interaction_area.body_entered.connect(_on_interaction_area_body_entered)
		interaction_area.body_exited.connect(_on_interaction_area_body_exited)

func find_interaction_area(node: Node) -> Area3D:
	if node is Area3D and node.name == "InteractionArea":
		return node
	for child in node.get_children():
		var found = find_interaction_area(child)
		if found:
			return found
	return null

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("KEY_E") and player_in_area:
		_interact()

func _interact() -> void:
	if target and target.instanced_scene and target.instanced_scene.has_method("_on_interacted"):
		target.instanced_scene._on_interacted()
		has_been_interacted = true
		
		# Guardar estado
		save_state()
		CheckpointManager.update_current_state()
		
	interacted.emit()

func _on_interaction_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_area = true

func _on_interaction_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_area = false

# Métodos para estado persistente
func save_state() -> void:
	var state = {
		"has_been_interacted": has_been_interacted,
		"player_in_area": player_in_area
	}
	CheckpointManager.save_interactable_state(get_path(), state)

func load_state(state: Dictionary) -> void:
	has_been_interacted = state.get("has_been_interacted", false)
	player_in_area = state.get("player_in_area", false)
	
	# Si ya fue interactuado, forzar el estado en el objetivo
	if has_been_interacted and target and target.instanced_scene and target.instanced_scene.has_method("force_interact"):
		target.instanced_scene.force_interact()

func get_state() -> Dictionary:
	return {
		"has_been_interacted": has_been_interacted,
		"player_in_area": player_in_area
	}

# Añadir al grupo "interactables"
func _enter_tree():
	add_to_group("interactables")
