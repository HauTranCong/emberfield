extends Node2D

@onready var interaction_area: InteractionArea = $interaction_area
@onready var ui_popup: UIPopupComponent = $UIPopupComponent
@onready var shop: ShopComponent = $ShopComponent

var npc_name: String = "blacksmith"
var weapons: Array[Dictionary] = []

## Which item types this shop sells
var shop_categories: Array[ItemData.ItemType] = [
	ItemData.ItemType.WEAPON,
	ItemData.ItemType.ARMOR,
	ItemData.ItemType.HELMET,
	ItemData.ItemType.SHIELD,
	ItemData.ItemType.BOOTS,
	ItemData.ItemType.ACCESSORY
]

func _ready() -> void:
	# Load items from ItemDatabase
	_load_shop_items()
	
	interaction_area.interact = Callable(self, "_on_interact")
	# Auto-close shop when player exits area (general approach for all NPCs)
	if ui_popup:
		ui_popup.setup_auto_close(interaction_area)
	
	# Connect shop signals for feedback
	if shop:
		shop.purchase_successful.connect(_on_purchase_successful)
		shop.purchase_failed.connect(_on_purchase_failed)

## Load all shop items from ItemDatabase with their icons
func _load_shop_items() -> void:
	weapons.clear()
	
	# Get all items from database that match shop categories
	for item_id in ItemDatabase.items.keys():
		var item_data: ItemData = ItemDatabase.items[item_id]
		
		# Filter only items this shop sells
		if item_data.item_type in shop_categories:
			# Get the icon texture
			var icon: AtlasTexture = null
			if item_data.use_atlas_icon and item_data.atlas_icon_name != "":
				icon = ItemIconAtlas.get_named_icon(item_data.atlas_icon_name)
			elif item_data.use_atlas_icon:
				icon = ItemIconAtlas.get_icon(item_data.atlas_row, item_data.atlas_col)
			elif item_data.icon != null:
				icon = item_data.icon
			else:
				icon = ItemIconAtlas.get_default_icon()
			
			# Create item dictionary with all relevant data
			var item_dict := {
				"id": item_data.id,
				"name": item_data.name,
				"description": item_data.description,
				"price": item_data.buy_price,
				"icon": icon,
				"attack_bonus": item_data.attack_bonus,
				"defense_bonus": item_data.defense_bonus,
				"speed_bonus": item_data.speed_bonus,
				"health_bonus": item_data.health_bonus,
				"rarity": item_data.rarity,
				"item_type": item_data.item_type
			}
			
			weapons.append(item_dict)
	
	print("[Blacksmith] Loaded %d items from ItemDatabase" % weapons.size())
	
	# Count by category
	var counts := {}
	for item in weapons:
		var type_name: String = ItemData.ItemType.keys()[item.item_type]
		counts[type_name] = counts.get(type_name, 0) + 1
	
	for type_name in counts:
		print("  - %s: %d items" % [type_name, counts[type_name]])

func _on_interact() -> void:
	print("Player is interacting with ", npc_name)
	
	if ui_popup:
		# Pass weapons data and self reference to the shop UI
		var shop_ui = ui_popup.open_ui({
			"items": weapons,
			"owner": self
		})
		
		if not shop_ui:
			print("Failed to open blacksmith shop UI")

## Called by SmithShopPopup when player clicks Buy button
func _on_purchase_requested(item: Dictionary) -> void:
	# Delegate to ShopComponent (general approach for all shops)
	shop.process_purchase(item)

## Called when purchase is successful
func _on_purchase_successful(item: Dictionary, remaining_gold: int) -> void:
	var item_name: String = item.get("name", "item")
	NotificationManager.show_success("Purchased %s! (%d G remaining)" % [item_name, remaining_gold])

func _on_purchase_failed(reason: String, item: Dictionary) -> void:
	var item_name: String = item.get("name", "item")
	match reason:
		"Not enough gold":
			NotificationManager.show_error("Not enough gold to buy %s!" % item_name)
		"Inventory full":
			NotificationManager.show_warning("Inventory full! Can't buy %s." % item_name)
		_:
			NotificationManager.show_error("Cannot purchase %s." % item_name)
