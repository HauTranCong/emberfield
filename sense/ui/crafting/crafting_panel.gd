extends Panel
class_name CraftingPanel

## ╔═══════════════════════════════════════════════════════════════════════╗
## ║                       CRAFTING PANEL                                   ║
## ╠═══════════════════════════════════════════════════════════════════════╣
## ║  Displays recipes from RecipeDatabase with tiered crafting.            ║
## ║  Can be embedded (smith shop) or standalone (CraftingStation).         ║
## ║                                                                       ║
## ║  Layout:                                                              ║
## ║  ┌─────────────────────────────────────────────────────────────┐       ║
## ║  │  [Augments] [Buffs] [All]          ← category tabs          │       ║
## ║  │  ─────────────────────────────────────────────────────────  │       ║
## ║  │  Recipe List  │  Recipe Detail                              │       ║
## ║  │  ┌──────────┐ │  Name: Flame Augment                       │       ║
## ║  │  │ Flame    │ │  Description: Imbue with fire               │       ║
## ║  │  │ Frost    │ │  [T1] [T2] [T3]                            │       ║
## ║  │  │ Power    │ │  ──────                                     │       ║
## ║  │  │ Life...  │ │  Ingredients:                               │       ║
## ║  │  │          │ │    3x fire_shard (3/3) ✓                    │       ║
## ║  │  │          │ │    2x iron_ore  (1/2) ✗                     │       ║
## ║  │  │          │ │  ──────                                     │       ║
## ║  │  │          │ │  Output: Flame Augment I                    │       ║
## ║  │  │          │ │  +5 ATK, Burn 3.0 dmg/s                    │       ║
## ║  │  │          │ │  [Craft]                                    │       ║
## ║  │  └──────────┘ │                                             │       ║
## ║  └─────────────────────────────────────────────────────────────┘       ║
## ╚═══════════════════════════════════════════════════════════════════════╝

signal item_crafted(item_id: String)

var player_inventory: InventoryData = null
var selected_recipe: CraftingRecipe = null
var selected_tier: int = 1
var current_category: String = "ALL"

## UI node references — built programmatically in _ready()
var category_tabs: HBoxContainer
var recipe_list_container: VBoxContainer
var detail_container: VBoxContainer
var detail_name_label: Label
var detail_desc_label: Label
var tier_buttons_container: HBoxContainer
var ingredients_container: VBoxContainer
var output_container: VBoxContainer
var craft_button: Button
var no_selection_label: Label


func _ready() -> void:
	_build_ui()


## Set player inventory data (called by smith shop or standalone popup)
func set_player_inventory(inventory_data: InventoryData) -> void:
	player_inventory = inventory_data
	if player_inventory and not player_inventory.inventory_changed.is_connected(_refresh_all):
		player_inventory.inventory_changed.connect(_refresh_all)
	_refresh_all()


## Initialize from UIPopupComponent data dict
func initialize(data: Dictionary) -> void:
	if data.has("inventory"):
		set_player_inventory(data["inventory"])


# =============================================================================
# UI CONSTRUCTION
# =============================================================================

