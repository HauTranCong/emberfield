# Hệ Thống Item - Emberfield

## Tổng Quan

Hệ thống item thống nhất với **một scene duy nhất** (`GameItem`) có thể cấu hình thành nhiều loại:
- Item drops từ enemy
- Gold coins
- Health/Stamina/XP pickups
- Treasure chests
- World items (tương tác)

---

## Kiến Trúc

```mermaid
flowchart TB
    subgraph GameItem["GameItem (Area2D)"]
        direction TB
        subgraph Modes["Configuration"]
            PM["PickupMode<br/>• AUTO<br/>• INTERACT<br/>• PROXIMITY<br/>• MAGNET"]
            VS["VisualStyle<br/>• STATIC<br/>• BOB<br/>• SPARKLE<br/>• ROTATE"]
            CT["ContentType<br/>• ITEM<br/>• GOLD<br/>• HEALTH<br/>• STAMINA<br/>• XP<br/>• MULTI_ITEM"]
        end
    end
    
    style GameItem fill:#2d2d2d,stroke:#4ecdc4
    style Modes fill:#1a1a1a
```

---

## Cấu Trúc File

```
sense/
├── items/
│   ├── game_item.gd        # Script chính - unified item system
│   ├── game_item.tscn      # Scene duy nhất cho mọi loại item
│   ├── item_spawner.gd     # Utility class để spawn items
│   ├── item_icon_atlas.gd  # Extract icons từ sprite sheet
│   ├── loot_table.gd       # Drop rate system
│   ├── debug_icon_atlas.gd # Debug tool xem sprite sheet
│   ├── debug_icon_atlas.tscn
│   ├── item_data.gd        # Resource định nghĩa item
│   └── item_database.gd    # Autoload chứa tất cả items
│
├── ui/inventory/
│   ├── inventory_data.gd   # Quản lý inventory + equipment
│   └── inventory_panel.gd  # UI hiển thị

assets/items/
└── item_icons.png          # Sprite sheet (512x867, 32x32 icons)
```

---

## Enums

### PickupMode - Cách nhặt item

| Mode | Mô tả |
|------|-------|
| `AUTO` | Tự động nhặt khi chạm vào |
| `INTERACT` | Cần nhấn phím tương tác |
| `PROXIMITY` | Tự động nhặt khi đến gần |
| `MAGNET` | Item tự bay về phía player |

### VisualStyle - Hiệu ứng visual

| Style | Mô tả |
|-------|-------|
| `STATIC` | Đứng yên |
| `BOB` | Nhấp nhô lên xuống |
| `SPARKLE` | Lấp lánh (cho quest items) |
| `ROTATE` | Xoay tròn |

### ContentType - Loại nội dung

| Type | Mô tả |
|------|-------|
| `ITEM` | Item thêm vào inventory |
| `GOLD` | Tiền tệ |
| `HEALTH` | Hồi máu |
| `STAMINA` | Hồi stamina |
| `XP` | Kinh nghiệm |
| `MULTI_ITEM` | Rương chứa nhiều item |

---

## Collision Layers

| Layer | Giá trị | Mô tả |
|-------|---------|-------|
| PICKUP | 10 (512) | Item có thể nhặt |
| PLAYER | 2 (2) | Player body |

GameItem setup:
```gdscript
collision_layer = CollisionLayers.Layer.PICKUP  # Layer 10
collision_mask = CollisionLayers.Layer.PLAYER   # Mask 2
```

---

## Signals

### GameItem Signals

```gdscript
signal collected(content_type: ContentType, item_id: String, quantity: int)
signal chest_opened(contents: Array[Dictionary])
```

### InventoryData Signals

```gdscript
signal inventory_changed
signal equipment_changed(slot_type: String)
signal gold_changed(amount: int)
```

### InventoryPanel Signals

```gdscript
signal inventory_closed
signal item_used(result: Dictionary)
```

---

## Item Icons từ Sprite Sheet

### Cấu Hình Atlas

Atlas được khởi tạo bởi `ItemDatabase` khi game chạy:

