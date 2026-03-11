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
	# === WEAPONS ===
	var iron_sword := ItemData.new()
	iron_sword.id = "iron_sword"
	iron_sword.name = "Iron Sword"
	iron_sword.description = "A basic iron sword. Reliable but nothing special."
	iron_sword.item_type = ItemData.ItemType.WEAPON
	iron_sword.rarity = ItemData.ItemRarity.COMMON
	iron_sword.stackable = false
	iron_sword.attack_bonus = 15
	iron_sword.buy_price = 100
	iron_sword.sell_price = 50
	# Use atlas icon
	iron_sword.use_atlas_icon = true
	iron_sword.atlas_icon_name = "sword_iron"
	items["iron_sword"] = iron_sword
	
	var steel_sword := ItemData.new()
	steel_sword.id = "steel_sword"
	steel_sword.name = "Steel Sword"
	steel_sword.description = "A well-crafted steel sword with a sharp edge."
	steel_sword.item_type = ItemData.ItemType.WEAPON
	steel_sword.rarity = ItemData.ItemRarity.COMMON
	steel_sword.stackable = false
	steel_sword.attack_bonus = 25
	steel_sword.buy_price = 300
	steel_sword.sell_price = 150
	steel_sword.use_atlas_icon = true
	steel_sword.atlas_icon_name = "sword_iron"
	items["steel_sword"] = steel_sword
	
	var fire_blade := ItemData.new()
	fire_blade.id = "fire_blade"
	fire_blade.name = "Flame Blade"
	fire_blade.description = "A magical blade imbued with fire essence. Burns with eternal flame."
	fire_blade.item_type = ItemData.ItemType.WEAPON
	fire_blade.rarity = ItemData.ItemRarity.COMMON
	fire_blade.stackable = false
	fire_blade.attack_bonus = 40
	fire_blade.buy_price = 1000
	fire_blade.sell_price = 500
	fire_blade.use_atlas_icon = true
	fire_blade.atlas_icon_name = "sword_iron"
	items["fire_blade"] = fire_blade
	
	# More weapons
	var battle_axe := ItemData.new()
	battle_axe.id = "battle_axe"
	battle_axe.name = "Battle Axe"
	battle_axe.description = "A heavy axe that deals massive damage."
	battle_axe.item_type = ItemData.ItemType.WEAPON
	battle_axe.rarity = ItemData.ItemRarity.COMMON
	battle_axe.stackable = false
	battle_axe.attack_bonus = 30
	battle_axe.speed_bonus = -5.0
	battle_axe.buy_price = 250
	battle_axe.sell_price = 125
	battle_axe.use_atlas_icon = true
	battle_axe.atlas_row = 3
	battle_axe.atlas_col = 2
	items["battle_axe"] = battle_axe
	
	var dagger := ItemData.new()
	dagger.id = "dagger"
	dagger.name = "Dagger"
	dagger.description = "A quick, light blade for swift attacks."
	dagger.item_type = ItemData.ItemType.WEAPON
	dagger.rarity = ItemData.ItemRarity.COMMON
	dagger.stackable = false
	dagger.attack_bonus = 10
	dagger.speed_bonus = 15.0
	dagger.buy_price = 90
	dagger.sell_price = 45
	dagger.use_atlas_icon = true
	dagger.atlas_row = 0
	dagger.atlas_col = 1
	items["dagger"] = dagger
	
	var war_hammer := ItemData.new()
	war_hammer.id = "war_hammer"
	war_hammer.name = "War Hammer"
	war_hammer.description = "A crushing weapon that breaks through armor."
	war_hammer.item_type = ItemData.ItemType.WEAPON
	war_hammer.rarity = ItemData.ItemRarity.COMMON
	war_hammer.stackable = false
	war_hammer.attack_bonus = 35
	war_hammer.speed_bonus = -10.0
	war_hammer.buy_price = 400
	war_hammer.sell_price = 200
	war_hammer.use_atlas_icon = true
	war_hammer.atlas_row = 3
	war_hammer.atlas_col = 1
	items["war_hammer"] = war_hammer
	
	var hunting_bow := ItemData.new()
	hunting_bow.id = "hunting_bow"
	hunting_bow.name = "Hunting Bow"
	hunting_bow.description = "A reliable bow for ranged combat."
	hunting_bow.item_type = ItemData.ItemType.WEAPON
	hunting_bow.rarity = ItemData.ItemRarity.COMMON
	hunting_bow.stackable = false
	hunting_bow.attack_bonus = 20
	hunting_bow.buy_price = 180
	hunting_bow.sell_price = 90
	hunting_bow.use_atlas_icon = true
	hunting_bow.atlas_row = 1
	hunting_bow.atlas_col = 8
	items["hunting_bow"] = hunting_bow
	
	# === ARMOR ===
	var leather_armor := ItemData.new()
	leather_armor.id = "leather_armor"
	leather_armor.name = "Leather Armor"
	leather_armor.description = "Light leather armor that provides basic protection."
	leather_armor.item_type = ItemData.ItemType.ARMOR
	leather_armor.rarity = ItemData.ItemRarity.COMMON
	leather_armor.stackable = false
	leather_armor.defense_bonus = 10
	leather_armor.buy_price = 80
	leather_armor.sell_price = 40
	leather_armor.use_atlas_icon = true
	leather_armor.atlas_icon_name = "leather_armor"
	items["leather_armor"] = leather_armor
	
	var iron_armor := ItemData.new()
	iron_armor.id = "iron_armor"
	iron_armor.name = "Iron Armor"
	iron_armor.description = "Sturdy iron armor. Heavy but protective."
	iron_armor.item_type = ItemData.ItemType.ARMOR
	iron_armor.rarity = ItemData.ItemRarity.COMMON
	iron_armor.stackable = false
	iron_armor.defense_bonus = 25
	iron_armor.speed_bonus = -10.0
	iron_armor.buy_price = 400
	iron_armor.sell_price = 200
	iron_armor.use_atlas_icon = true
	iron_armor.atlas_icon_name = "leather_armor"
	items["iron_armor"] = iron_armor
	
	var chainmail := ItemData.new()
	chainmail.id = "chainmail"
	chainmail.name = "Chainmail Armor"
	chainmail.description = "Flexible armor made of interlocking rings."
	chainmail.item_type = ItemData.ItemType.ARMOR
	chainmail.rarity = ItemData.ItemRarity.COMMON
	chainmail.stackable = false
	chainmail.defense_bonus = 18
	chainmail.speed_bonus = -5.0
	chainmail.buy_price = 250
	chainmail.sell_price = 125
	chainmail.use_atlas_icon = true
	chainmail.atlas_row = 7
	chainmail.atlas_col = 3
	items["chainmail"] = chainmail
	
	var plate_armor := ItemData.new()
	plate_armor.id = "plate_armor"
	plate_armor.name = "Plate Armor"
	plate_armor.description = "Heavy full plate armor. Maximum protection."
	plate_armor.item_type = ItemData.ItemType.ARMOR
	plate_armor.rarity = ItemData.ItemRarity.COMMON
	plate_armor.stackable = false
	plate_armor.defense_bonus = 35
	plate_armor.speed_bonus = -15.0
	plate_armor.buy_price = 600
	plate_armor.sell_price = 300
	plate_armor.use_atlas_icon = true
	plate_armor.atlas_row = 7
	plate_armor.atlas_col = 4
	items["plate_armor"] = plate_armor
	
	# === HELMET ===
	var iron_helmet := ItemData.new()
	iron_helmet.id = "iron_helmet"
	iron_helmet.name = "Iron Helmet"
	iron_helmet.description = "A sturdy iron helmet to protect your head."
	iron_helmet.item_type = ItemData.ItemType.HELMET
	iron_helmet.rarity = ItemData.ItemRarity.COMMON
	iron_helmet.stackable = false
	iron_helmet.defense_bonus = 8
	iron_helmet.buy_price = 60
	iron_helmet.sell_price = 30
	iron_helmet.use_atlas_icon = true
	iron_helmet.atlas_icon_name = "helmet_horned"
	items["iron_helmet"] = iron_helmet
	
	var leather_cap := ItemData.new()
	leather_cap.id = "leather_cap"
	leather_cap.name = "Leather Cap"
	leather_cap.description = "A simple leather hood for basic protection."
	leather_cap.item_type = ItemData.ItemType.HELMET
	leather_cap.rarity = ItemData.ItemRarity.COMMON
	leather_cap.stackable = false
	leather_cap.defense_bonus = 4
	leather_cap.buy_price = 30
	leather_cap.sell_price = 15
	leather_cap.use_atlas_icon = true
	leather_cap.atlas_row = 6
	leather_cap.atlas_col = 0
	items["leather_cap"] = leather_cap
	
	var steel_helmet := ItemData.new()
	steel_helmet.id = "steel_helmet"
	steel_helmet.name = "Steel Helmet"
	steel_helmet.description = "A well-crafted steel helmet for superior protection."
	steel_helmet.item_type = ItemData.ItemType.HELMET
	steel_helmet.rarity = ItemData.ItemRarity.COMMON
	steel_helmet.stackable = false
	steel_helmet.defense_bonus = 15
	steel_helmet.buy_price = 120
	steel_helmet.sell_price = 60
	steel_helmet.use_atlas_icon = true
	steel_helmet.atlas_row = 6
	steel_helmet.atlas_col = 1
	items["steel_helmet"] = steel_helmet
	
	# === SHIELD ===
	var wooden_shield := ItemData.new()
	wooden_shield.id = "wooden_shield"
	wooden_shield.name = "Wooden Shield"
	wooden_shield.description = "A simple wooden shield. Better than nothing."
	wooden_shield.item_type = ItemData.ItemType.SHIELD
	wooden_shield.rarity = ItemData.ItemRarity.COMMON
	wooden_shield.stackable = false
	wooden_shield.defense_bonus = 12
	wooden_shield.buy_price = 50
	wooden_shield.sell_price = 25
	wooden_shield.use_atlas_icon = true
	wooden_shield.atlas_row = 18
	wooden_shield.atlas_col = 0
	items["wooden_shield"] = wooden_shield
	
	var iron_shield := ItemData.new()
	iron_shield.id = "iron_shield"
	iron_shield.name = "Iron Shield"
	iron_shield.description = "A sturdy iron shield for better protection."
	iron_shield.item_type = ItemData.ItemType.SHIELD
	iron_shield.rarity = ItemData.ItemRarity.COMMON
	iron_shield.stackable = false
	iron_shield.defense_bonus = 20
	iron_shield.buy_price = 150
	iron_shield.sell_price = 75
	iron_shield.use_atlas_icon = true
	iron_shield.atlas_row = 1
	iron_shield.atlas_col = 1
	items["iron_shield"] = iron_shield
	
	var kite_shield := ItemData.new()
	kite_shield.id = "kite_shield"
	kite_shield.name = "Kite Shield"
	kite_shield.description = "Large shield providing excellent defensive coverage."
	kite_shield.item_type = ItemData.ItemType.SHIELD
	kite_shield.rarity = ItemData.ItemRarity.COMMON
	kite_shield.stackable = false
	kite_shield.defense_bonus = 28
	kite_shield.speed_bonus = -5.0
	kite_shield.buy_price = 300
	kite_shield.sell_price = 150
	kite_shield.use_atlas_icon = true
	kite_shield.atlas_row = 1
	kite_shield.atlas_col = 2
	items["kite_shield"] = kite_shield
	
	# === BOOTS ===
	var leather_boots := ItemData.new()
	leather_boots.id = "leather_boots"
	leather_boots.name = "Leather Boots"
	leather_boots.description = "Comfortable leather boots for long journeys."
	leather_boots.item_type = ItemData.ItemType.BOOTS
	leather_boots.rarity = ItemData.ItemRarity.COMMON
	leather_boots.stackable = false
	leather_boots.defense_bonus = 5
	leather_boots.speed_bonus = 10.0
	leather_boots.buy_price = 40
	leather_boots.sell_price = 20
	leather_boots.use_atlas_icon = true
	leather_boots.atlas_icon_name = "boot_green"
	items["leather_boots"] = leather_boots
	
	var iron_boots := ItemData.new()
	iron_boots.id = "iron_boots"
	iron_boots.name = "Iron Boots"
	iron_boots.description = "Heavy iron boots that provide good protection."
	iron_boots.item_type = ItemData.ItemType.BOOTS
	iron_boots.rarity = ItemData.ItemRarity.COMMON
	iron_boots.stackable = false
	iron_boots.defense_bonus = 10
	iron_boots.speed_bonus = -5.0
	iron_boots.buy_price = 80
	iron_boots.sell_price = 40
	iron_boots.use_atlas_icon = true
	iron_boots.atlas_row = 7
	iron_boots.atlas_col = 1
	items["iron_boots"] = iron_boots
	
	var swift_boots := ItemData.new()
	swift_boots.id = "swift_boots"
	swift_boots.name = "Swift Boots"
	swift_boots.description = "Light boots enchanted for speed."
	swift_boots.item_type = ItemData.ItemType.BOOTS
	swift_boots.rarity = ItemData.ItemRarity.COMMON
	swift_boots.stackable = false
	swift_boots.defense_bonus = 3
	swift_boots.speed_bonus = 20.0
	swift_boots.buy_price = 150
	swift_boots.sell_price = 75
	swift_boots.use_atlas_icon = true
	swift_boots.atlas_row = 7
	swift_boots.atlas_col = 2
	items["swift_boots"] = swift_boots
	
	# === ACCESSORIES ===
	var silver_ring := ItemData.new()
	silver_ring.id = "silver_ring"
	silver_ring.name = "Silver Ring"
	silver_ring.description = "A simple silver ring with minor enchantments."
	silver_ring.item_type = ItemData.ItemType.ACCESSORY
	silver_ring.rarity = ItemData.ItemRarity.COMMON
	silver_ring.stackable = false
	silver_ring.attack_bonus = 5
	silver_ring.defense_bonus = 5
	silver_ring.buy_price = 200
	silver_ring.sell_price = 100
	silver_ring.use_atlas_icon = true
	silver_ring.atlas_row = 8
	silver_ring.atlas_col = 2
	items["silver_ring"] = silver_ring
	
	var gold_ring := ItemData.new()
	gold_ring.id = "gold_ring"
	gold_ring.name = "Gold Ring"
	gold_ring.description = "An elegant golden ring that boosts vitality."
	gold_ring.item_type = ItemData.ItemType.ACCESSORY
	gold_ring.rarity = ItemData.ItemRarity.COMMON
	gold_ring.stackable = false
	gold_ring.health_bonus = 20
	gold_ring.defense_bonus = 8
	gold_ring.buy_price = 350
	gold_ring.sell_price = 175
	gold_ring.use_atlas_icon = true
	gold_ring.atlas_row = 8
	gold_ring.atlas_col = 4
	items["gold_ring"] = gold_ring
	
	var strength_amulet := ItemData.new()
	strength_amulet.id = "strength_amulet"
	strength_amulet.name = "Strength Amulet"
	strength_amulet.description = "An amulet that enhances physical power."
	strength_amulet.item_type = ItemData.ItemType.ACCESSORY
	strength_amulet.rarity = ItemData.ItemRarity.COMMON
	strength_amulet.stackable = false
	strength_amulet.attack_bonus = 12
	strength_amulet.buy_price = 280
	strength_amulet.sell_price = 140
	strength_amulet.use_atlas_icon = true
	strength_amulet.atlas_row = 8
	strength_amulet.atlas_col = 6
	items["strength_amulet"] = strength_amulet
	
	# === CONSUMABLES ===
	var health_potion := ItemData.new()
	health_potion.id = "health_potion"
	health_potion.name = "Health Potion"
	health_potion.description = "A red potion that restores health."
	health_potion.item_type = ItemData.ItemType.CONSUMABLE
	health_potion.rarity = ItemData.ItemRarity.COMMON
	health_potion.stackable = true
	health_potion.max_stack = 20
	health_potion.heal_amount = 50
	health_potion.buy_price = 25
	health_potion.sell_price = 10
	health_potion.use_atlas_icon = true
	health_potion.atlas_icon_name = "potion_red"
	items["health_potion"] = health_potion
	
	var large_health_potion := ItemData.new()
	large_health_potion.id = "large_health_potion"
	large_health_potion.name = "Large Health Potion"
	large_health_potion.description = "A large red potion that greatly restores health."
	large_health_potion.item_type = ItemData.ItemType.CONSUMABLE
	large_health_potion.rarity = ItemData.ItemRarity.COMMON
	large_health_potion.stackable = true
	large_health_potion.max_stack = 10
	large_health_potion.heal_amount = 100
	large_health_potion.buy_price = 75
	large_health_potion.sell_price = 30
	large_health_potion.use_atlas_icon = true
	large_health_potion.atlas_icon_name = "potion_red"
	items["large_health_potion"] = large_health_potion
	
	var stamina_potion := ItemData.new()
	stamina_potion.id = "stamina_potion"
	stamina_potion.name = "Stamina Potion"
	stamina_potion.description = "A blue potion that restores stamina."
	stamina_potion.item_type = ItemData.ItemType.CONSUMABLE
	stamina_potion.rarity = ItemData.ItemRarity.COMMON
	stamina_potion.stackable = true
	stamina_potion.max_stack = 20
	stamina_potion.stamina_restore = 50.0
	stamina_potion.buy_price = 20
	stamina_potion.sell_price = 8
	stamina_potion.use_atlas_icon = true
	stamina_potion.atlas_row = 9  # Potion row - blue potion
	stamina_potion.atlas_col = 1
	items["stamina_potion"] = stamina_potion
	
	# === MATERIALS ===
	var iron_ore := ItemData.new()
	iron_ore.id = "iron_ore"
	iron_ore.name = "Iron Ore"
	iron_ore.description = "Raw iron ore. Can be smelted into iron ingots."
	iron_ore.item_type = ItemData.ItemType.MATERIAL
	iron_ore.rarity = ItemData.ItemRarity.COMMON
	iron_ore.stackable = true
	iron_ore.max_stack = 99
	iron_ore.buy_price = 10
	iron_ore.sell_price = 5
	iron_ore.use_atlas_icon = true
	iron_ore.atlas_icon_name = "iron_ore"
	items["iron_ore"] = iron_ore
	
	var gold_ore := ItemData.new()
	gold_ore.id = "gold_ore"
	gold_ore.name = "Gold Ore"
	gold_ore.description = "Precious gold ore. Valuable but soft."
	gold_ore.item_type = ItemData.ItemType.MATERIAL
	gold_ore.rarity = ItemData.ItemRarity.COMMON
	gold_ore.stackable = true
	gold_ore.max_stack = 99
	gold_ore.buy_price = 50
	gold_ore.sell_price = 25
	gold_ore.use_atlas_icon = true
	gold_ore.atlas_icon_name = "iron_ore"
	items["gold_ore"] = gold_ore
	
	var monster_bone := ItemData.new()
	monster_bone.id = "monster_bone"
	monster_bone.name = "Monster Bone"
	monster_bone.description = "A bone from a defeated monster. Used in crafting."
	monster_bone.item_type = ItemData.ItemType.MATERIAL
	monster_bone.rarity = ItemData.ItemRarity.COMMON
	monster_bone.stackable = true
	monster_bone.max_stack = 99
	monster_bone.buy_price = 15
	monster_bone.sell_price = 7
	monster_bone.use_atlas_icon = true
	monster_bone.atlas_icon_name = "bone"  # Uses ICONS["bone"] = Vector2i(17, 9)
	items["monster_bone"] = monster_bone
	
	var bone := ItemData.new()
	bone.id = "bone"
	bone.name = "Bone"
	bone.description = "A skeletal bone. Common drop from skeleton enemies."
	bone.item_type = ItemData.ItemType.MATERIAL
	bone.rarity = ItemData.ItemRarity.COMMON
	bone.stackable = true
	bone.max_stack = 99
	bone.buy_price = 5
	bone.sell_price = 2
	bone.use_atlas_icon = true
	bone.atlas_icon_name = "bone"  # Uses ICONS["bone"] = Vector2i(17, 9)
	items["bone"] = bone
	
	# === CURRENCY (for visual drops) ===
	var gold_coin := ItemData.new()
	gold_coin.id = "gold_coin"
	gold_coin.name = "Gold Coin"
	gold_coin.description = "A shiny gold coin."
	gold_coin.item_type = ItemData.ItemType.MATERIAL  # or create CURRENCY type
	gold_coin.rarity = ItemData.ItemRarity.COMMON
	gold_coin.stackable = true
	gold_coin.max_stack = 9999
	gold_coin.buy_price = 1
	gold_coin.sell_price = 1
	gold_coin.use_atlas_icon = true
	gold_coin.atlas_icon_name = "gold_coin"
	items["gold_coin"] = gold_coin


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
