# Inventory System Documentation

## Overview

The Emberfield inventory system is a pixel-art styled RPG inventory with equipment slots, item management, drag & drop functionality, and tab filtering. It follows a **data-driven architecture** separating data management from UI rendering.

---

## Architecture Diagram

```mermaid
flowchart TB
    subgraph Data["Data Layer"]
        ItemData["ItemData<br/>(Resource)<br/>• id, name<br/>• type, rarity<br/>• stats"]
        InventoryData["InventoryData<br/>(Resource)<br/>• inventory[]<br/>• equipment<br/>• gold"]
        ItemDatabase["ItemDatabase<br/>(Autoload)<br/>• items Dict<br/>• get_item()"]
    end
    
    ItemDatabase --> InventoryData
    InventoryData --> ItemData
    
    subgraph UI["InventoryPanel (UI)"]
        direction TB
        subgraph Grid["Inventory Grid"]
            direction LR
            Slots["[InventorySlotUI] x 32"]
            Tabs["Tab: [All][Equip][Material]"]
            Tooltip["Tooltip Panel"]
        end
        
        subgraph Equipment["Equipment Panel"]
            direction LR
            Helmet["[Helmet]"]
            ArmorWeapon["[Armor][Weapon]"]
            BootsShield["[Boots][Shield]"]
            Acc["[Acc1][Acc2]"]
            Stats["ATK: 0 DEF: 0<br/>Gold: 500"]
        end
    end
    
    InventoryData --> UI
    
    style Data fill:#2d2d2d
    style UI fill:#1a1a2e
    style Grid fill:#3d3d4d
    style Equipment fill:#3d3d4d
```

---

## File Structure

```
sense/ui/inventory/
├── inventory_data.gd      # Inventory data manager
├── inventory_slot_ui.gd   # Individual slot rendering
├── inventory_panel.gd     # Main panel controller
└── inventory_panel.tscn   # Panel scene file

sense/items/
├── item_data.gd           # Item resource definition
├── item_database.gd       # Pre-defined items (Autoload)
├── item_icon_atlas.gd     # Sprite sheet icon extraction
├── game_item.gd           # Droppable item scene script
├── game_item.tscn         # Droppable item scene
├── debug_icon_atlas.gd    # Debug tool for viewing sprite sheet
└── debug_icon_atlas.tscn  # Debug tool scene

assets/items/
└── item_icons.png         # Sprite sheet (512x867, 32x32 icons)
```

---

## Core Components

### 1. ItemData (Resource)

**File:** `item_data.gd`

Defines all properties for an item.

#### Item Types

| Type        | Slot           | Description                      |
|-------------|----------------|----------------------------------|
| WEAPON      | weapon         | Adds attack damage               |
| ARMOR       | armor          | Adds defense                     |
| HELMET      | helmet         | Adds defense                     |
| BOOTS       | boots          | Adds speed                       |
| SHIELD      | shield         | Adds defense                     |
| ACCESSORY   | accessory_1/2  | Various bonuses (2 slots)        |
| CONSUMABLE  | -              | Use for effects (heal, stamina)  |
| MATERIAL    | -              | Crafting materials               |
| QUEST       | -              | Cannot be dropped or sold        |

#### Item Rarity

| Rarity     | Color    | Color Code              |
|------------|----------|-------------------------|
| COMMON     | Gray     | `Color(0.7, 0.7, 0.7)`  |
| UNCOMMON   | Green    | `Color(0.3, 0.8, 0.3)`  |
| RARE       | Blue     | `Color(0.3, 0.5, 1.0)`  |
| EPIC       | Purple   | `Color(0.7, 0.3, 0.9)`  |
| LEGENDARY  | Orange   | `Color(1.0, 0.6, 0.1)`  |

#### Properties