```gdscript
# Trong item_database.gd _init_icon_atlas()
const ICON_SHEET_PATH := "res://assets/items/item_icons.png"
# Sprite sheet: 512x867 pixels, 32x32 icons, 16 columns
ItemIconAtlas.init(sheet, Vector2i(32, 32), 16)
```

### Predefined Icon Names (ICONS Dictionary)

| Icon Name | Position (Row, Col) | Description |
|-----------|---------------------|-------------|
| `default` | (0, 2) | Default bag icon for missing items |
| `helmet_horned` | (0, 0) | Horned helmet |
| `scroll` | (0, 1) | Scroll |
| `bag` | (0, 2) | Bag (default icon) |
| `heart` | (0, 4) | Health heart |
| `gamepad` | (0, 5) | Gamepad |
| `brain` | (0, 6) | Brain |
| `skull` | (0, 8) | Skull |
| `arrow` | (1, 0) | Arrow projectile |
| `boot_green` | (1, 1) | Green boots |
| `gem_green` | (1, 2) | Green gem |
| `cape_red` | (1, 3) | Red cape |
| `cape_blue` | (1, 4) | Blue cape |
| `sword_iron` | (5, 1) | Iron sword |
| `leather_armor` | (7, 5) | Leather armor |
| `potion_red` | (9, 0) | Red health potion |
| `gold_coin` | (12, 7) | Gold coin currency |
| `iron_ore` | (17, 1) | Iron ore material |
| `bone` | (17, 9) | Bone drop |

### Sử Dụng Atlas Icon

```gdscript
var item := ItemData.new()
item.use_atlas_icon = true
item.atlas_row = 2
item.atlas_col = 5

# Hoặc dùng tên preset (RECOMMENDED)
item.atlas_icon_name = "iron_sword"  # Uses ICONS dictionary lookup
```

### Default Icon Fallback

Khi một item không có icon được định nghĩa trong ICONS dictionary, hệ thống sẽ tự động sử dụng **default icon** (bag icon tại vị trí row=0, col=2).

```gdscript
# ItemIconAtlas.gd
const DEFAULT_ICON := Vector2i(0, 2)  # bag icon

## Get a predefined icon by name (returns default if not found)
static func get_named_icon(icon_name: String) -> AtlasTexture:
    if not ICONS.has(icon_name):
        push_warning("ItemIconAtlas: Unknown icon name '%s', using default" % icon_name)
        return get_icon(DEFAULT_ICON.x, DEFAULT_ICON.y)
    var pos: Vector2i = ICONS[icon_name]
    return get_icon(pos.x, pos.y)

## Get the default icon directly
static func get_default_icon() -> AtlasTexture:
    return get_icon(DEFAULT_ICON.x, DEFAULT_ICON.y)
```

### Lấy Icon

```gdscript
var texture := item.get_icon()  # Tự động dùng atlas hoặc icon thường

# Hoặc lấy trực tiếp từ atlas
var icon := ItemIconAtlas.get_named_icon("sword_iron")
var default_icon := ItemIconAtlas.get_default_icon()

# Xem danh sách tất cả icons có sẵn
var available := ItemIconAtlas.get_available_icons()
```

---

## Loot Table

### Tạo Loot Table

```gdscript
var loot := LootTable.new()
loot.drop_count = 3          # Roll 3 lần
loot.nothing_weight = 40     # 40% không drop gì

# Gold range
loot.gold_range = Vector2i(10, 50)

# Add entries: item_id, weight, min_qty, max_qty
loot.add_entry("health_potion", 100, 1, 2)  # Common
loot.add_entry("iron_ore", 50, 1, 5)        # Uncommon
loot.add_entry("diamond", 5, 1, 1)          # Rare
```

### Sử Dụng Trong Enemy

```gdscript
# skeleton.gd
@export var loot_table: LootTable

func _ready():
    if loot_table == null:
        loot_table = _create_default_loot_table()

func _create_default_loot_table() -> LootTable:
    var table := LootTable.new()
    table.drop_count = 2
    table.nothing_weight = 40
    table.gold_range = Vector2i(5, 15)
    table.add_entry("bone", 100, 1, 3)
    table.add_entry("health_potion", 30, 1, 1)
    return table
```

