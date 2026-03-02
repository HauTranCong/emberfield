# 🔥 Emberfield

<p align="center">
  <img src="icon.svg" alt="Emberfield Logo" width="128" height="128">
</p>

## 📖 Giới thiệu

**Emberfield** là một dự án game 2D Action RPG được phát triển bằng **Godot Engine 4.6**. Game theo phong cách pixel art với hệ thống combat, inventory, equipment, NPC shops và khám phá thế giới.

### ✨ Tính năng chính

- 🎮 **Hệ thống Player**: Di chuyển 8 hướng, tấn công, state machine
- ⚔️ **Combat System**: Hitbox/Hurtbox component-based, i-frames, knockback
- 🎒 **Inventory System**: 32 slots, equipment (7 slots), drag & drop, tabs
- 💰 **Item System**: Loot tables, gold/health/XP pickups, chests
- 🏪 **NPC & Shops**: Blacksmith, Merchant với shop UI
- 👾 **Enemies**: Skeleton với AI (patrol, chase, attack)
- 🗺️ **Maps**: Town map với tileset, portals

### 🎯 Thông số kỹ thuật

| Spec | Value |
|------|-------|
| **Engine** | Godot 4.6 |
| **Resolution** | 1280x720 |
| **Rendering** | GL Compatibility (Pixel Perfect) |
| **Architecture** | Component-based, State Machine |

---

## 📁 Cấu trúc thư mục

```
emberfield/
│
├── 📄 project.godot              # Godot project config
├── 📄 LAYER_AND_MASK_STANDARDS.md
├── 📄 README.md
│
├── 📂 assets/                    # Game assets
│   ├── 📂 enemies/               # Enemy sprites
│   ├── 📂 soldiers/              # Player sprites
│   ├── 📂 items/                 # Item icon sprite sheet (512x867, 32x32)
│   ├── 📂 Shop/                  # Shop UI & NPC sprites
│   ├── 📂 Font/                  # Pixel fonts
│   └── 📂 tilesets/              # Map tilesets
│
├── 📂 docs/                      # Documentation
│   ├── architecture.md           # System architecture
│   ├── combat_system.md          # Combat mechanics
│   ├── inventory_system.md       # Inventory & equipment
│   └── item_system.md            # Item spawning & loot
│
└── 📂 sense/                     # Source code
    ├── 📂 globals/               # Autoloads (CollisionLayers, GameEvent)
    ├── 📂 components/            # Reusable components
    ├── 📂 entities/              # Player, Enemies, NPCs
    ├── 📂 items/                 # Item system
    ├── 📂 maps/                  # Game maps
    └── 📂 ui/                    # HUD, Inventory UI
```

---

## 🧩 Systems Overview

### Component System

| Component | File | Purpose |
|-----------|------|---------|
| **HealthComponent** | `health_component.gd` | HP management, death signal |
| **HitboxComponent** | `hitbox_component.gd` | Deal damage, LOS check |
| **HurtboxComponent** | `hurtbox_component.gd` | Receive damage, i-frames |
| **InteractionManager** | `interaction_manager.gd` | NPC/object interaction |
| **ShopComponent** | `shop_component.gd` | Shop functionality |

### Item System

| Component | File | Purpose |
|-----------|------|---------|
| **ItemData** | `item_data.gd` | Item resource definition |
| **ItemDatabase** | `item_database.gd` | All items registry (Autoload) |
| **ItemIconAtlas** | `item_icon_atlas.gd` | Extract icons from sprite sheet |
| **GameItem** | `game_item.gd` | Droppable item (AUTO, MAGNET, INTERACT) |
| **ItemSpawner** | `item_spawner.gd` | Factory for spawning items |
| **LootTable** | `loot_table.gd` | Drop rate configuration |

### Inventory System

| Component | File | Purpose |
|-----------|------|---------|
| **InventoryData** | `inventory_data.gd` | Inventory state (32 slots + equipment) |
| **InventoryPanel** | `inventory_panel.gd` | Main UI controller |
| **InventorySlotUI** | `inventory_slot_ui.gd` | Individual slot rendering |

### Entity Structure

```
Player/Enemy (CharacterBody2D)
├── AnimatedSprite2D
├── CollisionShape2D
├── HealthComponent (Node)
├── HitboxComponent (Area2D)     # Layer 7/8
│   └── CollisionShape2D
└── HurtboxComponent (Area2D)    # Layer 5/6
    └── CollisionShape2D
```

