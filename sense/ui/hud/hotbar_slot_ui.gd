class_name HotbarSlotUI
extends Control

## ╔═══════════════════════════════════════════════════════════════════════╗
## ║                      HOTBAR SLOT UI                                   ║
## ╠═══════════════════════════════════════════════════════════════════════╣
## ║  Single slot in the hotbar. Two modes:                                ║
## ║                                                                       ║
## ║  1. SKILL slot — auto-populated from SkillComponent, shows cooldown   ║
## ║  2. ITEM  slot — accepts drag-drop from inventory, quick-use on key   ║
## ║                                                                       ║
## ║  Visual layout:                                                       ║
## ║  ┌──────────────────────────┐                                         ║
## ║  │  [Item / Skill Icon]     │                                         ║
## ║  │                    [x5]  │ ◄─ quantity (items only)                ║
## ║  │  [Q]                     │ ◄─ keybind label (bottom-left)          ║
## ║  │  ░░░░░ cooldown sweep ░░░│ ◄─ cooldown overlay (skills only)       ║
## ║  └──────────────────────────┘                                         ║
## ╚═══════════════════════════════════════════════════════════════════════╝

signal slot_activated(slot_index: int)
signal slot_right_clicked(slot_index: int)
signal hotbar_item_dropped(slot_index: int, drag_data: Dictionary)

## Slot modes
enum SlotMode { SKILL, ITEM }

@export var slot_index: int = 0
@export var slot_mode: SlotMode = SlotMode.ITEM

# Visual constants — matches InventorySlotUI pixel-art style
const SLOT_SIZE := Vector2(44, 44)
const BORDER_WIDTH := 2
const ICON_PADDING := 4

const BG_COLOR := Color(0.12, 0.11, 0.15, 0.95)
const BG_EMPTY := Color(0.08, 0.07, 0.1, 0.85)
const BG_HOVER := Color(0.18, 0.16, 0.22, 1.0)
const BG_COOLDOWN := Color(0.05, 0.05, 0.08, 0.7)

const BORDER_COLOR := Color(0.35, 0.32, 0.28, 1.0)
const BORDER_HOVER := Color(0.6, 0.55, 0.45, 1.0)
const BORDER_SKILL := Color(0.4, 0.35, 0.65, 1.0)
const BORDER_ITEM := Color(0.35, 0.32, 0.28, 1.0)

const KEYBIND_COLOR := Color(0.9, 0.85, 0.7, 0.9)
const KEYBIND_SHADOW := Color(0, 0, 0, 0.8)
const COOLDOWN_OVERLAY := Color(0.0, 0.0, 0.0, 0.55)
const EMPTY_LABEL_COLOR := Color(0.3, 0.3, 0.35, 0.6)

# State
var item: ItemData = null
var quantity: int = 0
var keybind_label: String = ""
var cooldown_ratio: float = 0.0  # 0.0 = ready, 1.0 = fully on cooldown
var is_hovered: bool = false
var inventory_index: int = -1  # Source inventory index (for item slots)
var skill_id: String = ""  # For skill slots


func _ready() -> void:
	custom_minimum_size = SLOT_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(func() -> void: is_hovered = true; queue_redraw())
	mouse_exited.connect(func() -> void: is_hovered = false; queue_redraw())


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			slot_activated.emit(slot_index)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			slot_right_clicked.emit(slot_index)


# ============================================================================
# PUBLIC API
# ============================================================================

func set_item(new_item: ItemData, new_quantity: int = 1, inv_index: int = -1) -> void:
	item = new_item
	quantity = new_quantity
	inventory_index = inv_index
	skill_id = ""
	queue_redraw()


func set_skill(new_skill_id: String) -> void:
	skill_id = new_skill_id
	item = null
	quantity = 0
	inventory_index = -1
	queue_redraw()


func set_keybind(label: String) -> void:
	keybind_label = label
	queue_redraw()


func set_cooldown(ratio: float) -> void:
	cooldown_ratio = clampf(ratio, 0.0, 1.0)
	queue_redraw()


func clear_slot() -> void:
	item = null
	quantity = 0
	inventory_index = -1
	skill_id = ""
	cooldown_ratio = 0.0
	queue_redraw()


func is_empty() -> bool:
	return item == null and skill_id == ""


# ============================================================================
# DRAG AND DROP
# ============================================================================