func _build_ui() -> void:
	# Clear existing children (in case this is in a .tscn with placeholder nodes)
	for child in get_children():
		child.queue_free()

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)

	var root_vbox := VBoxContainer.new()
	root_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(root_vbox)

	# Title
	var title := Label.new()
	title.text = "Crafting Station"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4, 1.0))
	root_vbox.add_child(title)

	# Category tabs
	category_tabs = HBoxContainer.new()
	category_tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	category_tabs.add_theme_constant_override("separation", 8)
	root_vbox.add_child(category_tabs)
	_create_category_tabs()

	# Separator
	var sep1 := HSeparator.new()
	root_vbox.add_child(sep1)

	# Main content: recipe list (left) + detail (right)
	var content_hbox := HBoxContainer.new()
	content_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_hbox.add_theme_constant_override("separation", 10)
	root_vbox.add_child(content_hbox)

	# LEFT: Recipe list in scroll container
	var list_scroll := ScrollContainer.new()
	list_scroll.custom_minimum_size.x = 180
	list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content_hbox.add_child(list_scroll)

	recipe_list_container = VBoxContainer.new()
	recipe_list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_scroll.add_child(recipe_list_container)

	# Vertical separator between list and detail
	var vsep := VSeparator.new()
	content_hbox.add_child(vsep)

	# RIGHT: Detail panel in scroll container
	var detail_scroll := ScrollContainer.new()
	detail_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content_hbox.add_child(detail_scroll)

	detail_container = VBoxContainer.new()
	detail_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_container.add_theme_constant_override("separation", 6)
	detail_scroll.add_child(detail_container)

	# No-selection placeholder
	no_selection_label = Label.new()
	no_selection_label.text = "Select a recipe to view details."
	no_selection_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	no_selection_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	no_selection_label.modulate = Color(0.6, 0.6, 0.6, 1.0)
	no_selection_label.add_theme_font_size_override("font_size", 14)
	detail_container.add_child(no_selection_label)

	# Detail: recipe name
	detail_name_label = Label.new()
	detail_name_label.add_theme_font_size_override("font_size", 16)
	detail_name_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5, 1.0))
	detail_name_label.visible = false
	detail_container.add_child(detail_name_label)

	# Detail: description
	detail_desc_label = Label.new()
	detail_desc_label.add_theme_font_size_override("font_size", 12)
	detail_desc_label.modulate = Color(0.8, 0.8, 0.8, 1.0)
	detail_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_desc_label.visible = false
	detail_container.add_child(detail_desc_label)

	# Detail: tier buttons
	tier_buttons_container = HBoxContainer.new()
	tier_buttons_container.add_theme_constant_override("separation", 6)
	tier_buttons_container.visible = false
	detail_container.add_child(tier_buttons_container)

	# Separator
	var sep2 := HSeparator.new()
	sep2.name = "IngredientSep"
	detail_container.add_child(sep2)

	# Detail: ingredients
	var ing_title := Label.new()
	ing_title.name = "IngredientsTitle"
	ing_title.text = "Ingredients:"
	ing_title.add_theme_font_size_override("font_size", 13)
	ing_title.visible = false
	detail_container.add_child(ing_title)

	ingredients_container = VBoxContainer.new()
	ingredients_container.add_theme_constant_override("separation", 2)
	detail_container.add_child(ingredients_container)

	# Separator
	var sep3 := HSeparator.new()
	sep3.name = "OutputSep"
	detail_container.add_child(sep3)

	# Detail: output preview
	var out_title := Label.new()
	out_title.name = "OutputTitle"
	out_title.text = "Result:"
	out_title.add_theme_font_size_override("font_size", 13)
	out_title.visible = false
	detail_container.add_child(out_title)

	output_container = VBoxContainer.new()
	output_container.add_theme_constant_override("separation", 2)
	detail_container.add_child(output_container)

	# Craft button
	craft_button = Button.new()
	craft_button.text = "Craft"
	craft_button.custom_minimum_size = Vector2(120, 36)
	craft_button.disabled = true
	craft_button.visible = false
	craft_button.pressed.connect(_on_craft_pressed)
	var btn_center := HBoxContainer.new()
	btn_center.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_center.add_child(craft_button)
	detail_container.add_child(btn_center)


func _create_category_tabs() -> void:
	for child in category_tabs.get_children():
		child.queue_free()

	var categories := ["All", "Augments", "Buffs"]
	var btn_group := ButtonGroup.new()

	for cat_name in categories:
		var btn := Button.new()
		btn.text = cat_name
		btn.toggle_mode = true
		btn.button_group = btn_group
		btn.custom_minimum_size = Vector2(80, 28)
		btn.add_theme_font_size_override("font_size", 13)
		if cat_name == "All":
			btn.button_pressed = true
		btn.pressed.connect(_on_category_tab_pressed.bind(cat_name))
		category_tabs.add_child(btn)


# =============================================================================
# RECIPE LIST
# =============================================================================

