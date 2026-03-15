class_name SkillData
extends Resource

## ╔════════════════════════════════════════════════════════════╗
## ║  Skill Data — defines one activatable skill                ║
## ║  Referenced by SkillComponent via skill_id                 ║
## ╚════════════════════════════════════════════════════════════╝

@export var id: String = ""
@export var skill_name: String = ""
@export var description: String = ""
@export var cooldown: float = 5.0
@export var stamina_cost: float = 30.0
@export var damage_multiplier: float = 1.5
@export var range_radius: float = 40.0            # Hitbox radius
@export var knockback_force: float = 150.0
@export var effect_scene: PackedScene = null       # Optional VFX scene
