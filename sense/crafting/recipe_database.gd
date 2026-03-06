extends Node

## ╔════════════════════════════════════════════════════════════╗
## ║  RecipeDatabase — Autoload                                ║
## ║  Mirrors the ItemDatabase pattern:                        ║
## ║  - Dictionary of CraftingRecipe keyed by recipe_id        ║
## ║  - get_recipe(id) → CraftingRecipe                        ║
## ║  - get_recipes_by_category(cat) → Array[CraftingRecipe]   ║
## ╚════════════════════════════════════════════════════════════╝

var recipes: Dictionary = {}  # recipe_id: String → CraftingRecipe


func _ready() -> void:
	_create_recipes()


func get_recipe(recipe_id: String) -> CraftingRecipe:
	return recipes.get(recipe_id)


func get_all_recipes() -> Array:
	return recipes.values()


func get_recipes_by_category(category: CraftingRecipe.RecipeCategory) -> Array:
	var result: Array = []
	for recipe: CraftingRecipe in recipes.values():
		if recipe.category == category:
			result.append(recipe)
	return result


func _create_recipes() -> void:
	# === AUGMENT RECIPES ===

	_add_recipe("flame_augment", "Flame Augment", "Imbue equipment with fire.", CraftingRecipe.RecipeCategory.AUGMENT, [
		{"tier": 1, "ingredients": [{"item_id": "fire_shard", "quantity": 3}, {"item_id": "iron_ore", "quantity": 2}], "result_item_id": "flame_augment_t1", "result_quantity": 1},
		{"tier": 2, "ingredients": [{"item_id": "inferno_shard", "quantity": 3}, {"item_id": "gold_ore", "quantity": 2}], "result_item_id": "flame_augment_t2", "result_quantity": 1},
		{"tier": 3, "ingredients": [{"item_id": "hellfire_shard", "quantity": 3}, {"item_id": "monster_bone", "quantity": 1}], "result_item_id": "flame_augment_t3", "result_quantity": 1},
	])

	_add_recipe("frost_augment", "Frost Augment", "Imbue equipment with ice.", CraftingRecipe.RecipeCategory.AUGMENT, [
		{"tier": 1, "ingredients": [{"item_id": "frost_shard", "quantity": 3}, {"item_id": "iron_ore", "quantity": 2}], "result_item_id": "frost_augment_t1", "result_quantity": 1},
		{"tier": 2, "ingredients": [{"item_id": "blizzard_shard", "quantity": 3}, {"item_id": "gold_ore", "quantity": 2}], "result_item_id": "frost_augment_t2", "result_quantity": 1},
	])

	_add_recipe("power_augment", "Power Augment", "Raw strength increase.", CraftingRecipe.RecipeCategory.AUGMENT, [
		{"tier": 1, "ingredients": [{"item_id": "power_fragment", "quantity": 3}, {"item_id": "iron_ore", "quantity": 2}], "result_item_id": "power_augment_t1", "result_quantity": 1},
		{"tier": 2, "ingredients": [{"item_id": "greater_power_fragment", "quantity": 3}, {"item_id": "gold_ore", "quantity": 2}], "result_item_id": "power_augment_t2", "result_quantity": 1},
	])

	_add_recipe("lifesteal_augment", "Lifesteal Augment", "Drain life on hit.", CraftingRecipe.RecipeCategory.AUGMENT, [
		{"tier": 1, "ingredients": [{"item_id": "spirit_essence", "quantity": 3}, {"item_id": "monster_bone", "quantity": 2}], "result_item_id": "lifesteal_augment_t1", "result_quantity": 1},
		{"tier": 2, "ingredients": [{"item_id": "spirit_essence", "quantity": 5}, {"item_id": "gold_ore", "quantity": 3}], "result_item_id": "lifesteal_augment_t2", "result_quantity": 1},
	])

	_add_recipe("crit_augment", "Critical Augment", "Increase critical strike chance.", CraftingRecipe.RecipeCategory.AUGMENT, [
		{"tier": 1, "ingredients": [{"item_id": "power_fragment", "quantity": 2}, {"item_id": "monster_bone", "quantity": 3}], "result_item_id": "crit_augment_t1", "result_quantity": 1},
		{"tier": 2, "ingredients": [{"item_id": "greater_power_fragment", "quantity": 3}, {"item_id": "monster_bone", "quantity": 5}], "result_item_id": "crit_augment_t2", "result_quantity": 1},
	])

	_add_recipe("whirlwind_augment", "Whirlwind Augment", "Grants the Whirlwind skill.", CraftingRecipe.RecipeCategory.AUGMENT, [
		{"tier": 1, "ingredients": [{"item_id": "power_fragment", "quantity": 5}, {"item_id": "fire_shard", "quantity": 3}, {"item_id": "monster_bone", "quantity": 3}], "result_item_id": "whirlwind_augment", "result_quantity": 1},
	])

	_add_recipe("shield_bash_augment", "Shield Bash Augment", "Grants the Shield Bash skill.", CraftingRecipe.RecipeCategory.AUGMENT, [
		{"tier": 1, "ingredients": [{"item_id": "frost_shard", "quantity": 3}, {"item_id": "iron_ore", "quantity": 5}, {"item_id": "monster_bone", "quantity": 2}], "result_item_id": "shield_bash_augment", "result_quantity": 1},
	])

	# === CONSUMABLE BUFF RECIPES ===

	_add_recipe("vitality_tonic", "Vitality Tonic", "Temporary max HP boost.", CraftingRecipe.RecipeCategory.CONSUMABLE_BUFF, [
		{"tier": 1, "ingredients": [{"item_id": "herb_segment", "quantity": 2}, {"item_id": "monster_bone", "quantity": 1}], "result_item_id": "vitality_tonic_t1", "result_quantity": 1},
		{"tier": 2, "ingredients": [{"item_id": "herb_segment", "quantity": 4}, {"item_id": "gold_ore", "quantity": 2}], "result_item_id": "vitality_tonic_t2", "result_quantity": 1},
	])

	_add_recipe("speed_elixir", "Speed Elixir", "Temporary movement speed boost.", CraftingRecipe.RecipeCategory.CONSUMABLE_BUFF, [
		{"tier": 1, "ingredients": [{"item_id": "herb_segment", "quantity": 2}, {"item_id": "frost_shard", "quantity": 1}], "result_item_id": "speed_elixir_t1", "result_quantity": 1},
		{"tier": 2, "ingredients": [{"item_id": "herb_segment", "quantity": 4}, {"item_id": "blizzard_shard", "quantity": 2}], "result_item_id": "speed_elixir_t2", "result_quantity": 1},
	])

	_add_recipe("defense_brew", "Defense Brew", "Temporary defense boost.", CraftingRecipe.RecipeCategory.CONSUMABLE_BUFF, [
		{"tier": 1, "ingredients": [{"item_id": "iron_ore", "quantity": 3}, {"item_id": "herb_segment", "quantity": 1}], "result_item_id": "defense_brew_t1", "result_quantity": 1},
		{"tier": 2, "ingredients": [{"item_id": "gold_ore", "quantity": 3}, {"item_id": "herb_segment", "quantity": 3}], "result_item_id": "defense_brew_t2", "result_quantity": 1},
	])


## Helper to construct and register a recipe
func _add_recipe(id: String, recipe_name: String, desc: String, category: CraftingRecipe.RecipeCategory, tier_data: Array) -> void:
	var recipe := CraftingRecipe.new()
	recipe.id = id
	recipe.recipe_name = recipe_name
	recipe.description = desc
	recipe.category = category
	recipe.tiers.assign(tier_data)
	recipes[id] = recipe
