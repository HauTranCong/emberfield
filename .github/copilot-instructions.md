# GitHub Copilot Instructions for Godot Project

## Project Context
This is a Godot 2D game project with:
- Strict collision layer and mask standards (10 layers)
- Component-based architecture (Hitbox, Hurtbox, Health, Buff, Skill, PassiveEffect components)
- State machine pattern for Player and Enemy AI
- Augment system for equipment customization
- Tiered crafting system
- Procedural dungeon generation (Binding of Isaac style)
- Scene transition service for map management
- Debug visualization system

## Autoloads (8 total, defined in project.godot)
| Singleton | Script | Purpose |
|-----------|--------|---------|
| CollisionLayers | `sense/globals/collision_layers.gd` | Layer bitmask enum |
| InteractionManager | `sense/components/interaction_manager.tscn` | E-to-interact prompt system |
| GameEvent | `sense/globals/game_event.gd` | Global signal bus |
| ItemDatabase | `sense/items/item_database.gd` | All item definitions |
| SceneTransitionService | `sense/globals/scene_transition_service.gd` | Map transitions with fade |
| CameraService | `sense/globals/camera_service.gd` | Camera mode management |
| RecipeDatabase | `sense/ui/crafting/recipe_database.gd` | Crafting recipe registry |
| SkillDatabase | `sense/skills/skill_database.gd` | Skill definitions |

## Critical Rules for Entity Creation

### ALWAYS Follow Layer & Mask Standards
When creating or modifying ANY game entity (Player, Enemy, NPC, Interactable, Pickup), you MUST:

1. **Reference LAYER_AND_MASK_STANDARDS.md** for correct layer configuration
2. **Apply these exact layer assignments:**
   - Layer 1: World/Environment (walls, obstacles, terrain)
   - Layer 2: Player
   - Layer 3: Enemy
   - Layer 4: NPC
   - Layer 5: PlayerHurtbox
   - Layer 6: EnemyHurtbox
   - Layer 7: PlayerHitbox
   - Layer 8: EnemyHitbox
   - Layer 9: Interactable (shop, chest, door)
   - Layer 10: Pickup

3. **Apply correct masks for each entity type:**

**Player:**
```
collision_layer = 2
collision_mask = 1 | 3 | 4 | 8 | 9 | 10
```

**Enemy:**
```
collision_layer = 3
collision_mask = 1 | 2 | 7
```

**NPC:**
```
collision_layer = 4
collision_mask = 1 | 2
```

**Interactable (Shop/Chest/Door):**
```
collision_layer = 9
collision_mask = 2
```

**Player Attack Hitbox (Area2D):**
```
collision_layer = 7
collision_mask = 6
```

**Enemy Attack Hitbox (Area2D):**
```
collision_layer = 8
collision_mask = 5
```

**Pickup Item:**
```
collision_layer = 10
collision_mask = 2
```

## Code Generation Standards

### When creating GDScript files:
- Use `extends CharacterBody2D` or `extends Area2D` appropriately
- **Use `CollisionLayers.Layer` enum** from `sense/globals/collision_layers.gd`
- Always include collision layer/mask configuration in `_ready()`
- Add comments explaining which layers are being used

### Component Architecture
Entities that can deal/receive damage should have:
```
Entity (CharacterBody2D)
├── AnimatedSprite2D
├── CollisionShape2D
├── HealthComponent (Node)         # HP management (enemies)
├── HitboxComponent (Area2D)       # Deals damage
│   └── CollisionShape2D
├── HurtboxComponent (Area2D)      # Receives damage (has i-frames)
│   └── CollisionShape2D
├── BuffComponent (Node)           # Timed stat buffs
├── PassiveEffectProcessor (Node)  # On-hit/on-damage effects (life_steal, burn, thorns)
├── SkillComponent (Node)          # Equipment-bound active skills (Q/E/R/F)
└── SkillExecutor (Node)           # Spawns skill hitboxes + VFX
```
Note: Player uses CharacterStats (Resource) instead of HealthComponent for HP.

### State Machine Pattern
Use enum for states:
```gdscript
enum State { IDLE, MOVE, ATTACK, SKILL, DEATH }  # Player (5 states)
enum State { IDLE, PATROL, CHASE, ATTACK, DEATH }  # Enemy (5 states)
```

### Input Mappings
```
Movement:     WASD / Arrow keys
Attack:       A (character_attack)
Interact:     E (character_interact)
Inventory:    B (open_inventory)
Skills:       Q (skill_1), E (skill_2), R (skill_3), F (skill_4)
Hotbar:       1-8 (hotbar_1 through hotbar_8)
UI Nav:       ui_left/right/up/down
```

### When creating .tscn scenes:
- Set collision_layer and collision_mask properties
- Use proper node hierarchy (CollisionShape2D child of body)
- Name nodes descriptively (e.g., "PlayerHurtbox", "AttackHitbox")