```gdscript
# Basic Info
@export var id: String
@export var name: String
@export var description: String
@export var icon: Texture2D
@export var item_type: ItemType

# Icon from Atlas (sprite sheet)
@export var use_atlas_icon: bool = false
@export var atlas_icon_name: String = ""   # Named icon from ICONS dict
@export var atlas_row: int = 0              # Or direct row/col
@export var atlas_col: int = 0
@export var rarity: ItemRarity

# Stacking
@export var stackable: bool = true
@export var max_stack: int = 99

# Value
@export var buy_price: int
@export var sell_price: int

# Equipment Stats
@export var attack_bonus: int
@export var defense_bonus: int
@export var health_bonus: int
@export var speed_bonus: float

# Consumable Effects
@export var heal_amount: int
@export var stamina_restore: float
@export var effect_duration: float
```

#### Helper Methods

```gdscript
func get_rarity_color() -> Color    # Returns color based on rarity
func is_equippable() -> bool        # WEAPON, ARMOR, HELMET, BOOTS, SHIELD, ACCESSORY
func is_consumable() -> bool        # CONSUMABLE type
func get_icon() -> Texture2D        # Returns atlas icon or direct texture
```

---

### 1b. ItemIconAtlas (Static Class)

**File:** `sense/items/item_icon_atlas.gd`

Extracts individual icons from a sprite sheet.

#### Initialization

```gdscript
# Called by ItemDatabase on ready
ItemIconAtlas.init(sheet: Texture2D, size: Vector2i, cols: int)
```

#### Usage

```gdscript
# Get icon by row/column
var icon := ItemIconAtlas.get_icon(5, 1)  # row 5, col 1

# Get icon by name (from ICONS dictionary)
var icon := ItemIconAtlas.get_named_icon("sword_iron")

# Get icon by linear index
var icon := ItemIconAtlas.get_icon_by_index(83)
```

#### Predefined Icons (ICONS Dictionary)

```gdscript
const ICONS := {
    "sword_iron": Vector2i(5, 1),
    "leather_armor": Vector2i(7, 5),
    "potion_red": Vector2i(9, 0),
    "iron_ore": Vector2i(17, 1),
    "gold_coin": Vector2i(12, 7),
    "boot_green": Vector2i(1, 1),
    "helmet_horned": Vector2i(0, 0),
    # ... add more as needed
}
```

#### Debug Tool

Use `debug_icon_atlas.tscn` to visualize the sprite sheet grid:
- Hover to see row/col numbers
- Click to copy `ItemIconAtlas.get_icon(row, col)` code
- Adjust `icon_size` export if icons appear wrong (16 or 32)

---

### 2. InventoryData (Resource)

**File:** `inventory_data.gd`

Manages inventory storage, equipment, and gold.

#### Signals

```gdscript
signal inventory_changed
signal equipment_changed(slot_type: String)
signal gold_changed(amount: int)
```

#### Inventory Structure

```
INVENTORY_SIZE = 32 (8 columns × 4 rows)

Each slot: { "item": ItemData, "quantity": int }
```

#### Equipment Slots

```gdscript
var equipped_helmet: ItemData
var equipped_armor: ItemData
var equipped_weapon: ItemData
var equipped_shield: ItemData
var equipped_boots: ItemData
var equipped_accessory_1: ItemData
var equipped_accessory_2: ItemData
```

#### Key Methods

| Method                              | Description                                    |
|-------------------------------------|------------------------------------------------|
| `add_item(item, qty) -> int`        | Add item, returns remaining if full            |
| `remove_item_at(index, qty) -> bool`| Remove from specific slot                      |
| `remove_item(item, qty) -> bool`    | Remove by item reference                       |
| `get_item_at(index) -> Dictionary`  | Get {item, quantity} at index                  |
| `has_item(id, qty) -> bool`         | Check if inventory contains item               |
| `get_item_count(id) -> int`         | Total quantity of item                         |
| `swap_slots(from, to)`              | Swap two inventory slots                       |
| `equip_item(index)`                 | Equip item from inventory                      |
| `unequip_item(slot_type, target?)`  | Unequip to inventory (optional target slot)    |
| `swap_equipment(from, to)`          | Swap between equipment slots                   |
| `get_equipped(slot_type) -> ItemData` | Get equipped item                            |
| `get_total_attack_bonus() -> int`   | Sum of all equipment attack                    |
| `get_total_defense_bonus() -> int`  | Sum of all equipment defense                   |
| `use_item(index) -> Dictionary`     | Use consumable, returns effect result          |

