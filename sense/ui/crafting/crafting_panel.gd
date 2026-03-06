extends Panel
class_name CraftingPanel

## Crafting panel UI - displays crafting recipes and handles crafting

signal item_crafted(item_id: String)

@onready var recipe_list: VBoxContainer = $MarginContainer/VBoxContainer/RecipeContainer/RecipeList
@onready var crafting_title: Label = $MarginContainer/VBoxContainer/CraftingTitle

var available_recipes: Array[Dictionary] = []
var player_inventory: InventoryData = null

func _ready() -> void:
	_load_crafting_recipes()

## Load crafting recipes
func _load_crafting_recipes() -> void:
	# TODO: Load from a crafting database
	# For now, create some example recipes
	available_recipes = [
		{
			"id": "iron_sword",
			"name": "Iron Sword",
			"result_item_id": "iron_sword",
			"ingredients": [
				{"item_id": "iron_ore", "quantity": 3},
				{"item_id": "wood", "quantity": 1}
			],
			"crafting_cost": 50
		},
		{
			"id": "steel_sword",
			"name": "Steel Sword",
			"result_item_id": "steel_sword",
			"ingredients": [
				{"item_id": "steel_ore", "quantity": 3},
				{"item_id": "wood", "quantity": 1}
			],
			"crafting_cost": 100
		}
	]
	
	_refresh_recipes()

## Set player inventory data
func set_player_inventory(inventory_data: InventoryData) -> void:
	player_inventory = inventory_data
	if player_inventory:
		player_inventory.inventory_changed.connect(_refresh_recipes)
	_refresh_recipes()

## Refresh the recipes display
func _refresh_recipes() -> void:
	if not recipe_list:
		return
	# Clear existing recipe items
	for child in recipe_list.get_children():
		child.queue_free()
	
	if available_recipes.is_empty():
		var no_recipe_label := Label.new()
		no_recipe_label.text = "No recipes available yet.\nComplete quests to unlock recipes!"
		no_recipe_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_recipe_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		no_recipe_label.add_theme_font_size_override("font_size", 14)
		no_recipe_label.modulate = Color(0.7, 0.7, 0.7, 1.0)
		recipe_list.add_child(no_recipe_label)
		return
	
	# Create recipe items
	for recipe in available_recipes:
		var recipe_row := _create_recipe_row(recipe)
		recipe_list.add_child(recipe_row)

