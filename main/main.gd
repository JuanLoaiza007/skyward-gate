extends Node3D

func _ready():
	var level_scene = load("res://levels/level_0/level_0.tscn")
	var level_instance = level_scene.instantiate()
	add_child(level_instance)
