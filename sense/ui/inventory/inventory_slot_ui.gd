@tool
class_name InventorySlotUI
extends Control

## Inventory slot UI component - displays a single item slot
##
## ╔═══════════════════════════════════════════════════════════════╗
## ║                    SLOT VISUAL STRUCTURE                      ║
## ╠═══════════════════════════════════════════════════════════════╣
## ║  ┌────────────────────────────────────────┐                   ║
## ║  │  ┌──────────────────────────────────┐  │ ◄─ Border        ║
## ║  │  │                                  │  │                   ║
## ║  │  │         [Item Icon]              │  │ ◄─ Item texture  ║
## ║  │  │                                  │  │                   ║
## ║  │  │                          [x99]   │  │ ◄─ Stack count   ║
## ║  │  └──────────────────────────────────┘  │                   ║
## ║  └────────────────────────────────────────┘                   ║
## ║           ▲                                                   ║
## ║           └─ Rarity glow color                                ║
## ╚═══════════════════════════════════════════════════════════════╝

signal slot_clicked(index: int)
signal slot_right_clicked(index: int)
signal slot_hovered(index: int, is_hovering: bool)
signal slot_dropped(from_index: int, to_index: int)
signal equipment_dropped(from_data: Dictionary, to_slot_type: String)  # For equipment drag & drop
signal inventory_to_equipment_dropped(from_index: int, to_slot_type: String)  # Inv -> Equip
signal equipment_to_inventory_dropped(from_slot_type: String, to_index: int)  # Equip -> Inv

@export var slot_index: int = -1
@export var slot_type: String = ""  # For equipment slots: "helmet", "weapon", etc.
@export var is_equipment_slot: bool = false

# Pixel Art Colors - Stone/Metal theme
const SLOT_BG_COLOR := Color(0.14, 0.12, 0.16, 1.0)
const SLOT_BG_EMPTY := Color(0.1, 0.09, 0.12, 1.0)
const SLOT_BG_DROP_TARGET := Color(0.2, 0.25, 0.18, 1.0)  # Highlight when can drop

# Border colors - pixel art style with light top-left, dark bottom-right
const BORDER_LIGHT := Color(0.45, 0.4, 0.35, 1.0)
const BORDER_MID := Color(0.3, 0.27, 0.24, 1.0)
const BORDER_DARK := Color(0.18, 0.16, 0.14, 1.0)

const SLOT_BORDER_COLOR := Color(0.35, 0.32, 0.28, 1.0)
const SLOT_BORDER_HOVER := Color(0.6, 0.55, 0.45, 1.0)
const SLOT_BORDER_SELECTED := Color(1.0, 0.8, 0.3, 1.0)
const SLOT_BORDER_DROP := Color(0.4, 0.7, 0.3, 1.0)  # Green when can drop

const SLOT_SIZE := Vector2(44, 44)
const ICON_PADDING := 4
const BORDER_WIDTH := 2

var item: ItemData = null
var quantity: int = 0
var is_hovered: bool = false
var is_selected: bool = false
var is_drag_target: bool = false  # True when dragging over this slot


func _ready() -> void:
	custom_minimum_size = SLOT_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_RIGHT:
				slot_right_clicked.emit(slot_index)


# ============================================================================
# DRAG AND DROP
# ============================================================================

## Called when drag starts - returns drag data if slot has item
func _get_drag_data(_at_position: Vector2) -> Variant:
	if item == null:
		return null
	
	# Create drag preview
	var preview := _create_drag_preview()
	set_drag_preview(preview)
	
	# Return drag data
	return {
		"type": "inventory_item",
		"from_index": slot_index,
		"item": item,
		"quantity": quantity,
		"is_equipment": is_equipment_slot,
		"slot_type": slot_type
	}


## Called to check if we can drop here
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if data == null or not data is Dictionary:
		return false
	
	if not data.has("type") or data.type != "inventory_item":
		return false
	
	var dragged_item: ItemData = data.item
	
	# Equipment slot validation
	if is_equipment_slot:
		# Can't drop on same equipment slot
		if data.is_equipment and data.slot_type == slot_type:
			return false
		# Check if item can be equipped in this slot
		if dragged_item != null and not _item_fits_equipment_slot(dragged_item):
			return false
	else:
		# Regular inventory slot - can't drop on same slot
		if not data.is_equipment and data.from_index == slot_index:
			return false
	
	# Update visual
	is_drag_target = true
	queue_redraw()
	
	return true


