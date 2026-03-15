extends PanelContainer
class_name AugmentPanel

## ╔═══════════════════════════════════════════════════════════════════════╗
## ║                       AUGMENT PANEL                                    ║
## ╠═══════════════════════════════════════════════════════════════════════╣
## ║  Sub-panel opened from InventoryPanel when clicking "Augment" on an   ║
## ║  equipment slot. Displays augment slots in a column layout:            ║
## ║  first slot = Skill (ACTIVE_SKILL), remaining = Passive.              ║
## ║  Layout defined in AugmentPanel.tscn, logic only in this script.      ║
## ║                                                                       ║
## ║  Scene tree:                                                          ║
## ║  AugmentPanel (PanelContainer)                                        ║
## ║  └── RootVBox (VBoxContainer)                                         ║
## ║      ├── TitleRow (HBoxContainer)                                     ║
## ║      │   ├── TitleLabel                                               ║
## ║      │   └── CloseBtn                                                 ║
## ║      ├── StatsLabel                                                   ║
## ║      ├── HSeparator1                                                  ║
## ║      ├── SlotsTitleLabel                                              ║
## ║      ├── SlotsContainer (VBoxContainer) ← dynamic rows               ║
## ║      ├── HSeparator2                                                  ║
## ║      ├── AvailableTitleLabel                                          ║
## ║      ├── ScrollContainer                                              ║
## ║      │   └── AvailableGrid (GridContainer) ← dynamic buttons          ║
## ║      └── NoAugmentsLabel                                              ║
## ╚═══════════════════════════════════════════════════════════════════════╝

signal augment_applied(equip_slot: String)
signal augment_removed(equip_slot: String, augment_index: int)
signal panel_closed

var inventory: InventoryData
var equip_slot: String = ""
var equipment_item: ItemData = null

## Scene node references
@onready var title_label: Label = $RootVBox/TitleRow/TitleLabel
@onready var close_btn: Button = $RootVBox/TitleRow/CloseBtn
@onready var stats_label: Label = $RootVBox/StatsLabel
@onready var slots_title_label: Label = $RootVBox/SlotsTitleLabel
@onready var slots_container: VBoxContainer = $RootVBox/SlotsContainer
@onready var available_title_label: Label = $RootVBox/AvailableTitleLabel
@onready var available_grid: GridContainer = $RootVBox/ScrollContainer/AvailableGrid
@onready var no_augments_label: Label = $RootVBox/NoAugmentsLabel


func _ready() -> void:
	close_btn.pressed.connect(_on_close_pressed)


func setup(inv: InventoryData, slot: String) -> void:
	inventory = inv
	equip_slot = slot
	equipment_item = inventory.get_equipped(slot)

	if inventory and not inventory.inventory_changed.is_connected(_refresh):
		inventory.inventory_changed.connect(_refresh)

	_refresh()


func _refresh() -> void:
	equipment_item = inventory.get_equipped(equip_slot) if inventory else null
	if equipment_item == null:
		visible = false
		return

	visible = true
	_update_title()
	_update_stats()
	_draw_augment_slots()
	_draw_available_augments()

# =============================================================================
# DISPLAY UPDATES
# =============================================================================

func _update_title() -> void:
	if equipment_item:
		title_label.text = "Augment: %s" % equipment_item.name
		title_label.add_theme_color_override("font_color", equipment_item.get_rarity_color())


func _update_stats() -> void:
	if equipment_item == null:
		stats_label.text = ""
		return

	var parts: Array[String] = []
	if equipment_item.attack_bonus > 0:
		parts.append("ATK: %d" % equipment_item.attack_bonus)
	if equipment_item.defense_bonus > 0:
		parts.append("DEF: %d" % equipment_item.defense_bonus)
	if equipment_item.health_bonus > 0:
		parts.append("HP: %d" % equipment_item.health_bonus)
	if equipment_item.speed_bonus > 0:
		parts.append("SPD: %.0f" % equipment_item.speed_bonus)
	stats_label.text = "  ".join(parts) if parts.size() > 0 else "No base stats"


