# Dungeon System — Implementation Guide & Best Practices

> Use this prompt when adding features to the dungeon system, creating new room types,
> adding enemies, or modifying dungeon generation. Covers architecture, spawning patterns,
> room locking, difficulty scaling, tile structures, and camera configuration.

---

## Architecture Overview

```
┌────────────────────────────────────────────────────────────────────────┐
│                        DUNGEON SYSTEM FLOW                             │
│                                                                        │
│   Portal (Town)                                                        │
│       │                                                                │
│       ▼  SceneTransitionService.go_to_dungeon()                        │
│   ┌─────────────────────────────────────────────────────────────────┐  │
│   │ DungeonLevel._ready()                                           │  │
│   │  1. Get player from "player" group                              │  │
│   │  2. CameraService → ROOM mode (bounded to room)                │  │
│   │  3. DungeonGenerator.generate() → random walk algorithm         │  │
│   │  4. _render_room(START) → draw tiles, spawn enemies             │  │
│   │  5. Setup HUD minimap                                           │  │
│   └─────────────────────────────────────────────────────────────────┘  │
│                                                                        │
│   ┌─────────────────────────────────────────────────────────────────┐  │
│   │ ROOM GAMEPLAY LOOP (per _process frame)                         │  │
│   │                                                                 │  │
│   │  _check_door_collision()                                        │  │
│   │    │                                                            │  │
│   │    ├─ _doors_locked == true → skip (enemies alive)              │  │
│   │    └─ player at door tile → _go_to_room(dir)                    │  │
│   │         ├─ _render_room(new_pos) → clear old, draw new          │  │
│   │         ├─ Teleport player to opposite wall                     │  │
│   │         └─ Update HUD minimap                                   │  │
│   └─────────────────────────────────────────────────────────────────┘  │
│                                                                        │
│   ┌─────────────────────────────────────────────────────────────────┐  │
│   │ ENEMY SPAWNING & ROOM LOCKING                                   │  │
│   │                                                                 │  │
│   │  _spawn_room_enemies(room)                                      │  │
│   │    ├─ room.cleared? → skip                                      │  │
│   │    ├─ Get count from _get_enemy_count_for_room()                │  │
│   │    ├─ Instantiate SKELETON_SCENE × count                        │  │
│   │    ├─ Position randomly within safe bounds (4 tiles from walls) │  │
│   │    ├─ Connect tree_exiting → _on_enemy_removed()                │  │
│   │    └─ _lock_doors() → paint wall tiles over door openings       │  │
│   │                                                                 │  │
│   │  _on_enemy_removed(enemy)                                       │  │
│   │    ├─ Remove from _active_enemies                               │  │
│   │    └─ All dead? → room.cleared = true, _unlock_doors()          │  │
│   │                    → Spawn return portal (boss rooms)           │  │
│   └─────────────────────────────────────────────────────────────────┘  │
│                                                                        │
│   Return Portal (Boss room, after cleared)                             │
│       │                                                                │
│       ▼  SceneTransitionService.go_to_town()                           │
│   Back to Town                                                         │
└────────────────────────────────────────────────────────────────────────┘
```

---

## Room Type Behavior Table

| Room Type  | Enemies | Doors Locked | Structures | Tint   | Special Spawn        |
|------------|---------|--------------|------------|--------|----------------------|
| START      | 0       | Never        | No         | White  | Player spawn point   |
| NORMAL     | 2–3     | Until cleared| Yes (1-2)  | White  | —                    |
| BOSS       | 1       | Until cleared| No         | Red    | Return portal (after clear) |
| TREASURE   | 0       | Never        | No         | Yellow | (Future: loot chest) |

---

## Difficulty Scaling

Enemy count in NORMAL rooms scales by grid distance from START:

| Distance from START | Enemy Count |
|---------------------|-------------|
| 1                   | 2           |
| 2                   | 2–3 (random)|
| 3+                  | 3           |

Distance is Euclidean: `Vector2(room.pos - start_pos).length()`.

To add stat scaling (future), modify skeleton stats after instantiation:
```gdscript
# Example: scale enemy health by distance
var dist := Vector2(room.pos - start_pos).length()
var health_mult := 1.0 + (dist - 1.0) * 0.25
enemy.get_node("HealthComponent").max_health *= health_mult
```

---

## Key Files

| File | Class | Purpose |
|------|-------|---------|
| `sense/maps/dungeon/dungeon_generator.gd` | `DungeonGenerator` | Procedural layout via random walk |
| `sense/maps/dungeon/dungeon_level.gd` | `DungeonLevel` | Room rendering, enemy spawning, door locking |
| `sense/maps/dungeon/dungeon_tilestructure.gd` | `DungeonTileStructure` | Tile structure library |
| `sense/maps/dungeon/tileset_structure.gd` | `TilesetStructure` | Structure resource (atlas region) |
| `sense/maps/dungeon/dungeon_map.tscn` | — | Scene: FloorLayer + WallLayer + Camera2D + PlayerSpawn |
| `sense/maps/dungeon/return_portal.gd` | — | Interact to return to town |
| `sense/globals/camera_service.gd` | `CameraService` | ROOM mode with bounds clamping |

---

## Adding a New Enemy Type

### Step 1: Create the enemy scene

Follow the component architecture from `copilot-instructions.md`:
```
NewEnemy (CharacterBody2D)
├── AnimatedSprite2D
├── CollisionShape2D
├── HealthComponent (Node)
├── HitboxComponent (Area2D)       # Layer 8, Mask 5
│   └── CollisionShape2D
├── HurtboxComponent (Area2D)      # Layer 6, Mask 7
│   └── CollisionShape2D
└── HealthBar (ProgressBar)
```

