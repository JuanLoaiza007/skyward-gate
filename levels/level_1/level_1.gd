extends Node3D

const DEATH_HEIGHT = -30.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:	
	pass # Add any initialization logic here if needed

func _physics_process(delta: float) -> void:
	var player = $Player
	if player and player.global_position.y < DEATH_HEIGHT:
		if player.has_node("HealthComponent"):
			player.get_node("HealthComponent").take_damage(999, Vector3.DOWN)