## Check if an item can be equipped in this equipment slot
func _item_fits_equipment_slot(check_item: ItemData) -> bool:
	if check_item == null:
		return true  # Empty swap is always valid
	
	# Map slot_type to valid ItemTypes
	match slot_type:
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


## Called when item is dropped
func _drop_data(_at_position: Vector2, data: Variant) -> void:
	is_drag_target = false
	queue_redraw()
	
	if data == null or not data is Dictionary:
		return
	
	# Determine drop type based on source and destination
	if is_equipment_slot:
		if data.is_equipment:
			# Equipment -> Equipment (swap between equipment slots)
			equipment_dropped.emit(data, slot_type)
		else:
			# Inventory -> Equipment (equip item)
			inventory_to_equipment_dropped.emit(data.from_index, slot_type)
	else:
		if data.is_equipment:
			# Equipment -> Inventory (unequip item)
			equipment_to_inventory_dropped.emit(data.slot_type, slot_index)
		else:
			# Inventory -> Inventory (swap items)
			slot_dropped.emit(data.from_index, slot_index)


## Called when drag leaves this control
func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		is_drag_target = false
		queue_redraw()


## Create a visual preview for dragging
func _create_drag_preview() -> Control:
	var preview := Control.new()
	preview.custom_minimum_size = SLOT_SIZE
	preview.size = SLOT_SIZE
	preview.modulate.a = 0.8
	
	# We'll draw the preview manually
	var preview_drawer := DragPreviewDrawer.new()
	preview_drawer.item = item
	preview_drawer.quantity = quantity
	preview_drawer.custom_minimum_size = SLOT_SIZE
	preview_drawer.size = SLOT_SIZE
	
	preview.add_child(preview_drawer)
	return preview


func _on_mouse_entered() -> void:
	is_hovered = true
	slot_hovered.emit(slot_index, true)
	queue_redraw()


func _on_mouse_exited() -> void:
	is_hovered = false
	slot_hovered.emit(slot_index, false)
	queue_redraw()


func set_item(new_item: ItemData, new_quantity: int = 1) -> void:
	item = new_item
	quantity = new_quantity
	queue_redraw()


func clear_slot() -> void:
	item = null
	quantity = 0
	queue_redraw()


func set_selected(selected: bool) -> void:
	is_selected = selected
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, SLOT_SIZE)
	
	# Draw slot background - highlight if drag target
	var bg_color := SLOT_BG_COLOR if item != null else SLOT_BG_EMPTY
	if is_drag_target:
		bg_color = SLOT_BG_DROP_TARGET
	_draw_slot_background(rect, bg_color)
	
	# Draw border
	var border_color := SLOT_BORDER_COLOR
	if is_drag_target:
		border_color = SLOT_BORDER_DROP
	elif is_selected:
		border_color = SLOT_BORDER_SELECTED
	elif is_hovered:
		border_color = SLOT_BORDER_HOVER
	_draw_slot_border(rect, border_color)
	
	# Draw equipment slot indicator if empty
	if is_equipment_slot and item == null:
		_draw_equipment_indicator(rect)
	
	# Draw item icon if present
	if item != null:
		_draw_item_icon(rect)
		
		# Draw rarity border glow
		if item.rarity != ItemData.ItemRarity.COMMON:
			_draw_rarity_glow(rect, item.get_rarity_color())
		
		# Draw stack count
		if item.stackable and quantity > 1:
			_draw_stack_count(rect)


func _draw_slot_background(rect: Rect2, color: Color) -> void:
	# Main background - solid color for pixel art
	draw_rect(rect, color)
	
	# Pixel art inner bevel - light top/left edge
	draw_rect(Rect2(rect.position + Vector2(BORDER_WIDTH, BORDER_WIDTH),
					Vector2(rect.size.x - BORDER_WIDTH * 2, 1)), Color(1, 1, 1, 0.08))
	draw_rect(Rect2(rect.position + Vector2(BORDER_WIDTH, BORDER_WIDTH),
					Vector2(1, rect.size.y - BORDER_WIDTH * 2)), Color(1, 1, 1, 0.08))
	
	# Dark bottom/right inner edge
	draw_rect(Rect2(rect.position + Vector2(BORDER_WIDTH, rect.size.y - BORDER_WIDTH - 1),
					Vector2(rect.size.x - BORDER_WIDTH * 2, 1)), Color(0, 0, 0, 0.2))
	draw_rect(Rect2(rect.position + Vector2(rect.size.x - BORDER_WIDTH - 1, BORDER_WIDTH),
					Vector2(1, rect.size.y - BORDER_WIDTH * 2)), Color(0, 0, 0, 0.2))