Collision setup:
```gdscript
# Body
collision_layer = CollisionLayers.Layer.ENEMY        # Layer 3
collision_mask = CollisionLayers.Layer.WORLD          # Mask 1

# Hitbox
hitbox.collision_layer = CollisionLayers.Layer.ENEMY_HITBOX    # Layer 8
hitbox.collision_mask = CollisionLayers.Layer.PLAYER_HURTBOX   # Mask 5

# Hurtbox
hurtbox.collision_layer = CollisionLayers.Layer.ENEMY_HURTBOX  # Layer 6
hurtbox.collision_mask = CollisionLayers.Layer.PLAYER_HITBOX   # Mask 7
```

### Step 2: Add to DungeonLevel spawning

In `dungeon_level.gd`, preload the scene and add to spawn logic:
```gdscript
const NEW_ENEMY_SCENE := preload("res://sense/entities/enemies/new_enemy/new_enemy.tscn")
```

Modify `_spawn_room_enemies()` to vary enemy types:
```gdscript
# Example: pick random enemy type
var enemy_scenes := [SKELETON_SCENE, NEW_ENEMY_SCENE]
var enemy := enemy_scenes.pick_random().instantiate() as Node2D
```

### Step 3: Ensure death triggers cleanup

The enemy MUST call `queue_free()` on death. `DungeonLevel` tracks enemies via `tree_exiting` signal — when the last enemy is freed, doors unlock automatically.

---

## Adding a New Tile Structure

### Step 1: Find atlas coordinates

Open the tileset PNG in Godot's TileSet editor. Hover over tiles to see atlas positions (column, row).

### Step 2: Add to DungeonTileStructure

In `sense/maps/dungeon/dungeon_tilestructure.gd`:
```gdscript
## My new structure: atlas (col_start, row_start) to (col_end, row_end) = WxH tiles
static func my_structure() -> TilesetStructure:
    return TilesetStructure.new(
        TilesetStructure.Layer.WALL,    # or Layer.FLOOR
        Vector2i(col_start, row_start), # Top-left atlas coord
        Vector2i(col_end, row_end)      # Bottom-right atlas coord
    )
```

### Step 3: Register in random pool

Add to `get_random_wall_structure()`:
```gdscript
var choices: Array[Callable] = [
    wall_block_large,
    wall_panel,
    pillar,
    # ... existing
    my_structure,  # ← add here
]
```

### Structure placement rules
- Only placed in NORMAL rooms (START/BOSS/TREASURE stay clean)
- Safe bounds: 4+ tiles from walls to avoid blocking doors
- Max 1–2 structures per room
- Overlap check: 1 tile padding between structures
- Source IDs must match `dungeon_map.tscn` TileSet: WALL=0, FLOOR=1

---

## Camera Configuration

The dungeon uses `CameraService.Mode.ROOM` which clamps the camera view within room bounds.

```gdscript
# In _ready()
CameraService.use_custom_camera(camera, player, CameraService.Mode.ROOM)

# In _render_room() — update bounds each room transition
CameraService.set_room_bounds(Rect2(
    Vector2.ZERO,
    Vector2(room_width * TILE_SIZE, room_height * TILE_SIZE)
))

# In _exit_tree() — clean up before restoring player camera
CameraService.clear_room_bounds()
CameraService.restore_player_camera()
```

Camera settings (single source of truth in `camera_service.gd`):
- Zoom: `(2, 2)`
- Position smoothing: enabled, speed 10.0
- ROOM mode: follows player but clamps to `_room_bounds` so edges of room aren't visible

---

## Room Locking Mechanic

### How it works

1. Player enters an uncleared room → `_spawn_room_enemies()` runs
2. `_lock_doors()` paints wall tiles (`atlas (2,2)`) over all door openings
3. `_check_door_collision()` returns early while `_doors_locked == true`
4. Each enemy death triggers `_on_enemy_removed()` via `tree_exiting` signal
5. When `_active_enemies` is empty → `room.cleared = true`, `_unlock_doors()` erases wall tiles
6. Cleared rooms never spawn enemies again (persists for current dungeon run)

### Extending the lock visual

To replace plain wall tiles with a gate sprite:
```gdscript
# Instead of painting wall tiles, instantiate a gate scene at each door
# and free it on unlock. Store refs in an Array[Node2D] like _active_enemies.
```

---

## DungeonGenerator.Room Properties

```gdscript
class Room:
    var pos: Vector2i          # Grid position (e.g., Vector2i(5, 5))
    var type: RoomType         # START, NORMAL, BOSS, TREASURE
    var doors: Array[Dir]      # Connected directions [UP, RIGHT, ...]
    var cleared: bool          # True when all enemies defeated
```

- `cleared` defaults to `false` on NORMAL/BOSS, `true` on START/TREASURE
- Resets every dungeon visit (dungeon scene is NON_CACHED in SceneTransitionService)

---

## Checklist for Dungeon Changes

- [ ] Collision layers match `LAYER_AND_MASK_STANDARDS.md`
- [ ] New enemies call `queue_free()` on death (required for room lock tracking)
- [ ] Structures use correct source ID (WALL=0, FLOOR=1)
- [ ] Camera bounds updated in `_render_room()` via `CameraService.set_room_bounds()`
- [ ] Room type behavior matches the table above (enemies, tint, structures)
- [ ] HUD minimap updated on room transition
- [ ] `_exit_tree()` cleans up camera bounds and active enemies
- [ ] Test: START room has no enemies, NORMAL has 2-3, BOSS has 1
- [ ] Test: Doors lock on enemy spawn, unlock on all enemies defeated
- [ ] Test: Re-entering cleared room has no enemies
