class_name PassiveEffectProcessor
extends Node

## ╔═══════════════════════════════════════════════════════════════════════╗
## ║                 PASSIVE EFFECT PROCESSOR                              ║
## ╠═══════════════════════════════════════════════════════════════════════╣
## ║  Decoupled combat-effect handler. Owner injects:                      ║
## ║  - get_passive_effects_func: Callable → Array[{effect, value}]        ║
## ║  - get_owner_stats_func: Callable → CharacterStats                    ║
## ║                                                                       ║
## ║  Owner wires HitboxComponent.hit_landed → on_hit_landed()             ║
## ║  Owner wires HurtboxComponent.damage_received → on_damage_received()  ║
## ║                                                                       ║
## ║  This component never imports BuffComponent or InventoryData.         ║
## ╚═══════════════════════════════════════════════════════════════════════╝

## Injected by owner — returns Array[Dictionary] of {effect: PassiveEffect, value: float}
var get_passive_effects_func: Callable

## Injected by owner — returns CharacterStats (for healing, etc.)
var get_owner_stats_func: Callable

## Injected by owner — returns the owner Node2D (for position-based effects)
var get_owner_node_func: Callable


## Called by owner when HitboxComponent.hit_landed fires
## Parameters: hurtbox = the HurtboxComponent that was hit, damage_dealt = int
func on_hit_landed(hurtbox: Area2D, damage_dealt: int) -> void:
	if not get_passive_effects_func.is_valid():
		return

	var effects: Array[Dictionary] = get_passive_effects_func.call()

	for entry: Dictionary in effects:
		var effect: int = entry.get("effect", ItemData.PassiveEffect.NONE)
		var value: float = entry.get("value", 0.0)

		match effect:
			ItemData.PassiveEffect.LIFE_STEAL:
				_apply_life_steal(damage_dealt, value)

			ItemData.PassiveEffect.CRIT_CHANCE:
				pass  # Crit is handled BEFORE damage in calculate_crit_damage(), not here

			ItemData.PassiveEffect.BURN_ON_HIT:
				_apply_dot_to_target(hurtbox, "burn", value)

			ItemData.PassiveEffect.FREEZE_ON_HIT:
				_apply_slow_to_target(hurtbox, value)

			ItemData.PassiveEffect.POISON_ON_HIT:
				_apply_dot_to_target(hurtbox, "poison", value)


## Called by owner when HurtboxComponent.damage_received fires
## Parameters: amount = damage taken, from_position = attacker position
func on_damage_received(amount: int, _knockback: float, from_position: Vector2) -> void:
	if not get_passive_effects_func.is_valid():
		return

	var effects: Array[Dictionary] = get_passive_effects_func.call()

	for entry: Dictionary in effects:
		var effect: int = entry.get("effect", ItemData.PassiveEffect.NONE)
		var value: float = entry.get("value", 0.0)

		match effect:
			ItemData.PassiveEffect.THORNS:
				_apply_thorns(amount, value, from_position)


## Check if crit should apply, returns modified damage
## Called by the owner BEFORE dealing damage (inside attack logic)
func calculate_crit_damage(base_damage: int) -> int:
	if not get_passive_effects_func.is_valid():
		return base_damage

	var effects: Array[Dictionary] = get_passive_effects_func.call()
	var total_crit_chance := 0.0

	for entry: Dictionary in effects:
		if entry.get("effect", 0) == ItemData.PassiveEffect.CRIT_CHANCE:
			total_crit_chance += entry.get("value", 0.0)

	# Roll crit
	if total_crit_chance > 0.0 and randf() * 100.0 < total_crit_chance:
		return base_damage * 2
	return base_damage


func _apply_life_steal(damage_dealt: int, percent: float) -> void:
	if not get_owner_stats_func.is_valid():
		return
	var stats: CharacterStats = get_owner_stats_func.call()
	var heal_amount := int(float(damage_dealt) * percent / 100.0)
	if heal_amount > 0:
		stats.heal(heal_amount)


func _apply_dot_to_target(hurtbox: Area2D, _dot_type: String, damage_per_tick: float) -> void:
	# Find the HealthComponent on the target entity
	var target_entity := hurtbox.get_parent()
	if target_entity == null:
		return
	var health_comp: HealthComponent = _find_child_of_type(target_entity, "HealthComponent")
	if health_comp == null:
		return

	# Apply DoT via a lightweight timer (3 ticks, 1s apart)
	# TODO: Replace with a proper StatusEffectComponent on the enemy in future
	var ticks := 3
	var tick_damage := int(damage_per_tick)
	for i: int in range(ticks):
		if not is_instance_valid(target_entity):
			return
		await get_tree().create_timer(1.0).timeout
		if is_instance_valid(health_comp) and not health_comp.is_dead():
			health_comp.take_damage(tick_damage)


func _apply_slow_to_target(hurtbox: Area2D, slow_percent: float) -> void:
	# Reduce target's movement speed temporarily
	var target_entity := hurtbox.get_parent()
	if target_entity == null or not target_entity.has_method("apply_slow"):
		return
	target_entity.apply_slow(slow_percent, 2.0)  # 2 second slow


func _apply_thorns(damage_received: int, reflect_percent: float, from_position: Vector2) -> void:
	# Reflect damage back to attacker — find nearest enemy at from_position
	var reflect_damage := int(float(damage_received) * reflect_percent / 100.0)
	if reflect_damage <= 0:
		return

	if not get_owner_node_func.is_valid():
		return
	var owner_node: Node2D = get_owner_node_func.call()
	if owner_node == null:
		return

	# Find enemies near the attacker position
	var space_state := owner_node.get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.position = from_position
	query.collision_mask = CollisionLayers.Layer.ENEMY
	query.collide_with_bodies = true
	var results := space_state.intersect_point(query, 1)

	for result: Dictionary in results:
		var collider: Object = result.get("collider")
		if collider is Node:
			var health_comp: HealthComponent = _find_child_of_type(collider as Node, "HealthComponent")
			if health_comp and not health_comp.is_dead():
				health_comp.take_damage(reflect_damage)
				return


## Utility: find first child node of a given class name
func _find_child_of_type(parent: Node, type_name: String) -> Node:
	for child: Node in parent.get_children():
		if child.get_class() == type_name or (child.get_script() and child.get_script().get_global_name() == type_name):
			return child
	return null
