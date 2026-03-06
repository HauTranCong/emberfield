class_name Hotbar
extends PanelContainer

## ╔═══════════════════════════════════════════════════════════════════════╗
## ║                           HOTBAR                                      ║
## ╠═══════════════════════════════════════════════════════════════════════╣
## ║  Bottom-center HUD hotbar with:                                       ║
## ║  • 4 SKILL slots (auto-populated from SkillComponent, keys Q/E/R/F)  ║
## ║  • 8 ITEM slots  (drag-drop from inventory, keys 1-8)                ║
## ║                                                                       ║
## ║  Layout (bottom-center of screen):                                    ║
## ║  ┌───┬───┬───┬───┐ │ ┌───┬───┬───┬───┬───┬───┬───┬───┐              ║
## ║  │ Q │ E │ R │ F │ │ │ 1 │ 2 │ 3 │ 4 │ 5 │ 6 │ 7 │ 8 │             ║
## ║  └───┴───┴───┴───┘ │ └───┴───┴───┴───┴───┴───┴───┴───┘              ║
## ║    SKILL SLOTS      │        ITEM SLOTS                               ║
## ╚═══════════════════════════════════════════════════════════════════════╝

signal hotbar_item_used(slot_index: int, item: ItemData, inventory_index: int)

const SKILL_SLOT_COUNT := 4
const ITEM_SLOT_COUNT := 8
const SLOT_SPACING := 3
const SECTION_SPACING := 8

## Keybind labels for skill slots (Q, E, R, F)
const SKILL_KEYBINDS: Array[String] = ["Q", "E", "R", "F"]

## Input action names for skill slots (handled by SkillComponent, shown here for display)
const SKILL_INPUT_ACTIONS: Array[String] = ["skill_1", "skill_2", "skill_3", "skill_4"]

## Input action names for item slots (1-8 keys)
const ITEM_INPUT_ACTIONS: Array[String] = [
	"hotbar_1", "hotbar_2", "hotbar_3", "hotbar_4",
	"hotbar_5", "hotbar_6", "hotbar_7", "hotbar_8"
]

## Keybind labels for item slots
const ITEM_KEYBINDS: Array[String] = ["1", "2", "3", "4", "5", "6", "7", "8"]

# Slot arrays
var skill_slots: Array[HotbarSlotUI] = []
var item_slots: Array[HotbarSlotUI] = []

# References (injected via setup)
var inventory: InventoryData
var skill_component: SkillComponent

# Scene node references
@onready var _skill_section: HBoxContainer = $RootHBox/SkillSection
@onready var _item_section: HBoxContainer = $RootHBox/ItemSection


func _ready() -> void:
	_create_slots()
	_ensure_input_actions()


func setup(inv: InventoryData, skill_comp: SkillComponent = null) -> void:
	inventory = inv
	skill_component = skill_comp

	# Connect inventory changes to refresh item quantities
	if inventory and not inventory.inventory_changed.is_connected(_refresh_item_slots):
		inventory.inventory_changed.connect(_refresh_item_slots)

	# Connect skill component to auto-populate skill slots
	if skill_component:
		if not skill_component.skills_changed.is_connected(_refresh_skill_slots):
			skill_component.skills_changed.connect(_refresh_skill_slots)
		if not skill_component.skill_cooldown_updated.is_connected(_on_skill_cooldown_updated):
			skill_component.skill_cooldown_updated.connect(_on_skill_cooldown_updated)
		_refresh_skill_slots()


# ============================================================================
# INPUT — item slot quick-use (1-8 keys)
# ============================================================================

func _unhandled_input(event: InputEvent) -> void:
	for i in range(ITEM_SLOT_COUNT):
		if event.is_action_pressed(ITEM_INPUT_ACTIONS[i]):
			_activate_item_slot(i)
			get_viewport().set_input_as_handled()
			return


# ============================================================================
# SLOT CREATION (scene provides layout, script creates slot nodes)
# ============================================================================

func _create_slots() -> void:
	# --- SKILL SLOTS ---
	for i in range(SKILL_SLOT_COUNT):
		var slot := HotbarSlotUI.new()
		slot.slot_index = i
		slot.slot_mode = HotbarSlotUI.SlotMode.SKILL
		slot.set_keybind(SKILL_KEYBINDS[i])
		slot.slot_activated.connect(_on_skill_slot_activated)
		_skill_section.add_child(slot)
		skill_slots.append(slot)

	# --- ITEM SLOTS ---
	for i in range(ITEM_SLOT_COUNT):
		var slot := HotbarSlotUI.new()
		slot.slot_index = i
		slot.slot_mode = HotbarSlotUI.SlotMode.ITEM
		slot.set_keybind(ITEM_KEYBINDS[i])
		slot.slot_activated.connect(_on_item_slot_activated)
		slot.slot_right_clicked.connect(_on_item_slot_right_clicked)
		slot.hotbar_item_dropped.connect(_on_hotbar_item_dropped)
		_item_section.add_child(slot)
		item_slots.append(slot)


# ============================================================================
# SKILL SLOT MANAGEMENT (auto-populated from SkillComponent)
# ============================================================================

func _refresh_skill_slots() -> void:
	# Clear all skill slots first
	for slot in skill_slots:
		slot.clear_slot()
		slot.set_cooldown(0.0)

	if skill_component == null:
		return

	# Map skill_component.available_skills into the 4 skill slots
	# SkillComponent already maps each skill to input_action (skill_1..skill_4)
	for skill_entry: Dictionary in skill_component.available_skills:
		var input_action: String = skill_entry.get("input_action", "")
		var s_id: String = skill_entry.get("skill_id", "")
		var action_idx := SKILL_INPUT_ACTIONS.find(input_action)
		if action_idx >= 0 and action_idx < SKILL_SLOT_COUNT:
			skill_slots[action_idx].set_skill(s_id)


