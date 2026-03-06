class_name InventoryData
extends Resource

## Inventory data manager - handles item storage and equipment
##
## ╔═══════════════════════════════════════════════════════════════════════╗
## ║                      INVENTORY STRUCTURE                              ║
## ╠═══════════════════════════════════════════════════════════════════════╣
## ║                                                                       ║
## ║  ┌─────────────────────┐    ┌───────────────────────────────────────┐ ║
## ║  │   EQUIPMENT SLOTS   │    │           INVENTORY GRID              │ ║
## ║  │                     │    │                                       │ ║
## ║  │  [Helmet]           │    │  [00][01][02][03][04][05][06][07]     │ ║
## ║  │  [Armor]  [Weapon]  │    │  [08][09][10][11][12][13][14][15]     │ ║
## ║  │  [Boots]  [Shield]  │    │  [16][17][18][19][20][21][22][23]     │ ║
## ║  │  [Acc1]   [Acc2]    │    │  [24][25][26][27][28][29][30][31]     │ ║
## ║  │                     │    │  ...                                  │ ║
## ║  └─────────────────────┘    └───────────────────────────────────────┘ ║
## ║                                                                       ║
## ╚═══════════════════════════════════════════════════════════════════════╝

signal inventory_changed
signal equipment_changed(slot_type: String)
signal augments_changed(equip_slot: String)
signal gold_changed(amount: int)

const INVENTORY_SIZE: int = 32  # 8 columns x 4 rows

# Equipment slots
var equipped_helmet: ItemData = null
var equipped_armor: ItemData = null
var equipped_weapon: ItemData = null
var equipped_shield: ItemData = null
var equipped_boots: ItemData = null
var equipped_accessory_1: ItemData = null
var equipped_accessory_2: ItemData = null

# Inventory grid - array of {item: ItemData, quantity: int}
var inventory_slots: Array[Dictionary] = []

# Currency
var gold: int = 0:
	set(value):
		gold = maxi(value, 0)
		gold_changed.emit(gold)


func _init() -> void:
	# Initialize empty inventory slots
	inventory_slots.clear()
	for i in range(INVENTORY_SIZE):
		inventory_slots.append({"item": null, "quantity": 0})


## Add item to inventory, returns remaining quantity that couldn't be added
func add_item(item: ItemData, quantity: int = 1) -> int:
	if item == null or quantity <= 0:
		return quantity
	
	var remaining := quantity
	
	# If stackable, try to add to existing stacks first
	if item.stackable:
		for slot in inventory_slots:
			if slot.item != null and slot.item.id == item.id:
				var can_add := mini(item.max_stack - slot.quantity, remaining)
				if can_add > 0:
					slot.quantity += can_add
					remaining -= can_add
				if remaining <= 0:
					break
	
	# Add to empty slots
	if remaining > 0:
		for slot in inventory_slots:
			if slot.item == null:
				var add_amount := mini(item.max_stack if item.stackable else 1, remaining)
				slot.item = item
				slot.quantity = add_amount
				remaining -= add_amount
				if remaining <= 0:
					break
	
	inventory_changed.emit()
	return remaining


## Remove item from inventory by index
func remove_item_at(index: int, quantity: int = 1) -> bool:
	if index < 0 or index >= inventory_slots.size():
		return false
	
	var slot := inventory_slots[index]
	if slot.item == null:
		return false
	
	slot.quantity -= quantity
	if slot.quantity <= 0:
		slot.item = null
		slot.quantity = 0
	
	inventory_changed.emit()
	return true


## Remove item by ItemData reference
func remove_item(item: ItemData, quantity: int = 1) -> bool:
	if item == null:
		return false
	
	var remaining := quantity
	for i in range(inventory_slots.size()):
		var slot := inventory_slots[i]
		if slot.item != null and slot.item.id == item.id:
			var remove_amount := mini(slot.quantity, remaining)
			slot.quantity -= remove_amount
			remaining -= remove_amount
			if slot.quantity <= 0:
				slot.item = null
				slot.quantity = 0
			if remaining <= 0:
				break
	
	inventory_changed.emit()
	return remaining < quantity


