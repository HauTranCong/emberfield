# Health Component - Reusable health system
# Attach to any Node, connect signals to handle damage/death
class_name HealthComponent
extends Node

## Maximum health points
@export var max_health: int = 100

## Emitted when health changes
signal health_changed(current: int, maximum: int)
## Emitted when health reaches 0
signal died

var current_health: int

func _ready() -> void:
	current_health = max_health


## Apply damage, returns actual damage dealt
func take_damage(amount: int) -> int:
	var actual_damage := mini(amount, current_health)
	current_health = maxi(0, current_health - amount)
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0:
		died.emit()
	
	return actual_damage


## Restore health
func heal(amount: int) -> void:
	current_health = mini(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)


## Set health to max
func reset() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)


## Check if dead
func is_dead() -> bool:
	return current_health <= 0


## Get health percentage (0.0 to 1.0)
func get_health_percent() -> float:
	return float(current_health) / float(max_health)
