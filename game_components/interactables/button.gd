extends Interactable

var interaction_area: Area3D
var player_in_area: bool = false

func _ready() -> void:
	super._ready()
	interaction_area = $InteractionArea
	interaction_area.body_entered.connect(_on_interaction_area_body_entered)
	interaction_area.body_exited.connect(_on_interaction_area_body_exited)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("KEY_E") and player_in_area:
		_interact()

func _interact() -> void:
	interacted.emit()

func _on_interaction_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_area = true

func _on_interaction_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_area = false