---

## 🎮 Điều khiển

| Input | Action |
|-------|--------|
| `W` `A` `S` `D` / Arrow Keys | Di chuyển |
| `Space` / `J` | Tấn công |
| `E` | Tương tác (NPC, Shop, Pickup) |
| `B` / `I` | Mở Inventory |
| `ESC` | Đóng UI |

---

## 🔧 Collision Layers

| Layer | Name | Bit | Description |
|-------|------|-----|-------------|
| 1 | WORLD | 1 | Walls, obstacles, terrain |
| 2 | PLAYER | 2 | Player body |
| 3 | ENEMY | 4 | Enemy body |
| 4 | NPC | 8 | NPCs |
| 5 | PLAYER_HURTBOX | 16 | Player receives damage |
| 6 | ENEMY_HURTBOX | 32 | Enemy receives damage |
| 7 | PLAYER_HITBOX | 64 | Player attack area |
| 8 | ENEMY_HITBOX | 128 | Enemy attack area |
| 9 | INTERACTABLE | 256 | Shop, chest, door |
| 10 | PICKUP | 512 | Items to collect |

> 📚 Chi tiết: [LAYER_AND_MASK_STANDARDS.md](LAYER_AND_MASK_STANDARDS.md)

---

## 📦 Item Icon Atlas

Sprite sheet: `assets/items/item_icons.png` (512x867, 32x32 icons, 16 columns)

### Available Icons

| Name | Position | Name | Position |
|------|----------|------|----------|
| `sword_iron` | (5, 1) | `leather_armor` | (7, 5) |
| `helmet_horned` | (0, 0) | `boot_green` | (1, 1) |
| `potion_red` | (9, 0) | `gold_coin` | (12, 7) |
| `heart` | (0, 4) | `bone` | (17, 9) |
| `iron_ore` | (17, 1) | `gem_green` | (1, 2) |

### Adding New Icons

1. Add to `ItemIconAtlas.ICONS` dictionary:
```gdscript
const ICONS := {
    "new_item": Vector2i(row, col),
}
```

2. Create item in `ItemDatabase`:
```gdscript
var item := ItemData.new()
item.use_atlas_icon = true
item.atlas_icon_name = "new_item"
```

> 🔧 Use `debug_icon_atlas.tscn` to find row/col positions

---

## 🚀 Quick Start

### Spawn Items

```gdscript
# Spawn item
ItemSpawner.spawn_item(get_tree(), position, "health_potion", 1)

# Spawn gold (magnet effect)
ItemSpawner.spawn_gold(get_tree(), position, 100)

# Spawn from loot table
ItemSpawner.spawn_enemy_drops(get_tree(), position, loot_table, xp_amount)
```

### Add Item to Inventory

```gdscript
var item := ItemDatabase.get_item("iron_sword")
inventory.add_item(item, 1)
```

### Create Loot Table

```gdscript
var loot := LootTable.new()
loot.drop_count = 2
loot.nothing_weight = 40
loot.gold_range = Vector2i(5, 20)
loot.add_entry("bone", 100, 1, 3)      # Common
loot.add_entry("health_potion", 30)    # Uncommon
```

---

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [architecture.md](docs/architecture.md) | System architecture & design |
| [combat_system.md](docs/combat_system.md) | Combat mechanics, hitbox/hurtbox |
| [inventory_system.md](docs/inventory_system.md) | Inventory, equipment, UI |
| [item_system.md](docs/item_system.md) | Items, loot tables, spawning |

---

## 👥 Module Ownership

| Module | Folder | Description |
|--------|--------|-------------|
| Player | `sense/entities/player/` | Character controller, stats |
| Enemies | `sense/entities/enemies/` | AI, behaviors |
| NPCs | `sense/entities/npcs/` | Dialogue, shop logic |
| Items | `sense/items/` | Item spawning, loot |
| Inventory | `sense/ui/inventory/` | Inventory UI |
| Components | `sense/components/` | Shared components |

---

## 🔄 Recent Updates

- ✅ Item icon atlas system with default fallback
- ✅ Inventory drag & drop with equipment validation
- ✅ Loot table for enemy drops
- ✅ Gold/Health/XP pickup types
- ✅ Comprehensive documentation

---

## 📄 License

*MIT License*

---

<p align="center">
  Made with ❤️ using Godot Engine 4.6
</p>
