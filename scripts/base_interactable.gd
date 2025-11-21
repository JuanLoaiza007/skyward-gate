class_name Interactable
extends StaticBody3D

signal interacted

func _ready() -> void:
	_update_state()
	interacted.connect(_on_interacted)

func _update_state() -> void:
	pass

# Virtual method for direct player interaction (KEY_E)
func _interact() -> void:
	pass

# Virtual method for interaction via signal from other interactables
func _on_interacted() -> void:
	print("_on_interacted called on: ", name)
	pass