## Get item at index
func get_item_at(index: int) -> Dictionary:
	if index < 0 or index >= inventory_slots.size():
		return {"item": null, "quantity": 0}
	return inventory_slots[index]


## Check if inventory has item
func has_item(item_id: String, quantity: int = 1) -> bool:
	var total := 0
	for slot in inventory_slots:
		if slot.item != null and slot.item.id == item_id:
			total += slot.quantity
	return total >= quantity


## Get total quantity of item
func get_item_count(item_id: String) -> int:
	var total := 0
	for slot in inventory_slots:
		if slot.item != null and slot.item.id == item_id:
			total += slot.quantity
	return total


## Sort inventory: group by item type, then rarity (desc), then name
func sort_inventory() -> void:
	# Collect all non-empty slots
	var items: Array[Dictionary] = []
	for slot in inventory_slots:
		if slot.item != null:
			items.append({"item": slot.item, "quantity": slot.quantity})

	# Sort: item_type ascending, rarity descending, name ascending
	items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_item: ItemData = a.item
		var b_item: ItemData = b.item
		# Equipment first, then consumables, then materials, then segments, then augments
		var type_order_a := _get_sort_type_order(a_item.item_type)
		var type_order_b := _get_sort_type_order(b_item.item_type)
		if type_order_a != type_order_b:
			return type_order_a < type_order_b
		# Higher rarity first within same type
		if a_item.rarity != b_item.rarity:
			return a_item.rarity > b_item.rarity
		# Alphabetical by name
		return a_item.name.naturalnocasecmp_to(b_item.name) < 0
	)

	# Rebuild inventory: sorted items first, then empty slots
	for i in range(INVENTORY_SIZE):
		if i < items.size():
			inventory_slots[i] = items[i]
		else:
			inventory_slots[i] = {"item": null, "quantity": 0}

	inventory_changed.emit()


## Sort order for item types (lower = earlier)
func _get_sort_type_order(item_type: ItemData.ItemType) -> int:
	match item_type:
		ItemData.ItemType.WEAPON:     return 0
		ItemData.ItemType.ARMOR:      return 1
		ItemData.ItemType.HELMET:     return 2
		ItemData.ItemType.SHIELD:     return 3
		ItemData.ItemType.BOOTS:      return 4
		ItemData.ItemType.ACCESSORY:  return 5
		ItemData.ItemType.CONSUMABLE: return 6
		ItemData.ItemType.MATERIAL:   return 7
		ItemData.ItemType.QUEST:      return 8
		ItemData.ItemType.SEGMENT:    return 9
		ItemData.ItemType.AUGMENT:    return 10
		_: return 99


## Swap two inventory slots
func swap_slots(index_a: int, index_b: int) -> void:
	if index_a < 0 or index_a >= inventory_slots.size():
		return
	if index_b < 0 or index_b >= inventory_slots.size():
		return
	
	var temp := inventory_slots[index_a]
	inventory_slots[index_a] = inventory_slots[index_b]
	inventory_slots[index_b] = temp
	inventory_changed.emit()