---

### 3. InventorySlotUI (Control)

**File:** `inventory_slot_ui.gd`

Custom-drawn slot with pixel art style.

#### Signals

```gdscript
signal slot_clicked(index: int)
signal slot_right_clicked(index: int)
signal slot_hovered(index: int, is_hovering: bool)
signal slot_dropped(from_index: int, to_index: int)
signal equipment_dropped(from_data: Dictionary, to_slot_type: String)
signal inventory_to_equipment_dropped(from_index: int, to_slot_type: String)
signal equipment_to_inventory_dropped(from_slot_type: String, to_index: int)
```

#### Visual States

| State        | Border Color               | Background Color           |
|--------------|----------------------------|----------------------------|
| Normal       | Stone gray                 | Dark slate                 |
| Hover        | Light gold                 | Same                       |
| Selected     | Bright gold                | Same                       |
| Drop Target  | Green                      | Greenish tint              |

#### Drag & Drop

- **`_get_drag_data()`** - Creates drag preview with item icon
- **`_can_drop_data()`** - Validates drop (equipment slot compatibility)
- **`_drop_data()`** - Emits appropriate signal based on source/destination

---

### 4. InventoryPanel (CanvasLayer)

**File:** `inventory_panel.gd`, `inventory_panel.tscn`

Main UI controller.

#### Tab Filtering

| Tab      | Shows                                |
|----------|--------------------------------------|
| All      | All items                            |
| Equip    | WEAPON, ARMOR, HELMET, BOOTS, SHIELD, ACCESSORY |
| Material | MATERIAL, QUEST                      |

#### Input

| Action           | Effect                    |
|------------------|---------------------------|
| `open_inventory` | Toggle inventory (B key)  |
| `ui_cancel`      | Close inventory (Escape)  |
| Right-click item | Equip/Use item            |
| Drag & drop      | Move/swap items           |

#### Integration with Player

```gdscript
# In player.gd
var inventory: InventoryData
var inventory_panel: CanvasLayer

func _setup_inventory() -> void:
    inventory = InventoryData.new()
    inventory_panel = preload("res://sense/ui/inventory/inventory_panel.tscn").instantiate()
    get_tree().root.add_child(inventory_panel)
    inventory_panel.setup(inventory)
```

---

## Signal Flow

```
User Action          Signal Chain
───────────          ────────────
Click slot        → slot_clicked
                  → _on_inventory_slot_clicked
                  → select slot / swap items

Right-click       → slot_right_clicked
                  → _on_inventory_slot_right_clicked
                  → equip_item() / use_item()

Hover             → slot_hovered
                  → _on_slot_hovered
                  → show tooltip

Drag & Drop       → _get_drag_data (creates preview)
                  → _can_drop_data (validates)
                  → _drop_data (emits drop signal)
                  → _on_slot_dropped / _on_inventory_to_equipment_dropped
                  → swap_slots() / equip_item()
```

---

## Sequence Diagrams

### 1. Open/Close Inventory Flow

```mermaid
sequenceDiagram
    participant U as User Input
    participant P as Player
    participant IP as InventoryPanel
    participant ID as InventoryData
    participant SUI as InventorySlotUI[]

    U->>P: Press "open_inventory" (B key)
    P->>IP: toggle_inventory()
    
    alt Inventory is closed
        IP->>IP: show()
        IP->>IP: _refresh_inventory()
        
        loop For each slot (0..31)
            IP->>ID: get_item_at(index)
            ID-->>IP: {item, quantity}
            IP->>SUI: set_item(item, quantity)
            SUI->>SUI: queue_redraw()
        end
        
        IP->>IP: _refresh_equipment_slots()
        IP->>IP: _refresh_stats()
        IP->>P: get_tree().paused = true
        
    else Inventory is open
        IP->>IP: hide()
        IP->>IP: _clear_selection()
        IP->>IP: _hide_tooltip()
        IP-->>P: inventory_closed.emit()
        IP->>P: get_tree().paused = false
    end
```