func _draw_slot_border(rect: Rect2, color: Color) -> void:
	# Pixel art style border - 3D bevel effect
	
	# Outer dark edge (bottom-right)
	draw_rect(Rect2(rect.position.x, rect.position.y + rect.size.y - BORDER_WIDTH,
					rect.size.x, BORDER_WIDTH), BORDER_DARK)
	draw_rect(Rect2(rect.position.x + rect.size.x - BORDER_WIDTH, rect.position.y,
					BORDER_WIDTH, rect.size.y), BORDER_DARK)
	
	# Outer light edge (top-left)
	draw_rect(Rect2(rect.position.x, rect.position.y,
					rect.size.x - BORDER_WIDTH, BORDER_WIDTH), color.lightened(0.2))
	draw_rect(Rect2(rect.position.x, rect.position.y,
					BORDER_WIDTH, rect.size.y - BORDER_WIDTH), color.lightened(0.2))
	
	# Middle border
	draw_rect(Rect2(rect.position.x + 1, rect.position.y + 1,
					rect.size.x - 2, rect.size.y - 2), color, false, 1.0)
	
	# Corner pixels for cleaner look
	draw_rect(Rect2(rect.position, Vector2(1, 1)), BORDER_MID)
	draw_rect(Rect2(rect.position + rect.size - Vector2(1, 1), Vector2(1, 1)), BORDER_MID)


func _draw_equipment_indicator(rect: Rect2) -> void:
	# Draw a faint icon indicating what type of equipment goes here
	var icon_color := Color(0.3, 0.35, 0.4, 0.5)
	var center := rect.get_center()
	var icon_size := 16.0
	
	match slot_type:
		"helmet":
			# Simple helmet shape
			var points := [
				center + Vector2(-icon_size/2, icon_size/4),
				center + Vector2(-icon_size/2, -icon_size/4),
				center + Vector2(-icon_size/4, -icon_size/2),
				center + Vector2(icon_size/4, -icon_size/2),
				center + Vector2(icon_size/2, -icon_size/4),
				center + Vector2(icon_size/2, icon_size/4),
			]
			draw_polyline(points, icon_color, 2.0)
		"armor":
			# Simple armor/chest shape
			draw_rect(Rect2(center - Vector2(icon_size/2, icon_size/2), 
						   Vector2(icon_size, icon_size)), icon_color, false, 2.0)
		"weapon":
			# Sword shape
			draw_line(center + Vector2(-icon_size/2, icon_size/2), 
					 center + Vector2(icon_size/2, -icon_size/2), icon_color, 2.0)
			draw_line(center + Vector2(-icon_size/4, 0), 
					 center + Vector2(icon_size/4, 0), icon_color, 2.0)
		"shield":
			# Shield shape - circle
			draw_arc(center, icon_size/2, 0, TAU, 16, icon_color, 2.0)
		"boots":
			# Boot shape
			draw_line(center + Vector2(-icon_size/3, -icon_size/2), 
					 center + Vector2(-icon_size/3, icon_size/4), icon_color, 2.0)
			draw_line(center + Vector2(-icon_size/3, icon_size/4), 
					 center + Vector2(icon_size/2, icon_size/4), icon_color, 2.0)
		"accessory", "accessory_1", "accessory_2":
			# Ring shape
			draw_arc(center, icon_size/3, 0, TAU, 12, icon_color, 2.0)


