extends Node

var current_checkpoint_data: Dictionary = {}
var collected_items: Array = []
var interactables_state: Dictionary = {}

func set_checkpoint(checkpoint_id: String, player_position: Vector3, player_health: int, level_path: String) -> void:
	current_checkpoint_data = {
		"checkpoint_id": checkpoint_id,
		"player_position": player_position,
		"player_health": player_health,
		"level_path": level_path,
		"collected_items": collected_items.duplicate(),
		"interactables_state": interactables_state.duplicate(true)
	}

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