## Equip item from inventory slot
func equip_item(inventory_index: int) -> bool:
	var slot := get_item_at(inventory_index)
	if slot.item == null or not slot.item.is_equippable():
		return false
	
	var item: ItemData = slot.item
	var equipped_item: ItemData = null
	var slot_type := ""
	
	# Determine which slot to equip to
	match item.item_type:
		ItemData.ItemType.HELMET:
			equipped_item = equipped_helmet
			equipped_helmet = item
			slot_type = "helmet"
		ItemData.ItemType.ARMOR:
			equipped_item = equipped_armor
			equipped_armor = item
			slot_type = "armor"
		ItemData.ItemType.WEAPON:
			equipped_item = equipped_weapon
			equipped_weapon = item
			slot_type = "weapon"
		ItemData.ItemType.SHIELD:
			equipped_item = equipped_shield
			equipped_shield = item
			slot_type = "shield"
		ItemData.ItemType.BOOTS:
			equipped_item = equipped_boots
			equipped_boots = item
			slot_type = "boots"
		ItemData.ItemType.ACCESSORY:
			# Try first slot, then second
			if equipped_accessory_1 == null:
				equipped_accessory_1 = item
				slot_type = "accessory_1"
			elif equipped_accessory_2 == null:
				equipped_accessory_2 = item
				slot_type = "accessory_2"
			else:
				# Swap with first accessory
				equipped_item = equipped_accessory_1
				equipped_accessory_1 = item
				slot_type = "accessory_1"
		_:
			return false
	
	# Remove item from inventory
	inventory_slots[inventory_index].item = null
	inventory_slots[inventory_index].quantity = 0
	
	# Add previously equipped item back to inventory
	if equipped_item != null:
		add_item(equipped_item, 1)
	
	equipment_changed.emit(slot_type)
	inventory_changed.emit()
	return true


## Unequip item from equipment slot
## If target_index is provided, place item directly in that slot
func unequip_item(slot_type: String, target_index: int = -1) -> bool:
	var item: ItemData = null
	
	match slot_type:
		"helmet":
			item = equipped_helmet
			equipped_helmet = null
		"armor":
			item = equipped_armor
			equipped_armor = null
		"weapon":
			item = equipped_weapon
			equipped_weapon = null
		"shield":
			item = equipped_shield
			equipped_shield = null
		"boots":
			item = equipped_boots
			equipped_boots = null
		"accessory_1":
			item = equipped_accessory_1
			equipped_accessory_1 = null
		"accessory_2":
			item = equipped_accessory_2
			equipped_accessory_2 = null
		_:
			return false
	
	if item != null:
		var success := false
		
		# Try to place in specific slot if provided
		if target_index >= 0 and target_index < inventory_slots.size():
			var target_slot := inventory_slots[target_index]
			if target_slot.item == null:
				target_slot.item = item
				target_slot.quantity = 1
				success = true
			elif target_slot.item.is_equippable() and _item_fits_slot(target_slot.item, slot_type):
				# Swap with target slot item
				var swap_item: ItemData = target_slot.item
				target_slot.item = item
				target_slot.quantity = 1
				_set_equipped(slot_type, swap_item)
				success = true
		
		# Fall back to adding to any slot
		if not success:
			var remaining := add_item(item, 1)
			success = remaining == 0
		
		if not success:
			# Inventory full, re-equip item
			_set_equipped(slot_type, item)
			return false
	
	equipment_changed.emit(slot_type)
	inventory_changed.emit()
	return true


## Helper to set equipped item by slot type
func _set_equipped(slot_type: String, item: ItemData) -> void:
	match slot_type:
		"helmet": equipped_helmet = item
		"armor": equipped_armor = item
		"weapon": equipped_weapon = item
		"shield": equipped_shield = item
		"boots": equipped_boots = item
		"accessory_1": equipped_accessory_1 = item
		"accessory_2": equipped_accessory_2 = item


## Check if item fits in slot type
func _item_fits_slot(item: ItemData, slot_type: String) -> bool:
	if item == null:
		return true
	match slot_type:
		"helmet": return item.item_type == ItemData.ItemType.HELMET
		"armor": return item.item_type == ItemData.ItemType.ARMOR
		"weapon": return item.item_type == ItemData.ItemType.WEAPON
		"shield": return item.item_type == ItemData.ItemType.SHIELD
		"boots": return item.item_type == ItemData.ItemType.BOOTS
		"accessory_1", "accessory_2": return item.item_type == ItemData.ItemType.ACCESSORY
		_: return false


## Swap equipment between two equipment slots
func swap_equipment(from_slot: String, to_slot: String) -> bool:
	var from_item := get_equipped(from_slot)
	var to_item := get_equipped(to_slot)
	
	# Verify both items fit in swapped slots
	if not _item_fits_slot(from_item, to_slot):
		return false
	if not _item_fits_slot(to_item, from_slot):
		return false
	
	_set_equipped(from_slot, to_item)
	_set_equipped(to_slot, from_item)
	
	equipment_changed.emit(from_slot)
	equipment_changed.emit(to_slot)
	return true


