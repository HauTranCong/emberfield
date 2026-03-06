extends Node

## ╔════════════════════════════════════════════════════════════╗
## ║  SkillDatabase — Autoload                                  ║
## ║  Mirrors the ItemDatabase pattern:                         ║
## ║  - Dictionary of SkillData keyed by skill_id               ║
## ║  - get_skill(id) → SkillData                               ║
## ╚════════════════════════════════════════════════════════════╝

var skills: Dictionary = {}  # skill_id → SkillData

## Preloaded VFX scenes for skills that have visual effects
var _whirlwind_vfx: PackedScene = preload("res://sense/skills/WhirlwindVFX.tscn")


func _ready() -> void:
	_create_skills()


func get_skill(skill_id: String) -> SkillData:
	return skills.get(skill_id)


func get_all_skills() -> Array:
	return skills.values()


func _create_skills() -> void:
	_add_skill("whirlwind", "Whirlwind", "Spin attack hitting all nearby enemies.", 6.0, 35.0, 1.8, 50.0, 200.0, _whirlwind_vfx)
	_add_skill("shield_bash", "Shield Bash", "Bash forward, knocking back and stunning.", 8.0, 25.0, 1.2, 30.0, 300.0)
	_add_skill("fire_burst", "Fire Burst", "Launch a burst of fire in facing direction.", 10.0, 40.0, 2.0, 60.0, 100.0)


func _add_skill(id: String, sname: String, desc: String, cd: float, stam: float, dmg_mult: float, range_r: float, kb: float, vfx: PackedScene = null) -> void:
	var skill := SkillData.new()
	skill.id = id
	skill.skill_name = sname
	skill.description = desc
	skill.cooldown = cd
	skill.stamina_cost = stam
	skill.damage_multiplier = dmg_mult
	skill.range_radius = range_r
	skill.knockback_force = kb
	skill.effect_scene = vfx
	skills[id] = skill
