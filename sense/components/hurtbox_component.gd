# Hurtbox Component - Reusable damage receiver
# Attach to Area2D node, configure collision shape separately per entity
class_name HurtboxComponent
extends Area2D

## Time before this hurtbox can receive damage again (i-frames)
@export var invincibility_time: float = 0.5

## Emitted when damage is received
signal damage_received(amount: int, knockback: float, from_position: Vector2)

var can_take_damage: bool = true

func _ready() -> void:
	# Layer/Mask should be set in scene inspector based on entity type:
	# Player: Layer 5 (PLAYER_HURTBOX), Mask: Layer 8 (ENEMY_HITBOX)
	# Enemy: Layer 6 (ENEMY_HURTBOX), Mask: Layer 7 (PLAYER_HITBOX)
	pass


## Called by HitboxComponent when hit
func take_damage(amount: int, knockback: float, from_position: Vector2) -> void:
	# print("[HURTBOX] take_damage called! Amount: ", amount, " can_take_damage: ", can_take_damage)
	# print("[HURTBOX] My layer: ", collision_layer, " My mask: ", collision_mask)
	if not can_take_damage:
		# print("[HURTBOX] Blocked - invincible!")
		return
	
	# print("[HURTBOX] Emitting damage_received signal")
	damage_received.emit(amount, knockback, from_position)
	
	# Start invincibility frames
	can_take_damage = false
	await get_tree().create_timer(invincibility_time).timeout
	can_take_damage = true


## Reset invincibility (useful when respawning)
func reset() -> void:
	can_take_damage = true