## Get equipped item by slot type
func get_equipped(slot_type: String) -> ItemData:
	match slot_type:
		"helmet": return equipped_helmet
		"armor": return equipped_armor
		"weapon": return equipped_weapon
		"shield": return equipped_shield
		"boots": return equipped_boots
		"accessory_1": return equipped_accessory_1
		"accessory_2": return equipped_accessory_2
		_: return null


## Calculate total equipment bonuses (includes augment stat contributions)
func get_total_attack_bonus() -> int:
	var total := 0
	for item: ItemData in [equipped_weapon, equipped_helmet, equipped_armor, equipped_boots,
				 equipped_shield, equipped_accessory_1, equipped_accessory_2]:
		if item != null:
			total += item.attack_bonus
			total += _get_augment_stat_sum(item, "attack_bonus")
	return total


func get_total_defense_bonus() -> int:
	var total := 0
	for item: ItemData in [equipped_weapon, equipped_helmet, equipped_armor, equipped_boots,
				 equipped_shield, equipped_accessory_1, equipped_accessory_2]:
		if item != null:
			total += item.defense_bonus
			total += _get_augment_stat_sum(item, "defense_bonus")
	return total


func get_total_health_bonus() -> int:
	var total := 0
	for item: ItemData in [equipped_weapon, equipped_helmet, equipped_armor, equipped_boots,
				 equipped_shield, equipped_accessory_1, equipped_accessory_2]:
		if item != null:
			total += item.health_bonus
			total += _get_augment_stat_sum(item, "health_bonus")
	return total


func get_total_speed_bonus() -> float:
	var total := 0.0
	for item: ItemData in [equipped_weapon, equipped_helmet, equipped_armor, equipped_boots,
				 equipped_shield, equipped_accessory_1, equipped_accessory_2]:
		if item != null:
			total += item.speed_bonus
			total += _get_augment_stat_sum_float(item, "speed_bonus")
	return total


## Helper: sum an int stat field from all augments applied to an equipment item
func _get_augment_stat_sum(equipment: ItemData, stat_field: String) -> int:
	var total := 0
	for augment_id: String in equipment.applied_augments:
		var augment: ItemData = ItemDatabase.get_item(augment_id)
		if augment != null:
			total += augment.get(stat_field)
	return total


## Helper: sum a float stat field from all augments applied to an equipment item
func _get_augment_stat_sum_float(equipment: ItemData, stat_field: String) -> float:
	var total := 0.0
	for augment_id: String in equipment.applied_augments:
		var augment: ItemData = ItemDatabase.get_item(augment_id)
		if augment != null:
			total += augment.get(stat_field)
	return total


## Use consumable item at index
func use_item(index: int) -> Dictionary:
	var slot := get_item_at(index)
	if slot.item == null or not slot.item.is_consumable():
		return {"success": false}

	var item: ItemData = slot.item

	# Handle timed buff consumables (crafted AUGMENT with TIMED_BUFF type)
	if item.is_timed_buff():
		var buff_result := {
			"success": true,
			"is_timed_buff": true,
			"buff_item": item,  # Pass full ItemData so BuffComponent can read it
			"heal_amount": 0,
			"stamina_restore": 0.0,
			"effect_duration": item.buff_duration
		}
		remove_item_at(index, 1)
		return buff_result

	# Handle regular consumables (existing logic)
	var result := {
		"success": true,
		"is_timed_buff": false,
		"heal_amount": item.heal_amount,
		"stamina_restore": item.stamina_restore,
		"effect_duration": item.effect_duration
	}

	remove_item_at(index, 1)
	return result


# =============================================================================
# AUGMENT MANAGEMENT
# =============================================================================