func _get_drag_data(_at_position: Vector2) -> Variant:
	if item == null:
		return null
	# Only allow dragging from ITEM slots (not skill slots)
	if slot_mode == SlotMode.SKILL:
		return null

	var preview := _create_drag_preview()
	set_drag_preview(preview)

	return {
		"type": "inventory_item",
		"from_index": inventory_index,
		"item": item,
		"quantity": quantity,
		"is_equipment": false,
		"slot_type": "",
		"source": "hotbar",
		"hotbar_index": slot_index,
	}


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if data == null or not data is Dictionary:
		return false
	if slot_mode == SlotMode.SKILL:
		return false  # Can't drop items onto skill slots
	if not data.has("type") or data.type != "inventory_item":
		return false
	var dragged_item: ItemData = data.get("item")
	if dragged_item == null:
		return false
	return true


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	is_hovered = false
	queue_redraw()
	if data == null or not data is Dictionary:
		return
	hotbar_item_dropped.emit(slot_index, data)


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		queue_redraw()


func _create_drag_preview() -> Control:
	var preview := Control.new()
	preview.custom_minimum_size = SLOT_SIZE
	preview.size = SLOT_SIZE
	preview.modulate.a = 0.8

	var drawer := InventorySlotUI.DragPreviewDrawer.new()
	drawer.item = item
	drawer.quantity = quantity
	drawer.custom_minimum_size = SLOT_SIZE
	drawer.size = SLOT_SIZE
	preview.add_child(drawer)
	return preview


# ============================================================================
# DRAWING
# ============================================================================

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, SLOT_SIZE)

	# Background
	var bg := BG_EMPTY
	if is_hovered:
		bg = BG_HOVER
	elif not is_empty():
		bg = BG_COLOR
	draw_rect(rect, bg)

	# Pixel-art 3D bevel border
	var border := BORDER_COLOR
	if is_hovered:
		border = BORDER_HOVER
	elif slot_mode == SlotMode.SKILL:
		border = BORDER_SKILL
	_draw_bevel_border(rect, border)

	# Item / Skill icon
	if item != null:
		_draw_item_icon(rect)
		# Rarity glow
		if item.rarity != ItemData.ItemRarity.COMMON:
			_draw_rarity_glow(rect, item.get_rarity_color())
		# Stack count
		if item.stackable and quantity > 1:
			_draw_stack_count(rect)
	elif skill_id != "":
		_draw_skill_icon(rect)

	# Cooldown sweep overlay (skill slots)
	if cooldown_ratio > 0.0:
		_draw_cooldown_overlay(rect)

	# Keybind label — bottom-left
	if keybind_label != "":
		_draw_keybind(rect)

	# Empty slot mode indicator
	if is_empty():
		_draw_empty_indicator(rect)


func _draw_bevel_border(rect: Rect2, color: Color) -> void:
	var dark := Color(0.18, 0.16, 0.14, 1.0)
	# Bottom-right dark
	draw_rect(Rect2(rect.position.x, rect.position.y + rect.size.y - BORDER_WIDTH,
					rect.size.x, BORDER_WIDTH), dark)
	draw_rect(Rect2(rect.position.x + rect.size.x - BORDER_WIDTH, rect.position.y,
					BORDER_WIDTH, rect.size.y), dark)
	# Top-left light
	draw_rect(Rect2(rect.position.x, rect.position.y,
					rect.size.x - BORDER_WIDTH, BORDER_WIDTH), color.lightened(0.2))
	draw_rect(Rect2(rect.position.x, rect.position.y,
					BORDER_WIDTH, rect.size.y - BORDER_WIDTH), color.lightened(0.2))
	# Mid border
	draw_rect(Rect2(rect.position.x + 1, rect.position.y + 1,
					rect.size.x - 2, rect.size.y - 2), color, false, 1.0)


func _draw_item_icon(rect: Rect2) -> void:
	var icon: Texture2D = item.get_icon() if item else null
	if icon == null:
		var ph := Rect2(rect.position + Vector2(ICON_PADDING + BORDER_WIDTH, ICON_PADDING + BORDER_WIDTH),
						rect.size - Vector2((ICON_PADDING + BORDER_WIDTH) * 2, (ICON_PADDING + BORDER_WIDTH) * 2))
		draw_rect(ph, Color(0.4, 0.45, 0.5, 0.5))
		return
	var icon_rect := Rect2(rect.position + Vector2(ICON_PADDING + BORDER_WIDTH, ICON_PADDING + BORDER_WIDTH),
						   rect.size - Vector2((ICON_PADDING + BORDER_WIDTH) * 2, (ICON_PADDING + BORDER_WIDTH) * 2))
	draw_texture_rect(icon, icon_rect, false)


