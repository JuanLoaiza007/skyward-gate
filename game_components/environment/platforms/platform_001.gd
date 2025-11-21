extends MeshInstance3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$StaticBody3D.add_to_group("grass_surface")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
