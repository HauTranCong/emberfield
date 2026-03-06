class_name BuffComponent
extends Node

## ╔═══════════════════════════════════════════════════════════════════════╗
## ║                      BUFF COMPONENT                                   ║
## ╠═══════════════════════════════════════════════════════════════════════╣
## ║  Manages timed stat buffs. Decoupled from CharacterStats.             ║
## ║  The owner entity (Player) wires signals:                             ║
## ║                                                                       ║
## ║  BuffComponent.buffs_changed ──▶ Player._on_buffs_changed()           ║
## ║                                    └─▶ stats.apply_buff_bonuses(buff) ║
## ║                                                                       ║
## ║  BuffComponent.buff_applied  ──▶ HUD.show_buff_icon()                 ║
## ║  BuffComponent.buff_expired  ──▶ HUD.hide_buff_icon()                 ║
## ╚═══════════════════════════════════════════════════════════════════════╝

## Emitted when any buff starts (for HUD icon display)
signal buff_applied(buff_data: Dictionary)

## Emitted when a buff expires (for HUD icon removal)
signal buff_expired(buff_id: String)

## Emitted when the aggregate buff stats change (for CharacterStats recalc)
signal buffs_changed

## Active buffs array. Each entry:
## {
##   "id": String,              # Unique buff identifier (usually source item_id)
##   "source_item_id": String,  # ItemData.id that created this buff
##   "attack_bonus": int,
##   "defense_bonus": int,
##   "health_bonus": int,
##   "speed_bonus": float,
##   "passive_effect": ItemData.PassiveEffect,
##   "passive_value": float,
##   "remaining_time": float,   # Seconds remaining (-1 = permanent, from augments)
##   "total_duration": float    # Original duration (for UI progress bar)
## }
var active_buffs: Array[Dictionary] = []


func _process(delta: float) -> void:
	var expired_ids: Array[String] = []

	for buff: Dictionary in active_buffs:
		var remaining: float = buff.get("remaining_time", -1.0)
		if remaining < 0.0:
			continue  # Permanent buff (from augment), skip tick
		buff["remaining_time"] = remaining - delta
		if buff["remaining_time"] <= 0.0:
			expired_ids.append(buff.get("id", ""))

	if expired_ids.size() > 0:
		for buff_id: String in expired_ids:
			_remove_buff_internal(buff_id)
		buffs_changed.emit()


## Apply a timed buff from an ItemData (TIMED_BUFF augment type)
## If a buff with the same id already exists, refresh its duration (no stacking)
func apply_buff(item: ItemData) -> void:
	var buff_id := item.id

	# Check for existing buff → refresh duration
	for existing: Dictionary in active_buffs:
		if existing.get("id", "") == buff_id:
			existing["remaining_time"] = item.buff_duration
			existing["total_duration"] = item.buff_duration
			buffs_changed.emit()
			return

	# Create new buff entry
	var buff_data := {
		"id": buff_id,
		"source_item_id": item.id,
		"attack_bonus": item.attack_bonus,
		"defense_bonus": item.defense_bonus,
		"health_bonus": item.health_bonus,
		"speed_bonus": item.speed_bonus,
		"passive_effect": item.passive_effect,
		"passive_value": item.passive_value,
		"remaining_time": item.buff_duration,
		"total_duration": item.buff_duration,
	}

	active_buffs.append(buff_data)
	buff_applied.emit(buff_data)
	buffs_changed.emit()


## Manually remove a buff by id
func remove_buff(buff_id: String) -> void:
	_remove_buff_internal(buff_id)
	buffs_changed.emit()


## Clear all buffs (e.g. on death)
func clear_all_buffs() -> void:
	var ids: Array[String] = []
	for buff: Dictionary in active_buffs:
		ids.append(buff.get("id", ""))
	active_buffs.clear()
	for id: String in ids:
		buff_expired.emit(id)
	buffs_changed.emit()


# === STAT AGGREGATION (called by CharacterStats) ===

func get_total_buff_attack() -> int:
	var total := 0
	for buff: Dictionary in active_buffs:
		total += buff.get("attack_bonus", 0)
	return total


func get_total_buff_defense() -> int:
	var total := 0
	for buff: Dictionary in active_buffs:
		total += buff.get("defense_bonus", 0)
	return total


func get_total_buff_health() -> int:
	var total := 0
	for buff: Dictionary in active_buffs:
		total += buff.get("health_bonus", 0)
	return total


func get_total_buff_speed() -> float:
	var total := 0.0
	for buff: Dictionary in active_buffs:
		total += buff.get("speed_bonus", 0.0)
	return total


# === PASSIVE EFFECT QUERIES (called by PassiveEffectProcessor) ===

## Returns all active passive effects as Array[{effect: PassiveEffect, value: float}]
func get_active_passive_effects() -> Array[Dictionary]:
	var effects: Array[Dictionary] = []
	for buff: Dictionary in active_buffs:
		var effect: int = buff.get("passive_effect", ItemData.PassiveEffect.NONE)
		if effect != ItemData.PassiveEffect.NONE:
			effects.append({"effect": effect, "value": buff.get("passive_value", 0.0)})
	return effects


func _remove_buff_internal(buff_id: String) -> void:
	for i: int in range(active_buffs.size() - 1, -1, -1):
		if active_buffs[i].get("id", "") == buff_id:
			active_buffs.remove_at(i)
			buff_expired.emit(buff_id)
			return
