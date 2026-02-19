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


## Calculate total equipment bonuses
func get_total_attack_bonus() -> int:
	var total := 0
	for item in [equipped_weapon, equipped_helmet, equipped_armor, equipped_boots, 
				 equipped_shield, equipped_accessory_1, equipped_accessory_2]:
		if item != null:
			total += item.attack_bonus
	return total


func get_total_defense_bonus() -> int:
	var total := 0
	for item in [equipped_weapon, equipped_helmet, equipped_armor, equipped_boots, 
				 equipped_shield, equipped_accessory_1, equipped_accessory_2]:
		if item != null:
			total += item.defense_bonus
	return total


func get_total_health_bonus() -> int:
	var total := 0
	for item in [equipped_weapon, equipped_helmet, equipped_armor, equipped_boots, 
				 equipped_shield, equipped_accessory_1, equipped_accessory_2]:
		if item != null:
			total += item.health_bonus
	return total


func get_total_speed_bonus() -> float:
	var total := 0.0
	for item in [equipped_weapon, equipped_helmet, equipped_armor, equipped_boots, 
				 equipped_shield, equipped_accessory_1, equipped_accessory_2]:
		if item != null:
			total += item.speed_bonus
	return total


## Use consumable item at index
func use_item(index: int) -> Dictionary:
	var slot := get_item_at(index)
	if slot.item == null or not slot.item.is_consumable():
		return {"success": false}
	
	var item: ItemData = slot.item
	var result := {
		"success": true,
		"heal_amount": item.heal_amount,
		"stamina_restore": item.stamina_restore,
		"effect_duration": item.effect_duration
	}
	
	remove_item_at(index, 1)
	return result
