extends Control
class_name SmithShopPopup

signal buy_requested(item: Dictionary)
signal close_requested

@onready var dim: ColorRect = $Dim
@onready var gold_label: Label = $Main/MainMargin/MainAlign/TitleRow/GoldLabel
@onready var main_tab_container: HBoxContainer = $Main/MainMargin/MainAlign/MainTabsRow
@onready var category_tab_container: HBoxContainer = $Main/MainMargin/MainAlign/ShopContent/CategoryTabs
@onready var shop_content: VBoxContainer = $Main/MainMargin/MainAlign/ShopContent
@onready var crafting_content: HBoxContainer = $Main/MainMargin/MainAlign/CraftingContent
@onready var crafting_panel: CraftingPanel = $Main/MainMargin/MainAlign/CraftingContent/CraftingPanel
@onready var inventory_container: Control = $Main/MainMargin/MainAlign/CraftingContent/InventoryContainer
@onready var items_list: VBoxContainer = $Main/MainMargin/MainAlign/ShopContent/ItemsScroll/ItemsList
@onready var close_btn: Button = $Main/MainMargin/MainAlign/TitleRow/Close

var _inventory: InventoryData = null

var items: Array[Dictionary] = []
var owner_npc: Node = null
var current_category: String = "ALL"
var category_buttons: Dictionary = {}
var main_tab_buttons: Dictionary = {}
var current_main_tab: String = "BUY_SELL"

enum Category {
	ALL,
	WEAPONS,
	ARMOR,
	HELMETS,
	SHIELDS,
	BOOTS,
	ACCESSORIES,
	CONSUMABLES
}

var category_filters: Dictionary = {}


func _init_category_filters() -> void:
	category_filters = {
		"ALL": [],
		"WEAPONS": [ItemData.ItemType.WEAPON],
		"ARMOR": [ItemData.ItemType.ARMOR],
		"HELMETS": [ItemData.ItemType.HELMET],
		"SHIELDS": [ItemData.ItemType.SHIELD],
		"BOOTS": [ItemData.ItemType.BOOTS],
		"ACCESSORIES": [ItemData.ItemType.ACCESSORY],
		"CONSUMABLES": [ItemData.ItemType.CONSUMABLE],
	}


func _ready() -> void:
	visible = false
	_init_category_filters()
	_create_main_tabs()
	_create_category_tabs()
	_switch_main_tab("BUY_SELL")
	_connect_signals()
	_setup_gold_display()


func _connect_signals() -> void:
	if dim and dim.has_signal("dim_clicked"):
		dim.dim_clicked.connect(_on_dim_clicked)
	if close_btn:
		close_btn.pressed.connect(_on_close_pressed)


func _setup_gold_display() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player and player.get("inventory"):
		_inventory = player.inventory
		_inventory.gold_changed.connect(_on_gold_changed)
		_update_gold_label(_inventory.gold)


func _on_gold_changed(amount: int) -> void:
	_update_gold_label(amount)


func _update_gold_label(amount: int) -> void:
	if gold_label:
		gold_label.text = "%d G" % amount


func _create_main_tabs() -> void:
	if not main_tab_container:
		return
	for child in main_tab_container.get_children():
		child.queue_free()
	main_tab_buttons.clear()

	var main_tabs: Array[String] = ["BUY_SELL", "CRAFTING"]
	var main_tab_labels: Dictionary = {"BUY_SELL": "Buy/Sell", "CRAFTING": "Crafting"}

	for tab in main_tabs:
		var btn := Button.new()
		btn.text = main_tab_labels[tab]
		btn.toggle_mode = true
		if main_tab_buttons.is_empty():
			btn.button_group = ButtonGroup.new()
		else:
			btn.button_group = main_tab_buttons.values()[0].button_group
		btn.custom_minimum_size = Vector2(120, 40)
		btn.add_theme_font_size_override("font_size", 16)
		if tab == "BUY_SELL":
			btn.button_pressed = true
		btn.pressed.connect(_on_main_tab_pressed.bind(tab))
		main_tab_container.add_child(btn)
		main_tab_buttons[tab] = btn


func _on_main_tab_pressed(tab: String) -> void:
	_switch_main_tab(tab)


func _switch_main_tab(tab: String) -> void:
	current_main_tab = tab
	if tab == "BUY_SELL":
		shop_content.visible = true
		crafting_content.visible = false
	elif tab == "CRAFTING":
		shop_content.visible = false
		crafting_content.visible = true
		_setup_crafting_view()


func _setup_crafting_view() -> void:
	var current_player: Node = get_tree().get_first_node_in_group("player")
	var inv_data: InventoryData = null

	if current_player and current_player.get("inventory"):
		inv_data = current_player.inventory

	if crafting_panel and inv_data:
		crafting_panel.set_player_inventory(inv_data)

	# Only create inventory panel once
	if inventory_container.get_child_count() == 0:
		var embedded_inv := Panel.new()
		var inv_script: GDScript = preload("res://sense/ui/crafting/embedded_inventory_panel.gd")
		embedded_inv.set_script(inv_script)
		embedded_inv.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		inventory_container.add_child(embedded_inv)

	# Set inventory data on the embedded panel (it's already ready after add_child)
	if inv_data and inventory_container.get_child_count() > 0:
		var panel: Node = inventory_container.get_child(0)
		if panel.has_method("set_inventory_data"):
			panel.set_inventory_data(inv_data)