### 2. Add Item to Inventory Flow

```mermaid
sequenceDiagram
    participant SRC as Source (Pickup/Shop/Chest)
    participant ID as InventoryData
    participant IP as InventoryPanel
    participant SUI as InventorySlotUI

    SRC->>ID: add_item(ItemData, quantity)
    
    ID->>ID: Check if item.stackable
    
    alt Stackable Item
        loop Find existing stack
            ID->>ID: Check inventory[i].item.id == item.id
            alt Found & stack not full
                ID->>ID: Add to existing stack
                ID->>ID: Calculate overflow
                Note over ID: remaining = qty - (max_stack - current)
            end
        end
    end
    
    alt Has remaining quantity
        loop Find empty slot
            ID->>ID: Check inventory[i].item == null
            alt Found empty
                ID->>ID: inventory[i] = {item, qty}
                ID->>ID: remaining -= qty
            end
        end
    end
    
    ID-->>ID: inventory_changed.emit()
    ID-->>SRC: return remaining (0 = success)
    
    Note over IP: Signal received
    IP->>IP: _refresh_inventory()
    
    loop For each visible slot
        IP->>ID: get_item_at(index)
        IP->>SUI: set_item(item, quantity)
        SUI->>SUI: queue_redraw()
    end
```

### 3. Tab Filtering Flow

```mermaid
sequenceDiagram
    participant U as User
    participant IP as InventoryPanel
    participant TB as Tab Buttons
    participant ID as InventoryData
    participant SUI as InventorySlotUI[]

    U->>TB: Click "Equip" tab
    TB-->>IP: _on_tab_pressed(TabFilter.EQUIP)
    IP->>IP: current_filter = TabFilter.EQUIP
    IP->>IP: _refresh_inventory()
    
    loop For each slot index (0..31)
        IP->>ID: get_item_at(index)
        ID-->>IP: {item, quantity}
        
        IP->>IP: _item_matches_filter(item)
        
        alt TabFilter.ALL
            IP-->>IP: return true
        else TabFilter.EQUIP
            IP->>IP: Check item.is_equippable()
            Note over IP: WEAPON, ARMOR, HELMET,<br/>BOOTS, SHIELD, ACCESSORY
        else TabFilter.MATERIAL
            IP->>IP: Check MATERIAL or QUEST type
        end
        
        alt Item matches filter
            IP->>SUI: set_item(item, quantity)
            IP->>SUI: show()
        else Item doesn't match
            IP->>SUI: set_item(null, 0)
            Note over SUI: Show empty slot or hide
        end
    end
    
    IP->>IP: _update_tab_visuals()
```

### 4. Tooltip Display Flow

```mermaid
sequenceDiagram
    participant U as User
    participant SUI as InventorySlotUI
    participant IP as InventoryPanel
    participant TP as TooltipPanel
    participant ITM as ItemData

    U->>SUI: Mouse enter slot
    SUI-->>IP: slot_hovered(index, true)
    IP->>IP: _on_slot_hovered(index, true)
    
    IP->>IP: get_item_at(index)
    
    alt Has item
        IP->>ITM: Access item properties
        IP->>TP: _show_tooltip(item)
        
        TP->>TP: Set name_label.text = item.name
        TP->>TP: Set name color = item.get_rarity_color()
        TP->>TP: Set type_label.text = ItemType name
        TP->>TP: Set description_label.text
        
        alt item.is_equippable()
            TP->>TP: Show stats (ATK, DEF, HP, SPD)
        else item.is_consumable()
            TP->>TP: Show effects (Heal, Stamina)
        end
        
        TP->>TP: Set price_label (Buy/Sell)
        TP->>TP: Position near mouse
        TP->>TP: show()
        
    else Empty slot
        IP->>TP: hide()
    end
    
    Note over U,SUI: Mouse leave
    U->>SUI: Mouse exit slot
    SUI-->>IP: slot_hovered(index, false)
    IP->>TP: _hide_tooltip()
    TP->>TP: hide()
```

