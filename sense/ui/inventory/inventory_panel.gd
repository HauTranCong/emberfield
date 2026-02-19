extends CanvasLayer

## Inventory panel UI - main inventory interface
## Uses scene nodes instead of building UI in code

signal inventory_closed
signal item_used(result: Dictionary)

const GRID_COLUMNS := 8
const INVENTORY_SIZE := 32

## Tab filter types
enum TabFilter { ALL, EQUIP, MATERIAL }

# Node references from scene
@onready var slots_grid: GridContainer = $CenterContainer/MainPanel/MainMargin/MainHBox/InventoryVBox/InventoryGrid/GridMargin/SlotsGrid
@onready var equip_grid: GridContainer = $CenterContainer/MainPanel/MainMargin/MainHBox/EquipmentPanel/EquipMargin/EquipVBox/EquipGrid

# Tab buttons
@onready var tab_all: Button = $CenterContainer/MainPanel/MainMargin/MainHBox/InventoryVBox/TabsContainer/TabAll
@onready var tab_equip: Button = $CenterContainer/MainPanel/MainMargin/MainHBox/InventoryVBox/TabsContainer/TabEquip
@onready var tab_material: Button = $CenterContainer/MainPanel/MainMargin/MainHBox/InventoryVBox/TabsContainer/TabMaterial

# Equipment slot references
@onready var helmet_slot: Panel = $CenterContainer/MainPanel/MainMargin/MainHBox/EquipmentPanel/EquipMargin/EquipVBox/EquipGrid/HelmetSlot
@onready var weapon_slot: Panel = $CenterContainer/MainPanel/MainMargin/MainHBox/EquipmentPanel/EquipMargin/EquipVBox/EquipGrid/WeaponSlot
@onready var armor_slot: Panel = $CenterContainer/MainPanel/MainMargin/MainHBox/EquipmentPanel/EquipMargin/EquipVBox/EquipGrid/ArmorSlot
@onready var shield_slot: Panel = $CenterContainer/MainPanel/MainMargin/MainHBox/EquipmentPanel/EquipMargin/EquipVBox/EquipGrid/ShieldSlot
@onready var boots_slot: Panel = $CenterContainer/MainPanel/MainMargin/MainHBox/EquipmentPanel/EquipMargin/EquipVBox/EquipGrid/BootsSlot
@onready var accessory1_slot: Panel = $CenterContainer/MainPanel/MainMargin/MainHBox/EquipmentPanel/EquipMargin/EquipVBox/EquipGrid/Accessory1Slot
@onready var accessory2_slot: Panel = $CenterContainer/MainPanel/MainMargin/MainHBox/EquipmentPanel/EquipMargin/EquipVBox/EquipGrid/Accessory2Slot

# Stats labels
@onready var atk_value: Label = $CenterContainer/MainPanel/MainMargin/MainHBox/EquipmentPanel/EquipMargin/EquipVBox/StatsGrid/AtkValue
@onready var def_value: Label = $CenterContainer/MainPanel/MainMargin/MainHBox/EquipmentPanel/EquipMargin/EquipVBox/StatsGrid/DefValue
@onready var gold_value: Label = $CenterContainer/MainPanel/MainMargin/MainHBox/EquipmentPanel/EquipMargin/EquipVBox/StatsGrid/GoldValue

# Tooltip
@onready var tooltip_panel: Panel = $CenterContainer/MainPanel/TooltipPanel
@onready var tooltip_name: Label = $CenterContainer/MainPanel/TooltipPanel/MarginContainer/TooltipContent/ItemName
@onready var tooltip_type: Label = $CenterContainer/MainPanel/TooltipPanel/MarginContainer/TooltipContent/ItemType
@onready var tooltip_desc: Label = $CenterContainer/MainPanel/TooltipPanel/MarginContainer/TooltipContent/ItemDesc
@onready var tooltip_stats: Label = $CenterContainer/MainPanel/TooltipPanel/MarginContainer/TooltipContent/ItemStats

var inventory_data: InventoryData
var inventory_slots: Array[InventorySlotUI] = []
var equipment_slots: Dictionary = {}
var selected_slot_index: int = -1
var current_tab: TabFilter = TabFilter.ALL
var tab_buttons: Array[Button] = []


func _ready() -> void:
	visible = false
	_create_inventory_slots()
	_setup_equipment_slots()
	_setup_tabs()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	
	if event.is_action_pressed("open_inventory") or event.is_action_pressed("ui_cancel"):
		close_inventory()
		get_viewport().set_input_as_handled()


