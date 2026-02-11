class_name CharacterStats
extends Resource

signal health_changed(current: int, maximum: int)
signal stamina_changed(current: float, maximum: float)
signal died

# === HEALTH ===
@export var max_health: int = 100
var current_health: int:
	set(value):
		current_health = clampi(value, 0, max_health)
		health_changed.emit(current_health, max_health)
		if current_health <= 0:
			died.emit()

# === STAMINA ===
@export var max_stamina: float = 100.0
@export var stamina_regen_rate: float = 15.0  # Per second
var current_stamina: float:
	set(value):
		current_stamina = clampf(value, 0.0, max_stamina)
		stamina_changed.emit(current_stamina, max_stamina)

# === COMBAT ===
@export var attack_damage: int = 10
@export var attack_stamina_cost: float = 20.0
@export var defense: int = 0  # Giảm damage nhận vào

# === MOVEMENT ===
@export var move_speed: float = 120.0
@export var run_speed: float = 180.0
@export var run_stamina_cost: float = 10.0  # Per second


func _init() -> void:
	current_health = max_health
	current_stamina = max_stamina


func take_damage(amount: int) -> void:
	var actual_damage := maxi(amount - defense, 1)
	current_health -= actual_damage


func heal(amount: int) -> void:
	current_health += amount


func use_stamina(amount: float) -> bool:
	if current_stamina >= amount:
		current_stamina -= amount
		return true
	return false


func regen_stamina(delta: float) -> void:
	current_stamina += stamina_regen_rate * delta


func is_alive() -> bool:
	return current_health > 0


func has_stamina(amount: float) -> bool:
	return current_stamina >= amount


func reset() -> void:
	current_health = max_health
	current_stamina = max_stamina
