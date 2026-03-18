## ItemHelper - Utility functions to simplify item creation
## Use this to reduce code duplication when creating items

class_name ItemHelper

## Quick item creation with common defaults
static func create_item(data: Dictionary) -> ItemData:
	var item := ItemData.new()
	
	# Required fields
	item.id = data.get("id", "")
	item.name = data.get("name", "Unnamed Item")
	item.description = data.get("description", "")
	item.item_type = data.get("type", ItemData.ItemType.MATERIAL)
	
	# Common fields with defaults
	item.rarity = data.get("rarity", ItemData.ItemRarity.COMMON)
	item.stackable = data.get("stackable", false)
	item.max_stack = data.get("max_stack", 99)
	item.buy_price = data.get("price", 0)
	item.sell_price = data.get("sell_price", item.buy_price / 2)
	
	# Stats
	item.attack_bonus = data.get("attack", 0)
	item.defense_bonus = data.get("defense", 0)
	item.health_bonus = data.get("health", 0)
	item.speed_bonus = data.get("speed", 0.0)
	
	# Consumable effects
	item.heal_amount = data.get("heal", 0)
	item.stamina_restore = data.get("stamina", 0.0)
	item.effect_duration = data.get("duration", 0.0)
	
	# Augment properties
	item.augment_type = data.get("augment_type", ItemData.AugmentType.NONE)
	item.passive_effect = data.get("passive_effect", ItemData.PassiveEffect.NONE)
	item.passive_value = data.get("passive_value", 0.0)
	item.active_skill_id = data.get("active_skill_id", "")
	item.buff_duration = data.get("buff_duration", 0.0)
	
	# Icon - supports both atlas name and row/col
	item.use_atlas_icon = data.get("use_atlas", true)
	if data.has("icon_name"):
		item.atlas_icon_name = data["icon_name"]
	elif data.has("icon_row") and data.has("icon_col"):
		item.atlas_row = data["icon_row"]
		item.atlas_col = data["icon_col"]
	elif data.has("icon"):
		item.icon = data["icon"]
	
	return item


## Example usage in item_database.gd:
##
## func _create_sample_items() -> void:
##     # Weapons
##     items["iron_sword"] = ItemHelper.create_item({
##         "id": "iron_sword",
##         "name": "Iron Sword",
##         "description": "A basic iron sword.",
##         "type": ItemData.ItemType.WEAPON,
##         "price": 100,
##         "attack": 15,
##         "icon_name": "sword_iron"
##     })
##     
##     items["health_potion"] = ItemHelper.create_item({
##         "id": "health_potion",
##         "name": "Health Potion",
##         "description": "Restores 50 HP.",
##         "type": ItemData.ItemType.CONSUMABLE,
##         "stackable": true,
##         "max_stack": 20,
##         "price": 25,
##         "heal": 50,
##         "icon_name": "potion_red"
##     })
##
## This reduces 15+ lines per item to just 5-8 lines!


## Create weapon with common defaults
static func create_weapon(id: String, name: String, desc: String, price: int, attack: int, icon: String, speed: float = 0.0) -> ItemData:
	return create_item({
		"id": id,
		"name": name,
		"description": desc,
		"type": ItemData.ItemType.WEAPON,
		"price": price,
		"attack": attack,
		"speed": speed,
		"icon_name": icon
	})


## Create armor with common defaults
static func create_armor(id: String, name: String, desc: String, price: int, defense: int, icon: String, speed: float = 0.0) -> ItemData:
	return create_item({
		"id": id,
		"name": name,
		"description": desc,
		"type": ItemData.ItemType.ARMOR,
		"price": price,
		"defense": defense,
		"speed": speed,
		"icon_name": icon
	})


## Create consumable with common defaults
static func create_consumable(id: String, name: String, desc: String, price: int, heal: int, icon: String) -> ItemData:
	return create_item({
		"id": id,
		"name": name,
		"description": desc,
		"type": ItemData.ItemType.CONSUMABLE,
		"stackable": true,
		"max_stack": 20,
		"price": price,
		"heal": heal,
		"icon_name": icon
	})


## Example: Ultra-concise weapon creation
static func quick_weapon(id: String, name: String, price: int, attack: int, icon: String = "sword_iron") -> ItemData:
	return create_weapon(id, name, "A %s weapon." % name.to_lower(), price, attack, icon)