func _on_skill_cooldown_updated(s_id: String, remaining: float) -> void:
	# Find which skill slot has this skill and update cooldown ratio
	for slot in skill_slots:
		if slot.skill_id == s_id:
			# Get total cooldown from SkillDatabase
			var skill_data: SkillData = SkillDatabase.get_skill(s_id)
			if skill_data and skill_data.cooldown > 0:
				slot.set_cooldown(remaining / skill_data.cooldown)
			else:
				slot.set_cooldown(0.0)
			break


func _on_skill_slot_activated(idx: int) -> void:
	# Skills are activated via SkillComponent's _unhandled_input, not here.
	# But clicking on a skill slot should also try to activate it.
	if skill_component and idx < skill_slots.size():
		var s_id := skill_slots[idx].skill_id
		if s_id != "":
			skill_component.try_activate_skill(s_id)


# ============================================================================
# ITEM SLOT MANAGEMENT (drag-drop from inventory)
# ============================================================================

## Assign an inventory item to an item slot (by reference — tracks inventory_index)
func assign_item_to_slot(slot_idx: int, inv_index: int) -> void:
	if slot_idx < 0 or slot_idx >= ITEM_SLOT_COUNT or inventory == null:
		return
	var slot_data := inventory.get_item_at(inv_index)
	if slot_data.item == null:
		item_slots[slot_idx].clear_slot()
		return
	item_slots[slot_idx].set_item(slot_data.item, slot_data.quantity, inv_index)


## Clear an item slot
func clear_item_slot(slot_idx: int) -> void:
	if slot_idx >= 0 and slot_idx < ITEM_SLOT_COUNT:
		item_slots[slot_idx].clear_slot()


func _activate_item_slot(idx: int) -> void:
	if idx < 0 or idx >= ITEM_SLOT_COUNT:
		return
	var slot := item_slots[idx]
	if slot.is_empty() or slot.item == null:
		return
	# Re-validate inventory reference (item may have been used/moved)
	if not _validate_slot(idx):
		return

	# Emit signal so player can use the item
	hotbar_item_used.emit(idx, slot.item, slot.inventory_index)


func _on_item_slot_activated(idx: int) -> void:
	_activate_item_slot(idx)


func _on_item_slot_right_clicked(idx: int) -> void:
	# Right-click removes item from hotbar slot
	if idx >= 0 and idx < ITEM_SLOT_COUNT:
		item_slots[idx].clear_slot()


func _on_hotbar_item_dropped(slot_idx: int, drag_data: Dictionary) -> void:
	var inv_index: int = drag_data.get("from_index", -1)
	var dragged_item: ItemData = drag_data.get("item")
	if inv_index < 0 or dragged_item == null or inventory == null:
		return

	# Check if this item is already on another hotbar slot — swap or remove old
	for i in range(ITEM_SLOT_COUNT):
		if i != slot_idx and item_slots[i].inventory_index == inv_index:
			item_slots[i].clear_slot()
			break

	# If drag came from another hotbar slot, swap
	var source: String = str(drag_data.get("source", ""))
	if source == "hotbar":
		var old_hotbar_idx: int = drag_data.get("hotbar_index", -1)
		if old_hotbar_idx >= 0 and old_hotbar_idx < ITEM_SLOT_COUNT and old_hotbar_idx != slot_idx:
			# Move old content of target to source
			var target_slot := item_slots[slot_idx]
			if not target_slot.is_empty():
				item_slots[old_hotbar_idx].set_item(target_slot.item, target_slot.quantity, target_slot.inventory_index)
			else:
				item_slots[old_hotbar_idx].clear_slot()

	# Assign new item
	assign_item_to_slot(slot_idx, inv_index)


## Refresh item slot quantities from inventory (called on inventory_changed)
func _refresh_item_slots() -> void:
	if inventory == null:
		return
	for i in range(ITEM_SLOT_COUNT):
		var slot := item_slots[i]
		if slot.inventory_index < 0:
			continue
		var slot_data := inventory.get_item_at(slot.inventory_index)
		if slot_data.item == null or slot_data.item.id != (slot.item.id if slot.item else ""):
			# Item was moved/consumed — clear the hotbar slot
			slot.clear_slot()
		else:
			slot.quantity = slot_data.quantity
			slot.queue_redraw()


## Validate that a hotbar slot still references a valid inventory item
func _validate_slot(idx: int) -> bool:
	var slot := item_slots[idx]
	if slot.inventory_index < 0 or inventory == null:
		return false
	var slot_data := inventory.get_item_at(slot.inventory_index)
	if slot_data.item == null or (slot.item != null and slot_data.item.id != slot.item.id):
		slot.clear_slot()
		return false
	# Update quantity
	slot.quantity = slot_data.quantity
	slot.queue_redraw()
	return true


# ============================================================================
# INPUT ACTION REGISTRATION (hotbar_1 through hotbar_8)
# ============================================================================

## Ensure hotbar_1..hotbar_8 input actions exist (keys 1-8)
func _ensure_input_actions() -> void:
	# Keys 1 through 8 have keycodes KEY_1(49) through KEY_8(56)
	for i in range(ITEM_SLOT_COUNT):
		var action_name := ITEM_INPUT_ACTIONS[i]
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
			var ev := InputEventKey.new()
			ev.physical_keycode = (KEY_1 + i) as Key
			InputMap.action_add_event(action_name, ev)
