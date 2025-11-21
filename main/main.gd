extends Node3D

func _ready():
	var game_world_scene = load("res://game_world/game_world.tscn")
	var game_world_instance = game_world_scene.instantiate()
	add_child(game_world_instance)