---

## Equipment System

### Equip Item

```gdscript
# Right-click in inventory to equip
inventory_data.equip_item(slot_index)

# Equipment slot types:
# "helmet", "armor", "weapon", "shield", "boots"
# "accessory_1", "accessory_2"
```

### Unequip Item

```gdscript
inventory_data.unequip_item("weapon")
```

### Get Equipment Bonuses

```gdscript
var total_attack := inventory.get_total_attack_bonus()
var total_defense := inventory.get_total_defense_bonus()
var total_health := inventory.get_total_health_bonus()
var total_speed := inventory.get_total_speed_bonus()
```

### Auto-Apply to Player Stats

Player tự động nhận equipment bonuses khi trang bị thay đổi:

```gdscript
# Trong player.gd
func _on_equipment_changed(_slot_type: String):
    stats.apply_equipment_bonuses(inventory)
```

---

## Consumable Items

### Sử Dụng Consumable

```gdscript
# Right-click consumable in inventory
var result := inventory_data.use_item(slot_index)

# result = {
#   "success": true,
#   "heal_amount": 50,
#   "stamina_restore": 0,
#   "effect_duration": 0
# }
```

### Player Nhận Effects

```gdscript
# Trong player.gd
func _on_item_used(result: Dictionary):
    if result.success:
        if result.heal_amount > 0:
            stats.heal(result.heal_amount)
        if result.stamina_restore > 0:
            stats.restore_stamina(result.stamina_restore)
```

---

## Character Stats với Equipment

```gdscript
# character_stats.gd
# Base stats
@export var base_attack_damage: int = 10
@export var base_defense: int = 0
@export var base_max_health: int = 100
@export var base_move_speed: float = 120.0

# Equipment bonuses
var equipment_attack_bonus: int = 0
var equipment_defense_bonus: int = 0
var equipment_health_bonus: int = 0
var equipment_speed_bonus: float = 0.0

# Final stats (computed)
var attack_damage: int:
    get: return base_attack_damage + equipment_attack_bonus

var defense: int:
    get: return base_defense + equipment_defense_bonus
```

---

## Factory Methods

GameItem cung cấp static factory methods:

```gdscript
# Tạo item instance trực tiếp
var item := GameItem.create_item("health_potion", 5)

# Tạo gold
var gold := GameItem.create_gold(100)

# Tạo health pickup
var health := GameItem.create_health(25)

# Tạo chest (contents array + gold amount)
var chest := GameItem.create_chest([{"item_id": "sword", "quantity": 1}], 50)
```

---

## ⚠️ Quan Trọng: Sử Dụng ItemDatabase

**LUÔN** lấy item từ `ItemDatabase` thay vì tạo `ItemData.new()`:

```gdscript
# ✅ ĐÚNG - Item có icon từ atlas
var sword := ItemDatabase.get_item("iron_sword")
if sword:
    inventory.add_item(sword, 1)

# ❌ SAI - Item sẽ không có icon!
var sword := ItemData.new()
sword.id = "iron_sword"
# ... icon sẽ bị thiếu vì use_atlas_icon = false
```

Items trong `ItemDatabase` đã được cấu hình `use_atlas_icon = true` và tọa độ atlas.

---

## Sequence Diagrams

### 1. Item Pickup Flow

```mermaid
sequenceDiagram
    participant P as Player
    participant GI as GameItem (Area2D)
    participant IS as ItemSpawner
    participant IDB as ItemDatabase
    participant ID as InventoryData
    participant IP as InventoryPanel

    Note over GI,P: AUTO/MAGNET Pickup Mode
    GI->>GI: body_entered(Player)
    GI->>GI: _collect_item()
    
    alt ContentType.ITEM
        GI->>IDB: get_item(item_id)
        IDB-->>GI: ItemData
        GI->>P: inventory.add_item(ItemData, qty)
        P->>ID: add_item(item, quantity)
        ID->>ID: Find empty slot or stack
        ID-->>ID: inventory_changed.emit()
        ID-->>IP: Signal received
        IP->>IP: _refresh_inventory()
    else ContentType.GOLD
        GI->>ID: gold += amount
        ID-->>ID: gold_changed.emit(amount)
    else ContentType.HEALTH
        GI->>P: stats.heal(amount)
    end
    
    GI->>GI: collected.emit()
    GI->>GI: queue_free()
```

