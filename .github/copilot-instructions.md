# GitHub Copilot Instructions for Godot Project

## Project Context
This is a Godot 2D game project with strict collision layer and mask standards.

## Critical Rules for Entity Creation

### ALWAYS Follow Layer & Mask Standards
When creating or modifying ANY game entity (Player, Enemy, NPC, Interactable, Pickup), you MUST:

1. **Reference LAYER_AND_MASK_STANDARDS.md** for correct layer configuration
2. **Apply these exact layer assignments:**
   - Layer 1: World/Environment (tường, obstacles, terrain)
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
- Always include collision layer/mask configuration in `_ready()`
- Use `|` operator for combining masks: `collision_mask = 1 | 2 | 3`
- Add comments explaining which layers are being used

### When creating .tscn scenes:
- Set collision_layer and collision_mask properties
- Use proper node hierarchy (CollisionShape2D child of body)
- Name nodes descriptively (e.g., "PlayerHurtbox", "AttackHitbox")

### Example Enemy Script Pattern:
```gdscript
extends CharacterBody2D

func _ready():
    # Layer 3 (Enemy), Mask: 1 (World), 2 (Player), 7 (PlayerHitbox)
    collision_layer = 3
    collision_mask = 1 | 2 | 7
```

## File Structure Conventions
- Player scripts: `sense/player/`
- Enemy scripts: Create in `sense/enemies/` (create if needed)
- NPC scripts: Create in `sense/npcs/` (create if needed)
- Map scripts: `sense/maps/`
- Shop/Interactable: `sense/Town Shop/` or `sense/interactables/`

## Naming Conventions
- Scripts: snake_case (e.g., `goblin_enemy.gd`)
- Scenes: PascalCase (e.g., `GoblinEnemy.tscn`)
- Nodes: PascalCase (e.g., `AttackHitbox`, `CollisionShape2D`)

## Always Include
- Health system for entities that can take damage
- Proper signal connections for collisions
- Comments explaining layer/mask choices
- Error handling for null references
