extends Node
class_name ShopComponent

## Reusable component for handling shop purchases
## Manages gold transactions and item purchases for any NPC shop
## Usage: Add as child to shop NPC, connect buy_requested signal from UI

signal purchase_successful(item: Dictionary, remaining_gold: int)
signal purchase_failed(reason: String, item: Dictionary)

## Process a purchase request from the shop UI
func process_purchase(item: Dictionary) -> bool:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		push_error("ShopComponent: Player not found!")
		purchase_failed.emit("Player not found", item)
		return false
	
	if not player.inventory:
		push_error("ShopComponent: Player has no inventory!")
		purchase_failed.emit("Player has no inventory", item)
		return false
	
	var inventory: InventoryData = player.inventory
	var price: int = item.get("price", 0)
	var item_name: String = item.get("name", "Unknown")
	var item_id: String = item.get("id", "")
	
	# Check if player has enough gold
	if inventory.gold < price:
		print("Not enough gold! Need %d, have %d" % [price, inventory.gold])
		purchase_failed.emit("Not enough gold", item)
		return false
	
	# Get item data from ItemDatabase
	var item_data: ItemData = ItemDatabase.get_item(item_id)
	if item_data == null:
		push_error("ShopComponent: Item '%s' not found in ItemDatabase!" % item_id)
		purchase_failed.emit("Item not found", item)
		return false
	
	# Try to add item to inventory
	var remaining := inventory.add_item(item_data, 1)
	if remaining > 0:
		print("Inventory full! Cannot add item.")
		purchase_failed.emit("Inventory full", item)
		return false
	
	# Success - deduct gold
	inventory.gold -= price
	print("✓ Purchased %s for %d gold! Remaining: %d gold" % [item_name, price, inventory.gold])
	purchase_successful.emit(item, inventory.gold)
	return true

## Get player's current gold amount
func get_player_gold() -> int:
	var player = get_tree().get_first_node_in_group("player")
	if player and player.inventory:
		return player.inventory.gold
	return 0
