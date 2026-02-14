# GitHub Copilot Instructions for Godot Project

## Project Context
This is a Godot 2D game project with:
- Strict collision layer and mask standards
- Component-based architecture (Hitbox, Hurtbox, Health components)
- State machine pattern for Player and Enemy AI
- Debug visualization system

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
├── HealthComponent (Node)
├── HitboxComponent (Area2D)    # Deals damage
│   └── CollisionShape2D
└── HurtboxComponent (Area2D)   # Receives damage
    └── CollisionShape2D
```

### State Machine Pattern
Use enum for states:
```gdscript
enum State { IDLE, MOVE, ATTACK, DEATH }  # Player
enum State { IDLE, PATROL, CHASE, ATTACK, DEATH }  # Enemy
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

## File Structure Conventions
```
sense/
├── components/     # HitboxComponent, HurtboxComponent, HealthComponent
├── entities/
│   ├── player/     # player.gd, character_stats.gd
│   ├── enemies/    # skeleton/, etc.
│   └── npcs/       # blacksmith/, merchant/
├── globals/        # collision_layers.gd, game_manager.gd
├── maps/           # town.tscn, forest.tscn
└── ui/             # hud/
```

## Naming Conventions
- Scripts: snake_case (e.g., `goblin_enemy.gd`)
- Scenes: PascalCase (e.g., `GoblinEnemy.tscn`)
- Nodes: PascalCase (e.g., `AttackHitbox`, `CollisionShape2D`)

## Always Include
- Health system for entities that can take damage
- Proper signal connections for collisions
- Comments explaining layer/mask choices
- Error handling for null references
- `@export var debug_draw_enabled: bool` for visualization
- ASCII diagram in comments explaining state machine

## Documentation Reference
- `LAYER_AND_MASK_STANDARDS.md` - Collision layer details
- `docs/COMBAT_SYSTEM.md` - Combat interaction flow