func _draw_augment_slots() -> void:
	for child in slots_container.get_children():
		child.queue_free()

	var slot_count := equipment_item.get_augment_slot_count()
	var applied := equipment_item.applied_augments

	slots_title_label.text = "Augment Slots (%d/%d):" % [applied.size(), slot_count]

	if slot_count == 0:
		var lbl := Label.new()
		lbl.text = "This equipment has no augment slots."
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.modulate = Color(0.5, 0.5, 0.5, 1.0)
		slots_container.add_child(lbl)
		return

	# Categorize applied augments: skills first, then passives
	var skill_entries: Array[Dictionary] = []
	var passive_entries: Array[Dictionary] = []
	for i in range(applied.size()):
		var aug_item: ItemData = ItemDatabase.get_item(applied[i])
		if aug_item and aug_item.augment_type == ItemData.AugmentType.ACTIVE_SKILL:
			skill_entries.append({"aug_id": applied[i], "array_index": i})
		else:
			passive_entries.append({"aug_id": applied[i], "array_index": i})

	# Display order: skills first, then passives, then empties
	var display_entries: Array[Dictionary] = []
	display_entries.append_array(skill_entries)
	display_entries.append_array(passive_entries)

	var has_skill := skill_entries.size() > 0

	for i in range(slot_count):
		if i < display_entries.size():
			var entry: Dictionary = display_entries[i]
			var aug_item: ItemData = ItemDatabase.get_item(entry["aug_id"])
			var is_skill := aug_item and aug_item.augment_type == ItemData.AugmentType.ACTIVE_SKILL
			var type_text := "Skill" if is_skill else "Passive"
			var type_color := Color(0.4, 0.7, 1.0) if is_skill else Color(0.6, 0.8, 0.4)
			var row := _create_augment_slot_row(type_text, entry["array_index"], type_color)
			slots_container.add_child(row)
		else:
			# Empty slot — first empty hints "Skill" if no skill applied yet
			var is_first_empty := (i == display_entries.size())
			if not has_skill and is_first_empty:
				var row := _create_augment_slot_row("Skill", -1, Color(0.4, 0.7, 1.0, 0.5))
				slots_container.add_child(row)
			else:
				var row := _create_augment_slot_row("Passive", -1, Color(0.6, 0.8, 0.4, 0.5))
				slots_container.add_child(row)


## Creates a single augment slot row: [Type Label] [Icon + Name] [Remove]
func _create_augment_slot_row(slot_type: String, aug_array_index: int, type_color: Color) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)

	# Type label (Skill / Passive)
	var type_lbl := Label.new()
	type_lbl.text = slot_type
	type_lbl.custom_minimum_size = Vector2(55, 0)
	type_lbl.add_theme_font_size_override("font_size", 11)
	type_lbl.add_theme_color_override("font_color", type_color)
	type_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(type_lbl)

	# Slot panel
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 36)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(4)
	style.set_border_width_all(1)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 3
	style.content_margin_bottom = 3

	var is_filled := aug_array_index >= 0

	if is_filled:
		var aug_id: String = equipment_item.applied_augments[aug_array_index]
		var aug_item: ItemData = ItemDatabase.get_item(aug_id)

		style.bg_color = Color(0.15, 0.12, 0.25, 0.9)
		style.border_color = Color(0.6, 0.5, 0.8, 1.0)
		panel.add_theme_stylebox_override("panel", style)

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 6)
		panel.add_child(hbox)

		if aug_item:
			# Icon
			var icon_rect := TextureRect.new()
			icon_rect.custom_minimum_size = Vector2(24, 24)
			icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var icon := _get_item_icon(aug_item)
			if icon:
				icon_rect.texture = icon
			hbox.add_child(icon_rect)

			# Name (full, colored by rarity)
			var name_lbl := Label.new()
			name_lbl.text = aug_item.name
			name_lbl.add_theme_font_size_override("font_size", 11)
			name_lbl.add_theme_color_override("font_color", aug_item.get_rarity_color())
			name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			hbox.add_child(name_lbl)

		# Remove button
		var remove_btn := Button.new()
		remove_btn.text = "X"
		remove_btn.add_theme_font_size_override("font_size", 9)
		remove_btn.custom_minimum_size = Vector2(24, 24)
		remove_btn.pressed.connect(_on_remove_augment.bind(aug_array_index))
		hbox.add_child(remove_btn)
	else:
		style.bg_color = Color(0.08, 0.08, 0.08, 0.6)
		style.border_color = Color(0.3, 0.3, 0.3, 0.5)
		panel.add_theme_stylebox_override("panel", style)

		var empty_lbl := Label.new()
		empty_lbl.text = "Empty"
		empty_lbl.add_theme_font_size_override("font_size", 10)
		empty_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty_lbl.modulate = Color(0.4, 0.4, 0.4, 1.0)
		panel.add_child(empty_lbl)

	row.add_child(panel)
	return row


