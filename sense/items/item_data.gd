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
	QUEST
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
	return item_type == ItemType.CONSUMABLE


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