func _setup_tabs() -> void:
	tab_all.pressed.connect(_on_tab_pressed.bind(TabFilter.ALL))
	tab_equip.pressed.connect(_on_tab_pressed.bind(TabFilter.EQUIP))
	tab_material.pressed.connect(_on_tab_pressed.bind(TabFilter.MATERIAL))
	_update_tab_styles()


func _on_tab_pressed(tab: TabFilter) -> void:
	current_tab = tab
	_update_tab_styles()
	_refresh_inventory()


func _update_tab_styles() -> void:
	for i in range(tab_buttons.size()):
		var btn := tab_buttons[i]
		if i == current_tab:
			btn.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
		else:
			btn.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))


func _create_inventory_slots() -> void:
	inventory_slots.clear()
	for i in range(INVENTORY_SIZE):
		var slot := InventorySlotUI.new()
		slot.slot_index = i
		slot.is_equipment_slot = false
		slot.slot_clicked.connect(_on_inventory_slot_clicked)
		slot.slot_right_clicked.connect(_on_inventory_slot_right_clicked)
		slot.slot_hovered.connect(_on_slot_hovered)
		slot.slot_dropped.connect(_on_slot_dropped)
		slot.equipment_to_inventory_dropped.connect(_on_equipment_to_inventory_dropped)
		slots_grid.add_child(slot)
		inventory_slots.append(slot)


func _setup_equipment_slots() -> void:
	# Map slot types to their Panel placeholders
	var slot_mapping := {
		"helmet": helmet_slot,
		"weapon": weapon_slot,
		"armor": armor_slot,
		"shield": shield_slot,
		"boots": boots_slot,
		"accessory_1": accessory1_slot,
		"accessory_2": accessory2_slot
	}
	
	# Replace Panel placeholders with InventorySlotUI nodes
	for slot_type in slot_mapping:
		var placeholder: Panel = slot_mapping[slot_type]
		var parent := placeholder.get_parent()
		var idx := placeholder.get_index()
		
		# Create InventorySlotUI for this equipment slot
		var slot := InventorySlotUI.new()
		slot.slot_type = slot_type
		slot.is_equipment_slot = true
		slot.slot_index = -1  # Equipment slots don't use index
		slot.custom_minimum_size = Vector2(48, 48)
		
		# Connect signals
		slot.slot_right_clicked.connect(_on_equipment_slot_right_clicked.bind(slot_type))
		slot.slot_hovered.connect(_on_equipment_slot_hovered.bind(slot_type))
		slot.inventory_to_equipment_dropped.connect(_on_inventory_to_equipment_dropped)
		slot.equipment_dropped.connect(_on_equipment_swap_dropped)
		
		# Remove placeholder and add InventorySlotUI
		parent.remove_child(placeholder)
		placeholder.queue_free()
		parent.add_child(slot)
		parent.move_child(slot, idx)
		
		# Store reference
		equipment_slots[slot_type] = slot


## Setup inventory with data
func setup(data: InventoryData) -> void:
	inventory_data = data
	inventory_data.inventory_changed.connect(_refresh_inventory)
	inventory_data.equipment_changed.connect(_refresh_equipment)
	inventory_data.gold_changed.connect(_refresh_gold)
	
	_refresh_inventory()
	_refresh_equipment("")
	_refresh_stats()
	_refresh_gold(inventory_data.gold)


func open_inventory() -> void:
	visible = true
	_refresh_inventory()
	_refresh_stats()


func close_inventory() -> void:
	visible = false
	tooltip_panel.visible = false
	inventory_closed.emit()


func toggle_inventory() -> void:
	if visible:
		close_inventory()
	else:
		open_inventory()


func _refresh_inventory() -> void:
	if inventory_data == null:
		return
	
	for i in range(inventory_slots.size()):
		var slot_data := inventory_data.get_item_at(i)
		if slot_data.item != null:
			# Check if item matches current tab filter
			if _item_matches_filter(slot_data.item):
				inventory_slots[i].set_item(slot_data.item, slot_data.quantity)
				inventory_slots[i].visible = true
			else:
				inventory_slots[i].clear_slot()
				inventory_slots[i].visible = true  # Keep slot visible but empty when filtered
		else:
			inventory_slots[i].clear_slot()
			inventory_slots[i].visible = true


