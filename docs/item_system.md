# Hệ Thống Item - Emberfield

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

## Tổng Quan

Hệ thống item thống nhất với **một scene duy nhất** (`GameItem`) có thể cấu hình thành nhiều loại:
- Item drops từ enemy
- Gold coins
- Health/Stamina/XP pickups
- Treasure chests
- World items (tương tác)

## Kiến Trúc

```
╔═══════════════════════════════════════════════════════════════════════════════════╗
║                           UNIFIED GAME ITEM SYSTEM                                ║
╠═══════════════════════════════════════════════════════════════════════════════════╣
║                                                                                   ║
║  ┌──────────────────────────────────────────────────────────────────────────────┐ ║
║  │                           GameItem (Area2D)                                  │ ║
║  │                                                                              │ ║
║  │  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────────────────────┐ │ ║
║  │  │   PickupMode    │ │   VisualStyle   │ │        ContentType              │ │ ║
║  │  ├─────────────────┤ ├─────────────────┤ ├─────────────────────────────────┤ │ ║
║  │  │ • AUTO          │ │ • STATIC        │ │ • ITEM      (inventory item)    │ │ ║
║  │  │ • INTERACT      │ │ • BOB           │ │ • GOLD      (currency)          │ │ ║
║  │  │ • PROXIMITY     │ │ • SPARKLE       │ │ • HEALTH    (heal pickup)       │ │ ║
║  │  │ • MAGNET        │ │ • ROTATE        │ │ • STAMINA   (stamina pickup)    │ │ ║
║  │  │                 │ │                 │ │ • XP        (experience orb)    │ │ ║
║  │  │                 │ │                 │ │ • MULTI_ITEM (chest contents)   │ │ ║
║  │  └─────────────────┘ └─────────────────┘ └─────────────────────────────────┘ │ ║
║  └──────────────────────────────────────────────────────────────────────────────┘ ║
║                                                                                   ║
╚═══════════════════════════════════════════════════════════════════════════════════╝
```

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
│   └── debug_icon_atlas.tscn
│
├── ui/inventory/
│   ├── item_data.gd        # Resource định nghĩa item
│   ├── item_database.gd    # Autoload chứa tất cả items
│   ├── inventory_data.gd   # Quản lý inventory + equipment
│   └── inventory_panel.gd  # UI hiển thị

assets/items/
└── item_icons.png          # Sprite sheet (512x867, 32x32 icons)
```

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

## Sử Dụng

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

## Item Icons từ Sprite Sheet

### Cấu Hình Atlas

Atlas được khởi tạo bởi `ItemDatabase` khi game chạy:

```gdscript
# Trong item_database.gd _init_icon_atlas()
const ICON_SHEET_PATH := "res://assets/items/item_icons.png"
# Sprite sheet: 512x867 pixels, 32x32 icons, 16 columns
ItemIconAtlas.init(sheet, Vector2i(32, 32), 16)
```

### Sử Dụng Atlas Icon

```gdscript
var item := ItemData.new()
item.use_atlas_icon = true
item.atlas_row = 2
item.atlas_col = 5

# Hoặc dùng tên preset
item.atlas_icon_name = "iron_sword"  # Nếu đã định nghĩa trong ICON_POSITIONS
```

### Lấy Icon

```gdscript
var texture := item.get_icon()  # Tự động dùng atlas hoặc icon thường
```

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

## Debug

Enable debug visualization trong Inspector:

```gdscript
@export var debug_draw_enabled: bool = true
```

Hiển thị:
- Pickup range (circle)
- Magnet range (larger circle)
- Current state info
