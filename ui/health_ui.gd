extends CanvasLayer

@onready var health_label = $HealthLabel

func _ready():
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_node("HealthComponent"):
		var health_comp = player.get_node("HealthComponent")
		health_comp.health_changed.connect(_on_health_changed)
		_on_health_changed(health_comp.get_current_health())

func _on_health_changed(new_health: int):
	health_label.text = "Vidas: " + str(new_health)
