extends Control
class_name InventoryPanel

## Inventory panel UI - main inventory interface
## Uses scene nodes instead of building UI in code

signal inventory_closed
signal item_used(result: Dictionary)

const GRID_COLUMNS := 8
const INVENTORY_SIZE := 32

## Tab filter types
enum TabFilter { ALL, EQUIP, MATERIAL }

## If true, hide overlay and skip ESC close (managed by parent).
## Set via scene override or call set_embedded_mode() before _ready().
@export var embedded_mode: bool = false

## Internal flag
var _embedded := false

# Node references from scene
@onready var slots_grid: GridContainer = $CenterContainer/MainPanel/MainMargin/MainHBox/InventoryVBox/InventoryGrid/GridMargin/SlotsGrid
@onready var equip_grid: GridContainer = $CenterContainer/MainPanel/MainMargin/MainHBox/EquipmentPanel/EquipMargin/EquipVBox/EquipGrid

# Tab buttons
@onready var tab_all: Button = $CenterContainer/MainPanel/MainMargin/MainHBox/InventoryVBox/HeaderRow/TabsContainer/TabAll
@onready var tab_equip: Button = $CenterContainer/MainPanel/MainMargin/MainHBox/InventoryVBox/HeaderRow/TabsContainer/TabEquip
@onready var tab_material: Button = $CenterContainer/MainPanel/MainMargin/MainHBox/InventoryVBox/HeaderRow/TabsContainer/TabMaterial

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
	if not visible or _embedded:
		return
	
	if event.is_action_pressed("ui_cancel"):
		close_inventory()
		get_viewport().set_input_as_handled()


## Enable embedded mode: hides overlay, disables ESC-close, adjusts sizing for HBox
func set_embedded_mode(enabled: bool) -> void:
	_embedded = enabled
	# Hide overlay (parent handles dim background)
	var overlay = get_node_or_null("Overlay")
	if overlay:
		overlay.visible = not enabled
	
	if enabled:
		# Set minimum size so HBox can allocate proper space
		custom_minimum_size = Vector2(500, 450)
		# Shrink the MainPanel minimum to fit side-by-side
		var main_panel = get_node_or_null("CenterContainer/MainPanel")
		if main_panel:
			main_panel.custom_minimum_size = Vector2(500, 450)


func _setup_tabs() -> void:
	tab_buttons = [tab_all, tab_equip, tab_material]
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
			# Active tab - bright gold text with visible background
			btn.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4, 1.0))
			btn.add_theme_color_override("font_hover_color", Color(1.0, 0.9, 0.5, 1.0))
			btn.add_theme_color_override("font_pressed_color", Color(1.0, 0.85, 0.4, 1.0))
			var active_bg := StyleBoxFlat.new()
			active_bg.bg_color = Color(0.25, 0.22, 0.18, 1.0)
			active_bg.border_color = Color(0.6, 0.5, 0.3, 0.8)
			active_bg.set_border_width_all(1)
			active_bg.border_width_bottom = 2
			active_bg.set_corner_radius_all(2)
			active_bg.set_content_margin_all(6)
			btn.add_theme_stylebox_override("normal", active_bg)
			btn.add_theme_stylebox_override("hover", active_bg)
			btn.add_theme_stylebox_override("pressed", active_bg)
		else:
			# Inactive tab - dim text with subtle background
			btn.add_theme_color_override("font_color", Color(0.5, 0.48, 0.44, 1.0))
			btn.add_theme_color_override("font_hover_color", Color(0.7, 0.65, 0.55, 1.0))
			btn.add_theme_color_override("font_pressed_color", Color(0.6, 0.55, 0.45, 1.0))
			var inactive_bg := StyleBoxFlat.new()
			inactive_bg.bg_color = Color(0.12, 0.11, 0.1, 1.0)
			inactive_bg.border_color = Color(0.25, 0.22, 0.2, 0.5)
			inactive_bg.set_border_width_all(1)
			inactive_bg.set_corner_radius_all(2)
			inactive_bg.set_content_margin_all(6)
			btn.add_theme_stylebox_override("normal", inactive_bg)
			btn.add_theme_stylebox_override("hover", inactive_bg)
			btn.add_theme_stylebox_override("pressed", inactive_bg)


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
			inventory_slots[i].set_item(slot_data.item, slot_data.quantity)
			# Dim non-matching items instead of hiding them
			var matches_filter := _item_matches_filter(slot_data.item)
			inventory_slots[i].set_filtered(not matches_filter)
			inventory_slots[i].visible = true
		else:
			inventory_slots[i].clear_slot()
			inventory_slots[i].set_filtered(false)
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


