class_name SkillComponent
extends Node

## ╔═══════════════════════════════════════════════════════════════════════╗
## ║                    SKILL COMPONENT                                    ║
## ╠═══════════════════════════════════════════════════════════════════════╣
## ║  Manages equipment-bound active skills. Decoupled design:             ║
## ║                                                                       ║
## ║  Owner injects:                                                       ║
## ║  - get_active_skills_func: Callable → Array[{skill_id, slot}]         ║
## ║  - use_stamina_func: Callable(float) → bool                           ║
## ║                                                                       ║
## ║  Owner calls rebuild_skills() when equipment/augments change.         ║
## ║                                                                       ║
## ║  Skill key mapping (based on source equipment slot):                  ║
## ║  ┌───────────────────┬───────┐                                        ║
## ║  │ weapon augment    │ Q key │                                        ║
## ║  │ armor augment     │ E key │                                        ║
## ║  │ helmet augment    │ R key │                                        ║
## ║  │ boots augment     │ F key │                                        ║
## ║  │ shield augment    │ Q key │ (fallback)                             ║
## ║  │ accessory_1       │ E key │ (fallback)                             ║
## ║  │ accessory_2       │ R key │ (fallback)                             ║
## ║  └───────────────────┴───────┘                                        ║
## ╚═══════════════════════════════════════════════════════════════════════╝

signal skill_activated(skill_id: String)
signal skill_cooldown_updated(skill_id: String, remaining: float)
signal skills_changed

## Injected by owner — returns Array[{skill_id: String, source_equip_slot: String}]
var get_active_skills_func: Callable

## Injected by owner — attempts to use stamina, returns bool
var use_stamina_func: Callable

## Current available skills with cooldown tracking
## Array[Dictionary]: {skill_id, source_equip_slot, cooldown, current_cooldown, input_action}
var available_skills: Array[Dictionary] = []

## Skill input action mapping by equipment slot
const SLOT_INPUT_MAP: Dictionary = {
	"weapon": "skill_1",      # Q key (define in project input map)
	"armor": "skill_2",       # E key
	"helmet": "skill_3",      # R key
	"boots": "skill_4",       # F key
	"shield": "skill_1",
	"accessory_1": "skill_2",
	"accessory_2": "skill_3",
}


func _process(delta: float) -> void:
	# Tick down cooldowns
	for skill: Dictionary in available_skills:
		var cd: float = skill.get("current_cooldown", 0.0)
		if cd > 0.0:
			skill["current_cooldown"] = maxf(0.0, cd - delta)
			skill_cooldown_updated.emit(skill.get("skill_id", ""), skill["current_cooldown"])


func _unhandled_input(event: InputEvent) -> void:
	for skill: Dictionary in available_skills:
		var input_action: String = skill.get("input_action", "")
		if input_action.is_empty():
			continue
		if event.is_action_pressed(input_action):
			try_activate_skill(skill.get("skill_id", ""))
			return


## Rebuild the available skills list from owner's data
## Called by owner when equipment_changed or augments_changed fires
func rebuild_skills() -> void:
	available_skills.clear()

	if get_active_skills_func.is_null():
		skills_changed.emit()
		return

	var raw_skills: Array = get_active_skills_func.call()
	for entry: Dictionary in raw_skills:
		var skill_id: String = entry.get("skill_id", "")
		var slot: String = entry.get("source_equip_slot", "")
		var skill_data: SkillData = SkillDatabase.get_skill(skill_id) if skill_id != "" else null

		if skill_data == null:
			continue

		available_skills.append({
			"skill_id": skill_id,
			"source_equip_slot": slot,
			"cooldown": skill_data.cooldown,
			"current_cooldown": 0.0,
			"stamina_cost": skill_data.stamina_cost,
			"input_action": SLOT_INPUT_MAP.get(slot, ""),
		})

	skills_changed.emit()


## Attempt to activate a skill by id
func try_activate_skill(skill_id: String) -> bool:
	for skill: Dictionary in available_skills:
		if skill.get("skill_id", "") != skill_id:
			continue

		# Check cooldown
		if skill.get("current_cooldown", 0.0) > 0.0:
			return false

		# Check stamina
		var cost: float = skill.get("stamina_cost", 0.0)
		if not use_stamina_func.is_null() and not use_stamina_func.call(cost):
			return false

		# Start cooldown
		skill["current_cooldown"] = skill.get("cooldown", 0.0)

		# Emit activation signal — owner handles state change + execution
		skill_activated.emit(skill_id)
		return true

	return false


## Check if a skill is off cooldown
func is_skill_ready(skill_id: String) -> bool:
	for skill: Dictionary in available_skills:
		if skill.get("skill_id", "") == skill_id:
			return skill.get("current_cooldown", 0.0) <= 0.0
	return false