func _populate_recipe_list() -> void:
	for child in recipe_list_container.get_children():
		child.queue_free()

	var recipes: Array = _get_filtered_recipes()

	if recipes.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No recipes available."
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.modulate = Color(0.6, 0.6, 0.6, 1.0)
		empty_label.add_theme_font_size_override("font_size", 12)
		recipe_list_container.add_child(empty_label)
		return

	for recipe: CraftingRecipe in recipes:
		var row := _create_recipe_list_row(recipe)
		recipe_list_container.add_child(row)


func _create_recipe_list_row(recipe: CraftingRecipe) -> PanelContainer:
	var row := PanelContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.custom_minimum_size.y = 40

	var is_selected := (selected_recipe != null and selected_recipe.id == recipe.id)
	var can_craft_any := player_inventory != null and recipe.get_highest_craftable_tier(player_inventory) > 0

	# Styles
	var style_normal := StyleBoxFlat.new()
	style_normal.set_corner_radius_all(4)
	style_normal.set_border_width_all(1)

	if is_selected:
		style_normal.bg_color = Color(0.2, 0.25, 0.35, 0.9)
		style_normal.border_color = Color(0.6, 0.7, 1.0, 1.0)
	elif can_craft_any:
		style_normal.bg_color = Color(0.12, 0.12, 0.12, 0.6)
		style_normal.border_color = Color(0.4, 0.5, 0.3, 0.8)
	else:
		style_normal.bg_color = Color(0.08, 0.08, 0.08, 0.5)
		style_normal.border_color = Color(0.2, 0.2, 0.2, 0.6)

	var style_hover := StyleBoxFlat.new()
	style_hover.bg_color = Color(0.2, 0.22, 0.28, 0.8)
	style_hover.border_color = Color(0.6, 0.6, 0.3, 1.0)
	style_hover.set_border_width_all(2)
	style_hover.set_corner_radius_all(4)

	row.add_theme_stylebox_override("panel", style_normal)

	var btn := Button.new()
	btn.flat = true
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.mouse_entered.connect(func(): row.add_theme_stylebox_override("panel", style_hover))
	btn.mouse_exited.connect(func(): row.add_theme_stylebox_override("panel", style_normal))
	btn.pressed.connect(_on_recipe_selected.bind(recipe))
	row.add_child(btn)

	# Recipe name label
	var name_lbl := Label.new()
	name_lbl.text = recipe.recipe_name
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not can_craft_any:
		name_lbl.modulate = Color(0.5, 0.5, 0.5, 1.0)
	btn.add_child(name_lbl)

	return row


func _get_filtered_recipes() -> Array:
	match current_category:
		"Augments":
			return RecipeDatabase.get_recipes_by_category(CraftingRecipe.RecipeCategory.AUGMENT)
		"Buffs":
			return RecipeDatabase.get_recipes_by_category(CraftingRecipe.RecipeCategory.CONSUMABLE_BUFF)
		_:
			return RecipeDatabase.get_all_recipes()


# =============================================================================
# DETAIL PANEL
# =============================================================================

func _refresh_detail() -> void:
	# Clear dynamic containers
	for child in ingredients_container.get_children():
		child.queue_free()
	for child in output_container.get_children():
		child.queue_free()

	if selected_recipe == null:
		_set_detail_visibility(false)
		no_selection_label.visible = true
		return

	no_selection_label.visible = false
	_set_detail_visibility(true)

	# Recipe name and description
	detail_name_label.text = selected_recipe.recipe_name
	detail_desc_label.text = selected_recipe.description

	# Tier buttons
	_rebuild_tier_buttons()

	# Ingredients for selected tier
	_rebuild_ingredients()

	# Output preview
	_rebuild_output_preview()

	# Craft button state
	var can_craft := selected_recipe.can_craft(player_inventory, selected_tier) if player_inventory else false
	craft_button.disabled = not can_craft
	craft_button.modulate = Color(1, 1, 1, 1) if can_craft else Color(0.5, 0.5, 0.5, 1)