func _draw_skill_icon(rect: Rect2) -> void:
	# Draw placeholder: colored circle with abbreviated skill name
	var center := rect.get_center()
	var skill_data: SkillData = SkillDatabase.get_skill(skill_id) if skill_id != "" else null
	var circle_color := Color(0.5, 0.4, 0.7, 0.8)
	draw_arc(center, 12, 0, TAU, 16, circle_color, 2.0)
	var display_text := ""
	if skill_data:
		# Use first 2 chars of skill_name, e.g. "Wh" for Whirlwind
		display_text = skill_data.skill_name.substr(0, 2) if skill_data.skill_name != "" else skill_id.substr(0, 2)
	elif skill_id != "":
		display_text = skill_id.substr(0, 2)
	if display_text != "":
		var font := ThemeDB.fallback_font
		draw_string(font, center + Vector2(-7, 5), display_text.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.8, 0.75, 0.95, 1.0))


func _draw_rarity_glow(rect: Rect2, color: Color) -> void:
	var glow := color
	glow.a = 0.7
	var inner := BORDER_WIDTH + 1
	draw_rect(Rect2(rect.position.x + inner, rect.position.y + inner, rect.size.x - inner * 2, 2), glow)
	draw_rect(Rect2(rect.position.x + inner, rect.position.y + rect.size.y - inner - 2, rect.size.x - inner * 2, 2), glow)
	draw_rect(Rect2(rect.position.x + inner, rect.position.y + inner, 2, rect.size.y - inner * 2), glow)
	draw_rect(Rect2(rect.position.x + rect.size.x - inner - 2, rect.position.y + inner, 2, rect.size.y - inner * 2), glow)


func _draw_stack_count(rect: Rect2) -> void:
	var font := ThemeDB.fallback_font
	var font_size := 9
	var text := str(quantity)
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_RIGHT, -1, font_size)
	var text_pos := Vector2(rect.position.x + rect.size.x - text_size.x - 3,
							rect.position.y + rect.size.y - 3)
	var bg_rect := Rect2(text_pos.x - 2, text_pos.y - font_size + 2, text_size.x + 4, font_size + 2)
	draw_rect(bg_rect, Color(0, 0, 0, 0.7))
	draw_string(font, text_pos + Vector2(1, 1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0, 0, 0, 0.8))
	draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)


func _draw_cooldown_overlay(rect: Rect2) -> void:
	# Draw a partial dark overlay from top proportional to cooldown_ratio
	var inner_rect := Rect2(rect.position + Vector2(BORDER_WIDTH, BORDER_WIDTH),
							rect.size - Vector2(BORDER_WIDTH * 2, BORDER_WIDTH * 2))
	var cd_height := inner_rect.size.y * cooldown_ratio
	draw_rect(Rect2(inner_rect.position, Vector2(inner_rect.size.x, cd_height)), COOLDOWN_OVERLAY)


func _draw_keybind(rect: Rect2) -> void:
	var font := ThemeDB.fallback_font
	var font_size := 8
	var pos := Vector2(rect.position.x + 4, rect.position.y + rect.size.y - 3)
	# Background pill
	var text_size := font.get_string_size(keybind_label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var bg_rect := Rect2(pos.x - 2, pos.y - font_size + 1, text_size.x + 4, font_size + 2)
	draw_rect(bg_rect, Color(0, 0, 0, 0.65))
	# Shadow + text
	draw_string(font, pos + Vector2(1, 1), keybind_label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, KEYBIND_SHADOW)
	draw_string(font, pos, keybind_label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, KEYBIND_COLOR)


func _draw_empty_indicator(rect: Rect2) -> void:
	var center := rect.get_center()
	if slot_mode == SlotMode.SKILL:
		# Small skill icon placeholder
		draw_arc(center, 8, 0, TAU, 12, EMPTY_LABEL_COLOR, 1.5)
	else:
		# Small plus sign
		draw_line(center + Vector2(-5, 0), center + Vector2(5, 0), EMPTY_LABEL_COLOR, 1.5)
		draw_line(center + Vector2(0, -5), center + Vector2(0, 5), EMPTY_LABEL_COLOR, 1.5)