### 2. Enemy Loot Drop Flow

```mermaid
sequenceDiagram
    participant E as Enemy
    participant HC as HealthComponent
    participant LT as LootTable
    participant IS as ItemSpawner
    participant IDB as ItemDatabase
    participant GI as GameItem

    E->>HC: take_damage(amount)
    HC->>HC: current_health <= 0
    HC-->>E: died.emit()
    
    E->>IS: spawn_enemy_drops(loot_table, xp)
    IS->>LT: roll_drops()
    
    loop For each drop_count
        LT->>LT: Calculate weighted random
        LT-->>IS: {item_id, quantity}
    end
    
    LT-->>IS: Array[drops]
    
    loop For each drop
        IS->>IDB: get_item(item_id)
        IDB-->>IS: ItemData (with atlas icon)
        IS->>GI: instantiate GameItem.tscn
        IS->>GI: setup(item_id, qty, pickup_mode)
        GI->>GI: Set collision_layer = PICKUP
        GI->>GI: Set collision_mask = PLAYER
        IS->>IS: Add scatter effect from death position
    end
    
    opt Has gold_range
        IS->>GI: spawn_gold(random amount)
    end
    
    opt Has XP
        IS->>GI: spawn_xp(xp_amount)
    end
```

### 3. Equip Item Flow

```mermaid
sequenceDiagram
    participant U as User Input
    participant IP as InventoryPanel
    participant SUI as InventorySlotUI
    participant ID as InventoryData
    participant CS as CharacterStats

    U->>SUI: Right-click on equipment item
    SUI-->>IP: slot_right_clicked(index)
    IP->>IP: _on_inventory_slot_right_clicked(index)
    IP->>ID: get_item_at(index)
    ID-->>IP: {item: ItemData, quantity: int}
    
    alt item.is_equippable()
        IP->>ID: equip_item(index)
        ID->>ID: Determine slot_type from item_type
        
        opt Already has equipped item
            ID->>ID: Swap with inventory slot
        end
        
        ID->>ID: _set_equipped(slot_type, item)
        ID->>ID: Remove from inventory[index]
        ID-->>ID: equipment_changed.emit(slot_type)
        ID-->>ID: inventory_changed.emit()
        
        ID-->>IP: Signal received
        IP->>IP: _refresh_equipment_slots()
        IP->>IP: _refresh_inventory()
        IP->>IP: _refresh_stats()
        
        IP->>CS: get_total_attack_bonus()
        IP->>CS: get_total_defense_bonus()
    end
```

### 4. Use Consumable Flow

```mermaid
sequenceDiagram
    participant U as User Input
    participant IP as InventoryPanel
    participant ID as InventoryData
    participant P as Player
    participant CS as CharacterStats

    U->>IP: Right-click on consumable
    IP->>ID: get_item_at(index)
    ID-->>IP: {item: ItemData, quantity: int}
    
    alt item.is_consumable()
        IP->>ID: use_item(index)
        ID->>ID: Check quantity > 0
        ID->>ID: Build result Dictionary
        
        Note over ID: result = {<br/>heal_amount,<br/>stamina_restore,<br/>effect_duration<br/>}
        
        ID->>ID: remove_item_at(index, 1)
        ID-->>ID: inventory_changed.emit()
        ID-->>IP: return result
        
        IP-->>P: item_used.emit(result)
        
        P->>P: _on_item_used(result)
        
        alt result.heal_amount > 0
            P->>CS: heal(heal_amount)
            CS->>CS: current_health += amount
            CS->>CS: Clamp to max_health
        end
        
        alt result.stamina_restore > 0
            P->>CS: restore_stamina(amount)
        end
    end
```