func _set_detail_visibility(vis: bool) -> void:
	detail_name_label.visible = vis
	detail_desc_label.visible = vis
	tier_buttons_container.visible = vis
	craft_button.visible = vis

	# Show/hide separator and titles
	for child in detail_container.get_children():
		if child.name in ["IngredientSep", "OutputSep", "IngredientsTitle", "OutputTitle"]:
			child.visible = vis


func _rebuild_tier_buttons() -> void:
	for child in tier_buttons_container.get_children():
		child.queue_free()

	var max_tier := selected_recipe.get_max_tier()
	if max_tier <= 1:
		tier_buttons_container.visible = false
		return

	tier_buttons_container.visible = true
	var btn_group := ButtonGroup.new()

	for t in range(1, max_tier + 1):
		var btn := Button.new()
		btn.text = "Tier %d" % t
		btn.toggle_mode = true
		btn.button_group = btn_group
		btn.custom_minimum_size = Vector2(64, 26)
		btn.add_theme_font_size_override("font_size", 12)
		if t == selected_tier:
			btn.button_pressed = true
		var can_craft_tier := selected_recipe.can_craft(player_inventory, t) if player_inventory else false
		if not can_craft_tier:
			btn.modulate = Color(0.6, 0.6, 0.6, 1.0)
		btn.pressed.connect(_on_tier_selected.bind(t))
		tier_buttons_container.add_child(btn)


func _rebuild_ingredients() -> void:
	var ingredients := selected_recipe.get_ingredients(selected_tier)

	for ingredient: Dictionary in ingredients:
		var item_id: String = ingredient.get("item_id", "")
		var required_qty: int = ingredient.get("quantity", 0)
		var owned_qty: int = player_inventory.get_item_count(item_id) if player_inventory else 0
		var item_data: ItemData = ItemDatabase.get_item(item_id)
		var display_name: String = item_data.name if item_data else item_id

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 6)

		# Icon (small)
		if item_data:
			var icon_rect := TextureRect.new()
			icon_rect.custom_minimum_size = Vector2(20, 20)
			icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var icon: Texture2D = _get_item_icon(item_data)
			if icon:
				icon_rect.texture = icon
			hbox.add_child(icon_rect)

		# Name + quantity
		var has_enough := owned_qty >= required_qty
		var lbl := Label.new()
		lbl.text = "%s  (%d/%d)" % [display_name, owned_qty, required_qty]
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if has_enough:
			lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4, 1.0))
		else:
			lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4, 1.0))
		hbox.add_child(lbl)

		ingredients_container.add_child(hbox)


func _rebuild_output_preview() -> void:
	var result_id := selected_recipe.get_result_item_id(selected_tier)
	var result_qty := selected_recipe.get_result_quantity(selected_tier)
	var result_item: ItemData = ItemDatabase.get_item(result_id)

	if result_item == null:
		var lbl := Label.new()
		lbl.text = "Unknown output: %s" % result_id
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.modulate = Color(1.0, 0.4, 0.4, 1.0)
		output_container.add_child(lbl)
		return

	# Output item row
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)

	# Icon
	var icon_rect := TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(32, 32)
	icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon: Texture2D = _get_item_icon(result_item)
	if icon:
		icon_rect.texture = icon
	hbox.add_child(icon_rect)

	# Name with rarity color
	var name_lbl := Label.new()
	var qty_text := " x%d" % result_qty if result_qty > 1 else ""
	name_lbl.text = result_item.name + qty_text
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", result_item.get_rarity_color())
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(name_lbl)

	output_container.add_child(hbox)

	# Stat summary
	var stats_text := _get_output_stats_text(result_item)
	if stats_text != "":
		var stats_lbl := Label.new()
		stats_lbl.text = stats_text
		stats_lbl.add_theme_font_size_override("font_size", 11)
		stats_lbl.modulate = Color(0.7, 0.9, 0.7, 1.0)
		stats_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		output_container.add_child(stats_lbl)


