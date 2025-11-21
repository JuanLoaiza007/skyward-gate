extends Interactable

@export var is_active: bool = true:
	set(value):
		is_active = value
		_update_state()

func _ready() -> void:
	super._ready()
	_update_state()

func _update_state() -> void:
	visible = is_active
	# Disable/enable collision shapes and interaction areas
	for child in get_children():
		if child is CollisionShape3D:
			child.disabled = !is_active
		elif child is Area3D:
			child.monitoring = is_active

# Function to toggle the door on/off like a switch
func toggle() -> void:
	is_active = !is_active

func _on_interacted() -> void:
	toggle()