### 5. Drag & Drop Flow

```mermaid
sequenceDiagram
    participant U as User
    participant SRC as Source Slot (UI)
    participant DST as Destination Slot (UI)
    participant IP as InventoryPanel
    participant ID as InventoryData

    U->>SRC: Start drag
    SRC->>SRC: _get_drag_data()
    SRC-->>U: Preview with item icon
    
    U->>DST: Hover over destination
    DST->>DST: _can_drop_data()
    
    alt Inventory to Inventory
        DST-->>U: Valid (green border)
        U->>DST: Drop
        DST-->>IP: slot_dropped(from, to)
        IP->>ID: swap_slots(from, to)
        ID-->>ID: inventory_changed.emit()
        
    else Inventory to Equipment
        DST->>DST: Check _item_fits_slot()
        DST-->>U: Valid if compatible
        U->>DST: Drop
        DST-->>IP: inventory_to_equipment_dropped(idx, slot_type)
        IP->>ID: equip_item(index)
        ID-->>ID: equipment_changed.emit()
        
    else Equipment to Inventory
        U->>DST: Drop
        DST-->>IP: equipment_to_inventory_dropped(slot_type, idx)
        IP->>ID: unequip_item(slot_type, target_index)
        ID-->>ID: equipment_changed.emit()
        ID-->>ID: inventory_changed.emit()
    end
    
    IP->>IP: _refresh_all()
```

### 6. Complete Item Lifecycle

```mermaid
sequenceDiagram
    participant W as World/Enemy
    participant IS as ItemSpawner
    participant GI as GameItem
    participant P as Player
    participant ID as InventoryData
    participant IP as InventoryPanel
    participant CS as CharacterStats

    Note over W,CS: PHASE 1: Item Creation
    W->>IS: spawn_item() or spawn_enemy_drops()
    IS->>GI: Create & configure GameItem
    GI->>GI: Set visual style (BOB/SPARKLE)
    GI->>GI: Set pickup mode (AUTO/MAGNET)
    
    Note over W,CS: PHASE 2: Item Pickup
    P->>GI: Enter collision area
    GI->>ID: add_item(ItemData, qty)
    ID-->>IP: inventory_changed
    GI->>GI: queue_free()
    
    Note over W,CS: PHASE 3: Item Management
    
    alt Equip
        P->>ID: equip_item(index)
        ID-->>IP: equipment_changed
        IP->>CS: Recalculate bonuses
        CS->>P: Apply attack/defense/speed
    else Use Consumable
        P->>ID: use_item(index)
        ID-->>P: Effect result
        P->>CS: Apply heal/stamina
    else Drop
        P->>ID: remove_item_at(index)
        P->>IS: spawn_world_item()
    end
```

---

## Hướng Dẫn Sử Dụng

### 1. Spawn Item Thường

```gdscript
# Spawn health potion
ItemSpawner.spawn_item(
    get_tree(),
    global_position,
    "health_potion",
    1
)

# Spawn với scatter effect
ItemSpawner.spawn_item(
    get_tree(),
    global_position,
    "iron_sword",
    1,
    enemy_position,  # scatter from this point
    GameItem.PickupMode.AUTO
)
```

### 2. Spawn Gold

```gdscript
# Spawn gold với magnet effect
ItemSpawner.spawn_gold(
    get_tree(),
    global_position,
    100  # amount
)
```

### 3. Spawn Health/Stamina/XP

```gdscript
# Health pickup
ItemSpawner.spawn_health(get_tree(), position, 25)

# Stamina pickup
ItemSpawner.spawn_stamina(get_tree(), position, 30)

# XP orb
ItemSpawner.spawn_xp(get_tree(), position, 50)
```

### 4. Spawn Từ Loot Table

```gdscript
# Trong enemy script
@export var loot_table: LootTable

func _on_died():
    ItemSpawner.spawn_enemy_drops(
        get_tree(),
        global_position,
        loot_table,
        xp_amount  # optional XP
    )
```