### Example Enemy Script Pattern:
```gdscript
extends CharacterBody2D

func _ready():
    # Use CollisionLayers enum instead of magic numbers
    collision_layer = CollisionLayers.Layer.ENEMY
    collision_mask = CollisionLayers.Layer.WORLD
    
    # Setup hitbox/hurtbox
    hitbox.collision_layer = CollisionLayers.Layer.ENEMY_HITBOX
    hitbox.collision_mask = CollisionLayers.Layer.PLAYER_HURTBOX
```

## Combat Rules
- Hitbox deals damage → Hurtbox receives damage (NOT via body collision)
- HitboxComponent has `check_line_of_sight` to prevent attacking through walls
- Player has 0.5s iframe after taking damage
- Enemy attack has HITBOX_DELAY (0.8s) to sync with animation
- PassiveEffectProcessor handles on-hit effects (life_steal, burn, freeze, poison) and on-damage effects (thorns)
- SkillComponent binds active skills to equipment slots: weapon→Q, armor→E, helmet→R, boots→F
- SkillExecutor spawns skill-specific hitboxes + VFX (whirlwind=AoE, shield_bash=cone, fire_burst=ranged)
- Damage formula: `effective_damage = max(1, raw_damage - target_defense)`

## Buff & Augment System
- **BuffComponent**: Manages timed stat buffs (attack/defense/health/speed bonuses). Ticks down in `_process`. Emits `buff_applied`, `buff_expired`, `buffs_changed`.
- **Augments**: Applied to equipment via `InventoryData.apply_augment()`. Types: `STAT_BOOST`, `PASSIVE_EFFECT`, `ACTIVE_SKILL`, `TIMED_BUFF`.
- **Augment slot layout**: Column-based. First slot = Skill (ACTIVE_SKILL), remaining = Passive. At most 1 ACTIVE_SKILL per equipment piece.
- **AugmentPanel**: Scene-designed (`AugmentPanel.tscn` + `augment_panel.gd`). Static layout via scene nodes, dynamic rows built in code. Uses `@onready` references.
- **PassiveEffect enum**: `LIFE_STEAL`, `CRIT_CHANCE`, `THORNS`, `BURN_ON_HIT`, `FREEZE_ON_HIT`, `POISON_ON_HIT`
- Equipment has `get_augment_slot_count()` based on rarity (Common=0, Uncommon=1, Rare=2, Epic=3, Legendary=4)
- **Hotbar skill slots**: Only show ACTIVE_SKILL augments. First skill per input_action wins (no overwriting).

## Crafting System
- **CraftingRecipe**: Has 1-3 tiers per recipe, each with different ingredients and result items
- **RecipeDatabase** (Autoload): Stores all recipes. Categories: `AUGMENT`, `CONSUMABLE_BUFF`
- **CraftingPanel**: Tiered crafting UI with category tabs (Augments, Buffs, All)
- Crafted items go directly into player inventory. Emits `GameEvent.item_crafted`

## Dungeon System
- **DungeonGenerator**: Procedural room layout using random walk algorithm (Binding of Isaac style)
- **RoomType enum**: `START`, `NORMAL`, `BOSS`, `TREASURE`
- **DungeonLevel**: Renders rooms with TileMapLayers, handles door transitions between rooms
- Uses CameraService in ROOM mode with bounded camera
- DungeonMinimap shows explored rooms in HUD
- BOSS room: furthest dead-end from start. TREASURE room: random dead-end with return portal

