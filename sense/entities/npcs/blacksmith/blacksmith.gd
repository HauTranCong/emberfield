extends Node2D

@onready var interaction_area: InteractionArea = $interaction_area
@onready var ui_popup: UIPopupComponent = $UIPopupComponent
@onready var shop: ShopComponent = $ShopComponent

var npc_name: String = "blacksmith"
var weapons: Array[Dictionary] = [
	{"id":"w_iron_sword", "name":"Iron Sword", "price":120},
	{"id":"w_iron_axe", "name":"Iron Axe", "price":150},
	{"id":"w_bow", "name":"Hunter Bow", "price":180},
	{"id":"w_dagger", "name":"Dagger", "price":90},
]

func _ready() -> void:
	interaction_area.interact = Callable(self, "_on_interact")
	# Auto-close shop when player exits area (general approach for all NPCs)
	if ui_popup:
		ui_popup.setup_auto_close(interaction_area)

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