### 5. Spawn Treasure Chest

```gdscript
ItemSpawner.spawn_chest(
    get_tree(),
    position,
    ["iron_sword", "health_potion"],  # item_ids array
    50,             # gold amount
    true,           # requires key
    "iron_key"      # key item id
)
```

### 6. Spawn World Item (Static, Interact)

```gdscript
ItemSpawner.spawn_world_item(
    get_tree(),
    position,
    "rare_gem",
    1
)
```

---

## Implementation Guide: Spawning Items from Enemy & Chest

### 🎯 Overview

This guide explains how to implement item drops from **Enemies** and **Chests** using the `ItemSpawner` and `LootTable` systems.

```mermaid
flowchart TB
    subgraph Sources["Sources"]
        Enemy["Enemy<br/>(dies)"]
        Chest["Chest<br/>(interact)"]
    end
    
    Enemy -->|"HealthComponent.died"| LootTable["LootTable.roll()<br/>- weighted items<br/>- gold range"]
    Chest -->|"Player presses interact"| ChestOpen["GameItem.open_chest()<br/>- fixed contents<br/>- gold amount"]
    
    LootTable --> ItemSpawner["ItemSpawner<br/>spawn_item() / spawn_gold() / spawn_enemy_drops()"]
    ChestOpen --> ItemSpawner
    
    ItemSpawner --> GameItem["GameItem (Area2D)<br/>- Layer 10 (PICKUP), Mask 2 (PLAYER)<br/>- pickup_mode: AUTO/MAGNET/INTERACT"]
    
    GameItem -->|"Player touches / interacts"| InventoryData["InventoryData<br/>add_item() / add gold / heal player"]
    
    style Sources fill:#2d2d2d
    style ItemSpawner fill:#4ecdc4,color:#000
    style GameItem fill:#ff6b6b,color:#000
```

---

### 🦴 Enemy Loot Drops - Step by Step

#### Step 1: Create LootTable for Enemy

```gdscript
# In your enemy script (e.g., skeleton.gd)
extends CharacterBody2D

@export var loot_table: LootTable
@export var xp_reward: int = 25

func _ready():
    # Create default loot table if not set in inspector
    if loot_table == null:
        loot_table = _create_loot_table()
    
    # Connect health component death signal
    $HealthComponent.died.connect(_on_died)

func _create_loot_table() -> LootTable:
    var table := LootTable.new()
    
    # === BASIC SETTINGS ===
    table.drop_count = 2          # Roll 2 times for items
    table.nothing_weight = 40     # 40% chance to drop nothing per roll
    table.gold_range = Vector2i(5, 20)  # Drop 5-20 gold
    
    # === ADD ITEM ENTRIES ===
    # add_entry(item_id, weight, min_quantity, max_quantity)
    table.add_entry("bone", 100, 1, 3)           # Common drop
    table.add_entry("health_potion", 30, 1, 1)   # Uncommon drop
    table.add_entry("iron_ore", 20, 1, 2)        # Rare drop
    
    # === GUARANTEED DROPS (always drop these) ===
    table.guaranteed_drops = ["monster_bone"]    # Always drops 1
    
    return table
```

#### Step 2: Spawn Drops on Death

```gdscript
func _on_died() -> void:
    # Spawn all drops (items + gold + XP)
    var drops := ItemSpawner.spawn_enemy_drops(
        get_tree(),
        global_position,
        loot_table,
        xp_reward
    )
    
    # Optional: Log what was dropped
    print("Enemy dropped %d items, %d gold, %d XP" % [
        drops.items.size(),
        drops.gold_amount,
        drops.xp_amount
    ])
    
    # Play death animation then remove
    queue_free()
```

#### Step 3: Understanding LootTable Weights

**Example:** `drop_count = 1`, `nothing_weight = 40`

**Entries:**
- bone: weight = 100
- health_potion: weight = 30
- diamond: weight = 10

**Total weight** = 40 + 100 + 30 + 10 = **180**