### 5. Swap Inventory Slots Flow

```mermaid
sequenceDiagram
    participant U as User
    participant SRC as Source SlotUI
    participant DST as Destination SlotUI
    participant IP as InventoryPanel
    participant ID as InventoryData

    U->>SRC: Start drag from slot[3]
    SRC->>SRC: _get_drag_data()
    
    Note over SRC: Create drag preview
    SRC->>SRC: Create TextureRect with item.icon
    SRC-->>U: Return {type: "inventory", index: 3, item: ItemData}
    
    U->>DST: Drag over slot[7]
    DST->>DST: _can_drop_data(data)
    DST->>DST: Check data.type == "inventory"
    DST-->>U: return true
    DST->>DST: is_drop_target = true
    DST->>DST: queue_redraw() (green border)
    
    U->>DST: Drop on slot[7]
    DST->>DST: _drop_data(data)
    DST-->>IP: slot_dropped(from: 3, to: 7)
    
    IP->>IP: _on_slot_dropped(3, 7)
    IP->>ID: swap_slots(3, 7)
    
    ID->>ID: temp = inventory[3]
    ID->>ID: inventory[3] = inventory[7]
    ID->>ID: inventory[7] = temp
    ID-->>ID: inventory_changed.emit()
    
    IP->>IP: _refresh_inventory()
```

### 6. Equipment Stats Calculation Flow

```mermaid
sequenceDiagram
    participant IP as InventoryPanel
    participant ID as InventoryData
    participant EQ as Equipment Slots
    participant ITM as ItemData
    participant UI as Stats Labels

    IP->>IP: _refresh_stats()
    
    IP->>ID: get_total_attack_bonus()
    
    ID->>ID: total = 0
    
    loop For each equipment slot
        ID->>EQ: Get equipped_weapon
        alt Has item
            EQ-->>ID: ItemData
            ID->>ITM: item.attack_bonus
            ID->>ID: total += attack_bonus
        end
        
        ID->>EQ: Get equipped_armor
        ID->>EQ: Get equipped_helmet
        ID->>EQ: Get equipped_boots
        ID->>EQ: Get equipped_shield
        ID->>EQ: Get equipped_accessory_1
        ID->>EQ: Get equipped_accessory_2
    end
    
    ID-->>IP: return total_attack
    
    IP->>ID: get_total_defense_bonus()
    ID-->>IP: return total_defense
    
    IP->>ID: get_total_health_bonus()
    ID-->>IP: return total_health
    
    IP->>UI: attack_label.text = "ATK: " + str(attack)
    IP->>UI: defense_label.text = "DEF: " + str(defense)
    IP->>UI: gold_label.text = "Gold: " + str(inventory.gold)
```

### 7. Right-Click Context Actions Flow

