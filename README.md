# 🔥 Emberfield

<p align="center">
  <img src="icon.svg" alt="Emberfield Logo" width="128" height="128">
</p>

## 📖 Giới thiệu

**Emberfield** là một dự án game 2D Action RPG được phát triển bằng **Godot Engine 4.6**. Game theo phong cách pixel art với hệ thống combat, inventory, equipment, NPC shops và khám phá thế giới.

### ✨ Tính năng chính

- 🎮 **Hệ thống Player**: Di chuyển 8 hướng, tấn công, skills, state machine (5 states)
- ⚔️ **Combat System**: Hitbox/Hurtbox component-based, i-frames, knockback, passive effects
- 🎒 **Inventory System**: 32 slots, equipment (7 slots), drag & drop, tabs, sorting
- 💎 **Augment System**: Equipment customization với stat boosts, passive effects, active skills
- 🔨 **Crafting System**: Tiered recipes (1-3 tiers), category tabs (Augments, Buffs)
- 🧪 **Buff System**: Timed stat buffs (attack/defense/health/speed) với status icons
- ⚡ **Skill System**: Equipment-bound active skills (Q/E/R/F), cooldowns, VFX
- 💰 **Item System**: 11 item types, 5 rarities, loot tables, gold/health/XP pickups, chests
- 🏪 **NPC & Shops**: Blacksmith, Merchant với shop UI, crafting station
- 👾 **Enemies**: Skeleton với AI (patrol, chase, attack), loot drops
- 🏰 **Dungeon System**: Procedural generation (Binding of Isaac style), 4 room types
- 🗺️ **Maps**: Town, Dungeon với scene transitions, minimap
- 🎯 **Hotbar**: 4 skill slots + 8 item slots với cooldown display

### 🎯 Thông số kỹ thuật

| Spec | Value |
|------|-------|
| **Engine** | Godot 4.6 |
| **Resolution** | 1280x720 |
| **Rendering** | GL Compatibility (Pixel Perfect) |
| **Architecture** | Component-based, State Machine |

### 🔌 Autoloads (8 Singletons)

| Singleton | Script | Purpose |
|-----------|--------|---------|
| CollisionLayers | `collision_layers.gd` | Layer bitmask enum |
| InteractionManager | `interaction_manager.tscn` | E-to-interact prompt |
| GameEvent | `game_event.gd` | Global signal bus (7 signals) |
| ItemDatabase | `item_database.gd` | All item definitions (~40+ items) |
| SceneTransitionService | `scene_transition_service.gd` | Map transitions with fade |
| CameraService | `camera_service.gd` | Camera modes (FOLLOW/STATIC/ROOM) |
| RecipeDatabase | `recipe_database.gd` | Crafting recipe registry |
| SkillDatabase | `skill_database.gd` | Skill definitions (3 skills) |

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
│   ├── architecture.md           # System architecture (UML diagrams)
│   ├── combat_system.md          # Combat mechanics & skills
│   ├── inventory_system.md       # Inventory, equipment & augments
│   ├── item_system.md            # Item spawning, loot & crafting
│   ├── dungeon_system.md         # Dungeon generation & gameplay
│   └── LAYER_AND_MASK_STANDARDS.md # Collision layer config
│
└── 📂 sense/                     # Source code
    ├── 📂 globals/               # Autoloads (8 singletons)
    ├── 📂 components/            # Reusable components (11 files)
    ├── 📂 entities/              # Player, Enemies, NPCs
    ├── 📂 items/                 # Item system
    ├── 📂 skills/                # Skill system
    ├── 📂 maps/                  # Town, Dungeon, Portal
    └── 📂 ui/                    # HUD, Inventory, Augment, Crafting
