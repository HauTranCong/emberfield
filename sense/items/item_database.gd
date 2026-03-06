extends Node

## Sample items database - preloaded item definitions
## Use this to get item data by ID

var items: Dictionary = {}

## Path to the item icons sprite sheet
const ICON_SHEET_PATH := "res://assets/items/item_icons.png"


func _ready() -> void:
	_init_icon_atlas()
	_create_sample_items()


## Initialize the icon atlas with sprite sheet
func _init_icon_atlas() -> void:
	var sheet := load(ICON_SHEET_PATH) as Texture2D
	if sheet:
		# Adjust icon_size based on your sprite sheet (16x16, 24x24, 32x32, etc.)
		# This sprite sheet uses 32x32 icons with 16 columns
		ItemIconAtlas.init(sheet, Vector2i(32, 32), 16)
		print("[ItemDatabase] Icon atlas initialized: %dx%d icons (32x32 each)" % [ItemIconAtlas.columns, ItemIconAtlas.rows])
		print("[ItemDatabase] Sprite sheet: %dx%d pixels" % [sheet.get_width(), sheet.get_height()])
	else:
		push_warning("[ItemDatabase] Could not load icon sheet: %s" % ICON_SHEET_PATH)


func _create_sample_items() -> void:
	_create_weapons()
	_create_armor()
	_create_helmets()
	_create_shields()
	_create_boots()
	_create_accessories()
	_create_consumables()
	_create_materials()


func _create_weapons() -> void:
	# Swords
	items["wooden_sword"] = ItemHelper.create_item({
		"id": "wooden_sword", "name": "Wooden Sword",
		"description": "A basic wooden sword. Not very effective but better than nothing.",
		"type": ItemData.ItemType.WEAPON, "price": 50, "attack": 5,
		"icon_name": "wooden_sword"
	})
	items["iron_sword"] = ItemHelper.create_item({
		"id": "iron_sword", "name": "Iron Sword",
		"description": "A basic iron sword. Reliable but nothing special.",
		"type": ItemData.ItemType.WEAPON, "price": 100, "attack": 15,
		"icon_name": "iron_sword"
	})
	items["platinum_sword"] = ItemHelper.create_item({
		"id": "platinum_sword", "name": "Platinum Sword",
		"description": "A finely crafted platinum sword. Light and deadly.",
		"type": ItemData.ItemType.WEAPON, "price": 300, "attack": 25, "speed": 5.0,
		"icon_name": "platinum_sword"
	})
	# Blades
	items["pirate_blade"] = ItemHelper.create_item({
		"id": "pirate_blade", "name": "Pirate Blade",
		"description": "A curved blade favored by pirates. Fast but less powerful.",
		"type": ItemData.ItemType.WEAPON, "price": 120, "attack": 12, "speed": 10.0,
		"icon_name": "pirate_blade"
	})
	# Axes
	items["battle_axe"] = ItemHelper.create_item({
		"id": "battle_axe", "name": "Battle Axe",
		"description": "A heavy axe that deals massive damage.",
		"type": ItemData.ItemType.WEAPON, "price": 250, "attack": 30, "speed": -5.0,
		"icon_name": "battle_axe"
	})
	# Daggers
	items["dagger"] = ItemHelper.create_item({
		"id": "dagger", "name": "Dagger",
		"description": "A quick, light blade for swift attacks.",
		"type": ItemData.ItemType.WEAPON, "price": 90, "attack": 10, "speed": 15.0,
		"icon_name": "dagger"
	})
	# Maces
	items["thron_mace"] = ItemHelper.create_item({
		"id": "thron_mace", "name": "Thron Mace",
		"description": "A heavy mace that can crush armor.",
		"type": ItemData.ItemType.WEAPON, "price": 220, "attack": 28, "speed": -10.0,
		"icon_name": "thron_mace"
	})
	# Bows
	items["hunting_bow"] = ItemHelper.create_item({
		"id": "hunting_bow", "name": "Hunting Bow",
		"description": "A reliable bow for ranged combat.",
		"type": ItemData.ItemType.WEAPON, "price": 180, "attack": 20,
		"icon_name": "hunting_bow"
	})