func _draw_available_augments() -> void:
	for child in available_grid.get_children():
		child.queue_free()

	if inventory == null or equipment_item == null:
		no_augments_label.visible = true
		return

	var skill_slot_open := _has_skill_slot_available()
	var has_room := equipment_item.applied_augments.size() < equipment_item.get_augment_slot_count()

	if not has_room:
		no_augments_label.text = "All augment slots are filled."
		no_augments_label.visible = true
		return

	# Find augment items in inventory, filtered by available slot types
	var found_any := false
	for i in range(inventory.inventory_slots.size()):
		var slot: Dictionary = inventory.inventory_slots[i]
		var item: ItemData = slot.get("item", null)
		if item == null:
			continue
		if not item.is_augment():
			continue

		# Filter: skill augments only shown if skill slot is open
		var is_skill_augment := item.augment_type == ItemData.AugmentType.ACTIVE_SKILL
		if is_skill_augment and not skill_slot_open:
			continue

		found_any = true
		var aug_btn := _create_available_augment_button(i, item)
		available_grid.add_child(aug_btn)

	no_augments_label.visible = not found_any
	if not found_any:
		no_augments_label.text = "No matching augment items in inventory."


func _create_available_augment_button(inv_index: int, item: ItemData) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(72, 64)

	var style_normal := StyleBoxFlat.new()
	style_normal.bg_color = Color(0.1, 0.1, 0.15, 0.8)
	style_normal.border_color = Color(0.3, 0.35, 0.3, 0.8)
	style_normal.set_border_width_all(1)
	style_normal.set_corner_radius_all(4)
	style_normal.content_margin_left = 4
	style_normal.content_margin_right = 4
	style_normal.content_margin_top = 4
	style_normal.content_margin_bottom = 4

	var style_hover := StyleBoxFlat.new()
	style_hover.bg_color = Color(0.15, 0.18, 0.25, 0.9)
	style_hover.border_color = Color(0.5, 0.6, 0.4, 1.0)
	style_hover.set_border_width_all(2)
	style_hover.set_corner_radius_all(4)
	style_hover.content_margin_left = 4
	style_hover.content_margin_right = 4
	style_hover.content_margin_top = 4
	style_hover.content_margin_bottom = 4

	panel.add_theme_stylebox_override("panel", style_normal)

	var btn := Button.new()
	btn.flat = true
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.mouse_entered.connect(func(): panel.add_theme_stylebox_override("panel", style_hover))
	btn.mouse_exited.connect(func(): panel.add_theme_stylebox_override("panel", style_normal))
	btn.pressed.connect(_on_augment_clicked.bind(inv_index))
	panel.add_child(btn)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(vbox)

	# Icon
	var icon_rect := TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(28, 28)
	icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon := _get_item_icon(item)
	if icon:
		icon_rect.texture = icon
	vbox.add_child(icon_rect)

	# Name (short)
	var name_lbl := Label.new()
	name_lbl.text = item.name.substr(0, 12)
	name_lbl.add_theme_font_size_override("font_size", 9)
	name_lbl.add_theme_color_override("font_color", item.get_rarity_color())
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_lbl)

	return panel


# =============================================================================
# EVENT HANDLERS
# =============================================================================

func _on_augment_clicked(augment_inventory_index: int) -> void:
	if inventory == null:
		return
	if inventory.apply_augment(equip_slot, augment_inventory_index):
		augment_applied.emit(equip_slot)
		GameEvent.augment_applied.emit(equip_slot, inventory.get_equipped(equip_slot).applied_augments[-1] if inventory.get_equipped(equip_slot) else "")
		_refresh()


func _on_remove_augment(augment_index: int) -> void:
	if inventory == null:
		return
	var eq := inventory.get_equipped(equip_slot)
	var aug_id: String = eq.applied_augments[augment_index] if eq and augment_index < eq.applied_augments.size() else ""
	if inventory.remove_augment(equip_slot, augment_index):
		augment_removed.emit(equip_slot, augment_index)
		GameEvent.augment_removed.emit(equip_slot, aug_id)
		_refresh()


func _on_close_pressed() -> void:
	panel_closed.emit()
	queue_free()


# =============================================================================
# AUGMENT SLOT HELPERS
# =============================================================================

## Returns true if the equipment can accept a new ACTIVE_SKILL augment
func _has_skill_slot_available() -> bool:
	if equipment_item == null or equipment_item.get_augment_slot_count() == 0:
		return false
	if equipment_item.applied_augments.size() >= equipment_item.get_augment_slot_count():
		return false
	for aug_id: String in equipment_item.applied_augments:
		var aug: ItemData = ItemDatabase.get_item(aug_id)
		if aug and aug.augment_type == ItemData.AugmentType.ACTIVE_SKILL:
			return false
	return true


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
