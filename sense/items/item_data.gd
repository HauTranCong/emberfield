class_name ItemData
extends Resource

## Item data resource - defines all properties of an item
##
## ╔═══════════════════════════════════════════════════════════════╗
## ║                    ITEM TYPE DIAGRAM                          ║
## ╠═══════════════════════════════════════════════════════════════╣
## ║  WEAPON     → Equipped in weapon slot, adds attack damage     ║
## ║  ARMOR      → Equipped in armor slot, adds defense            ║
## ║  HELMET     → Equipped in helmet slot, adds defense           ║
## ║  BOOTS      → Equipped in boots slot, adds speed              ║
## ║  ACCESSORY  → Equipped in accessory slots (2 slots)           ║
## ║  CONSUMABLE → Used from inventory, applies effect             ║
## ║  MATERIAL   → Crafting materials, cannot be used directly     ║
## ║  QUEST      → Quest items, cannot be dropped or sold          ║
## ║  SEGMENT    → Magical crafting drops, stackable max 99        ║
## ║  AUGMENT    → Crafted buff items, slotted into equipment      ║
## ╚═══════════════════════════════════════════════════════════════╝

enum ItemType {
	WEAPON,
	ARMOR,
	HELMET,
	BOOTS,
	SHIELD,
	ACCESSORY,
	CONSUMABLE,
	MATERIAL,
	QUEST,
	SEGMENT,   ## Magical crafting drops, stackable max 99
	AUGMENT    ## Crafted buff items, non-stackable, slotted into equipment
}

enum AugmentType {
	NONE,            ## Not an augment item
	STAT_BOOST,      ## Pure stat increase (ATK, DEF, HP, SPD)
	PASSIVE_EFFECT,  ## On-hit / on-damaged passive (life steal, burn, thorns, etc.)
	ACTIVE_SKILL,    ## Grants an activatable skill when slotted
	TIMED_BUFF       ## Consumable-style — used from inventory for temporary buff
}

enum PassiveEffect {
	NONE,
	LIFE_STEAL,     ## Heal % of damage dealt
	CRIT_CHANCE,    ## % chance for 2× damage
	THORNS,         ## Reflect % damage back to attacker on hit received
	BURN_ON_HIT,    ## Apply burn DoT on hit
	FREEZE_ON_HIT,  ## Apply slow on hit
	POISON_ON_HIT   ## Apply poison DoT on hit
}

enum ItemRarity {
	COMMON,      # White/Gray
	UNCOMMON,    # Green
	RARE,        # Blue
	EPIC,        # Purple
	LEGENDARY    # Orange/Gold
}

@export_category("Basic Info")
@export var id: String = ""
@export var name: String = "Item"
@export var description: String = ""
@export var icon: Texture2D
@export var item_type: ItemType = ItemType.MATERIAL
@export var rarity: ItemRarity = ItemRarity.COMMON

@export_category("Icon from Atlas")
## Use icon from sprite sheet atlas instead of individual texture
@export var use_atlas_icon: bool = false
## Icon name from ItemIconAtlas.ICONS (e.g., "sword_iron", "potion_health")
@export var atlas_icon_name: String = ""
## Or specify row/column directly in sprite sheet
@export var atlas_row: int = 0
@export var atlas_col: int = 0

@export_category("Stacking")
@export var stackable: bool = true
@export var max_stack: int = 99

@export_category("Value")
@export var buy_price: int = 0
@export var sell_price: int = 0

@export_category("Equipment Stats")
@export var attack_bonus: int = 0
@export var defense_bonus: int = 0
@export var health_bonus: int = 0
@export var speed_bonus: float = 0.0

@export_category("Consumable Effects")
@export var heal_amount: int = 0
@export var stamina_restore: float = 0.0
@export var effect_duration: float = 0.0

@export_category("Augment Properties")
@export var augment_type: AugmentType = AugmentType.NONE
@export var passive_effect: PassiveEffect = PassiveEffect.NONE
@export var passive_value: float = 0.0          ## e.g. 5.0 = 5% life steal, 10.0 = 10% crit
@export var active_skill_id: String = ""        ## Links to SkillData.id (e.g. "whirlwind")
@export var buff_duration: float = 0.0          ## > 0 means timed consumable buff; 0 = permanent augment

## Augments slotted into this equipment instance (array of augment item IDs)
## Only populated on duplicated equipment instances, never on ItemDatabase templates
var applied_augments: Array[String] = []


## Get the color associated with item rarity
func get_rarity_color() -> Color:
	match rarity:
		ItemRarity.COMMON:
			return Color(0.7, 0.7, 0.7, 1.0)  # Gray
		ItemRarity.UNCOMMON:
			return Color(0.3, 0.8, 0.3, 1.0)  # Green
		ItemRarity.RARE:
			return Color(0.3, 0.5, 1.0, 1.0)  # Blue
		ItemRarity.EPIC:
			return Color(0.7, 0.3, 0.9, 1.0)  # Purple
		ItemRarity.LEGENDARY:
			return Color(1.0, 0.6, 0.1, 1.0)  # Orange
		_:
			return Color.WHITE


## Check if this item can be equipped
func is_equippable() -> bool:
	return item_type in [
		ItemType.WEAPON,
		ItemType.ARMOR,
		ItemType.HELMET,
		ItemType.BOOTS,
		ItemType.SHIELD,
		ItemType.ACCESSORY
	]


## Check if this item is consumable
func is_consumable() -> bool:
	return item_type == ItemType.CONSUMABLE or is_timed_buff()


## Returns how many augment slots this equipment has, based on rarity
## Only equippable items have slots. Common=0, Uncommon=1, Rare=2, Epic=3, Legendary=4
func get_augment_slot_count() -> int:
	if not is_equippable():
		return 0
	match rarity:
		ItemRarity.COMMON:    return 0
		ItemRarity.UNCOMMON:  return 1
		ItemRarity.RARE:      return 2
		ItemRarity.EPIC:      return 3
		ItemRarity.LEGENDARY: return 4
		_: return 0


## True if this equipment piece can accept augments (has at least 1 slot and isn't full)
func is_augmentable() -> bool:
	return get_augment_slot_count() > 0 and applied_augments.size() < get_augment_slot_count()


## True if this is a SEGMENT or MATERIAL (valid crafting input)
func is_crafting_material() -> bool:
	return item_type in [ItemType.SEGMENT, ItemType.MATERIAL]


## True if this is an AUGMENT item that can be slotted into equipment
func is_augment() -> bool:
	return item_type == ItemType.AUGMENT and augment_type != AugmentType.TIMED_BUFF


## True if this is a timed buff consumable (crafted via AUGMENT type but used like a consumable)
func is_timed_buff() -> bool:
	return item_type == ItemType.AUGMENT and augment_type == AugmentType.TIMED_BUFF


## Get the icon texture (supports both direct texture and atlas)
func get_icon() -> Texture2D:
	if use_atlas_icon:
		# Debug: Check if atlas is initialized
		if ItemIconAtlas.sprite_sheet == null:
			push_warning("[ItemData] Atlas not initialized when getting icon for: %s" % id)
			return null
		
		# Try named icon first
		if not atlas_icon_name.is_empty():
			var atlas_icon := ItemIconAtlas.get_named_icon(atlas_icon_name)
			if atlas_icon:
				return atlas_icon
			else:
				push_warning("[ItemData] Named icon '%s' not found for item: %s" % [atlas_icon_name, id])
		# Fall back to row/col
		return ItemIconAtlas.get_icon(atlas_row, atlas_col)
	return icon
