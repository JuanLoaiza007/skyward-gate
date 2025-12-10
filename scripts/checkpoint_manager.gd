extends Node

var current_checkpoint_data: Dictionary = {}
var collected_items: Array = []
var interactables_state: Dictionary = {}

func set_checkpoint(checkpoint_id: String, player_position: Vector3, player_health: int, level_path: String) -> void:
	update_current_state()
	current_checkpoint_data = {
		"checkpoint_id": checkpoint_id,
		"player_position": player_position,
		"player_health": player_health,
		"level_path": level_path,
		"collected_items": collected_items.duplicate(),
		"interactables_state": interactables_state.duplicate(true)
	}
	print("Checkpoint guardado: ", current_checkpoint_data)

func update_current_state():
	var game_world = get_node("/root/Main/GameWorld")
	if not game_world or not game_world.current_level_node.get_child_count() > 0:
		return
	
	var current_level = game_world.current_level_node.get_child(0)
	
	# Actualizar lista de collectables recolectados
	collected_items.clear()
	for collectable in get_tree().get_nodes_in_group("collectables"):
		if collectable.collected:
			var relative_path = current_level.get_path_to(collectable)
			collected_items.append(str(relative_path))
			print("Collectable guardado: ", str(relative_path))
	
	# Actualizar estado de interactuables
	interactables_state.clear()
	for interactable in get_tree().get_nodes_in_group("interactables"):
		var relative_path = current_level.get_path_to(interactable)
		if interactable.has_method("get_state"):
			interactables_state[str(relative_path)] = interactable.get_state()
			print("Interactuable guardado: ", str(relative_path))

func get_checkpoint_data() -> Dictionary:
	return current_checkpoint_data

func clear_checkpoint() -> void:
	current_checkpoint_data = {}
	collected_items.clear()
	interactables_state.clear()

func add_collected_item(item_id: String) -> void:
	if not collected_items.has(item_id):
		collected_items.append(item_id)

func is_item_collected(item_id: String) -> bool:
	return collected_items.has(item_id)

func save_interactable_state(interactable_id: String, state: Dictionary) -> void:
	interactables_state[interactable_id] = state

func get_interactable_state(interactable_id: String) -> Dictionary:
	return interactables_state.get(interactable_id, {})

func get_unique_id_for_node(node: Node3D) -> String:
	return node.name + "_" + str(node.global_transform.origin)
