# Hitbox Component - Reusable attack hitbox
# Attach to Area2D node, configure collision shape separately per entity
class_name HitboxComponent
extends Area2D

## Damage dealt when hitting a hurtbox
@export var damage: int = 10
## Force applied to target on hit
@export var knockback_force: float = 100.0

## Emitted when this hitbox hits a hurtbox
signal hit_landed(hurtbox: Area2D)

func _ready() -> void:
	# Layer/Mask should be set in scene inspector based on entity type:
	# Player: Layer 7 (PLAYER_HITBOX), Mask: Layer 6 (ENEMY_HURTBOX)
	# Enemy: Layer 8 (ENEMY_HITBOX), Mask: Layer 5 (PLAYER_HURTBOX)
	area_entered.connect(_on_area_entered)
	# Default disabled, enable during attack
	monitoring = false


func _on_area_entered(area: Area2D) -> void:
	# var parent_name: String = str(area.get_parent().name) if area.get_parent() else "none"
	# print("[HITBOX] Hit detected! Area: ", area.name, " Parent: ", parent_name)
	# print("[HITBOX] My layer: ", collision_layer, " My mask: ", collision_mask)
	# print("[HITBOX] Target layer: ", area.collision_layer, " Target mask: ", area.collision_mask)
	# Check if it's a HurtboxComponent by checking for the method
	if area.has_method("take_damage"):
		# print("[HITBOX] Calling take_damage with damage: ", damage)
		area.take_damage(damage, knockback_force, global_position)
		hit_landed.emit(area)
	else:
		# print("[HITBOX] Area does NOT have take_damage method!")
		pass


## Call this to enable hitbox (during attack animation)
func activate() -> void:
	# print("[HITBOX] Activated! Layer: ", collision_layer, " Mask: ", collision_mask)
	monitoring = true


## Call this to disable hitbox (after attack ends)
func deactivate() -> void:
	monitoring = false