```mermaid
pie title Drop Probabilities
    "Nothing (22.2%)" : 40
    "Bone (55.6%)" : 100
    "Health Potion (16.7%)" : 30
    "Diamond (5.5%)" : 10
```

> **Note:** With `drop_count = 3`, the system rolls 3 times independently!

---

### 📦 Chest Implementation - Step by Step

#### Option A: Pre-defined Chest (Fixed Contents)

```gdscript
# Spawn a chest with specific items
func spawn_treasure_chest(position: Vector2) -> void:
    var chest := ItemSpawner.spawn_chest(
        get_tree(),
        position,
        ["iron_sword", "health_potion", "health_potion"],  # Fixed items
        100,        # Gold amount
        false,      # requires_key
        ""          # key_item_id
    )

# Spawn a locked chest (requires key)
func spawn_locked_chest(position: Vector2) -> void:
    var chest := ItemSpawner.spawn_chest(
        get_tree(),
        position,
        ["diamond", "rare_armor"],
        500,
        true,           # requires_key = true
        "golden_key"    # Player needs this item
    )
```

#### Option B: Random Chest (Using LootTable)

```gdscript
# Create a chest that uses LootTable for random rewards
func spawn_random_chest(position: Vector2) -> void:
    # Create loot table for chest
    var chest_loot := LootTable.new()
    chest_loot.drop_count = 3
    chest_loot.nothing_weight = 0  # Chests should always give something!
    chest_loot.gold_range = Vector2i(50, 200)
    
    # Add rare items for chest
    chest_loot.add_entry("iron_sword", 30, 1, 1)
    chest_loot.add_entry("leather_armor", 30, 1, 1)
    chest_loot.add_entry("health_potion", 50, 1, 3)
    chest_loot.add_entry("diamond", 10, 1, 1)
    
    # Roll the loot table
    var drops := chest_loot.roll()
    var gold := chest_loot.roll_gold()
    
    # Convert to item_ids array
    var item_ids: Array = []
    for drop in drops:
        for i in range(drop.quantity):
            item_ids.append(drop.item_id)
    
    # Spawn the chest
    ItemSpawner.spawn_chest(get_tree(), position, item_ids, gold)
```

#### Option C: Chest Entity Script

```gdscript
# chest.gd - Standalone chest entity
extends Area2D

@export var contents: Array[String] = []  # Item IDs
@export var gold_amount: int = 0
@export var requires_key: bool = false
@export var key_item_id: String = ""
@export var one_time_only: bool = true

var is_opened: bool = false

func _ready():
    # Setup collision for interaction
    collision_layer = CollisionLayers.Layer.INTERACTABLE
    collision_mask = CollisionLayers.Layer.PLAYER

func interact(player: Node2D) -> bool:
    if is_opened and one_time_only:
        return false
    
    # Check for key if required
    if requires_key and not key_item_id.is_empty():
        var inventory := player.get_inventory()
        if inventory == null or not inventory.has_item(key_item_id):
            # Show "need key" message
            return false
        # Consume the key
        inventory.remove_item_by_id(key_item_id, 1)
    
    # Spawn contents
    _spawn_contents()
    
    is_opened = true
    $AnimatedSprite2D.play("open")
    return true

func _spawn_contents() -> void:
    # Spawn items
    for item_id in contents:
        var offset := Vector2(randf_range(-20, 20), randf_range(-10, 10))
        ItemSpawner.spawn_item(
            get_tree(),
            global_position + offset,
            item_id,
            1,
            global_position,  # scatter_origin
            GameItem.PickupMode.AUTO
        )
    
    # Spawn gold
    if gold_amount > 0:
        ItemSpawner.spawn_gold(
            get_tree(),
            global_position,
            gold_amount,
            global_position
        )
```

---

### 🔧 Complete Enemy Example

