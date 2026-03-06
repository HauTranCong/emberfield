extends Control
class_name SmithShopPopup

signal buy_requested(item: Dictionary)

@onready var dim: ColorRect = $Dim
@onready var items_list: VBoxContainer = $Panel/VBox/ItemsScroll/ItemsList
@onready var close_btn: Button = $Panel/VBox/TitleRow/Close
@onready var gold_label: Label = $Panel/VBox/TitleRow/GoldLabel
@onready var main_tab_container: HBoxContainer = $Panel/VBox/MainTabsRow
@onready var category_tab_container: HBoxContainer = $Panel/VBox/ShopContent/CategoryTabs
@onready var shop_content: VBoxContainer = $Panel/VBox/ShopContent
@onready var crafting_content: HBoxContainer = $Panel/VBox/CraftingContent
@onready var crafting_panel: CraftingPanel = $Panel/VBox/CraftingContent/CraftingPanel
@onready var inventory_container: Control = $Panel/VBox/CraftingContent/InventoryContainer

var _inventory: InventoryData = null

var items: Array[Dictionary] = []
var owner_npc: Node = null  # Reference to the NPC that opened this shop

# Called when the node enters the scene tree for the first time.
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
		# Connect buy signal to owner if it has a purchase handler
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
	queue_free()  # Remove from scene tree when closed

func _on_dim_clicked(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		hide_popup()

func _refresh() -> void:
	# clear list
	for c in items_list.get_children():
		c.queue_free()

	for it in items:
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var name_lbl := Label.new()
		name_lbl.text = str(it.get("name", "Unknown"))
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var price_lbl := Label.new()
		price_lbl.text = "%s G" % str(it.get("price", 0))
		price_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		price_lbl.custom_minimum_size.x = 80

		var buy_btn := Button.new()
		buy_btn.text = "Buy"
		buy_btn.pressed.connect(func():
			emit_signal("buy_requested", it)
		)

		row.add_child(name_lbl)
		row.add_child(price_lbl)
		row.add_child(buy_btn)

		items_list.add_child(row)