func _get_output_stats_text(item: ItemData) -> String:
	var parts: Array[String] = []

	if item.attack_bonus > 0:
		parts.append("+%d ATK" % item.attack_bonus)
	if item.defense_bonus > 0:
		parts.append("+%d DEF" % item.defense_bonus)
	if item.health_bonus > 0:
		parts.append("+%d HP" % item.health_bonus)
	if item.speed_bonus > 0:
		parts.append("+%.0f SPD" % item.speed_bonus)

	if item.item_type == ItemData.ItemType.AUGMENT:
		match item.augment_type:
			ItemData.AugmentType.PASSIVE_EFFECT:
				parts.append(_get_passive_effect_text(item.passive_effect, item.passive_value))
			ItemData.AugmentType.ACTIVE_SKILL:
				parts.append("Skill: %s" % item.active_skill_id)
			ItemData.AugmentType.TIMED_BUFF:
				parts.append("Duration: %.0fs" % item.buff_duration)

	return "  ".join(parts)


func _get_passive_effect_text(effect: ItemData.PassiveEffect, value: float) -> String:
	match effect:
		ItemData.PassiveEffect.LIFE_STEAL:    return "Life Steal %.0f%%" % value
		ItemData.PassiveEffect.CRIT_CHANCE:   return "Crit +%.0f%%" % value
		ItemData.PassiveEffect.THORNS:        return "Thorns %.0f%%" % value
		ItemData.PassiveEffect.BURN_ON_HIT:   return "Burn %.0f dmg/s" % value
		ItemData.PassiveEffect.FREEZE_ON_HIT: return "Freeze %.0f%%" % value
		ItemData.PassiveEffect.POISON_ON_HIT: return "Poison %.0f dmg/s" % value
		_: return ""


# =============================================================================
# CRAFTING EXECUTION
# =============================================================================

func _on_craft_pressed() -> void:
	if selected_recipe == null or player_inventory == null:
		return
	if not selected_recipe.can_craft(player_inventory, selected_tier):
		return
	_execute_craft()


func _execute_craft() -> void:
	# Consume ingredients
	var ingredients := selected_recipe.get_ingredients(selected_tier)
	for ingredient: Dictionary in ingredients:
		var item_id: String = ingredient.get("item_id", "")
		var qty: int = ingredient.get("quantity", 0)
		var item_data: ItemData = ItemDatabase.get_item(item_id)
		if item_data:
			player_inventory.remove_item(item_data, qty)

	# Add result item
	var result_id := selected_recipe.get_result_item_id(selected_tier)
	var result_qty := selected_recipe.get_result_quantity(selected_tier)
	var result_item: ItemData = ItemDatabase.get_item_copy(result_id)
	if result_item:
		player_inventory.add_item(result_item, result_qty)

	item_crafted.emit(result_id)
	GameEvent.item_crafted.emit(selected_recipe.id, selected_tier)
	_refresh_all()


# =============================================================================
# EVENT HANDLERS
# =============================================================================

func _on_recipe_selected(recipe: CraftingRecipe) -> void:
	selected_recipe = recipe
	selected_tier = 1
	_refresh_all()


func _on_tier_selected(tier: int) -> void:
	selected_tier = tier
	_refresh_detail()


func _on_category_tab_pressed(cat_name: String) -> void:
	current_category = cat_name
	selected_recipe = null
	selected_tier = 1
	_refresh_all()


func _refresh_all() -> void:
	_populate_recipe_list()
	_refresh_detail()


# =============================================================================
# UTILITY
# =============================================================================

func _get_item_icon(item_data: ItemData) -> Texture2D:
	if item_data.use_atlas_icon and item_data.atlas_icon_name != "":
		return ItemIconAtlas.get_named_icon(item_data.atlas_icon_name)
	elif item_data.use_atlas_icon:
		return ItemIconAtlas.get_icon(item_data.atlas_row, item_data.atlas_col)
	elif item_data.icon != null:
		return item_data.icon
	return ItemIconAtlas.get_default_icon()