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
	steel_sword.rarity = ItemData.ItemRarity.UNCOMMON
	steel_sword.stackable = false
	steel_sword.attack_bonus = 25
	steel_sword.buy_price = 300
	steel_sword.sell_price = 150
	steel_sword.use_atlas_icon = true
	steel_sword.atlas_icon_name = "sword_iron"  # Reuse sword icon
	items["steel_sword"] = steel_sword
	
	var fire_blade := ItemData.new()
	fire_blade.id = "fire_blade"
	fire_blade.name = "Flame Blade"
	fire_blade.description = "A magical blade imbued with fire essence. Burns with eternal flame."
	fire_blade.item_type = ItemData.ItemType.WEAPON
	fire_blade.rarity = ItemData.ItemRarity.RARE
	fire_blade.stackable = false
	fire_blade.attack_bonus = 40
	fire_blade.buy_price = 1000
	fire_blade.sell_price = 500
	fire_blade.use_atlas_icon = true
	fire_blade.atlas_icon_name = "sword_iron"  # Reuse sword icon
	items["fire_blade"] = fire_blade
	
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
	iron_armor.rarity = ItemData.ItemRarity.UNCOMMON
	iron_armor.stackable = false
	iron_armor.defense_bonus = 25
	iron_armor.speed_bonus = -10.0
	iron_armor.buy_price = 400
	iron_armor.sell_price = 200
	iron_armor.use_atlas_icon = true
	iron_armor.atlas_icon_name = "leather_armor"  # Reuse armor icon
	items["iron_armor"] = iron_armor
	
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
	wooden_shield.atlas_row = 18  # Shield row - adjust with debug tool
	wooden_shield.atlas_col = 0
	items["wooden_shield"] = wooden_shield
	
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
	
	# === ACCESSORIES ===
	var silver_ring := ItemData.new()
	silver_ring.id = "silver_ring"
	silver_ring.name = "Silver Ring"
	silver_ring.description = "A simple silver ring with minor enchantments."
	silver_ring.item_type = ItemData.ItemType.ACCESSORY
	silver_ring.rarity = ItemData.ItemRarity.UNCOMMON
	silver_ring.stackable = false
	silver_ring.attack_bonus = 5
	silver_ring.defense_bonus = 5
	silver_ring.buy_price = 200
	silver_ring.sell_price = 100
	silver_ring.use_atlas_icon = true
	silver_ring.atlas_row = 8  # Ring row - adjust with debug tool
	silver_ring.atlas_col = 2
	items["silver_ring"] = silver_ring
	
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
	large_health_potion.rarity = ItemData.ItemRarity.UNCOMMON
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
	gold_ore.rarity = ItemData.ItemRarity.UNCOMMON
	gold_ore.stackable = true
	gold_ore.max_stack = 99
	gold_ore.buy_price = 50
	gold_ore.sell_price = 25
	gold_ore.use_atlas_icon = true
	gold_ore.atlas_icon_name = "iron_ore"  # Reuse ore icon
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

	# ═══════════════════════════════════════════════════════════
	# SEGMENT ITEMS — magical crafting drops from enemies/world
	# ═══════════════════════════════════════════════════════════

	var fire_shard := ItemData.new()
	fire_shard.id = "fire_shard"
	fire_shard.name = "Fire Shard"
	fire_shard.description = "A warm crystalline fragment."
	fire_shard.item_type = ItemData.ItemType.SEGMENT
	fire_shard.rarity = ItemData.ItemRarity.COMMON
	fire_shard.stackable = true
	fire_shard.max_stack = 99
	fire_shard.buy_price = 15
	fire_shard.sell_price = 5
	fire_shard.use_atlas_icon = true
	fire_shard.atlas_icon_name = "fire_shard"
	items["fire_shard"] = fire_shard

	var frost_shard := ItemData.new()
	frost_shard.id = "frost_shard"
	frost_shard.name = "Frost Shard"
	frost_shard.description = "A cold crystalline fragment."
	frost_shard.item_type = ItemData.ItemType.SEGMENT
	frost_shard.rarity = ItemData.ItemRarity.COMMON
	frost_shard.stackable = true
	frost_shard.max_stack = 99
	frost_shard.buy_price = 15
	frost_shard.sell_price = 5
	frost_shard.use_atlas_icon = true
	frost_shard.atlas_icon_name = "frost_shard"
	items["frost_shard"] = frost_shard

	var power_fragment := ItemData.new()
	power_fragment.id = "power_fragment"
	power_fragment.name = "Power Fragment"
	power_fragment.description = "Pulses with raw energy."
	power_fragment.item_type = ItemData.ItemType.SEGMENT
	power_fragment.rarity = ItemData.ItemRarity.COMMON
	power_fragment.stackable = true
	power_fragment.max_stack = 99
	power_fragment.buy_price = 20
	power_fragment.sell_price = 7
	power_fragment.use_atlas_icon = true
	power_fragment.atlas_icon_name = "power_fragment"
	items["power_fragment"] = power_fragment

	var spirit_essence := ItemData.new()
	spirit_essence.id = "spirit_essence"
	spirit_essence.name = "Spirit Essence"
	spirit_essence.description = "A wisp of spectral energy."
	spirit_essence.item_type = ItemData.ItemType.SEGMENT
	spirit_essence.rarity = ItemData.ItemRarity.UNCOMMON
	spirit_essence.stackable = true
	spirit_essence.max_stack = 99
	spirit_essence.buy_price = 30
	spirit_essence.sell_price = 10
	spirit_essence.use_atlas_icon = true
	spirit_essence.atlas_icon_name = "spirit_essence"
	items["spirit_essence"] = spirit_essence

	var venom_gland := ItemData.new()
	venom_gland.id = "venom_gland"
	venom_gland.name = "Venom Gland"
	venom_gland.description = "Drips with potent toxin."
	venom_gland.item_type = ItemData.ItemType.SEGMENT
	venom_gland.rarity = ItemData.ItemRarity.UNCOMMON
	venom_gland.stackable = true
	venom_gland.max_stack = 99
	venom_gland.buy_price = 25
	venom_gland.sell_price = 8
	venom_gland.use_atlas_icon = true
	venom_gland.atlas_icon_name = "venom_gland"
	items["venom_gland"] = venom_gland

	var herb_segment := ItemData.new()
	herb_segment.id = "herb_segment"
	herb_segment.name = "Herb Segment"
	herb_segment.description = "A fragrant healing herb."
	herb_segment.item_type = ItemData.ItemType.SEGMENT
	herb_segment.rarity = ItemData.ItemRarity.COMMON
	herb_segment.stackable = true
	herb_segment.max_stack = 99
	herb_segment.buy_price = 10
	herb_segment.sell_price = 3
	herb_segment.use_atlas_icon = true
	herb_segment.atlas_icon_name = "herb_segment"
	items["herb_segment"] = herb_segment

	var inferno_shard := ItemData.new()
	inferno_shard.id = "inferno_shard"
	inferno_shard.name = "Inferno Shard"
	inferno_shard.description = "Blazing hot crystal."
	inferno_shard.item_type = ItemData.ItemType.SEGMENT
	inferno_shard.rarity = ItemData.ItemRarity.RARE
	inferno_shard.stackable = true
	inferno_shard.max_stack = 99
	inferno_shard.buy_price = 50
	inferno_shard.sell_price = 18
	inferno_shard.use_atlas_icon = true
	inferno_shard.atlas_icon_name = "inferno_shard"
	items["inferno_shard"] = inferno_shard

	var blizzard_shard := ItemData.new()
	blizzard_shard.id = "blizzard_shard"
	blizzard_shard.name = "Blizzard Shard"
	blizzard_shard.description = "Freezing cold crystal."
	blizzard_shard.item_type = ItemData.ItemType.SEGMENT
	blizzard_shard.rarity = ItemData.ItemRarity.RARE
	blizzard_shard.stackable = true
	blizzard_shard.max_stack = 99
	blizzard_shard.buy_price = 50
	blizzard_shard.sell_price = 18
	blizzard_shard.use_atlas_icon = true
	blizzard_shard.atlas_icon_name = "blizzard_shard"
	items["blizzard_shard"] = blizzard_shard

	var greater_power_fragment := ItemData.new()
	greater_power_fragment.id = "greater_power_fragment"
	greater_power_fragment.name = "Greater Power Fragment"
	greater_power_fragment.description = "Surges with intense energy."
	greater_power_fragment.item_type = ItemData.ItemType.SEGMENT
	greater_power_fragment.rarity = ItemData.ItemRarity.RARE
	greater_power_fragment.stackable = true
	greater_power_fragment.max_stack = 99
	greater_power_fragment.buy_price = 60
	greater_power_fragment.sell_price = 22
	greater_power_fragment.use_atlas_icon = true
	greater_power_fragment.atlas_icon_name = "greater_power_fragment"
	items["greater_power_fragment"] = greater_power_fragment

	var hellfire_shard := ItemData.new()
	hellfire_shard.id = "hellfire_shard"
	hellfire_shard.name = "Hellfire Shard"
	hellfire_shard.description = "Burns with infernal flame."
	hellfire_shard.item_type = ItemData.ItemType.SEGMENT
	hellfire_shard.rarity = ItemData.ItemRarity.EPIC
	hellfire_shard.stackable = true
	hellfire_shard.max_stack = 99
	hellfire_shard.buy_price = 120
	hellfire_shard.sell_price = 45
	hellfire_shard.use_atlas_icon = true
	hellfire_shard.atlas_icon_name = "hellfire_shard"
	items["hellfire_shard"] = hellfire_shard

	# ═══════════════════════════════════════════════════════════
	# AUGMENT ITEMS — permanent augments (crafting outputs)
	# ═══════════════════════════════════════════════════════════

	var flame_augment_t1 := ItemData.new()
	flame_augment_t1.id = "flame_augment_t1"
	flame_augment_t1.name = "Flame Augment I"
	flame_augment_t1.description = "Imbue equipment with fire. Burns enemies on hit."
	flame_augment_t1.item_type = ItemData.ItemType.AUGMENT
	flame_augment_t1.rarity = ItemData.ItemRarity.UNCOMMON
	flame_augment_t1.stackable = false
	flame_augment_t1.max_stack = 1
	flame_augment_t1.augment_type = ItemData.AugmentType.PASSIVE_EFFECT
	flame_augment_t1.passive_effect = ItemData.PassiveEffect.BURN_ON_HIT
	flame_augment_t1.passive_value = 3.0
	flame_augment_t1.attack_bonus = 5
	flame_augment_t1.use_atlas_icon = true
	flame_augment_t1.atlas_icon_name = "flame_augment"
	items["flame_augment_t1"] = flame_augment_t1

	var flame_augment_t2 := ItemData.new()
	flame_augment_t2.id = "flame_augment_t2"
	flame_augment_t2.name = "Flame Augment II"
	flame_augment_t2.description = "Stronger fire imbue. Sears enemies on hit."
	flame_augment_t2.item_type = ItemData.ItemType.AUGMENT
	flame_augment_t2.rarity = ItemData.ItemRarity.RARE
	flame_augment_t2.stackable = false
	flame_augment_t2.max_stack = 1
	flame_augment_t2.augment_type = ItemData.AugmentType.PASSIVE_EFFECT
	flame_augment_t2.passive_effect = ItemData.PassiveEffect.BURN_ON_HIT
	flame_augment_t2.passive_value = 5.0
	flame_augment_t2.attack_bonus = 12
	flame_augment_t2.use_atlas_icon = true
	flame_augment_t2.atlas_icon_name = "flame_augment"
	items["flame_augment_t2"] = flame_augment_t2

	var flame_augment_t3 := ItemData.new()
	flame_augment_t3.id = "flame_augment_t3"
	flame_augment_t3.name = "Flame Augment III"
	flame_augment_t3.description = "Infernal fire imbue. Incinerates enemies on hit."
	flame_augment_t3.item_type = ItemData.ItemType.AUGMENT
	flame_augment_t3.rarity = ItemData.ItemRarity.EPIC
	flame_augment_t3.stackable = false
	flame_augment_t3.max_stack = 1
	flame_augment_t3.augment_type = ItemData.AugmentType.PASSIVE_EFFECT
	flame_augment_t3.passive_effect = ItemData.PassiveEffect.BURN_ON_HIT
	flame_augment_t3.passive_value = 8.0
	flame_augment_t3.attack_bonus = 20
	flame_augment_t3.use_atlas_icon = true
	flame_augment_t3.atlas_icon_name = "flame_augment"
	items["flame_augment_t3"] = flame_augment_t3

	var frost_augment_t1 := ItemData.new()
	frost_augment_t1.id = "frost_augment_t1"
	frost_augment_t1.name = "Frost Augment I"
	frost_augment_t1.description = "Imbue equipment with ice. Slows enemies on hit."
	frost_augment_t1.item_type = ItemData.ItemType.AUGMENT
	frost_augment_t1.rarity = ItemData.ItemRarity.UNCOMMON
	frost_augment_t1.stackable = false
	frost_augment_t1.max_stack = 1
	frost_augment_t1.augment_type = ItemData.AugmentType.PASSIVE_EFFECT
	frost_augment_t1.passive_effect = ItemData.PassiveEffect.FREEZE_ON_HIT
	frost_augment_t1.passive_value = 1.5
	frost_augment_t1.attack_bonus = 3
	frost_augment_t1.use_atlas_icon = true
	frost_augment_t1.atlas_icon_name = "frost_augment"
	items["frost_augment_t1"] = frost_augment_t1

	var frost_augment_t2 := ItemData.new()
	frost_augment_t2.id = "frost_augment_t2"
	frost_augment_t2.name = "Frost Augment II"
	frost_augment_t2.description = "Stronger ice imbue. Freezes enemies on hit."
	frost_augment_t2.item_type = ItemData.ItemType.AUGMENT
	frost_augment_t2.rarity = ItemData.ItemRarity.RARE
	frost_augment_t2.stackable = false
	frost_augment_t2.max_stack = 1
	frost_augment_t2.augment_type = ItemData.AugmentType.PASSIVE_EFFECT
	frost_augment_t2.passive_effect = ItemData.PassiveEffect.FREEZE_ON_HIT
	frost_augment_t2.passive_value = 3.0
	frost_augment_t2.attack_bonus = 8
	frost_augment_t2.use_atlas_icon = true
	frost_augment_t2.atlas_icon_name = "frost_augment"
	items["frost_augment_t2"] = frost_augment_t2

	var power_augment_t1 := ItemData.new()
	power_augment_t1.id = "power_augment_t1"
	power_augment_t1.name = "Power Augment I"
	power_augment_t1.description = "Raw strength increase."
	power_augment_t1.item_type = ItemData.ItemType.AUGMENT
	power_augment_t1.rarity = ItemData.ItemRarity.UNCOMMON
	power_augment_t1.stackable = false
	power_augment_t1.max_stack = 1
	power_augment_t1.augment_type = ItemData.AugmentType.STAT_BOOST
	power_augment_t1.attack_bonus = 8
	power_augment_t1.use_atlas_icon = true
	power_augment_t1.atlas_icon_name = "power_augment"
	items["power_augment_t1"] = power_augment_t1

	var power_augment_t2 := ItemData.new()
	power_augment_t2.id = "power_augment_t2"
	power_augment_t2.name = "Power Augment II"
	power_augment_t2.description = "Greater strength increase."
	power_augment_t2.item_type = ItemData.ItemType.AUGMENT
	power_augment_t2.rarity = ItemData.ItemRarity.RARE
	power_augment_t2.stackable = false
	power_augment_t2.max_stack = 1
	power_augment_t2.augment_type = ItemData.AugmentType.STAT_BOOST
	power_augment_t2.attack_bonus = 15
	power_augment_t2.use_atlas_icon = true
	power_augment_t2.atlas_icon_name = "power_augment"
	items["power_augment_t2"] = power_augment_t2

	var lifesteal_augment_t1 := ItemData.new()
	lifesteal_augment_t1.id = "lifesteal_augment_t1"
	lifesteal_augment_t1.name = "Lifesteal Augment I"
	lifesteal_augment_t1.description = "Drain 5% of damage dealt as health."
	lifesteal_augment_t1.item_type = ItemData.ItemType.AUGMENT
	lifesteal_augment_t1.rarity = ItemData.ItemRarity.UNCOMMON
	lifesteal_augment_t1.stackable = false
	lifesteal_augment_t1.max_stack = 1
	lifesteal_augment_t1.augment_type = ItemData.AugmentType.PASSIVE_EFFECT
	lifesteal_augment_t1.passive_effect = ItemData.PassiveEffect.LIFE_STEAL
	lifesteal_augment_t1.passive_value = 5.0
	lifesteal_augment_t1.use_atlas_icon = true
	lifesteal_augment_t1.atlas_icon_name = "lifesteal_augment"
	items["lifesteal_augment_t1"] = lifesteal_augment_t1

	var lifesteal_augment_t2 := ItemData.new()
	lifesteal_augment_t2.id = "lifesteal_augment_t2"
	lifesteal_augment_t2.name = "Lifesteal Augment II"
	lifesteal_augment_t2.description = "Drain 10% of damage dealt as health."
	lifesteal_augment_t2.item_type = ItemData.ItemType.AUGMENT
	lifesteal_augment_t2.rarity = ItemData.ItemRarity.RARE
	lifesteal_augment_t2.stackable = false
	lifesteal_augment_t2.max_stack = 1
	lifesteal_augment_t2.augment_type = ItemData.AugmentType.PASSIVE_EFFECT
	lifesteal_augment_t2.passive_effect = ItemData.PassiveEffect.LIFE_STEAL
	lifesteal_augment_t2.passive_value = 10.0
	lifesteal_augment_t2.use_atlas_icon = true
	lifesteal_augment_t2.atlas_icon_name = "lifesteal_augment"
	items["lifesteal_augment_t2"] = lifesteal_augment_t2

	var crit_augment_t1 := ItemData.new()
	crit_augment_t1.id = "crit_augment_t1"
	crit_augment_t1.name = "Critical Augment I"
	crit_augment_t1.description = "8% chance for 2x damage."
	crit_augment_t1.item_type = ItemData.ItemType.AUGMENT
	crit_augment_t1.rarity = ItemData.ItemRarity.UNCOMMON
	crit_augment_t1.stackable = false
	crit_augment_t1.max_stack = 1
	crit_augment_t1.augment_type = ItemData.AugmentType.PASSIVE_EFFECT
	crit_augment_t1.passive_effect = ItemData.PassiveEffect.CRIT_CHANCE
	crit_augment_t1.passive_value = 8.0
	crit_augment_t1.use_atlas_icon = true
	crit_augment_t1.atlas_icon_name = "crit_augment"
	items["crit_augment_t1"] = crit_augment_t1

	var crit_augment_t2 := ItemData.new()
	crit_augment_t2.id = "crit_augment_t2"
	crit_augment_t2.name = "Critical Augment II"
	crit_augment_t2.description = "15% chance for 2x damage."
	crit_augment_t2.item_type = ItemData.ItemType.AUGMENT
	crit_augment_t2.rarity = ItemData.ItemRarity.RARE
	crit_augment_t2.stackable = false
	crit_augment_t2.max_stack = 1
	crit_augment_t2.augment_type = ItemData.AugmentType.PASSIVE_EFFECT
	crit_augment_t2.passive_effect = ItemData.PassiveEffect.CRIT_CHANCE
	crit_augment_t2.passive_value = 15.0
	crit_augment_t2.use_atlas_icon = true
	crit_augment_t2.atlas_icon_name = "crit_augment"
	items["crit_augment_t2"] = crit_augment_t2

	var whirlwind_augment := ItemData.new()
	whirlwind_augment.id = "whirlwind_augment"
	whirlwind_augment.name = "Whirlwind Rune"
	whirlwind_augment.description = "Grants the Whirlwind skill when slotted into equipment."
	whirlwind_augment.item_type = ItemData.ItemType.AUGMENT
	whirlwind_augment.rarity = ItemData.ItemRarity.EPIC
	whirlwind_augment.stackable = false
	whirlwind_augment.max_stack = 1
	whirlwind_augment.augment_type = ItemData.AugmentType.ACTIVE_SKILL
	whirlwind_augment.active_skill_id = "whirlwind"
	whirlwind_augment.attack_bonus = 5
	whirlwind_augment.use_atlas_icon = true
	whirlwind_augment.atlas_icon_name = "whirlwind_augment"
	items["whirlwind_augment"] = whirlwind_augment

	var shield_bash_augment := ItemData.new()
	shield_bash_augment.id = "shield_bash_augment"
	shield_bash_augment.name = "Shield Bash Rune"
	shield_bash_augment.description = "Grants the Shield Bash skill when slotted into equipment."
	shield_bash_augment.item_type = ItemData.ItemType.AUGMENT
	shield_bash_augment.rarity = ItemData.ItemRarity.EPIC
	shield_bash_augment.stackable = false
	shield_bash_augment.max_stack = 1
	shield_bash_augment.augment_type = ItemData.AugmentType.ACTIVE_SKILL
	shield_bash_augment.active_skill_id = "shield_bash"
	shield_bash_augment.defense_bonus = 5
	shield_bash_augment.use_atlas_icon = true
	shield_bash_augment.atlas_icon_name = "shield_bash_augment"
	items["shield_bash_augment"] = shield_bash_augment

	# ═══════════════════════════════════════════════════════════
	# AUGMENT ITEMS — timed buff consumables (crafting outputs)
	# ═══════════════════════════════════════════════════════════

	var vitality_tonic_t1 := ItemData.new()
	vitality_tonic_t1.id = "vitality_tonic_t1"
	vitality_tonic_t1.name = "Vitality Tonic I"
	vitality_tonic_t1.description = "Temporarily increases max HP by 20 for 60 seconds."
	vitality_tonic_t1.item_type = ItemData.ItemType.AUGMENT
	vitality_tonic_t1.rarity = ItemData.ItemRarity.UNCOMMON
	vitality_tonic_t1.stackable = true
	vitality_tonic_t1.max_stack = 5
	vitality_tonic_t1.augment_type = ItemData.AugmentType.TIMED_BUFF
	vitality_tonic_t1.buff_duration = 60.0
	vitality_tonic_t1.health_bonus = 20
	vitality_tonic_t1.use_atlas_icon = true
	vitality_tonic_t1.atlas_icon_name = "vitality_tonic"
	items["vitality_tonic_t1"] = vitality_tonic_t1

	var vitality_tonic_t2 := ItemData.new()
	vitality_tonic_t2.id = "vitality_tonic_t2"
	vitality_tonic_t2.name = "Vitality Tonic II"
	vitality_tonic_t2.description = "Temporarily increases max HP by 50 for 90 seconds."
	vitality_tonic_t2.item_type = ItemData.ItemType.AUGMENT
	vitality_tonic_t2.rarity = ItemData.ItemRarity.RARE
	vitality_tonic_t2.stackable = true
	vitality_tonic_t2.max_stack = 5
	vitality_tonic_t2.augment_type = ItemData.AugmentType.TIMED_BUFF
	vitality_tonic_t2.buff_duration = 90.0
	vitality_tonic_t2.health_bonus = 50
	vitality_tonic_t2.use_atlas_icon = true
	vitality_tonic_t2.atlas_icon_name = "vitality_tonic"
	items["vitality_tonic_t2"] = vitality_tonic_t2

	var speed_elixir_t1 := ItemData.new()
	speed_elixir_t1.id = "speed_elixir_t1"
	speed_elixir_t1.name = "Speed Elixir I"
	speed_elixir_t1.description = "Temporarily increases move speed by 20 for 45 seconds."
	speed_elixir_t1.item_type = ItemData.ItemType.AUGMENT
	speed_elixir_t1.rarity = ItemData.ItemRarity.UNCOMMON
	speed_elixir_t1.stackable = true
	speed_elixir_t1.max_stack = 5
	speed_elixir_t1.augment_type = ItemData.AugmentType.TIMED_BUFF
	speed_elixir_t1.buff_duration = 45.0
	speed_elixir_t1.speed_bonus = 20.0
	speed_elixir_t1.use_atlas_icon = true
	speed_elixir_t1.atlas_icon_name = "speed_elixir"
	items["speed_elixir_t1"] = speed_elixir_t1

	var speed_elixir_t2 := ItemData.new()
	speed_elixir_t2.id = "speed_elixir_t2"
	speed_elixir_t2.name = "Speed Elixir II"
	speed_elixir_t2.description = "Temporarily increases move speed by 40 for 60 seconds."
	speed_elixir_t2.item_type = ItemData.ItemType.AUGMENT
	speed_elixir_t2.rarity = ItemData.ItemRarity.RARE
	speed_elixir_t2.stackable = true
	speed_elixir_t2.max_stack = 5
	speed_elixir_t2.augment_type = ItemData.AugmentType.TIMED_BUFF
	speed_elixir_t2.buff_duration = 60.0
	speed_elixir_t2.speed_bonus = 40.0
	speed_elixir_t2.use_atlas_icon = true
	speed_elixir_t2.atlas_icon_name = "speed_elixir"
	items["speed_elixir_t2"] = speed_elixir_t2

	var defense_brew_t1 := ItemData.new()
	defense_brew_t1.id = "defense_brew_t1"
	defense_brew_t1.name = "Defense Brew I"
	defense_brew_t1.description = "Temporarily increases defense by 8 for 45 seconds."
	defense_brew_t1.item_type = ItemData.ItemType.AUGMENT
	defense_brew_t1.rarity = ItemData.ItemRarity.UNCOMMON
	defense_brew_t1.stackable = true
	defense_brew_t1.max_stack = 5
	defense_brew_t1.augment_type = ItemData.AugmentType.TIMED_BUFF
	defense_brew_t1.buff_duration = 45.0
	defense_brew_t1.defense_bonus = 8
	defense_brew_t1.use_atlas_icon = true
	defense_brew_t1.atlas_icon_name = "defense_brew"
	items["defense_brew_t1"] = defense_brew_t1

	var defense_brew_t2 := ItemData.new()
	defense_brew_t2.id = "defense_brew_t2"
	defense_brew_t2.name = "Defense Brew II"
	defense_brew_t2.description = "Temporarily increases defense by 15 for 60 seconds."
	defense_brew_t2.item_type = ItemData.ItemType.AUGMENT
	defense_brew_t2.rarity = ItemData.ItemRarity.RARE
	defense_brew_t2.stackable = true
	defense_brew_t2.max_stack = 5
	defense_brew_t2.augment_type = ItemData.AugmentType.TIMED_BUFF
	defense_brew_t2.buff_duration = 60.0
	defense_brew_t2.defense_bonus = 15
	defense_brew_t2.use_atlas_icon = true
	defense_brew_t2.atlas_icon_name = "defense_brew"
	items["defense_brew_t2"] = defense_brew_t2


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
