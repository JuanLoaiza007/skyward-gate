extends Node
class_name HealthComponent

@export var max_health: int = 100
var current_health: int
var invulnerable = false
var invulnerability_timer = 0.0
const INVULNERABILITY_TIME = 1.0

signal health_changed(new_health: int)
signal damaged(amount: int, source_point: Vector3)
signal died

func _ready():
	current_health = max_health

func _process(delta: float) -> void:
	if invulnerable:
		invulnerability_timer -= delta
		if invulnerability_timer <= 0:
			invulnerable = false

func take_damage(amount: int, source_point: Vector3 = Vector3.ZERO):
	if amount <= 0 or invulnerable or not is_alive():
		return
	current_health -= amount
	current_health = max(0, current_health)
	invulnerable = true
	invulnerability_timer = INVULNERABILITY_TIME
	health_changed.emit(current_health)
	damaged.emit(amount, source_point)
	if current_health <= 0:
		died.emit()

func heal(amount: int):
	if amount <= 0:
		return
	current_health += amount
	current_health = min(max_health, current_health)
	health_changed.emit(current_health)

func is_alive() -> bool:
	return current_health > 0

func get_current_health() -> int:
	return current_health

func set_health(new_health: int):
	current_health = clamp(new_health, 0, max_health)
	health_changed.emit(current_health)
	if current_health <= 0:
		died.emit()
