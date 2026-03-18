class_name CraftingRecipe
extends Resource

## ╔════════════════════════════════════════════════════════════╗
## ║                  CRAFTING RECIPE                           ║
## ╠════════════════════════════════════════════════════════════╣
## ║  Each recipe has 1-3 tiers.                               ║
## ║  Higher tiers use rarer ingredients → stronger output.    ║
## ║                                                           ║
## ║  Recipe "flame_augment":                                  ║
## ║  ┌─────┬──────────────────────────┬───────────────────┐   ║
## ║  │ T1  │ 3× fire_shard + 2× iron │ flame_augment_t1  │   ║
## ║  │ T2  │ 3× inferno + 2× gold    │ flame_augment_t2  │   ║
## ║  │ T3  │ 3× hellfire + 1× m_bone │ flame_augment_t3  │   ║
## ║  └─────┴──────────────────────────┴───────────────────┘   ║
## ╚════════════════════════════════════════════════════════════╝

enum RecipeCategory {
	AUGMENT,         ## Output is an AUGMENT item (permanent or active skill)
	CONSUMABLE_BUFF  ## Output is a timed buff item
}

@export var id: String = ""
@export var recipe_name: String = ""
@export var description: String = ""
@export var category: RecipeCategory = RecipeCategory.AUGMENT

## Array of tier definitions. Each tier is a Dictionary:
## {
##   "tier": int,                                        # 1, 2, or 3
##   "ingredients": Array[Dictionary],                   # [{"item_id": "fire_shard", "quantity": 3}, ...]
##   "result_item_id": String,                           # ID in ItemDatabase (e.g. "flame_augment_t1")
##   "result_quantity": int                              # Usually 1
## }
@export var tiers: Array[Dictionary] = []


## Check if the player can craft a specific tier
func can_craft(inventory: InventoryData, tier: int) -> bool:
	var tier_data := _get_tier_data(tier)
	if tier_data.is_empty():
		return false
	for ingredient: Dictionary in tier_data.get("ingredients", []):
		var item_id: String = ingredient.get("item_id", "")
		var quantity: int = ingredient.get("quantity", 0)
		if not inventory.has_item(item_id, quantity):
			return false
	return true


## Returns the highest tier the player can currently craft (0 = none)
func get_highest_craftable_tier(inventory: InventoryData) -> int:
	var best := 0
	for tier_data: Dictionary in tiers:
		var t: int = tier_data.get("tier", 0)
		if can_craft(inventory, t):
			best = maxi(best, t)
	return best


## Get ingredient list for a specific tier (for UI display)
func get_ingredients(tier: int) -> Array[Dictionary]:
	var tier_data := _get_tier_data(tier)
	var raw: Array = tier_data.get("ingredients", [])
	var result: Array[Dictionary] = []
	result.assign(raw)
	return result


## Get result item ID for a specific tier
func get_result_item_id(tier: int) -> String:
	var tier_data := _get_tier_data(tier)
	return tier_data.get("result_item_id", "")


## Get result quantity for a specific tier
func get_result_quantity(tier: int) -> int:
	var tier_data := _get_tier_data(tier)
	return tier_data.get("result_quantity", 1)


## Get max tier available for this recipe
func get_max_tier() -> int:
	var max_t := 0
	for t: Dictionary in tiers:
		max_t = maxi(max_t, t.get("tier", 0))
	return max_t


func _get_tier_data(tier: int) -> Dictionary:
	for t: Dictionary in tiers:
		if t.get("tier", 0) == tier:
			return t
	return {}
