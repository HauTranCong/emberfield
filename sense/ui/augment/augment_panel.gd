extends PanelContainer
class_name AugmentPanel

## ╔═══════════════════════════════════════════════════════════════════════╗
## ║                       AUGMENT PANEL                                    ║
## ╠═══════════════════════════════════════════════════════════════════════╣
## ║  Sub-panel opened from InventoryPanel when clicking "Augment" on an   ║
## ║  equipment slot. Displays augment slots and allows drag-drop or       ║
## ║  click-to-apply augment items from inventory.                         ║
## ║                                                                       ║
## ║  Layout:                                                              ║
## ║  ┌──────────────────────────────────────────────────┐                  ║
## ║  │  Augment: Iron Sword                    [Close]  │                  ║
## ║  │  ATK: 10  DEF: 0  HP: 0  SPD: 0                 │                  ║
## ║  │  ──────────────────────────────────────           │                  ║
## ║  │  Augment Slots (2/2):                            │                  ║
## ║  │  [Flame Augment I]  [Empty Slot]                 │                  ║
## ║  │  ──────────────────────────────────────           │                  ║
## ║  │  Available Augments in Inventory:                 │                  ║
## ║  │  ┌───────────┐ ┌───────────┐ ┌───────────┐      │                  ║
## ║  │  │Power Aug I│ │Crit Aug I │ │Frost AugI │      │                  ║
## ║  │  └───────────┘ └───────────┘ └───────────┘      │                  ║
## ║  └──────────────────────────────────────────────────┘                  ║
## ╚═══════════════════════════════════════════════════════════════════════╝

signal augment_applied(equip_slot: String)
signal augment_removed(equip_slot: String, augment_index: int)
signal panel_closed

var inventory: InventoryData
var equip_slot: String = ""
var equipment_item: ItemData = null

## UI references
var title_label: Label
var stats_label: Label
var slots_container: HBoxContainer
var slots_title_label: Label
var available_title_label: Label
var available_grid: GridContainer
var close_btn: Button
var no_augments_label: Label


func _ready() -> void:
	_build_ui()


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
# UI CONSTRUCTION
# =============================================================================

func _build_ui() -> void:
	custom_minimum_size = Vector2(340, 320)

	# Style
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.06, 0.1, 0.95)
	style.border_color = Color(0.5, 0.4, 0.7, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	add_theme_stylebox_override("panel", style)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 8)
	add_child(root_vbox)

	# Title row
	var title_row := HBoxContainer.new()
	root_vbox.add_child(title_row)

	title_label = Label.new()
	title_label.text = "Augment: "
	title_label.add_theme_font_size_override("font_size", 15)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5, 1.0))
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title_label)

	close_btn = Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(28, 28)
	close_btn.pressed.connect(_on_close_pressed)
	title_row.add_child(close_btn)

	# Stats summary
	stats_label = Label.new()
	stats_label.add_theme_font_size_override("font_size", 12)
	stats_label.modulate = Color(0.7, 0.8, 0.7, 1.0)
	root_vbox.add_child(stats_label)

	# Separator
	root_vbox.add_child(HSeparator.new())

	# Augment slots title
	slots_title_label = Label.new()
	slots_title_label.text = "Augment Slots:"
	slots_title_label.add_theme_font_size_override("font_size", 13)
	root_vbox.add_child(slots_title_label)

	# Augment slots row
	slots_container = HBoxContainer.new()
	slots_container.add_theme_constant_override("separation", 6)
	root_vbox.add_child(slots_container)

	# Separator
	root_vbox.add_child(HSeparator.new())

	# Available augments in inventory
	available_title_label = Label.new()
	available_title_label.text = "Available Augments:"
	available_title_label.add_theme_font_size_override("font_size", 13)
	root_vbox.add_child(available_title_label)

	# Scrollable grid of available augments
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_vbox.add_child(scroll)

	available_grid = GridContainer.new()
	available_grid.columns = 4
	available_grid.add_theme_constant_override("h_separation", 4)
	available_grid.add_theme_constant_override("v_separation", 4)
	scroll.add_child(available_grid)

	# No augments label
	no_augments_label = Label.new()
	no_augments_label.text = "No augment items in inventory."
	no_augments_label.add_theme_font_size_override("font_size", 11)
	no_augments_label.modulate = Color(0.5, 0.5, 0.5, 1.0)
	no_augments_label.visible = false
	root_vbox.add_child(no_augments_label)


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

	for i in range(slot_count):
		var slot_panel := _create_augment_slot_ui(i, applied)
		slots_container.add_child(slot_panel)


func _create_augment_slot_ui(index: int, applied: Array[String]) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(72, 56)

	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(4)
	style.set_border_width_all(1)
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 4
	style.content_margin_bottom = 4

	var is_filled := index < applied.size()

	if is_filled:
		var aug_id: String = applied[index]
		var aug_item: ItemData = ItemDatabase.get_item(aug_id)

		style.bg_color = Color(0.15, 0.12, 0.25, 0.9)
		style.border_color = Color(0.6, 0.5, 0.8, 1.0)
		panel.add_theme_stylebox_override("panel", style)

		var vbox := VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		panel.add_child(vbox)

		# Icon
		if aug_item:
			var icon_rect := TextureRect.new()
			icon_rect.custom_minimum_size = Vector2(24, 24)
			icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var icon := _get_item_icon(aug_item)
			if icon:
				icon_rect.texture = icon
			vbox.add_child(icon_rect)

			# Name (short)
			var name_lbl := Label.new()
			name_lbl.text = aug_item.name.substr(0, 12)
			name_lbl.add_theme_font_size_override("font_size", 9)
			name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			vbox.add_child(name_lbl)

		# Remove button
		var remove_btn := Button.new()
		remove_btn.text = "Remove"
		remove_btn.add_theme_font_size_override("font_size", 9)
		remove_btn.custom_minimum_size = Vector2(60, 18)
		remove_btn.pressed.connect(_on_remove_augment.bind(index))
		vbox.add_child(remove_btn)
	else:
		style.bg_color = Color(0.08, 0.08, 0.08, 0.6)
		style.border_color = Color(0.3, 0.3, 0.3, 0.5)
		panel.add_theme_stylebox_override("panel", style)

		var empty_lbl := Label.new()
		empty_lbl.text = "Empty\nSlot"
		empty_lbl.add_theme_font_size_override("font_size", 10)
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty_lbl.modulate = Color(0.4, 0.4, 0.4, 1.0)
		panel.add_child(empty_lbl)

	return panel


func _draw_available_augments() -> void:
	for child in available_grid.get_children():
		child.queue_free()

	if inventory == null or equipment_item == null:
		no_augments_label.visible = true
		return

	# Check if equipment can accept augments
	if not equipment_item.is_augmentable():
		no_augments_label.text = "All augment slots are filled."
		no_augments_label.visible = true
		return

	# Find augment items in inventory
	var found_any := false
	for i in range(inventory.inventory_slots.size()):
		var slot: Dictionary = inventory.inventory_slots[i]
		var item: ItemData = slot.get("item", null)
		if item == null:
			continue
		if not item.is_augment():
			continue

		found_any = true
		var aug_btn := _create_available_augment_button(i, item)
		available_grid.add_child(aug_btn)

	no_augments_label.visible = not found_any
	if not found_any:
		no_augments_label.text = "No augment items in inventory."


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