func _item_matches_filter(item: ItemData) -> bool:
	match current_tab:
		TabFilter.ALL:
			return true
		TabFilter.EQUIP:
			return item.is_equippable()
		TabFilter.MATERIAL:
			return item.item_type == ItemData.ItemType.MATERIAL or item.item_type == ItemData.ItemType.QUEST
		_:
			return true


func _refresh_equipment(_slot_type: String) -> void:
	if inventory_data == null:
		return
	
	for slot_type in equipment_slots:
		var item := inventory_data.get_equipped(slot_type)
		var slot: InventorySlotUI = equipment_slots[slot_type]
		
		if item != null:
			slot.set_item(item, 1)
		else:
			slot.clear_slot()
	
	_refresh_stats()


func _refresh_stats() -> void:
	if inventory_data == null:
		return
	
	atk_value.text = str(inventory_data.get_total_attack_bonus())
	def_value.text = str(inventory_data.get_total_defense_bonus())


func _refresh_gold(amount: int) -> void:
	gold_value.text = _format_number(amount)


func _format_number(num: int) -> String:
	var str_num := str(num)
	var result := ""
	var count := 0
	for i in range(str_num.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = str_num[i] + result
		count += 1
	return result


func _on_inventory_slot_clicked(index: int) -> void:
	if inventory_data == null:
		return
	
	var slot_data := inventory_data.get_item_at(index)
	
	if selected_slot_index == -1:
		if slot_data.item != null:
			selected_slot_index = index
			inventory_slots[index].set_selected(true)
	else:
		if selected_slot_index != index:
			inventory_data.swap_slots(selected_slot_index, index)
		
		inventory_slots[selected_slot_index].set_selected(false)
		selected_slot_index = -1


## Handle drag and drop between slots
func _on_slot_dropped(from_index: int, to_index: int) -> void:
	if inventory_data == null:
		return
	
	# Don't swap with self
	if from_index == to_index:
		return
	
	# Swap the items
	inventory_data.swap_slots(from_index, to_index)
	
	# Clear any selection
	if selected_slot_index != -1:
		inventory_slots[selected_slot_index].set_selected(false)
		selected_slot_index = -1


## Handle drag from inventory to equipment slot
func _on_inventory_to_equipment_dropped(from_index: int, to_slot_type: String) -> void:
	if inventory_data == null:
		return
	
	var slot_data := inventory_data.get_item_at(from_index)
	if slot_data.item == null:
		return
	
	# Equip the item (this handles swapping with currently equipped)
	inventory_data.equip_item(from_index)
	
	# Clear selection
	if selected_slot_index != -1:
		inventory_slots[selected_slot_index].set_selected(false)
		selected_slot_index = -1


## Handle drag from equipment to inventory slot
func _on_equipment_to_inventory_dropped(from_slot_type: String, to_index: int) -> void:
	if inventory_data == null:
		return
	
	var equipped_item := inventory_data.get_equipped(from_slot_type)
	if equipped_item == null:
		return
	
	# Check if target slot is empty or can swap
	var target_data := inventory_data.get_item_at(to_index)
	
	if target_data.item == null:
		# Target is empty - just unequip to that slot
		inventory_data.unequip_item(from_slot_type, to_index)
	else:
		# Target has item - swap if compatible
		if target_data.item.is_equippable():
			# Check if item fits the equipment slot
			var fits := _item_fits_slot(target_data.item, from_slot_type)
			if fits:
				# Unequip current to temp, equip target, move unequipped to target slot
				inventory_data.unequip_item(from_slot_type, to_index)
	
	# Clear selection
	if selected_slot_index != -1:
		inventory_slots[selected_slot_index].set_selected(false)
		selected_slot_index = -1


## Handle drag between equipment slots (swap accessories, etc.)
func _on_equipment_swap_dropped(from_data: Dictionary, to_slot_type: String) -> void:
	if inventory_data == null:
		return
	
	var from_slot_type: String = from_data.slot_type
	if from_slot_type == to_slot_type:
		return
	
	# Only allow swapping between same-type slots (e.g., accessory_1 <-> accessory_2)
	var from_item := inventory_data.get_equipped(from_slot_type)
	var to_item := inventory_data.get_equipped(to_slot_type)
	
	# Check compatibility
	var from_fits_to := from_item == null or _item_fits_slot(from_item, to_slot_type)
	var to_fits_from := to_item == null or _item_fits_slot(to_item, from_slot_type)
	
	if from_fits_to and to_fits_from:
		inventory_data.swap_equipment(from_slot_type, to_slot_type)


## Check if an item can fit in a specific equipment slot type
func _item_fits_slot(check_item: ItemData, check_slot_type: String) -> bool:
	if check_item == null:
		return true
	
	match check_slot_type:
		"helmet":
			return check_item.item_type == ItemData.ItemType.HELMET
		"armor":
			return check_item.item_type == ItemData.ItemType.ARMOR
		"weapon":
			return check_item.item_type == ItemData.ItemType.WEAPON
		"shield":
			return check_item.item_type == ItemData.ItemType.SHIELD
		"boots":
			return check_item.item_type == ItemData.ItemType.BOOTS
		"accessory_1", "accessory_2":
			return check_item.item_type == ItemData.ItemType.ACCESSORY
		_:
			return false


func _on_inventory_slot_right_clicked(index: int) -> void:
	if inventory_data == null:
		return
	
	var slot_data := inventory_data.get_item_at(index)
	if slot_data.item == null:
		return
	
	if slot_data.item.is_equippable():
		inventory_data.equip_item(index)
	elif slot_data.item.is_consumable():
		var result := inventory_data.use_item(index)
		if result.success:
			_apply_consumable_effect(result)


## Handle right-click on equipment slot (unequip)
func _on_equipment_slot_right_clicked(_index: int, slot_type: String) -> void:
	if inventory_data == null:
		return
	inventory_data.unequip_item(slot_type)


## Handle hover on equipment slot
func _on_equipment_slot_hovered(_index: int, is_hovering: bool, slot_type: String) -> void:
	if not is_hovering:
		tooltip_panel.visible = false
		return
	
	if inventory_data == null:
		return
	
	var item := inventory_data.get_equipped(slot_type)
	if item != null:
		_show_tooltip(item, equipment_slots[slot_type])


func _on_slot_hovered(index: int, is_hovering: bool) -> void:
	if not is_hovering:
		tooltip_panel.visible = false
		return
	
	if inventory_data == null:
		return
	
	var slot_data := inventory_data.get_item_at(index)
	if slot_data.item != null:
		_show_tooltip(slot_data.item, inventory_slots[index])


func _show_tooltip(item: ItemData, slot: Control) -> void:
	tooltip_name.text = item.name
	tooltip_name.add_theme_color_override("font_color", item.get_rarity_color())
	
	tooltip_type.text = _get_item_type_string(item.item_type)
	tooltip_type.add_theme_color_override("font_color", item.get_rarity_color().darkened(0.3))
	
	tooltip_desc.text = item.description
	tooltip_stats.text = _get_item_stats_string(item)
	
	tooltip_panel.visible = true
	
	# Position tooltip near slot
	await get_tree().process_frame
	var slot_rect := slot.get_global_rect()
	tooltip_panel.global_position = Vector2(slot_rect.end.x + 10, slot_rect.position.y)


func _get_item_type_string(type: ItemData.ItemType) -> String:
	match type:
		ItemData.ItemType.WEAPON: return "Weapon"
		ItemData.ItemType.ARMOR: return "Armor"
		ItemData.ItemType.HELMET: return "Helmet"
		ItemData.ItemType.BOOTS: return "Boots"
		ItemData.ItemType.SHIELD: return "Shield"
		ItemData.ItemType.ACCESSORY: return "Accessory"
		ItemData.ItemType.CONSUMABLE: return "Consumable"
		ItemData.ItemType.MATERIAL: return "Material"
		ItemData.ItemType.QUEST: return "Quest Item"
		_: return "Unknown"


func _get_item_stats_string(item: ItemData) -> String:
	var stats := []
	if item.attack_bonus > 0:
		stats.append("⚔️ +%d ATK" % item.attack_bonus)
	if item.defense_bonus > 0:
		stats.append("🛡️ +%d DEF" % item.defense_bonus)
	if item.health_bonus > 0:
		stats.append("❤️ +%d HP" % item.health_bonus)
	if item.speed_bonus > 0:
		stats.append("👟 +%.1f SPD" % item.speed_bonus)
	if item.heal_amount > 0:
		stats.append("💚 Heals %d HP" % item.heal_amount)
	if item.stamina_restore > 0:
		stats.append("💙 Restores %.0f Stamina" % item.stamina_restore)
	
	if stats.size() > 0:
		return "\n".join(stats)
	return ""


func _apply_consumable_effect(result: Dictionary) -> void:
	print("[Inventory] Used consumable: heal=%d, stamina=%f" % [result.heal_amount, result.stamina_restore])
	# Emit signal so player can apply the effects
	item_used.emit(result)