## Create a recipe row UI element
func _create_recipe_row(recipe: Dictionary) -> PanelContainer:
	var row := PanelContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.custom_minimum_size.y = 80
	
	# Add padding
	row.add_theme_constant_override("margin_left", 8)
	row.add_theme_constant_override("margin_right", 8)
	row.add_theme_constant_override("margin_top", 8)
	row.add_theme_constant_override("margin_bottom", 8)
	
	# Style panel
	var style_normal := StyleBoxFlat.new()
	style_normal.bg_color = Color(0.1, 0.1, 0.1, 0.5)
	style_normal.border_color = Color(0.3, 0.3, 0.3, 0.8)
	style_normal.set_border_width_all(1)
	style_normal.set_corner_radius_all(4)
	
	var style_hover := StyleBoxFlat.new()
	style_hover.bg_color = Color(0.2, 0.2, 0.25, 0.8)
	style_hover.border_color = Color(0.6, 0.6, 0.2, 1.0)
	style_hover.set_border_width_all(2)
	style_hover.set_corner_radius_all(4)
	
	row.add_theme_stylebox_override("panel", style_normal)
	
	# Check if player can craft this recipe
	var can_craft := _can_craft_recipe(recipe)
	
	# Make row clickable
	var click_detector := Button.new()
	click_detector.flat = true
	click_detector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	click_detector.size_flags_vertical = Control.SIZE_EXPAND_FILL
	click_detector.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	click_detector.disabled = not can_craft
	
	# Hover effects
	if can_craft:
		click_detector.mouse_entered.connect(func():
			row.add_theme_stylebox_override("panel", style_hover)
		)
		click_detector.mouse_exited.connect(func():
			row.add_theme_stylebox_override("panel", style_normal)
		)
		click_detector.pressed.connect(func():
			_on_craft_requested(recipe)
		)
	else:
		# Grey out if can't craft
		style_normal.bg_color = Color(0.08, 0.08, 0.08, 0.5)
		style_normal.border_color = Color(0.2, 0.2, 0.2, 0.8)
		row.add_theme_stylebox_override("panel", style_normal)
	
	row.add_child(click_detector)
	
	# Content container
	var content := VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	click_detector.add_child(content)
	
	# Recipe name
	var name_lbl := Label.new()
	name_lbl.text = recipe.get("name", "Unknown Recipe")
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not can_craft:
		name_lbl.modulate = Color(0.5, 0.5, 0.5, 1.0)
	content.add_child(name_lbl)
	
	# Ingredients
	var ingredients_hbox := HBoxContainer.new()
	ingredients_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var ingredients_lbl := Label.new()
	var ingredients_text := "Requires: "
	var recipe_ingredients: Array = recipe.get("ingredients", [])
	for i: int in range(recipe_ingredients.size()):
		var ingredient: Dictionary = recipe_ingredients[i]
		ingredients_text += str(ingredient.get("quantity", 1)) + "x " + str(ingredient.get("item_id", "???"))
		if i < recipe_ingredients.size() - 1:
			ingredients_text += ", "
	ingredients_lbl.text = ingredients_text
	ingredients_lbl.add_theme_font_size_override("font_size", 11)
	ingredients_lbl.modulate = Color(0.7, 0.7, 0.7, 1.0)
	ingredients_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ingredients_hbox.add_child(ingredients_lbl)
	
	content.add_child(ingredients_hbox)
	
	# Cost
	var cost_lbl := Label.new()
	cost_lbl.text = "Cost: %d G" % recipe.get("crafting_cost", 0)
	cost_lbl.add_theme_font_size_override("font_size", 12)
	cost_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3, 1.0))
	cost_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(cost_lbl)
	
	return row

## Check if player can craft a recipe
func _can_craft_recipe(recipe: Dictionary) -> bool:
	if not player_inventory:
		return false
	
	# Check gold
	if player_inventory.gold < int(recipe.get("crafting_cost", 0)):
		return false
	
	# Check ingredients
	var check_ingredients: Array = recipe.get("ingredients", [])
	for ingredient: Dictionary in check_ingredients:
		var item_id: String = ingredient.get("item_id", "")
		var required_qty: int = ingredient.get("quantity", 1)
		var player_qty: int = player_inventory.get_item_count(item_id)
		
		if player_qty < required_qty:
			return false
	
	return true

## Handle craft request
func _on_craft_requested(recipe: Dictionary) -> void:
	if not player_inventory:
		return
	
	if not _can_craft_recipe(recipe):
		print("Cannot craft - missing ingredients or gold")
		return
	
	# Deduct cost
	player_inventory.gold -= int(recipe.get("crafting_cost", 0))
	
	# Remove ingredients
	var craft_ingredients: Array = recipe.get("ingredients", [])
	for ingredient: Dictionary in craft_ingredients:
		var item_id: String = ingredient.get("item_id", "")
		var required_qty: int = ingredient.get("quantity", 1)
		
		# Get the ItemData from database
		var item_data: ItemData = ItemDatabase.get_item(item_id)
		if item_data:
			player_inventory.remove_item(item_data, required_qty)
	
	# Add crafted item
	var result_item_id: String = recipe.get("result_item_id", "")
	if result_item_id != "":
		var item_data: ItemData = ItemDatabase.get_item(result_item_id)
		if item_data:
			player_inventory.add_item(item_data)
			print("Crafted: ", recipe.get("name", "Unknown"))
			item_crafted.emit(result_item_id)
	
	_refresh_recipes()