```mermaid
sequenceDiagram
    participant U as User
    participant SUI as InventorySlotUI
    participant IP as InventoryPanel
    participant ID as InventoryData
    participant P as Player

    U->>SUI: Right-click on slot[5]
    SUI-->>IP: slot_right_clicked(5)
    IP->>IP: _on_inventory_slot_right_clicked(5)
    
    IP->>ID: get_item_at(5)
    ID-->>IP: {item: ItemData, quantity: int}
    
    alt item == null
        Note over IP: Do nothing
    else item.is_equippable()
        IP->>ID: equip_item(5)
        
        ID->>ID: Determine slot_type from item.item_type
        Note over ID: WEAPON→"weapon"<br/>ARMOR→"armor"<br/>etc.
        
        ID->>ID: currently_equipped = get_equipped(slot_type)
        
        alt Has equipped item
            ID->>ID: Swap: inventory[5] = currently_equipped
        else No equipped item
            ID->>ID: inventory[5] = {item: null, quantity: 0}
        end
        
        ID->>ID: _set_equipped(slot_type, item)
        ID-->>ID: equipment_changed.emit(slot_type)
        ID-->>ID: inventory_changed.emit()
        
        ID-->>P: Signal propagates
        P->>P: _on_equipment_changed()
        P->>P: stats.apply_equipment_bonuses(inventory)
        
    else item.is_consumable()
        IP->>ID: use_item(5)
        
        ID->>ID: Build result dict
        ID->>ID: remove_item_at(5, 1)
        ID-->>ID: inventory_changed.emit()
        ID-->>IP: return {heal_amount, stamina_restore, ...}
        
        IP-->>P: item_used.emit(result)
        P->>P: _on_item_used(result)
        P->>P: Apply heal/stamina effects
    end
    
    IP->>IP: _refresh_inventory()
    IP->>IP: _refresh_equipment_slots()
    IP->>IP: _refresh_stats()
```

### 8. Equipment Drag & Drop Validation Flow

```mermaid
sequenceDiagram
    participant U as User
    participant SRC as Inventory SlotUI
    participant DST as Equipment SlotUI
    participant IP as InventoryPanel

    U->>SRC: Drag HELMET item from inventory
    SRC->>SRC: _get_drag_data()
    SRC-->>U: {type: "inventory", index: 2, item: HelmetItem}
    
    U->>DST: Hover over "weapon" equipment slot
    DST->>DST: _can_drop_data(data)
    DST->>DST: _item_fits_slot(item, "weapon")
    
    Note over DST: Check item.item_type compatibility
    DST->>DST: item.item_type == HELMET
    DST->>DST: slot_type == "weapon"
    DST-->>U: return false (incompatible)
    DST->>DST: Show red/invalid visual
    
    U->>DST: Hover over "helmet" equipment slot
    DST->>DST: _can_drop_data(data)
    DST->>DST: _item_fits_slot(item, "helmet")
    DST->>DST: item.item_type == HELMET ✓
    DST->>DST: slot_type == "helmet" ✓
    DST-->>U: return true (compatible)
    DST->>DST: is_drop_target = true
    DST->>DST: queue_redraw() (green border)
    
    U->>DST: Drop item
    DST->>DST: _drop_data(data)
    DST-->>IP: inventory_to_equipment_dropped(2, "helmet")
    IP->>IP: _on_inventory_to_equipment_dropped(2, "helmet")
    IP->>IP: inventory.equip_item(2)
```

---

## How to Add New Items

### Method 1: In ItemDatabase (Autoload)

Add to `_create_sample_items()` in `item_database.gd`:

```gdscript
var new_item := ItemData.new()
new_item.id = "unique_id"
new_item.name = "Display Name"
new_item.description = "Item description"
new_item.item_type = ItemData.ItemType.WEAPON
new_item.rarity = ItemData.ItemRarity.RARE
new_item.stackable = false
new_item.attack_bonus = 50
new_item.buy_price = 500
new_item.sell_price = 250

# IMPORTANT: Configure atlas icon!
new_item.use_atlas_icon = true
new_item.atlas_icon_name = "sword_iron"  # Use named icon
# OR specify row/col directly:
# new_item.atlas_row = 5
# new_item.atlas_col = 1

items["unique_id"] = new_item
```

### Method 2: Resource File (.tres)

Create `res://items/my_item.tres`:

```
[gd_resource type="Resource" script_class="ItemData" load_steps=2]

[ext_resource type="Script" path="res://sense/items/item_data.gd" id="1"]

[resource]
script = ExtResource("1")
id = "my_item"
name = "My Item"
item_type = 0
rarity = 2
use_atlas_icon = true
atlas_icon_name = "sword_iron"
```

---

## How to Give Items to Player

### ✅ Correct: Use ItemDatabase