## Apply an augment item to an equipped item's augment slot
## augment_inventory_index = index of the AUGMENT item in inventory_slots
## equip_slot = "weapon", "armor", "helmet", "boots", "shield", "accessory_1", "accessory_2"
## Returns true on success, false if slot full or invalid
func apply_augment(equip_slot: String, augment_inventory_index: int) -> bool:
	var augment_slot := get_item_at(augment_inventory_index)
	if augment_slot.item == null or not augment_slot.item.is_augment():
		return false

	var equipment: ItemData = get_equipped(equip_slot)
	if equipment == null:
		return false

	# Check if equipment has open augment slots
	if not equipment.is_augmentable():
		return false

	# Duplicate equipment on first augment to create unique instance
	# (so we don't mutate the ItemDatabase template)
	if equipment.applied_augments.size() == 0:
		var unique_equipment := equipment.duplicate() as ItemData
		unique_equipment.applied_augments = []
		_set_equipped(equip_slot, unique_equipment)
		equipment = unique_equipment

	# Add augment ID to equipment's applied_augments
	equipment.applied_augments.append(augment_slot.item.id)

	# Remove augment item from inventory
	remove_item_at(augment_inventory_index, 1)

	augments_changed.emit(equip_slot)
	equipment_changed.emit(equip_slot)
	inventory_changed.emit()
	return true


## Remove an augment from an equipped item and return it to inventory
## augment_index = index within equipment.applied_augments array
## Returns true on success (augment returned to inventory)
func remove_augment(equip_slot: String, augment_index: int) -> bool:
	var equipment: ItemData = get_equipped(equip_slot)
	if equipment == null:
		return false
	if augment_index < 0 or augment_index >= equipment.applied_augments.size():
		return false

	var augment_id: String = equipment.applied_augments[augment_index]
	var augment_item: ItemData = ItemDatabase.get_item(augment_id)
	if augment_item == null:
		return false

	# Add augment back to inventory (check for space first)
	var remaining := add_item(augment_item, 1)
	if remaining > 0:
		return false  # Inventory full

	# Remove from equipment's augment list
	equipment.applied_augments.remove_at(augment_index)

	augments_changed.emit(equip_slot)
	equipment_changed.emit(equip_slot)
	return true


# =============================================================================
# AUGMENT & PASSIVE EFFECT QUERIES
# =============================================================================

## Collect all passive effects from augments on all equipped items
## Returns Array[Dictionary] of {effect: PassiveEffect, value: float}
func get_all_augment_passive_effects() -> Array[Dictionary]:
	var effects: Array[Dictionary] = []
	for item: ItemData in [equipped_weapon, equipped_helmet, equipped_armor, equipped_boots,
				 equipped_shield, equipped_accessory_1, equipped_accessory_2]:
		if item == null:
			continue
		for augment_id: String in item.applied_augments:
			var augment: ItemData = ItemDatabase.get_item(augment_id)
			if augment != null and augment.passive_effect != ItemData.PassiveEffect.NONE:
				effects.append({"effect": augment.passive_effect, "value": augment.passive_value})
	return effects


## Collect all active skill IDs from augments on all equipped items
## Returns Array[Dictionary] of {skill_id: String, source_equip_slot: String}
func get_all_augment_active_skills() -> Array[Dictionary]:
	var skills: Array[Dictionary] = []
	var slot_names := ["weapon", "helmet", "armor", "boots", "shield", "accessory_1", "accessory_2"]
	var slot_items: Array[ItemData] = [equipped_weapon, equipped_helmet, equipped_armor, equipped_boots,
					   equipped_shield, equipped_accessory_1, equipped_accessory_2]
	for i: int in range(slot_items.size()):
		var item: ItemData = slot_items[i]
		if item == null:
			continue
		for augment_id: String in item.applied_augments:
			var augment: ItemData = ItemDatabase.get_item(augment_id)
			if augment != null and augment.augment_type == ItemData.AugmentType.ACTIVE_SKILL:
				skills.append({"skill_id": augment.active_skill_id, "source_equip_slot": slot_names[i]})
	return skills
