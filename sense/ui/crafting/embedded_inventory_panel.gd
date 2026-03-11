extends Panel
class_name EmbeddedInventoryPanel

## Embedded inventory display for shop/crafting views
## Unlike the full InventoryPanel, this is a simple Panel that can be embedded

signal inventory_changed

const GRID_COLUMNS := 6
const SLOT_SIZE := 64

var slots_grid: GridContainer = null
var inventory_title: Label = null

var inventory_data: InventoryData
var inventory_slots: Array[Panel] = []

func _ready() -> void:
	_setup_ui()

## Setup UI structure
func _setup_ui() -> void:
	if not slots_grid:
		# Create UI programmatically if nodes don't exist
		var margin := MarginContainer.new()
		margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		margin.add_theme_constant_override("margin_left", 10)
		margin.add_theme_constant_override("margin_top", 10)
		margin.add_theme_constant_override("margin_right", 10)
		margin.add_theme_constant_override("margin_bottom", 10)
		add_child(margin)
		
		var vbox := VBoxContainer.new()
		margin.add_child(vbox)
		
		inventory_title = Label.new()
		inventory_title.text = "Inventory"
		inventory_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		inventory_title.add_theme_font_size_override("font_size", 16)
		vbox.add_child(inventory_title)
		
		var scroll := ScrollContainer.new()
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vbox.add_child(scroll)
		
		slots_grid = GridContainer.new()
		slots_grid.columns = GRID_COLUMNS
		slots_grid.add_theme_constant_override("h_separation", 4)
		slots_grid.add_theme_constant_override("v_separation", 4)
		scroll.add_child(slots_grid)
	
	_create_inventory_slots()

## Create inventory slots
func _create_inventory_slots() -> void:
	# Clear existing slots
	for slot in inventory_slots:
		slot.queue_free()
	inventory_slots.clear()
	
	# Create 32 slots
	for i in range(32):
		var slot := _create_slot(i)
		slots_grid.add_child(slot)
		inventory_slots.append(slot)

## Create a single inventory slot
func _create_slot(_index: int) -> Panel:
	var slot := Panel.new()
	slot.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	
	# Style the slot
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	style.border_color = Color(0.3, 0.3, 0.3, 0.8)
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	slot.add_theme_stylebox_override("panel", style)
	
	# Icon display
	var icon_rect := TextureRect.new()
	icon_rect.name = "Icon"
	icon_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(icon_rect)
	
	# Quantity label
	var qty_label := Label.new()
	qty_label.name = "Quantity"
	qty_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	qty_label.offset_left = -30
	qty_label.offset_top = -20
	qty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	qty_label.add_theme_font_size_override("font_size", 12)
	qty_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	qty_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	qty_label.visible = false
	slot.add_child(qty_label)
	
	return slot

## Set inventory data and refresh display
func set_inventory_data(inv_data: InventoryData) -> void:
	if inventory_data and inventory_data.inventory_changed.is_connected(_refresh_display):
		inventory_data.inventory_changed.disconnect(_refresh_display)
	
	inventory_data = inv_data
	
	if inventory_data:
		inventory_data.inventory_changed.connect(_refresh_display)
		_refresh_display()

## Refresh the inventory display
func _refresh_display() -> void:
	if not inventory_data:
		return
	
	for i in range(inventory_slots.size()):
		var slot := inventory_slots[i]
		var icon_rect: TextureRect = slot.get_node("Icon")
		var qty_label: Label = slot.get_node("Quantity")
		
		if i < inventory_data.inventory_slots.size():
			var inv_slot := inventory_data.inventory_slots[i]
			var item_data: ItemData = inv_slot.get("item", null)
			var quantity: int = inv_slot.get("quantity", 0)
			
			if item_data != null:
				# Set icon
				var icon: Texture2D = null
				if item_data.use_atlas_icon and item_data.atlas_icon_name != "":
					icon = ItemIconAtlas.get_named_icon(item_data.atlas_icon_name)
				elif item_data.use_atlas_icon:
					icon = ItemIconAtlas.get_icon(item_data.atlas_row, item_data.atlas_col)
				elif item_data.icon != null:
					icon = item_data.icon
				else:
					icon = ItemIconAtlas.get_default_icon()
				
				icon_rect.texture = icon
				
				# Set quantity (for stackable items)
				if item_data.stackable and quantity > 1:
					qty_label.text = str(quantity)
					qty_label.visible = true
				else:
					qty_label.visible = false
			else:
				# Empty slot
				icon_rect.texture = null
				qty_label.visible = false
		else:
			# Slot doesn't exist in inventory
			icon_rect.texture = null
			qty_label.visible = false
	
	inventory_changed.emit()