func _create_armor() -> void:
	items["leather_armor"] = ItemHelper.create_item({
		"id": "leather_armor", "name": "Leather Armor",
		"description": "Light leather armor that provides basic protection.",
		"type": ItemData.ItemType.ARMOR, "price": 80, "defense": 10,
		"icon_name": "leather_armor"
	})
	items["iron_armor"] = ItemHelper.create_item({
		"id": "iron_armor", "name": "Iron Armor",
		"description": "Sturdy iron armor. Heavy but protective.",
		"type": ItemData.ItemType.ARMOR, "price": 400, "defense": 25, "speed": -10.0,
		"icon_name": "iron_armor"
	})
	items["plate_armor"] = ItemHelper.create_item({
		"id": "plate_armor", "name": "Plate Armor",
		"description": "Heavy full plate armor. Maximum protection.",
		"type": ItemData.ItemType.ARMOR, "price": 600, "defense": 35, "speed": -15.0,
		"icon_name": "plate_armor"
	})


func _create_helmets() -> void:
	items["iron_helmet"] = ItemHelper.create_item({
		"id": "iron_helmet", "name": "Iron Helmet",
		"description": "A sturdy iron helmet to protect your head.",
		"type": ItemData.ItemType.HELMET, "price": 60, "defense": 8,
		"icon_name": "iron_helmet"
	})
	items["leather_cap"] = ItemHelper.create_item({
		"id": "leather_cap", "name": "Leather Cap",
		"description": "A simple leather hood for basic protection.",
		"type": ItemData.ItemType.HELMET, "price": 30, "defense": 4,
		"icon_name": "leather_cap"
	})
	items["steel_helmet"] = ItemHelper.create_item({
		"id": "steel_helmet", "name": "Steel Helmet",
		"description": "A well-crafted steel helmet for superior protection.",
		"type": ItemData.ItemType.HELMET, "price": 120, "defense": 15,
		"icon_name": "steel_helmet"
	})


func _create_shields() -> void:
	items["wooden_shield"] = ItemHelper.create_item({
		"id": "wooden_shield", "name": "Wooden Shield",
		"description": "A simple wooden shield. Better than nothing.",
		"type": ItemData.ItemType.SHIELD, "price": 50, "defense": 12,
		"icon_name": "wooden_shield"
	})
	items["iron_shield"] = ItemHelper.create_item({
		"id": "iron_shield", "name": "Iron Shield",
		"description": "A sturdy iron shield for better protection.",
		"type": ItemData.ItemType.SHIELD, "price": 150, "defense": 20,
		"icon_name": "iron_shield"
	})
	items["kite_shield"] = ItemHelper.create_item({
		"id": "kite_shield", "name": "Kite Shield",
		"description": "Large shield providing excellent defensive coverage.",
		"type": ItemData.ItemType.SHIELD, "price": 300, "defense": 28, "speed": -5.0,
		"icon_name": "kite_shield"
	})


func _create_boots() -> void:
	items["leather_boots"] = ItemHelper.create_item({
		"id": "leather_boots", "name": "Leather Boots",
		"description": "Comfortable leather boots for long journeys.",
		"type": ItemData.ItemType.BOOTS, "price": 40, "defense": 5, "speed": 10.0,
		"icon_name": "leather_boots"
	})
	items["swift_boots"] = ItemHelper.create_item({
		"id": "swift_boots", "name": "Swift Boots",
		"description": "Light boots enchanted for speed.",
		"type": ItemData.ItemType.BOOTS, "price": 150, "defense": 3, "speed": 20.0,
		"icon_name": "swift_boots"
	})


