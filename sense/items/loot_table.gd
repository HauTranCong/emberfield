class_name LootTable
extends Resource

## Loot Table - Defines item drop chances for enemies/chests
##
## ╔═══════════════════════════════════════════════════════════════════════╗
## ║                         LOOT TABLE SYSTEM                             ║
## ╠═══════════════════════════════════════════════════════════════════════╣
## ║                                                                       ║
## ║  LootTable (Resource)                                                 ║
## ║  ├── entries: Array[LootEntry]                                        ║
## ║  │   ├── item_id: String                                              ║
## ║  │   ├── weight: int (chance relative to total)                       ║
## ║  │   ├── min_quantity: int                                            ║
## ║  │   └── max_quantity: int                                            ║
## ║  │                                                                    ║
## ║  ├── guaranteed_drops: Array[String] (always drop)                    ║
## ║  ├── drop_count: int (how many rolls)                                 ║
## ║  └── gold_range: Vector2i (min, max gold)                             ║
## ║                                                                       ║
## ║  Usage:                                                               ║
## ║  var drops = loot_table.roll()                                        ║
## ║  # Returns: [{item_id, quantity}, ...]                                ║
## ║                                                                       ║
## ╚═══════════════════════════════════════════════════════════════════════╝

## Single loot entry
class LootEntry:
	var item_id: String = ""
	var weight: int = 100  # Higher = more likely
	var min_quantity: int = 1
	var max_quantity: int = 1
	
	func _init(p_item_id: String = "", p_weight: int = 100, p_min: int = 1, p_max: int = 1) -> void:
		item_id = p_item_id
		weight = p_weight
		min_quantity = p_min
		max_quantity = p_max


## Loot entries with weights
@export var entries: Array[Dictionary] = []
# Each entry: {item_id: String, weight: int, min_quantity: int, max_quantity: int}

## Items that always drop
@export var guaranteed_drops: Array[String] = []

## How many times to roll the loot table
@export var drop_count: int = 1

## Chance to drop nothing (0-100)
@export var nothing_weight: int = 50

## Gold drop range (x = min, y = max). Set both to 0 for no gold
@export var gold_range: Vector2i = Vector2i(0, 0)


## Roll the loot table and return array of drops
## Returns: Array[{item_id: String, quantity: int}]
func roll() -> Array[Dictionary]:
	var drops: Array[Dictionary] = []
	
	# Add guaranteed drops first
	for item_id in guaranteed_drops:
		drops.append({"item_id": item_id, "quantity": 1})
	
	# Calculate total weight including "nothing"
	var total_weight := nothing_weight
	for entry in entries:
		total_weight += entry.get("weight", 100)
	
	# Roll for each drop slot
	for i in range(drop_count):
		var roll_result := _roll_once(total_weight)
		if roll_result.size() > 0:
			# Check if we already have this item, stack if possible
			var found := false
			for drop in drops:
				if drop.item_id == roll_result.item_id:
					drop.quantity += roll_result.quantity
					found = true
					break
			if not found:
				drops.append(roll_result)
	
	return drops


## Roll gold amount
func roll_gold() -> int:
	if gold_range.x <= 0 and gold_range.y <= 0:
		return 0
	return randi_range(gold_range.x, gold_range.y)


## Internal: Single roll
func _roll_once(total_weight: int) -> Dictionary:
	if total_weight <= 0 or entries.size() == 0:
		return {}
	
	var roll := randi_range(1, total_weight)
	var cumulative := nothing_weight  # Start with nothing weight
	
	# If roll falls in "nothing" range
	if roll <= cumulative:
		return {}
	
	# Check each entry
	for entry in entries:
		cumulative += entry.get("weight", 100)
		if roll <= cumulative:
			var qty := randi_range(
				entry.get("min_quantity", 1),
				entry.get("max_quantity", 1)
			)
			return {
				"item_id": entry.get("item_id", ""),
				"quantity": qty
			}
	
	return {}


## Helper: Add entry programmatically
func add_entry(item_id: String, weight: int = 100, min_qty: int = 1, max_qty: int = 1) -> void:
	entries.append({
		"item_id": item_id,
		"weight": weight,
		"min_quantity": min_qty,
		"max_quantity": max_qty
	})


## Helper: Create a simple loot table with equal chances
static func create_simple(item_ids: Array[String], drop_chance: int = 50) -> LootTable:
	var table := LootTable.new()
	table.nothing_weight = 100 - drop_chance
	for item_id in item_ids:
		table.add_entry(item_id, drop_chance / item_ids.size())
	return table