## Handle right-click on equipment slot (unequip or augment)
func _on_equipment_slot_right_clicked(_index: int, slot_type: String) -> void:
	if inventory_data == null:
		return

	var item := inventory_data.get_equipped(slot_type)
	if item != null and item.get_augment_slot_count() > 0:
		# If item has augment slots, open augment panel instead of unequipping
		_open_augment_panel(slot_type)
	else:
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
		ItemData.ItemType.SEGMENT: return "Segment"
		ItemData.ItemType.AUGMENT: return "Augment"
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

	# Augment-specific stats
	if item.item_type == ItemData.ItemType.AUGMENT:
		match item.augment_type:
			ItemData.AugmentType.PASSIVE_EFFECT:
				stats.append(_get_passive_effect_description(item.passive_effect, item.passive_value))
			ItemData.AugmentType.ACTIVE_SKILL:
				stats.append("Grants Skill: %s" % item.active_skill_id)
			ItemData.AugmentType.TIMED_BUFF:
				stats.append("Duration: %.0fs" % item.buff_duration)

	# Augment slots on equippable items
	if item.is_equippable() and item.get_augment_slot_count() > 0:
		stats.append("")
		stats.append("--- Augment Slots ---")
		var slot_count := item.get_augment_slot_count()
		for i in range(slot_count):
			if i < item.applied_augments.size():
				var aug_id: String = item.applied_augments[i]
				var aug_item: ItemData = ItemDatabase.get_item(aug_id)
				if aug_item:
					stats.append("  [%s]" % aug_item.name)
				else:
					stats.append("  [Unknown]")
			else:
				stats.append("  [ Empty Slot ]")

	if stats.size() > 0:
		return "\n".join(stats)
	return ""


func _get_passive_effect_description(effect: ItemData.PassiveEffect, value: float) -> String:
	match effect:
		ItemData.PassiveEffect.LIFE_STEAL:    return "Life Steal: %.0f%%" % value
		ItemData.PassiveEffect.CRIT_CHANCE:   return "Crit Chance: +%.0f%%" % value
		ItemData.PassiveEffect.THORNS:        return "Thorns: Reflect %.0f%% damage" % value
		ItemData.PassiveEffect.BURN_ON_HIT:   return "Burn: %.0f damage/s for 3s" % value
		ItemData.PassiveEffect.FREEZE_ON_HIT: return "Freeze: Slow %.0f%% for 2s" % value
		ItemData.PassiveEffect.POISON_ON_HIT: return "Poison: %.0f damage/s for 3s" % value
		_: return ""


func _apply_consumable_effect(result: Dictionary) -> void:
	print("[Inventory] Used consumable: heal=%d, stamina=%f" % [result.heal_amount, result.stamina_restore])
	# Emit signal so player can apply the effects
	item_used.emit(result)


# =============================================================================
# AUGMENT PANEL INTEGRATION
# =============================================================================

## Open the augment panel for a specific equipment slot
func _open_augment_panel(equip_slot: String) -> void:
	var equipment: ItemData = inventory_data.get_equipped(equip_slot)
	if equipment == null or equipment.get_augment_slot_count() == 0:
		return

	# Remove existing augment panel if any
	var existing := get_node_or_null("AugmentPanel")
	if existing:
		existing.queue_free()

	var panel := AugmentPanel.new()
	panel.name = "AugmentPanel"
	add_child(panel)
	panel.setup(inventory_data, equip_slot)

	# Position near the equipment panel
	var eq_slot_ui: Control = equipment_slots.get(equip_slot)
	if eq_slot_ui:
		await get_tree().process_frame
		var slot_rect := eq_slot_ui.get_global_rect()
		panel.global_position = Vector2(slot_rect.end.x + 10, slot_rect.position.y)


## Called from equipment slot context — shows augment button if item has slots
func _on_augment_button_pressed(equip_slot: String) -> void:
	_open_augment_panel(equip_slot)
