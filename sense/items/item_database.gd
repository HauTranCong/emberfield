extends Node

## Sample items database - preloaded item definitions
## Use this to get item data by ID

var items: Dictionary = {}

## Path to the item icons sprite sheet
const ICON_SHEET_PATH := "res://assets/items/item_icons.png"


func _ready() -> void:
	_init_icon_atlas()
	_create_all_items()


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


func _create_all_items() -> void:
	_create_weapons()
	_create_armor()
	_create_helmets()
	_create_shields()
	_create_boots()
	_create_accessories()
	_create_consumables()
	_create_materials()
	_create_segments()
	_create_augments()
	_create_timed_buffs()


func _create_weapons() -> void:
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
	items["steel_sword"] = ItemHelper.create_item({
		"id": "steel_sword", "name": "Steel Sword",
		"description": "A well-crafted steel sword with a sharp edge.",
		"type": ItemData.ItemType.WEAPON, "price": 300, "attack": 25,
		"icon_name": "iron_sword"
	})
	items["platinum_sword"] = ItemHelper.create_item({
		"id": "platinum_sword", "name": "Platinum Sword",
		"description": "A finely crafted platinum sword. Light and deadly.",
		"type": ItemData.ItemType.WEAPON, "price": 300, "attack": 25, "speed": 5.0,
		"icon_name": "platinum_sword"
	})
	items["fire_blade"] = ItemHelper.create_item({
		"id": "fire_blade", "name": "Flame Blade",
		"description": "A magical blade imbued with fire essence. Burns with eternal flame.",
		"type": ItemData.ItemType.WEAPON, "rarity": ItemData.ItemRarity.RARE,
		"price": 1000, "attack": 40,
		"icon_name": "iron_sword"
	})
	items["pirate_blade"] = ItemHelper.create_item({
		"id": "pirate_blade", "name": "Pirate Blade",
		"description": "A curved blade favored by pirates. Fast but less powerful.",
		"type": ItemData.ItemType.WEAPON, "price": 120, "attack": 12, "speed": 10.0,
		"icon_name": "pirate_blade"
	})
	items["battle_axe"] = ItemHelper.create_item({
		"id": "battle_axe", "name": "Battle Axe",
		"description": "A heavy axe that deals massive damage.",
		"type": ItemData.ItemType.WEAPON, "price": 250, "attack": 30, "speed": -5.0,
		"icon_name": "battle_axe"
	})
	items["dagger"] = ItemHelper.create_item({
		"id": "dagger", "name": "Dagger",
		"description": "A quick, light blade for swift attacks.",
		"type": ItemData.ItemType.WEAPON, "price": 90, "attack": 10, "speed": 15.0,
		"icon_name": "dagger"
	})
	items["war_hammer"] = ItemHelper.create_item({
		"id": "war_hammer", "name": "War Hammer",
		"description": "A crushing weapon that breaks through armor.",
		"type": ItemData.ItemType.WEAPON, "price": 400, "attack": 35, "speed": -10.0,
		"icon_name": "thron_mace"
	})
	items["thron_mace"] = ItemHelper.create_item({
		"id": "thron_mace", "name": "Thron Mace",
		"description": "A heavy mace that can crush armor.",
		"type": ItemData.ItemType.WEAPON, "price": 220, "attack": 28, "speed": -10.0,
		"icon_name": "thron_mace"
	})
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
	items["chainmail"] = ItemHelper.create_item({
		"id": "chainmail", "name": "Chainmail Armor",
		"description": "Flexible armor made of interlocking rings.",
		"type": ItemData.ItemType.ARMOR, "price": 250, "defense": 18, "speed": -5.0,
		"icon_row": 7, "icon_col": 3
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
	items["leather_cap"] = ItemHelper.create_item({
		"id": "leather_cap", "name": "Leather Cap",
		"description": "A simple leather hood for basic protection.",
		"type": ItemData.ItemType.HELMET, "price": 30, "defense": 4,
		"icon_name": "leather_cap"
	})
	items["iron_helmet"] = ItemHelper.create_item({
		"id": "iron_helmet", "name": "Iron Helmet",
		"description": "A sturdy iron helmet to protect your head.",
		"type": ItemData.ItemType.HELMET, "price": 60, "defense": 8,
		"icon_name": "iron_helmet"
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
	items["iron_boots"] = ItemHelper.create_item({
		"id": "iron_boots", "name": "Iron Boots",
		"description": "Heavy iron boots that provide good protection.",
		"type": ItemData.ItemType.BOOTS, "price": 80, "defense": 10, "speed": -5.0,
		"icon_row": 7, "icon_col": 1
	})
	items["swift_boots"] = ItemHelper.create_item({
		"id": "swift_boots", "name": "Swift Boots",
		"description": "Light boots enchanted for speed.",
		"type": ItemData.ItemType.BOOTS, "price": 150, "defense": 3, "speed": 20.0,
		"icon_name": "swift_boots"
	})


func _create_accessories() -> void:
	items["silver_ring"] = ItemHelper.create_item({
		"id": "silver_ring", "name": "Silver Ring",
		"description": "A simple silver ring with minor enchantments.",
		"type": ItemData.ItemType.ACCESSORY, "price": 200, "attack": 5, "defense": 5,
		"icon_row": 8, "icon_col": 2
	})
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
	items["strength_amulet"] = ItemHelper.create_item({
		"id": "strength_amulet", "name": "Strength Amulet",
		"description": "An amulet that enhances physical power.",
		"type": ItemData.ItemType.ACCESSORY, "price": 280, "attack": 12,
		"icon_row": 8, "icon_col": 6
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


func _create_segments() -> void:
	items["fire_shard"] = ItemHelper.create_item({
		"id": "fire_shard", "name": "Fire Shard",
		"description": "A warm crystalline fragment.",
		"type": ItemData.ItemType.SEGMENT, "stackable": true,
		"price": 15, "sell_price": 5,
		"icon_name": "fire_shard"
	})
	items["frost_shard"] = ItemHelper.create_item({
		"id": "frost_shard", "name": "Frost Shard",
		"description": "A cold crystalline fragment.",
		"type": ItemData.ItemType.SEGMENT, "stackable": true,
		"price": 15, "sell_price": 5,
		"icon_name": "frost_shard"
	})
	items["power_fragment"] = ItemHelper.create_item({
		"id": "power_fragment", "name": "Power Fragment",
		"description": "Pulses with raw energy.",
		"type": ItemData.ItemType.SEGMENT, "stackable": true,
		"price": 20, "sell_price": 7,
		"icon_name": "power_fragment"
	})
	items["spirit_essence"] = ItemHelper.create_item({
		"id": "spirit_essence", "name": "Spirit Essence",
		"description": "A wisp of spectral energy.",
		"type": ItemData.ItemType.SEGMENT, "rarity": ItemData.ItemRarity.UNCOMMON,
		"stackable": true, "price": 30, "sell_price": 10,
		"icon_name": "spirit_essence"
	})
	items["venom_gland"] = ItemHelper.create_item({
		"id": "venom_gland", "name": "Venom Gland",
		"description": "Drips with potent toxin.",
		"type": ItemData.ItemType.SEGMENT, "rarity": ItemData.ItemRarity.UNCOMMON,
		"stackable": true, "price": 25, "sell_price": 8,
		"icon_name": "venom_gland"
	})
	items["herb_segment"] = ItemHelper.create_item({
		"id": "herb_segment", "name": "Herb Segment",
		"description": "A fragrant healing herb.",
		"type": ItemData.ItemType.SEGMENT, "stackable": true,
		"price": 10, "sell_price": 3,
		"icon_name": "herb_segment"
	})
	items["inferno_shard"] = ItemHelper.create_item({
		"id": "inferno_shard", "name": "Inferno Shard",
		"description": "Blazing hot crystal.",
		"type": ItemData.ItemType.SEGMENT, "rarity": ItemData.ItemRarity.RARE,
		"stackable": true, "price": 50, "sell_price": 18,
		"icon_name": "inferno_shard"
	})
	items["blizzard_shard"] = ItemHelper.create_item({
		"id": "blizzard_shard", "name": "Blizzard Shard",
		"description": "Freezing cold crystal.",
		"type": ItemData.ItemType.SEGMENT, "rarity": ItemData.ItemRarity.RARE,
		"stackable": true, "price": 50, "sell_price": 18,
		"icon_name": "blizzard_shard"
	})
	items["greater_power_fragment"] = ItemHelper.create_item({
		"id": "greater_power_fragment", "name": "Greater Power Fragment",
		"description": "Surges with intense energy.",
		"type": ItemData.ItemType.SEGMENT, "rarity": ItemData.ItemRarity.RARE,
		"stackable": true, "price": 60, "sell_price": 22,
		"icon_name": "greater_power_fragment"
	})
	items["hellfire_shard"] = ItemHelper.create_item({
		"id": "hellfire_shard", "name": "Hellfire Shard",
		"description": "Burns with infernal flame.",
		"type": ItemData.ItemType.SEGMENT, "rarity": ItemData.ItemRarity.EPIC,
		"stackable": true, "price": 120, "sell_price": 45,
		"icon_name": "hellfire_shard"
	})


func _create_augments() -> void:
	# --- Flame augments ---
	items["flame_augment_t1"] = ItemHelper.create_item({
		"id": "flame_augment_t1", "name": "Flame Augment I",
		"description": "Imbue equipment with fire. Burns enemies on hit.",
		"type": ItemData.ItemType.AUGMENT, "rarity": ItemData.ItemRarity.UNCOMMON,
		"stackable": false, "max_stack": 1, "attack": 5,
		"augment_type": ItemData.AugmentType.PASSIVE_EFFECT,
		"passive_effect": ItemData.PassiveEffect.BURN_ON_HIT, "passive_value": 3.0,
		"icon_name": "flame_augment"
	})
	items["flame_augment_t2"] = ItemHelper.create_item({
		"id": "flame_augment_t2", "name": "Flame Augment II",
		"description": "Stronger fire imbue. Sears enemies on hit.",
		"type": ItemData.ItemType.AUGMENT, "rarity": ItemData.ItemRarity.RARE,
		"stackable": false, "max_stack": 1, "attack": 12,
		"augment_type": ItemData.AugmentType.PASSIVE_EFFECT,
		"passive_effect": ItemData.PassiveEffect.BURN_ON_HIT, "passive_value": 5.0,
		"icon_name": "flame_augment"
	})
	items["flame_augment_t3"] = ItemHelper.create_item({
		"id": "flame_augment_t3", "name": "Flame Augment III",
		"description": "Infernal fire imbue. Incinerates enemies on hit.",
		"type": ItemData.ItemType.AUGMENT, "rarity": ItemData.ItemRarity.EPIC,
		"stackable": false, "max_stack": 1, "attack": 20,
		"augment_type": ItemData.AugmentType.PASSIVE_EFFECT,
		"passive_effect": ItemData.PassiveEffect.BURN_ON_HIT, "passive_value": 8.0,
		"icon_name": "flame_augment"
	})
	# --- Frost augments ---
	items["frost_augment_t1"] = ItemHelper.create_item({
		"id": "frost_augment_t1", "name": "Frost Augment I",
		"description": "Imbue equipment with ice. Slows enemies on hit.",
		"type": ItemData.ItemType.AUGMENT, "rarity": ItemData.ItemRarity.UNCOMMON,
		"stackable": false, "max_stack": 1, "attack": 3,
		"augment_type": ItemData.AugmentType.PASSIVE_EFFECT,
		"passive_effect": ItemData.PassiveEffect.FREEZE_ON_HIT, "passive_value": 1.5,
		"icon_name": "frost_augment"
	})
	items["frost_augment_t2"] = ItemHelper.create_item({
		"id": "frost_augment_t2", "name": "Frost Augment II",
		"description": "Stronger ice imbue. Freezes enemies on hit.",
		"type": ItemData.ItemType.AUGMENT, "rarity": ItemData.ItemRarity.RARE,
		"stackable": false, "max_stack": 1, "attack": 8,
		"augment_type": ItemData.AugmentType.PASSIVE_EFFECT,
		"passive_effect": ItemData.PassiveEffect.FREEZE_ON_HIT, "passive_value": 3.0,
		"icon_name": "frost_augment"
	})
	# --- Power augments ---
	items["power_augment_t1"] = ItemHelper.create_item({
		"id": "power_augment_t1", "name": "Power Augment I",
		"description": "Raw strength increase.",
		"type": ItemData.ItemType.AUGMENT, "rarity": ItemData.ItemRarity.UNCOMMON,
		"stackable": false, "max_stack": 1, "attack": 8,
		"augment_type": ItemData.AugmentType.STAT_BOOST,
		"icon_name": "power_augment"
	})
	items["power_augment_t2"] = ItemHelper.create_item({
		"id": "power_augment_t2", "name": "Power Augment II",
		"description": "Greater strength increase.",
		"type": ItemData.ItemType.AUGMENT, "rarity": ItemData.ItemRarity.RARE,
		"stackable": false, "max_stack": 1, "attack": 15,
		"augment_type": ItemData.AugmentType.STAT_BOOST,
		"icon_name": "power_augment"
	})
	# --- Lifesteal augments ---
	items["lifesteal_augment_t1"] = ItemHelper.create_item({
		"id": "lifesteal_augment_t1", "name": "Lifesteal Augment I",
		"description": "Drain 5% of damage dealt as health.",
		"type": ItemData.ItemType.AUGMENT, "rarity": ItemData.ItemRarity.UNCOMMON,
		"stackable": false, "max_stack": 1,
		"augment_type": ItemData.AugmentType.PASSIVE_EFFECT,
		"passive_effect": ItemData.PassiveEffect.LIFE_STEAL, "passive_value": 5.0,
		"icon_name": "lifesteal_augment"
	})
	items["lifesteal_augment_t2"] = ItemHelper.create_item({
		"id": "lifesteal_augment_t2", "name": "Lifesteal Augment II",
		"description": "Drain 10% of damage dealt as health.",
		"type": ItemData.ItemType.AUGMENT, "rarity": ItemData.ItemRarity.RARE,
		"stackable": false, "max_stack": 1,
		"augment_type": ItemData.AugmentType.PASSIVE_EFFECT,
		"passive_effect": ItemData.PassiveEffect.LIFE_STEAL, "passive_value": 10.0,
		"icon_name": "lifesteal_augment"
	})
	# --- Crit augments ---
	items["crit_augment_t1"] = ItemHelper.create_item({
		"id": "crit_augment_t1", "name": "Critical Augment I",
		"description": "8% chance for 2x damage.",
		"type": ItemData.ItemType.AUGMENT, "rarity": ItemData.ItemRarity.UNCOMMON,
		"stackable": false, "max_stack": 1,
		"augment_type": ItemData.AugmentType.PASSIVE_EFFECT,
		"passive_effect": ItemData.PassiveEffect.CRIT_CHANCE, "passive_value": 8.0,
		"icon_name": "crit_augment"
	})
	items["crit_augment_t2"] = ItemHelper.create_item({
		"id": "crit_augment_t2", "name": "Critical Augment II",
		"description": "15% chance for 2x damage.",
		"type": ItemData.ItemType.AUGMENT, "rarity": ItemData.ItemRarity.RARE,
		"stackable": false, "max_stack": 1,
		"augment_type": ItemData.AugmentType.PASSIVE_EFFECT,
		"passive_effect": ItemData.PassiveEffect.CRIT_CHANCE, "passive_value": 15.0,
		"icon_name": "crit_augment"
	})
	# --- Skill augments ---
	items["whirlwind_augment"] = ItemHelper.create_item({
		"id": "whirlwind_augment", "name": "Whirlwind Rune",
		"description": "Grants the Whirlwind skill when slotted into equipment.",
		"type": ItemData.ItemType.AUGMENT, "rarity": ItemData.ItemRarity.EPIC,
		"stackable": false, "max_stack": 1, "attack": 5,
		"augment_type": ItemData.AugmentType.ACTIVE_SKILL,
		"active_skill_id": "whirlwind",
		"icon_name": "whirlwind_augment"
	})
	items["shield_bash_augment"] = ItemHelper.create_item({
		"id": "shield_bash_augment", "name": "Shield Bash Rune",
		"description": "Grants the Shield Bash skill when slotted into equipment.",
		"type": ItemData.ItemType.AUGMENT, "rarity": ItemData.ItemRarity.EPIC,
		"stackable": false, "max_stack": 1, "defense": 5,
		"augment_type": ItemData.AugmentType.ACTIVE_SKILL,
		"active_skill_id": "shield_bash",
		"icon_name": "shield_bash_augment"
	})


func _create_timed_buffs() -> void:
	items["vitality_tonic_t1"] = ItemHelper.create_item({
		"id": "vitality_tonic_t1", "name": "Vitality Tonic I",
		"description": "Temporarily increases max HP by 20 for 60 seconds.",
		"type": ItemData.ItemType.AUGMENT, "rarity": ItemData.ItemRarity.UNCOMMON,
		"stackable": true, "max_stack": 5, "health": 20,
		"augment_type": ItemData.AugmentType.TIMED_BUFF, "buff_duration": 60.0,
		"icon_name": "vitality_tonic"
	})
	items["vitality_tonic_t2"] = ItemHelper.create_item({
		"id": "vitality_tonic_t2", "name": "Vitality Tonic II",
		"description": "Temporarily increases max HP by 50 for 90 seconds.",
		"type": ItemData.ItemType.AUGMENT, "rarity": ItemData.ItemRarity.RARE,
		"stackable": true, "max_stack": 5, "health": 50,
		"augment_type": ItemData.AugmentType.TIMED_BUFF, "buff_duration": 90.0,
		"icon_name": "vitality_tonic"
	})
	items["speed_elixir_t1"] = ItemHelper.create_item({
		"id": "speed_elixir_t1", "name": "Speed Elixir I",
		"description": "Temporarily increases move speed by 20 for 45 seconds.",
		"type": ItemData.ItemType.AUGMENT, "rarity": ItemData.ItemRarity.UNCOMMON,
		"stackable": true, "max_stack": 5, "speed": 20.0,
		"augment_type": ItemData.AugmentType.TIMED_BUFF, "buff_duration": 45.0,
		"icon_name": "speed_elixir"
	})
	items["speed_elixir_t2"] = ItemHelper.create_item({
		"id": "speed_elixir_t2", "name": "Speed Elixir II",
		"description": "Temporarily increases move speed by 40 for 60 seconds.",
		"type": ItemData.ItemType.AUGMENT, "rarity": ItemData.ItemRarity.RARE,
		"stackable": true, "max_stack": 5, "speed": 40.0,
		"augment_type": ItemData.AugmentType.TIMED_BUFF, "buff_duration": 60.0,
		"icon_name": "speed_elixir"
	})
	items["defense_brew_t1"] = ItemHelper.create_item({
		"id": "defense_brew_t1", "name": "Defense Brew I",
		"description": "Temporarily increases defense by 8 for 45 seconds.",
		"type": ItemData.ItemType.AUGMENT, "rarity": ItemData.ItemRarity.UNCOMMON,
		"stackable": true, "max_stack": 5, "defense": 8,
		"augment_type": ItemData.AugmentType.TIMED_BUFF, "buff_duration": 45.0,
		"icon_name": "defense_brew"
	})
	items["defense_brew_t2"] = ItemHelper.create_item({
		"id": "defense_brew_t2", "name": "Defense Brew II",
		"description": "Temporarily increases defense by 15 for 60 seconds.",
		"type": ItemData.ItemType.AUGMENT, "rarity": ItemData.ItemRarity.RARE,
		"stackable": true, "max_stack": 5, "defense": 15,
		"augment_type": ItemData.AugmentType.TIMED_BUFF, "buff_duration": 60.0,
		"icon_name": "defense_brew"
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