func _create_category_tabs() -> void:
	if not category_tab_container:
		return
	for child in category_tab_container.get_children():
		child.queue_free()
	category_buttons.clear()

	var categories: Array[String] = ["ALL", "WEAPONS", "ARMOR", "HELMETS", "SHIELDS", "BOOTS", "ACCESSORIES", "CONSUMABLES"]

	for category in categories:
		var btn := Button.new()
		btn.text = category.capitalize()
		btn.toggle_mode = true
		if category_buttons.is_empty():
			btn.button_group = ButtonGroup.new()
		else:
			btn.button_group = category_buttons.values()[0].button_group
		btn.custom_minimum_size = Vector2(80, 30)
		if category == "ALL":
			btn.button_pressed = true
		btn.pressed.connect(_on_category_pressed.bind(category))
		category_tab_container.add_child(btn)
		category_buttons[category] = btn


func _on_category_pressed(category: String) -> void:
	_on_category_changed(category)


func _on_category_changed(category: String) -> void:
	current_category = category
	_refresh()


func initialize(data: Dictionary) -> void:
	if data.has("items"):
		set_items(data["items"])
	if data.has("owner"):
		owner_npc = data["owner"]
		if owner_npc and owner_npc.has_method("_on_purchase_requested"):
			buy_requested.connect(owner_npc._on_purchase_requested)


func set_items(new_items: Array[Dictionary]) -> void:
	items = new_items
	_refresh()


func show_popup() -> void:
	visible = true
	GameEvent.is_shop_open = true
	GameEvent.shop_opened.emit()


func hide_popup() -> void:
	GameEvent.is_shop_open = false
	GameEvent.shop_closed.emit()
	if _inventory and _inventory.gold_changed.is_connected(_on_gold_changed):
		_inventory.gold_changed.disconnect(_on_gold_changed)
	visible = false
	queue_free()


func _on_close_pressed() -> void:
	hide_popup()
	close_requested.emit()


func _on_dim_clicked(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		hide_popup()


func _refresh() -> void:
	for c in items_list.get_children():
		c.queue_free()

	var filtered_items := _filter_items_by_category(items, current_category)
	filtered_items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.get("price", 0) < b.get("price", 0))

	for it in filtered_items:
		var row := PanelContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.custom_minimum_size.y = 50

		row.add_theme_constant_override("margin_left", 8)
		row.add_theme_constant_override("margin_right", 8)
		row.add_theme_constant_override("margin_top", 8)
		row.add_theme_constant_override("margin_bottom", 8)

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

		var click_detector := Button.new()
		click_detector.flat = true
		click_detector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		click_detector.size_flags_vertical = Control.SIZE_EXPAND_FILL
		click_detector.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

		click_detector.mouse_entered.connect(func() -> void:
			row.add_theme_stylebox_override("panel", style_hover)
		)
		click_detector.mouse_exited.connect(func() -> void:
			row.add_theme_stylebox_override("panel", style_normal)
		)
		click_detector.pressed.connect(func() -> void:
			emit_signal("buy_requested", it)
		)

		row.add_child(click_detector)

		var content := HBoxContainer.new()
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_theme_constant_override("separation", 8)
		click_detector.add_child(content)

		if it.has("icon") and it["icon"] != null:
			var icon_rect := TextureRect.new()
			icon_rect.texture = it["icon"]
			icon_rect.custom_minimum_size = Vector2(32, 32)
			icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			content.add_child(icon_rect)

		var info_vbox := VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var name_lbl := Label.new()
		name_lbl.text = str(it.get("name", "Unknown"))
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var stats_text := ""
		if it.has("attack_bonus") and it["attack_bonus"] > 0:
			stats_text += " (+%d ATK)" % it["attack_bonus"]
		if it.has("defense_bonus") and it.get("defense_bonus", 0) > 0:
			stats_text += " (+%d DEF)" % it["defense_bonus"]
		if it.has("speed_bonus") and it.get("speed_bonus", 0) != 0:
			var speed_val: float = it["speed_bonus"]
			stats_text += " (%+.0f%% SPD)" % speed_val

		if stats_text != "":
			name_lbl.text += stats_text

		info_vbox.add_child(name_lbl)

		if it.has("description") and it["description"] != "":
			var desc_lbl := Label.new()
			desc_lbl.text = it["description"]
			desc_lbl.add_theme_font_size_override("font_size", 10)
			desc_lbl.modulate = Color(0.7, 0.7, 0.7, 1.0)
			desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			info_vbox.add_child(desc_lbl)

		content.add_child(info_vbox)

		var price_lbl := Label.new()
		price_lbl.text = "%d G" % int(it.get("price", 0))
		price_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		price_lbl.custom_minimum_size.x = 80
		price_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		price_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		price_lbl.add_theme_font_size_override("font_size", 14)
		price_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3, 1.0))
		content.add_child(price_lbl)

		items_list.add_child(row)


func _filter_items_by_category(all_items: Array[Dictionary], category: String) -> Array[Dictionary]:
	if category == "ALL":
		return all_items

	var filters: Array = category_filters.get(category, [])
	if filters.is_empty():
		return all_items

	var filtered: Array[Dictionary] = []
	for item in all_items:
		if item.has("item_type") and item["item_type"] in filters:
			filtered.append(item)

	return filtered
