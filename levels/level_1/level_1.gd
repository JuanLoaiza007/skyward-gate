extends Node3D

const DEATH_HEIGHT = -50.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Level1World/Terrain/StaticBody3D.add_to_group("grass_surface")
	$Level1World/Platform_001/StaticBody3D.add_to_group("grass_surface")
	$Level1World/Platform_002/StaticBody3D.add_to_group("grass_surface")
	$Level1World/Platform_003/StaticBody3D.add_to_group("grass_surface")
	$Level1World/Platform_004/StaticBody3D.add_to_group("grass_surface")
	$Level1World/Platform_005/StaticBody3D.add_to_group("grass_surface")
	$Level1World/Platform_006/StaticBody3D.add_to_group("grass_surface")
	$Level1World/Platform_007/StaticBody3D.add_to_group("grass_surface")
	$Level1World/Platform_008/StaticBody3D.add_to_group("grass_surface")
	$Level1World/Platform_009/StaticBody3D.add_to_group("grass_surface")
	$Level1World/Platforms/StaticBody3D.add_to_group("grass_surface")
	$Level1World/Platforms/StaticBody3D.add_to_group("grass_surface")
	pass # Add any initialization logic here if needed

func _physics_process(delta: float) -> void:
	var player = $Player
	if player and player.global_position.y < DEATH_HEIGHT:
		if player.has_node("HealthComponent"):
			player.get_node("HealthComponent").take_damage(999, Vector3.DOWN)
