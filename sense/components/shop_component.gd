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
	
	if not player.stats:
		push_error("ShopComponent: Player has no stats!")
		purchase_failed.emit("Player has no stats", item)
		return false
	
	var stats: CharacterStats = player.stats
	var price: int = item.get("price", 0)
	var item_name: String = item.get("name", "Unknown")
	
	# Check if player has enough gold
	if stats.gold >= price:
		stats.gold -= price
		print("Purchased %s for %d gold! Remaining: %d gold" % [item_name, price, stats.gold])
		purchase_successful.emit(item, stats.gold)
		# TODO: Add item to player inventory
		return true
	else:
		print("Not enough gold! Need %d, have %d" % [price, stats.gold])
		purchase_failed.emit("Not enough gold", item)
		return false

## Get player's current gold amount
func get_player_gold() -> int:
	var player = get_tree().get_first_node_in_group("player")
	if player and player.stats:
		return player.stats.gold
	return 0