```

---

## 🧩 Systems Overview

### Component System

| Component | File | Purpose |
|-----------|------|---------|
| **HealthComponent** | `health_component.gd` | HP management, death signal |
| **HitboxComponent** | `hitbox_component.gd` | Deal damage, LOS check |
| **HurtboxComponent** | `hurtbox_component.gd` | Receive damage, i-frames |
| **BuffComponent** | `buff_component.gd` | Timed stat buffs (ATK/DEF/HP/SPD) |
| **PassiveEffectProcessor** | `passive_effect_processor.gd` | On-hit/on-damage effects |
| **SkillComponent** | `skill_component.gd` | Equipment-bound active skills |
| **SkillExecutor** | `skill_executor.gd` | Spawn skill hitboxes + VFX |
| **InteractionManager** | `interaction_manager.gd` | NPC/object interaction |
| **ShopComponent** | `shop_component.gd` | Shop functionality |
| **UIPopupComponent** | `ui_popup_component.gd` | UI panel open/close helper |

### Item System

| Component | File | Purpose |
|-----------|------|---------|
| **ItemData** | `item_data.gd` | Item resource (11 types, 5 rarities, augments) |
| **ItemDatabase** | `item_database.gd` | All items registry (Autoload, ~40+ items) |
| **ItemIconAtlas** | `item_icon_atlas.gd` | Extract icons from sprite sheet |
| **ItemHelper** | `item_helper.gd` | Item utility functions |
| **GameItem** | `game_item.gd` | Droppable item (AUTO, MAGNET, INTERACT, PROXIMITY) |
| **ItemSpawner** | `item_spawner.gd` | Factory for spawning items |
| **LootTable** | `loot_table.gd` | Weighted drop rate configuration |

### Inventory System

| Component | File | Purpose |
|-----------|------|---------|
| **InventoryData** | `inventory_data.gd` | Inventory state (32 slots + 7 equip + augments) |
| **InventoryPanel** | `inventory_panel.gd` | Main UI controller with tabs |
| **InventorySlotUI** | `inventory_slot_ui.gd` | Individual slot with rarity glow |
| **AugmentPanel** | `augment_panel.gd` | Augment management UI |
| **CraftingPanel** | `crafting_panel.gd` | Tiered crafting UI |
| **CraftingRecipe** | `crafting_recipe.gd` | Recipe resource (1-3 tiers) |
| **RecipeDatabase** | `recipe_database.gd` | Recipe registry (Autoload) |
| **Hotbar** | `hotbar.gd` | Skill (Q/E/R/F) + item (1-8) quick bar |
| **DungeonMinimap** | `dungeon_minimap.gd` | Room-layout minimap for dungeons |

### Entity Structure

```
Player (CharacterBody2D)
├── AnimatedSprite2D
├── CollisionShape2D
├── HitboxComponent (Area2D)           # Layer 7
│   └── CollisionShape2D
├── HurtboxComponent (Area2D)          # Layer 5
│   └── CollisionShape2D
├── BuffComponent (Node)               # Timed stat buffs
├── PassiveEffectProcessor (Node)      # On-hit/on-damage effects
├── SkillComponent (Node)              # Active skills (Q/E/R/F)
└── SkillExecutor (Node)               # Skill hitbox + VFX spawning
Note: Player uses CharacterStats (Resource) for HP instead of HealthComponent

Enemy (CharacterBody2D)
├── AnimatedSprite2D
├── CollisionShape2D
├── HealthComponent (Node)             # HP management
├── HitboxComponent (Area2D)           # Layer 8
│   └── CollisionShape2D
└── HurtboxComponent (Area2D)          # Layer 6
    └── CollisionShape2D
```

---

## 🎮 Điều khiển

| Input | Action |
|-------|--------|
| `W` `A` `S` `D` / Arrow Keys | Di chuyển |
| `A` (character_attack) | Tấn công |
| `E` (character_interact) | Tương tác (NPC, Shop, Pickup) |
| `B` (open_inventory) | Mở Inventory |
| `Q` `E` `R` `F` | Skills (weapon/armor/helmet/boots) |
| `1` - `8` | Hotbar item slots |
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
| [architecture.md](docs/architecture.md) | System architecture, UML class diagrams |
| [combat_system.md](docs/combat_system.md) | Combat mechanics, skills, passive effects |
| [inventory_system.md](docs/inventory_system.md) | Inventory, equipment, augments, crafting |
| [item_system.md](docs/item_system.md) | Items, loot tables, spawning, augment types |
| [dungeon_system.md](docs/dungeon_system.md) | Procedural dungeon generation |
| [LAYER_AND_MASK_STANDARDS.md](docs/LAYER_AND_MASK_STANDARDS.md) | Collision layer configuration |

---

## 👥 Module Ownership

| Module | Folder | Description |
|--------|--------|-------------|
| Player | `sense/entities/player/` | Character controller, stats, state machine |
| Enemies | `sense/entities/enemies/` | AI, behaviors, loot drops |
| NPCs | `sense/entities/npcs/` | Shops, interaction, crafting |
| Items | `sense/items/` | Item spawning, loot tables |
| Skills | `sense/skills/` | Skill data, execution, VFX |
| Inventory | `sense/ui/inventory/` | Inventory UI, equipment |
| Augments | `sense/ui/augment/` | Augment management UI |
| Crafting | `sense/ui/crafting/` | Crafting recipes, panel |
| HUD | `sense/ui/hud/` | Health/stamina bars, hotbar, minimap |
| Components | `sense/components/` | Shared components (11 files) |
| Maps | `sense/maps/` | Town, Dungeon, Portal |

---

## 🔄 Recent Updates

- ✅ Procedural dungeon generation (Binding of Isaac style)
- ✅ Skill system with 3 skills (whirlwind, shield_bash, fire_burst)
- ✅ Augment system for equipment customization
- ✅ Tiered crafting system with recipe database
- ✅ Buff component with timed stat buffs
- ✅ Passive effects (life_steal, burn, freeze, poison, thorns, crit)
- ✅ Hotbar with skill slots (Q/E/R/F) + item slots (1-8)
- ✅ Dungeon minimap with room exploration tracking
- ✅ Scene transition service with fade + map caching
- ✅ Item icon atlas system with default fallback
- ✅ Inventory drag & drop with equipment validation
- ✅ Inventory sorting by type and rarity
- ✅ Loot table for enemy drops
- ✅ Gold/Health/Stamina/XP pickup types
- ✅ Comprehensive documentation (6 docs)

---

## 📄 License

*MIT License*

---

<p align="center">
  Made with ❤️ using Godot Engine 4.6
</p>