```gdscript
# skeleton_enemy.gd
extends CharacterBody2D

enum State { IDLE, PATROL, CHASE, ATTACK, DEATH }

@export var max_health: int = 50
@export var xp_reward: int = 25
@export var loot_table: LootTable

var current_state: State = State.IDLE

@onready var health_component: HealthComponent = $HealthComponent
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
    # Setup health
    health_component.max_health = max_health
    health_component.current_health = max_health
    health_component.died.connect(_on_died)
    
    # Setup loot table
    if loot_table == null:
        loot_table = _create_default_loot_table()

func _create_default_loot_table() -> LootTable:
    var table := LootTable.new()
    table.drop_count = 2
    table.nothing_weight = 30
    table.gold_range = Vector2i(10, 30)
    
    # Common drops
    table.add_entry("bone", 100, 1, 3)
    
    # Uncommon drops
    table.add_entry("health_potion", 40, 1, 1)
    table.add_entry("iron_ore", 25, 1, 2)
    
    # Rare drops
    table.add_entry("iron_sword", 5, 1, 1)
    
    return table

func _on_died() -> void:
    # Change to death state
    current_state = State.DEATH
    
    # Disable collision
    $CollisionShape2D.set_deferred("disabled", true)
    $HurtboxComponent/CollisionShape2D.set_deferred("disabled", true)
    
    # Spawn loot
    ItemSpawner.spawn_enemy_drops(
        get_tree(),
        global_position,
        loot_table,
        xp_reward
    )
    
    # Play death animation
    animated_sprite.play("death")
    await animated_sprite.animation_finished
    
    queue_free()
```

---

### 📋 Quick Reference: ItemSpawner Methods

| Method | Use Case | Pickup Mode |
|--------|----------|-------------|
| `spawn_item()` | Single item drop | AUTO |
| `spawn_gold()` | Currency drops (splits into piles) | MAGNET |
| `spawn_health()` | Health orb pickup | AUTO |
| `spawn_stamina()` | Stamina orb pickup | AUTO |
| `spawn_xp()` | Experience orb | MAGNET |
| `spawn_from_loot_table()` | Multiple items from LootTable | AUTO |
| `spawn_enemy_drops()` | Items + Gold + XP (full enemy death) | Mixed |
| `spawn_chest()` | Chest with contents | INTERACT |
| `spawn_world_item()` | Static item in world | INTERACT |

---

### 📋 Quick Reference: LootTable Properties

| Property | Type | Description |
|----------|------|-------------|
| `entries` | Array[Dictionary] | Items with weights |
| `guaranteed_drops` | Array[String] | Always drop these items |
| `drop_count` | int | How many times to roll |
| `nothing_weight` | int | Chance to drop nothing (0-100+) |
| `gold_range` | Vector2i | (min, max) gold amount |

### LootTable Entry Format

```gdscript
{
    "item_id": "health_potion",  # Must exist in ItemDatabase
    "weight": 100,               # Higher = more likely
    "min_quantity": 1,           # Minimum amount
    "max_quantity": 3            # Maximum amount
}
```

---

### ⚠️ Common Mistakes

1. **Item not in ItemDatabase**
   ```gdscript
   # ❌ Wrong - item_id doesn't exist
   table.add_entry("unknown_item", 100, 1, 1)
   
   # ✅ Correct - use existing item from ItemDatabase
   table.add_entry("health_potion", 100, 1, 1)
   ```

2. **Spawning before scene is ready**
   ```gdscript
   # ❌ Wrong - may cause errors
   func _init():
       ItemSpawner.spawn_item(...)
   
   # ✅ Correct - wait for scene tree
   func _on_died():
       ItemSpawner.spawn_item(get_tree(), ...)
   ```

3. **Missing get_tree() parameter**
   ```gdscript
   # ❌ Wrong
   ItemSpawner.spawn_item(position, "sword", 1)
   
   # ✅ Correct
   ItemSpawner.spawn_item(get_tree(), position, "sword", 1)
   ```

4. **Forgetting scatter_origin for nice visual**
   ```gdscript
   # Items spawn in place (boring)
   ItemSpawner.spawn_item(get_tree(), pos, "item", 1)
   
   # Items scatter outward from enemy (better!)
   ItemSpawner.spawn_item(get_tree(), pos, "item", 1, enemy_pos)
   ```