## File Structure Conventions
```
sense/
├── main.gd / Main.tscn          # Game entry point, service init
├── components/                   # Reusable game components
│   ├── health_component.gd       # Health management (enemies)
│   ├── hitbox_component.gd       # Deals damage (Area2D) with LOS check
│   ├── hurtbox_component.gd      # Receives damage (Area2D) with i-frames
│   ├── buff_component.gd         # Timed stat buff management
│   ├── passive_effect_processor.gd # On-hit/on-damage passive effects
│   ├── skill_component.gd        # Equipment-bound active skills
│   ├── shop_component.gd         # Shop purchase logic
│   ├── ui_popup_component.gd     # UI popup open/close helper
│   ├── interaction_manager.gd    # Global interaction prompt system
│   ├── interaction_manager.tscn
│   ├── interaction_scene.gd      # InteractionArea class definition
│   └── interaction_scene.tscn
├── entities/
│   ├── player/                   # player.gd, character_stats.gd, player.tscn
│   ├── enemies/
│   │   └── skeleton/             # skeleton.gd, skeleton.tscn
│   └── npcs/
│       ├── blacksmith/           # blacksmith.gd, furnace_fire.gd, smith_shop_popup
│       └── merchant/             # general_goods.gd, item_sell.gd, ui_general_shop.gd
├── globals/                      # Autoloaded singletons & services
│   ├── collision_layers.gd       # CollisionLayers.Layer enum
│   ├── game_event.gd             # Global event bus (7 signals)
│   ├── camera_service.gd         # Camera modes: FOLLOW, STATIC, ROOM
│   └── scene_transition_service.gd # Map transitions with fade + caching
├── items/                        # Item system
│   ├── item_data.gd              # Item resource (11 types, 5 rarities, augments)
│   ├── item_database.gd          # Item registry (Autoload, ~40+ items)
│   ├── item_helper.gd            # Item utility functions
│   ├── item_spawner.gd           # Spawns items/gold/health in world
│   ├── game_item.gd / game_item.tscn # World pickup entity (4 pickup modes)
│   ├── loot_table.gd             # Weighted loot drop tables
│   └── item_icon_atlas.gd        # Sprite sheet icon extraction
├── maps/
│   ├── town/                     # town.gd, town.tscn
│   ├── dungeon/                  # dungeon_generator.gd, dungeon_level.gd
│   │                             # dungeon_tilestructure.gd, tileset_structure.gd
│   │                             # return_portal.gd, return_portal.tscn
│   └── portal/                   # portal.gd, portal.tscn
├── skills/                       # Skill system
│   ├── skill_data.gd             # Skill resource definition
│   ├── skill_database.gd         # Skill registry (Autoload, 3 skills)
│   ├── skill_executor.gd         # Skill execution + hitbox spawning
│   └── whirlwind_vfx.gd / WhirlwindVFX.tscn # Skill VFX
└── ui/
    ├── dim_background.gd         # Background dimming for panels
    ├── hud/                      # hud.gd, pixel_bar.gd, dungeon_minimap.gd
    │                             # hotbar.gd, Hotbar.tscn, hotbar_slot_ui.gd
    ├── inventory/                # inventory_data.gd, inventory_panel.gd
    │                             # inventory_slot_ui.gd
    ├── augment/                  # augment_panel.gd + AugmentPanel.tscn (scene-designed)
    └── crafting/                 # crafting_panel.gd, crafting_recipe.gd
                                  # recipe_database.gd, embedded_inventory_panel.gd
```

## Naming Conventions
- Scripts: snake_case (e.g., `goblin_enemy.gd`)
- Scenes: PascalCase (e.g., `GoblinEnemy.tscn`)
- Nodes: PascalCase (e.g., `AttackHitbox`, `CollisionShape2D`)

## Implementation Workflow — Design First, Code Second
When implementing any new feature or fixing a bug, follow this order:

1. **Understand** — Read all relevant existing code, docs, and signals before changing anything.
2. **Design in plain language** — Write out the plan as structured comments / ASCII diagrams:
   - What files are affected and why.
   - Data flow: which signals fire, which functions are called, in what order.
   - Edge cases and how they are handled.
   - Node / scene hierarchy changes (if any).
3. **Implement incrementally** — Make small, verifiable changes one at a time:
   - **Create `.tscn` scenes first** — Build the node tree / UI layout in the scene file before writing any script logic. This includes setting collision layers/masks, node hierarchy, and exported property defaults directly in the scene.
   - Add/modify the **data layer** (Resources, enums, signals, InventoryData methods).
   - Then the **logic layer** (state machines, component methods, player handlers).
   - Then the **UI layer** (panels, slots, HUD updates).
   - Finally **wire everything together** (signal connections, autoload references).
   - All new files (`.gd` and `.tscn`) MUST be created inside the `sense/` directory following the existing folder structure.
4. **Validate each step** — Check for errors after every edit before moving on.

### Why this order matters
- Designing up front prevents half-implemented solutions and rework.
- Data → Logic → UI ensures each layer has a stable foundation to build on.
- Small increments make bugs obvious immediately instead of hiding in a large diff.

### Comment & Readability Standards
- Every new function must have a `##` doc-comment explaining **what** it does and **why**.
- Use ASCII diagrams in block comments for complex flows (state machines, signal chains, data transformations).
- Group related functions under `# ====` section headers with a short description.
- Prefer explicit, descriptive variable names over abbreviations (`inventory_index` not `idx`).

## Always Include
- Health system for entities that can take damage
- Proper signal connections for collisions
- Comments explaining layer/mask choices
- Error handling for null references
- `@export var debug_draw_enabled: bool` for visualization
- ASCII diagram in comments explaining state machine

## Documentation Reference
- `docs/LAYER_AND_MASK_STANDARDS.md` - Collision layer details
- `docs/architecture.md` - Full system architecture UML diagrams
- `docs/combat_system.md` - Combat interaction flow
- `docs/item_system.md` - Item system architecture
- `docs/inventory_system.md` - Inventory and equipment system
- `docs/dungeon_system.md` - Dungeon generation and gameplay

## Prompt Files
- `.github/prompts/item-shop-implementation.prompt.md` - Best practices for creating items & shop integration

