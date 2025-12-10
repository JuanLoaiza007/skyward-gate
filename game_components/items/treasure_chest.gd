extends Node3D

signal victory

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var victory_area = $VictoryArea
	if victory_area:
		victory_area.body_entered.connect(_on_victory_area_body_entered)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_victory_area_body_entered(body: Node3D) -> void:
	print("JAJAJA")
	if body.is_in_group("player"):
		victory.emit()