```gdscript
# ALWAYS get items from ItemDatabase to ensure icons work!
var sword := ItemDatabase.get_item("iron_sword")
if sword:
    player.inventory.add_item(sword, 1)

# Give stackable items
var potion := ItemDatabase.get_item("health_potion")
if potion:
    player.inventory.add_item(potion, 5)

# Give gold
player.inventory.gold += 100
```

### ❌ Wrong: Creating ItemData Manually

```gdscript
# DON'T DO THIS - icons won't work!
var sword := ItemData.new()
sword.id = "iron_sword"
sword.name = "Iron Sword"
# ... this item won't have atlas icon configured!
player.inventory.add_item(sword, 1)
```

### Why Use ItemDatabase?

Items in `ItemDatabase` have `use_atlas_icon = true` and atlas coordinates configured.
Manually created `ItemData` objects default to `use_atlas_icon = false`, causing missing icons.

---

## Maintenance Guide

### Adding New Item Type

1. Add enum value in `item_data.gd`:
   ```gdscript
   enum ItemType {
       ...,
       NEW_TYPE
   }
   ```

2. Update `is_equippable()` if it's equipment

3. Add slot in `inventory_data.gd` if needed

4. Update `_item_fits_slot()` in both:
   - `inventory_slot_ui.gd`
   - `inventory_panel.gd`

### Adding New Equipment Slot

1. Add variable in `inventory_data.gd`:
   ```gdscript
   var equipped_new_slot: ItemData = null
   ```

2. Update all match statements:
   - `equip_item()`
   - `unequip_item()`
   - `get_equipped()`
   - `_set_equipped()`
   - `_item_fits_slot()`

3. Add UI slot in `inventory_panel.tscn`

4. Update `_setup_equipment_slots()` in `inventory_panel.gd`

### Modifying Slot Appearance

Edit constants in `inventory_slot_ui.gd`:

```gdscript
const SLOT_SIZE := Vector2(44, 44)
const ICON_PADDING := 4
const BORDER_WIDTH := 2

# Colors
const SLOT_BG_COLOR := Color(0.14, 0.12, 0.16, 1.0)
const SLOT_BORDER_COLOR := Color(0.35, 0.32, 0.28, 1.0)
```

### Changing Tab Filters

1. Update `TabFilter` enum in `inventory_panel.gd`
2. Modify `_item_matches_filter()` logic
3. Add/remove tab buttons in `inventory_panel.tscn`
4. Connect buttons in `_setup_tabs()`

---

## Troubleshooting

### Item Icons Missing (Gray Squares)

1. **Are you using ItemDatabase?** Items must come from `ItemDatabase.get_item()`, not `ItemData.new()`
2. Check `item.use_atlas_icon` is `true`
3. Verify atlas is initialized: `ItemIconAtlas.sprite_sheet != null`
4. Check named icon exists in `ItemIconAtlas.ICONS` dictionary
5. Verify row/col coordinates are correct using `debug_icon_atlas.tscn`

### Item Not Appearing in Inventory

1. Check `item.icon` is assigned (or atlas configured)
2. Verify `inventory_changed` signal is connected
3. Call `_refresh_inventory()` after changes

### Drag & Drop Not Working

1. Ensure `mouse_filter = MOUSE_FILTER_STOP` on slots
2. Check `_can_drop_data()` returns true
3. Verify signal connections for drop handlers

### Equipment Stats Not Updating

1. Ensure `equipment_changed` signal is connected
2. Call `_refresh_stats()` after equip/unequip

### Tooltip Not Showing

1. Check tooltip_panel path in `inventory_panel.gd`
2. Verify `_show_tooltip()` is called on hover
3. Ensure tooltip_panel starts hidden

---

## Future Improvements

- [ ] Item sorting (by type, rarity, name)
- [ ] Item comparison tooltip
- [ ] Hotbar quick slots
- [ ] Item splitting (shift+drag)
- [ ] Context menu (use, equip, drop, destroy)
- [ ] Item search/filter
- [ ] Save/Load inventory to file
- [ ] Inventory capacity upgrades