func _draw_item_icon(rect: Rect2) -> void:
	var item_icon: Texture2D = item.get_icon() if item else null
	
	# Debug: trace icon retrieval
	if item != null and item_icon == null:
		print("[InventorySlotUI] Item '%s' returned null icon! use_atlas=%s, atlas_name='%s', row=%d, col=%d" % [
			item.id, item.use_atlas_icon, item.atlas_icon_name, item.atlas_row, item.atlas_col
		])
	
	if item == null or item_icon == null:
		# Draw placeholder if no icon
		var placeholder_rect := Rect2(
			rect.position + Vector2(ICON_PADDING + BORDER_WIDTH, ICON_PADDING + BORDER_WIDTH),
			rect.size - Vector2((ICON_PADDING + BORDER_WIDTH) * 2, (ICON_PADDING + BORDER_WIDTH) * 2)
		)
		draw_rect(placeholder_rect, Color(0.4, 0.45, 0.5, 0.5))
		return
	
	var icon_rect := Rect2(
		rect.position + Vector2(ICON_PADDING + BORDER_WIDTH, ICON_PADDING + BORDER_WIDTH),
		rect.size - Vector2((ICON_PADDING + BORDER_WIDTH) * 2, (ICON_PADDING + BORDER_WIDTH) * 2)
	)
	draw_texture_rect(item_icon, icon_rect, false)


func _draw_rarity_glow(rect: Rect2, color: Color) -> void:
	# Pixel art style rarity border - solid colored inner border
	var glow_color := color
	glow_color.a = 0.7
	
	# Draw colored border lines (pixel art style - no glow, just solid pixels)
	var inner := BORDER_WIDTH + 1
	# Top
	draw_rect(Rect2(rect.position.x + inner, rect.position.y + inner,
					rect.size.x - inner * 2, 2), glow_color)
	# Bottom
	draw_rect(Rect2(rect.position.x + inner, rect.position.y + rect.size.y - inner - 2,
					rect.size.x - inner * 2, 2), glow_color)
	# Left
	draw_rect(Rect2(rect.position.x + inner, rect.position.y + inner,
					2, rect.size.y - inner * 2), glow_color)
	# Right
	draw_rect(Rect2(rect.position.x + rect.size.x - inner - 2, rect.position.y + inner,
					2, rect.size.y - inner * 2), glow_color)


func _draw_stack_count(rect: Rect2) -> void:
	var font := ThemeDB.fallback_font
	var font_size := 9
	var text := str(quantity)
	
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_RIGHT, -1, font_size)
	var text_pos := Vector2(
		rect.position.x + rect.size.x - text_size.x - 3,
		rect.position.y + rect.size.y - 3
	)
	
	# Draw background for readability (pixel art style)
	var bg_rect := Rect2(text_pos.x - 2, text_pos.y - font_size + 2, text_size.x + 4, font_size + 2)
	draw_rect(bg_rect, Color(0, 0, 0, 0.7))
	
	# Shadow (1px offset for pixel look)
	draw_string(font, text_pos + Vector2(1, 1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0, 0, 0, 0.8))
	# Main text
	draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)


# ============================================================================
# DRAG PREVIEW INNER CLASS
# ============================================================================

## Inner class for drawing drag preview
class DragPreviewDrawer extends Control:
	var item: ItemData = null
	var quantity: int = 1
	
	func _draw() -> void:
		if item == null:
			return
		
		var rect := Rect2(Vector2.ZERO, size)
		
		# Draw semi-transparent background
		draw_rect(rect, Color(0.14, 0.12, 0.16, 0.9))
		
		# Draw border
		draw_rect(rect, Color(0.5, 0.45, 0.35, 1.0), false, 2.0)
		
		# Draw item icon
		var item_icon: Texture2D = item.get_icon() if item else null
		if item_icon:
			var icon_rect := Rect2(
				Vector2(4, 4),
				size - Vector2(8, 8)
			)
			draw_texture_rect(item_icon, icon_rect, false)
		
		# Draw rarity border
		if item.rarity != ItemData.ItemRarity.COMMON:
			var glow_color := item.get_rarity_color()
			glow_color.a = 0.8
			draw_rect(Rect2(2, 2, size.x - 4, size.y - 4), glow_color, false, 2.0)
		
		# Draw stack count
		if item.stackable and quantity > 1:
			var font := ThemeDB.fallback_font
			var font_size := 9
			var text := str(quantity)
			var text_pos := Vector2(size.x - 12, size.y - 3)
			draw_string(font, text_pos + Vector2(1, 1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.BLACK)
			draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
