class_name SkillExecutor
extends Node

## ╔═══════════════════════════════════════════════════════════════════════╗
## ║  Skill Executor — spawns skill hitboxes/effects in the world          ║
## ║  Decoupled: receives (skill_data, position, direction, base_damage)   ║
## ║  Does NOT reference Player, SkillComponent, or any other component    ║
## ╚═══════════════════════════════════════════════════════════════════════╝

signal skill_effect_finished(skill_id: String)


## Execute a skill at a position in a direction
func execute_skill(skill: SkillData, origin: Vector2, direction: Vector2, base_damage: int, parent_node: Node2D) -> void:
	match skill.id:
		"whirlwind":
			_execute_whirlwind(skill, origin, base_damage, parent_node)
		"shield_bash":
			_execute_shield_bash(skill, origin, direction, base_damage, parent_node)
		"fire_burst":
			_execute_fire_burst(skill, origin, direction, base_damage, parent_node)
		_:
			push_warning("SkillExecutor: Unknown skill '%s'" % skill.id)
			skill_effect_finished.emit(skill.id)


func _execute_whirlwind(skill: SkillData, origin: Vector2, base_damage: int, parent_node: Node2D) -> void:
	# AoE circle around player
	var damage := int(float(base_damage) * skill.damage_multiplier)
	var hitbox := _create_skill_hitbox(origin, skill.range_radius, damage, skill.knockback_force, parent_node)

	# Spawn VFX if effect_scene is set
	_spawn_vfx(skill, origin, parent_node)

	# Active for 0.5s (matches VFX animation length) then cleanup
	await get_tree().create_timer(0.5).timeout
	if is_instance_valid(hitbox):
		hitbox.queue_free()
	skill_effect_finished.emit(skill.id)


func _execute_shield_bash(skill: SkillData, origin: Vector2, direction: Vector2, base_damage: int, parent_node: Node2D) -> void:
	# Forward cone
	var damage := int(float(base_damage) * skill.damage_multiplier)
	var offset := direction.normalized() * skill.range_radius * 0.5
	var hitbox := _create_skill_hitbox(origin + offset, skill.range_radius * 0.6, damage, skill.knockback_force, parent_node)

	_spawn_vfx(skill, origin + offset, parent_node)

	await get_tree().create_timer(0.2).timeout
	if is_instance_valid(hitbox):
		hitbox.queue_free()
	skill_effect_finished.emit(skill.id)


func _execute_fire_burst(skill: SkillData, origin: Vector2, direction: Vector2, base_damage: int, parent_node: Node2D) -> void:
	# Ranged projectile-like AoE at distance
	var damage := int(float(base_damage) * skill.damage_multiplier)
	var target_pos := origin + direction.normalized() * skill.range_radius
	var hitbox := _create_skill_hitbox(target_pos, 25.0, damage, skill.knockback_force, parent_node)

	_spawn_vfx(skill, target_pos, parent_node)

	await get_tree().create_timer(0.4).timeout
	if is_instance_valid(hitbox):
		hitbox.queue_free()
	skill_effect_finished.emit(skill.id)


## Create a temporary HitboxComponent-compatible Area2D
func _create_skill_hitbox(pos: Vector2, radius: float, damage: int, knockback: float, parent_node: Node2D) -> Area2D:
	var area := Area2D.new()
	area.global_position = pos
	area.collision_layer = CollisionLayers.Layer.PLAYER_HITBOX   # Layer 7
	area.collision_mask = CollisionLayers.Layer.ENEMY_HURTBOX    # Layer 6
	area.monitoring = true
	area.monitorable = false

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	area.add_child(shape)

	# Connect to detect hurtboxes
	area.area_entered.connect(func(other: Area2D):
		if other.has_method("take_damage"):
			other.take_damage(damage, knockback, pos)
	)

	parent_node.get_parent().add_child(area)
	return area


## Spawn the VFX scene at a position (if skill has an effect_scene)
func _spawn_vfx(skill: SkillData, pos: Vector2, parent_node: Node2D) -> void:
	if skill.effect_scene == null:
		return
	var vfx: Node2D = skill.effect_scene.instantiate()
	vfx.global_position = pos
	parent_node.get_parent().add_child(vfx)