func _create_accessories() -> void:
	items["gold_ring"] = ItemHelper.create_item({
		"id": "gold_ring", "name": "Gold Ring",
		"description": "An elegant golden ring that boosts vitality.",
		"type": ItemData.ItemType.ACCESSORY, "price": 350, "health": 20, "defense": 8,
		"icon_row": 8, "icon_col": 4
	})
	items["diamond_ring"] = ItemHelper.create_item({
		"id": "diamond_ring", "name": "Diamond Ring",
		"description": "A sparkling diamond ring that enhances all stats.",
		"type": ItemData.ItemType.ACCESSORY, "price": 800, "attack": 10, "defense": 10, "health": 30,
		"icon_row": 8, "icon_col": 5
	})
	items["gold_necklace"] = ItemHelper.create_item({
		"id": "gold_necklace", "name": "Gold Necklace",
		"description": "A beautiful gold necklace that increases defense.",
		"type": ItemData.ItemType.ACCESSORY, "price": 500, "defense": 15,
		"icon_row": 8, "icon_col": 6
	})


func _create_consumables() -> void:
	items["health_potion"] = ItemHelper.create_item({
		"id": "health_potion", "name": "Health Potion",
		"description": "A red potion that restores health.",
		"type": ItemData.ItemType.CONSUMABLE, "stackable": true, "max_stack": 20,
		"price": 25, "sell_price": 10, "heal": 50,
		"icon_name": "potion_red"
	})
	items["large_health_potion"] = ItemHelper.create_item({
		"id": "large_health_potion", "name": "Large Health Potion",
		"description": "A large red potion that greatly restores health.",
		"type": ItemData.ItemType.CONSUMABLE, "stackable": true, "max_stack": 10,
		"price": 75, "sell_price": 30, "heal": 100,
		"icon_name": "potion_red"
	})
	items["stamina_potion"] = ItemHelper.create_item({
		"id": "stamina_potion", "name": "Stamina Potion",
		"description": "A blue potion that restores stamina.",
		"type": ItemData.ItemType.CONSUMABLE, "stackable": true, "max_stack": 20,
		"price": 20, "sell_price": 8, "stamina": 50.0,
		"icon_row": 9, "icon_col": 1
	})


func _create_materials() -> void:
	items["iron_ore"] = ItemHelper.create_item({
		"id": "iron_ore", "name": "Iron Ore",
		"description": "Raw iron ore. Can be smelted into iron ingots.",
		"stackable": true, "price": 10,
		"icon_name": "iron_ore"
	})
	items["gold_ore"] = ItemHelper.create_item({
		"id": "gold_ore", "name": "Gold Ore",
		"description": "Precious gold ore. Valuable but soft.",
		"stackable": true, "price": 50,
		"icon_name": "gold_ore"
	})

	items["monster_bone"] = ItemHelper.create_item({
		"id": "monster_bone", "name": "Monster Bone",
		"description": "A bone from a defeated monster. Used in crafting.",
		"stackable": true, "price": 15,
		"icon_name": "bone"
	})
	items["bone"] = ItemHelper.create_item({
		"id": "bone", "name": "Bone",
		"description": "A skeletal bone. Common drop from skeleton enemies.",
		"stackable": true, "price": 5,
		"icon_name": "bone"
	})
	items["gold_coin"] = ItemHelper.create_item({
		"id": "gold_coin", "name": "Gold Coin",
		"description": "A shiny gold coin.",
		"stackable": true, "max_stack": 9999,
		"price": 1, "sell_price": 1,
		"icon_name": "gold_coin"
	})


## Get item data by ID
func get_item(item_id: String) -> ItemData:
	if items.has(item_id):
		return items[item_id]
	return null


## Get a duplicate of item data (for instances)
func get_item_copy(item_id: String) -> ItemData:
	var item := get_item(item_id)
	if item != null:
		return item.duplicate()
	return null
