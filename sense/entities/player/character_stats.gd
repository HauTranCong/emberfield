class_name CharacterStats
extends Resource

## Character stats với equipment bonus system
##
## ╔═══════════════════════════════════════════════════════════════════════╗
## ║                    STAT CALCULATION                                   ║
## ╠═══════════════════════════════════════════════════════════════════════╣
## ║  Final Stat = Base Stat + Equipment Bonus                             ║
## ║                                                                       ║
## ║  Example:                                                             ║
## ║  ┌────────────────────────────────────────────────────────────────┐   ║
## ║  │ Base Attack = 10                                               │   ║
## ║  │ + Iron Sword (attack_bonus: +5)                                │   ║
## ║  │ + Strength Ring (attack_bonus: +2)                             │   ║
## ║  │ = get_total_attack() → 17                                      │   ║
## ║  └────────────────────────────────────────────────────────────────┘   ║
## ╚═══════════════════════════════════════════════════════════════════════╝

signal health_changed(current: int, maximum: int)
signal stamina_changed(current: float, maximum: float)
signal died

# === BASE HEALTH ===
@export var base_max_health: int = 100
var max_health: int:
	get:
		return base_max_health + equipment_health_bonus
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

# === BASE COMBAT ===
@export var base_attack_damage: int = 10
@export var attack_stamina_cost: float = 20.0
@export var base_defense: int = 0  # Giảm damage nhận vào

# === BASE MOVEMENT ===
@export var base_move_speed: float = 120.0
@export var run_speed: float = 180.0
@export var run_stamina_cost: float = 10.0  # Per second

# === EQUIPMENT BONUSES ===
var equipment_attack_bonus: int = 0
var equipment_defense_bonus: int = 0
var equipment_health_bonus: int = 0
var equipment_speed_bonus: float = 0.0

# === COMPUTED STATS (with equipment) ===
var attack_damage: int:
	get:
		return base_attack_damage + equipment_attack_bonus

var defense: int:
	get:
		return base_defense + equipment_defense_bonus

var move_speed: float:
	get:
		return base_move_speed + equipment_speed_bonus


func _init() -> void:
	current_health = max_health
	current_stamina = max_stamina


## Apply equipment bonuses from inventory
func apply_equipment_bonuses(inventory: InventoryData) -> void:
	if inventory == null:
		return
	
	equipment_attack_bonus = inventory.get_total_attack_bonus()
	equipment_defense_bonus = inventory.get_total_defense_bonus()
	equipment_health_bonus = inventory.get_total_health_bonus()
	equipment_speed_bonus = inventory.get_total_speed_bonus()
	
	# Re-emit health change in case max_health changed
	health_changed.emit(current_health, max_health)


## Clear all equipment bonuses
func clear_equipment_bonuses() -> void:
	equipment_attack_bonus = 0
	equipment_defense_bonus = 0
	equipment_health_bonus = 0
	equipment_speed_bonus = 0
	health_changed.emit(current_health, max_health)


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


func restore_stamina(amount: float) -> void:
	current_stamina = clampf(current_stamina + amount, 0.0, max_stamina)


func regen_stamina(delta: float) -> void:
	current_stamina += stamina_regen_rate * delta


func is_alive() -> bool:
	return current_health > 0


func has_stamina(amount: float) -> bool:
	return current_stamina >= amount


func reset() -> void:
	current_health = max_health
	current_stamina = max_stamina
