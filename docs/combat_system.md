# Combat System - Enemy & Player Interaction

## Tổng quan

Hệ thống combat trong Emberfield sử dụng **Hitbox/Hurtbox pattern** để xử lý damage giữa Player và Enemy. Điều này tách biệt hoàn toàn logic damage ra khỏi physics collision.

---

## State Machine Diagrams

### Player State Machine

```mermaid
stateDiagram-v2
    [*] --> IDLE
    
    IDLE --> MOVE : movement_input
    IDLE --> ATTACK : attack_pressed
    IDLE --> SKILL : skill_pressed
    IDLE --> DEATH : HP <= 0
    
    MOVE --> IDLE : no_input
    MOVE --> ATTACK : attack_pressed
    MOVE --> SKILL : skill_pressed
    MOVE --> DEATH : HP <= 0
    
    ATTACK --> IDLE : animation_finished
    ATTACK --> DEATH : HP <= 0
    
    SKILL --> IDLE : skill_effect_finished
    SKILL --> DEATH : HP <= 0
    
    DEATH --> [*] : game_over
    
    note right of IDLE : velocity = 0
    note right of MOVE : speed = move_speed
    note right of ATTACK : velocity = 0\nhitbox active
    note right of SKILL : velocity = 0\nskill hitbox active
    note right of DEATH : play death anim
```

### Enemy (Skeleton) State Machine

```mermaid
stateDiagram-v2
    [*] --> IDLE
    
    IDLE --> PATROL : timer >= 2s
    IDLE --> CHASE : player_detected
    IDLE --> DEATH : HP <= 0
    
    PATROL --> IDLE : timer >= 2s
    PATROL --> CHASE : player_detected
    PATROL --> DEATH : HP <= 0
    
    CHASE --> ATTACK : distance <= ATTACK_RANGE
    CHASE --> PATROL : player_lost
    CHASE --> DEATH : HP <= 0
    
    ATTACK --> CHASE : animation_finished
    ATTACK --> DEATH : HP <= 0
    
    DEATH --> [*] : queue_free()
    
    note right of IDLE : velocity = 0\nwait 2s
    note right of PATROL : random direction\nspeed = 30
    note right of CHASE : move toward player\nspeed = 50
    note right of ATTACK : velocity = 0\nhitbox after 0.8s delay
    note right of DEATH : play death anim\ndrop loot
```

---

## Sơ đồ tương tác tổng quan

```mermaid
graph TB
    subgraph Player["PLAYER (CharacterBody2D)"]
        direction TB
        P_Info["Layer 2: PLAYER<br/>Mask: WORLD|NPC|INTERACTABLE"]
        subgraph P_Components[" "]
            P_Hitbox["HITBOX (Area2D)<br/>Layer 7: PLAYER_HITBOX<br/>Mask 6: ENEMY_HURTBOX"]
            P_Hurtbox["HURTBOX (Area2D)<br/>Layer 5: PLAYER_HURTBOX<br/>Mask 8: ENEMY_HITBOX"]
        end
    end
    
    subgraph Enemy["ENEMY (CharacterBody2D)"]
        direction TB
        E_Info["Layer 3: ENEMY<br/>Mask: WORLD"]
        subgraph E_Components[" "]
            E_Hitbox["HITBOX (Area2D)<br/>Layer 8: ENEMY_HITBOX<br/>Mask 5: PLAYER_HURTBOX"]
            E_Hurtbox["HURTBOX (Area2D)<br/>Layer 6: ENEMY_HURTBOX<br/>Mask 7: PLAYER_HITBOX"]
        end
    end
    
    P_Hitbox -->|"Player hits Enemy"| E_Hurtbox
    E_Hitbox -->|"Enemy hits Player"| P_Hurtbox
    
    style P_Hitbox fill:#ff6b6b
    style P_Hurtbox fill:#4ecdc4
    style E_Hitbox fill:#ff6b6b
    style E_Hurtbox fill:#4ecdc4
```

---

## Chi tiết Collision Layers

| Layer | Tên | Bit Value | Mô tả |
|-------|-----|-----------|-------|
| 1 | WORLD | 1 | Tường, obstacles, terrain |
| 2 | PLAYER | 2 | Player body |
| 3 | ENEMY | 4 | Enemy body |
| 4 | NPC | 8 | NPC body |
| 5 | PLAYER_HURTBOX | 16 | Vùng Player nhận damage |
| 6 | ENEMY_HURTBOX | 32 | Vùng Enemy nhận damage |
| 7 | PLAYER_HITBOX | 64 | Vùng Player gây damage |
| 8 | ENEMY_HITBOX | 128 | Vùng Enemy gây damage |
| 9 | INTERACTABLE | 256 | Shop, chest, door |
| 10 | PICKUP | 512 | Items có thể nhặt |

---

### Player Attacks Enemy

```mermaid
sequenceDiagram
    participant P as Player
    participant PH as Player Hitbox
    participant EHurt as Enemy Hurtbox
    participant EHealth as Enemy HealthComponent
    participant E as Skeleton
    
    P->>P: Input: attack_pressed
    P->>P: _change_state(ATTACK)
    P->>PH: monitoring = true
    P->>P: play("attack_" + direction)
    
    Note over PH,EHurt: Collision Check (Layer 7 → Mask 6)
    
    PH->>EHurt: area_entered signal
    PH->>PH: _has_clear_line_of_sight(target)
    alt Clear LOS
        PH->>EHurt: take_damage(damage, knockback, position)
        EHurt->>EHurt: emit damage_received
        EHurt->>EHealth: take_damage(amount)
        EHealth->>E: health_changed signal
        alt HP <= 0
            EHealth->>E: died signal
            E->>E: _change_state(DEATH)
        end
    else Blocked by Wall
        Note over PH: Attack blocked - no damage
    end
    
    P->>PH: monitoring = false
    P->>P: _change_state(IDLE)
```

---

### Enemy Attacks Player

```mermaid
sequenceDiagram
    participant S as Skeleton
    participant SH as Skeleton Hitbox
    participant PHurt as Player Hurtbox
    participant PStats as CharacterStats
    participant P as Player
    participant HUD as HUD
    
    S->>S: distance_to_player <= ATTACK_RANGE
    S->>S: _change_state(ATTACK)
    S->>S: play("attack_" + direction)
    
    Note over S: Wait HITBOX_DELAY (0.8s)
    
    S->>SH: monitoring = true
    
    Note over SH,PHurt: Collision Check (Layer 8 → Mask 5)
    
    SH->>PHurt: area_entered signal
    PHurt->>PHurt: check can_take_damage
    alt Can Take Damage
        PHurt->>PHurt: emit damage_received
        PHurt->>P: apply knockback
        P->>PStats: take_damage(amount)
        PStats->>HUD: health_changed signal
        HUD->>HUD: update health_bar
        PHurt->>PHurt: can_take_damage = false
        Note over PHurt: i-frames (0.5s)
        PHurt->>PHurt: can_take_damage = true
    else Invincible
        Note over PHurt: Damage blocked
    end
    
    S->>SH: monitoring = false
    S->>S: _change_state(CHASE)
```

---

## Iframe System (Player)

Mục đích: Ngăn Player bị hit liên tục, cho thời gian phản ứng.

```mermaid
gantt
    title Iframe Timeline (0.5 seconds)
    dateFormat X
    axisFormat %s
    
    section Damage
    HIT! :milestone, hit1, 0, 0
    Next HIT OK :milestone, hit2, 500, 500
    
    section Invincibility
    INVINCIBLE (0.5s) :active, inv, 0, 500
```

```mermaid
flowchart LR
    subgraph Iframe["Invincibility Period (0.5s)"]
        A["Player nhấp nháy<br/>(alpha 0.5 ↔ 1.0)"]
        B["Mọi damage bị bỏ qua"]
        C["Enemy vẫn có thể attack<br/>(nhưng không gây damage)"]
    end
    
    HIT["HIT!"] --> Iframe
    Iframe --> OK["Có thể nhận damage"]
    
    style HIT fill:#ff6b6b
    style OK fill:#4ecdc4
```

**Code trong _physics_process():**

```gdscript
if invincibility_timer > 0:
    invincibility_timer -= delta
    # Hiệu ứng nhấp nháy
    anim.modulate.a = 0.5 if fmod(invincibility_timer * 10, 1.0) > 0.5 else 1.0
else:
    anim.modulate.a = 1.0
```

---

## Passive & Skill Combat Systems

### PassiveEffectProcessor

Xử lý passive effects từ augments trên equipment. Được inject vào Player qua callables để giữ decoupling.

**On-Hit Effects** (kích hoạt khi Player gây damage):
| Effect | Mô Tả |
|--------|-------|
| `LIFE_STEAL` | Hồi HP theo % damage dealt |
| `CRIT_CHANCE` | % cơ hội gây critical (2x damage) |
| `BURN_ON_HIT` | Gây burn DoT cho target |
| `FREEZE_ON_HIT` | Làm chậm target |
| `POISON_ON_HIT` | Gây poison DoT cho target |

**On-Damage Effects** (kích hoạt khi Player nhận damage):
| Effect | Mô Tả |
|--------|-------|
| `THORNS` | Phản damage lại attacker theo % |

### Skill Activation Flow

```mermaid
sequenceDiagram
    participant P as Player
    participant SC as SkillComponent
    participant SE as SkillExecutor
    participant SDB as SkillDatabase
    participant HB as Skill Hitbox (Area2D)
    participant EHurt as Enemy Hurtbox

    P->>P: Input: Q/E/R/F pressed
    P->>SC: try_activate_skill(skill_id)
    SC->>SC: Check cooldown_remaining <= 0
    SC->>SC: Check stamina available
    SC->>P: use_stamina(stamina_cost)
    SC-->>P: skill_activated signal
    P->>P: _change_state(SKILL)
    
    P->>SE: execute_skill(skill_data, origin, dir, damage, parent)
    
    alt Whirlwind (AoE)
        SE->>HB: Create circular hitbox at player
        SE->>SE: Spawn WhirlwindVFX
    else Shield Bash (Cone)
        SE->>HB: Create forward hitbox
    else Fire Burst (Ranged)
        SE->>HB: Create hitbox at target position
    end
    
    HB->>EHurt: area_entered (Layer 7 → Mask 6)
    EHurt->>EHurt: take_damage()
    
    SE-->>P: skill_effect_finished signal
    P->>P: _change_state(IDLE)
    SC->>SC: Start cooldown timer
```

### Skill Slot Mapping

| Equipment Slot | Skill Key | Input Action |
|---------------|-----------|-------------|
| Weapon | Q | skill_1 |
| Armor | E | skill_2 |
| Helmet | R | skill_3 |
| Boots | F | skill_4 |

Skills are bound to equipment via `ACTIVE_SKILL` augments applied to equipment items.

---

## Component Classes

### HitboxComponent (Area2D)
```gdscript
# Vùng GÂY damage
# Layer: PLAYER_HITBOX (7) hoặc ENEMY_HITBOX (8)
# Mask: ENEMY_HURTBOX (6) hoặc PLAYER_HURTBOX (5)

extends Area2D
class_name HitboxComponent

@export var damage: int = 10
@export var knockback_force: float = 100.0

func activate() -> void:
    monitoring = true

func deactivate() -> void:
    monitoring = false

func _on_area_entered(area: Area2D) -> void:
    if area is HurtboxComponent:
        area.receive_damage(damage, knockback_force, global_position)
```

### HurtboxComponent (Area2D)
```gdscript
# Vùng NHẬN damage
# Layer: PLAYER_HURTBOX (5) hoặc ENEMY_HURTBOX (6)
# Mask: ENEMY_HITBOX (8) hoặc PLAYER_HITBOX (7)

extends Area2D
class_name HurtboxComponent

signal damage_received(amount: int, knockback: float, from_position: Vector2)

func receive_damage(amount: int, knockback: float, from_position: Vector2) -> void:
    emit_signal("damage_received", amount, knockback, from_position)
```

### HealthComponent (Node)
```gdscript
# Quản lý HP
# Emit signals khi HP thay đổi hoặc chết

extends Node
class_name HealthComponent

signal health_changed(current: int, maximum: int)
signal died

@export var max_health: int = 100
var current_health: int

func take_damage(amount: int) -> void:
    current_health = max(0, current_health - amount)
    emit_signal("health_changed", current_health, max_health)
    if current_health <= 0:
        emit_signal("died")

func heal(amount: int) -> void:
    current_health = min(max_health, current_health + amount)
    emit_signal("health_changed", current_health, max_health)
```

---

## Damage Flow Sequence

```mermaid
sequenceDiagram
    participant PI as Player Input
    participant PH as Player Hitbox
    participant PHurt as Player Hurtbox
    participant EHurt as Enemy Hurtbox
    participant EHit as Enemy Hitbox
    participant EAI as Enemy
    
    PI->>PH: attack_pressed
    PH->>PH: activate()
    PH->>EHurt: collision detected
    EHurt->>EHurt: receive_damage()
    EHurt->>EHit: damage_received signal
    EHit->>EAI: take_damage()
    EAI->>EAI: HP -= X
    PH->>PH: deactivate()
```

---

## Debug Visualization

Cả Player và Enemy đều có `debug_draw_enabled` export để hiển thị:

### Player Debug Draw
- 🔵 Vòng tròn state color (IDLE=cyan, MOVE=xanh lá, ATTACK=đỏ)
- 📍 Đường chỉ hướng nhìn (last_dir)
- 💚 Velocity vector với mũi tên
- 🟡 Hitbox position khi attack
- 💙 Iframe indicator khi bất tử
- ⚫ 8 chấm hiển thị các vị trí hitbox có thể

### Enemy (Skeleton) Debug Draw
- 🟢 Detection range (150px) - vòng tròn xanh lá
- 🔴 Attack range (30px) - vòng tròn đỏ
- 🟠 Đường đến player khi chase/attack
- 🟡 Hitbox position khi attack
- 📍 Đường chỉ hướng nhìn (last_direction)

---

## Cấu hình quan trọng

### Player Stats
| Stat | Giá trị mặc định | Mô tả |
|------|------------------|-------|
| base_max_health | 100 | HP tối đa |
| base_move_speed | 120 | Tốc độ di chuyển |
| base_attack_damage | 10 | Damage mỗi đòn |
| base_defense | 0 | Giảm damage nhận |
| invincibility_duration | 0.5s | Thời gian bất tử |

**Damage Formula:** `effective_damage = max(1, raw_damage - target_defense)`

**Stat Bonuses:** Final stats = base + equipment_bonus + buff_bonus

### Enemy (Skeleton) Stats
| Stat | Giá trị | Mô tả |
|------|---------|-------|
| max_health | 50 | HP tối đa |
| SPEED | 30 | Tốc độ patrol |
| CHASE_SPEED | 50 | Tốc độ đuổi |
| DETECTION_RANGE | 150px | Phạm vi phát hiện |
| ATTACK_RANGE | 30px | Khoảng cách tấn công |
| HITBOX_DELAY | 0.8s | Delay trước khi hitbox active |
| damage | 15 | Damage mỗi đòn |
| knockback_force | 80 | Lực đẩy lùi |

---

## Troubleshooting

### Player không gây damage cho Enemy
1. Check Player Hitbox layer = 7 (PLAYER_HITBOX)
2. Check Player Hitbox mask = 6 (ENEMY_HURTBOX)
3. Check Enemy Hurtbox layer = 6 (ENEMY_HURTBOX)
4. Check Enemy Hurtbox mask = 7 (PLAYER_HITBOX)
5. Đảm bảo `attack_hitbox.activate()` được gọi
6. Đảm bảo signal `damage_received` được connect

### Enemy không gây damage cho Player
1. Check Enemy Hitbox layer = 8 (ENEMY_HITBOX)
2. Check Enemy Hitbox mask = 5 (PLAYER_HURTBOX)
3. Check Player Hurtbox layer = 5 (PLAYER_HURTBOX)
4. Check Player Hurtbox mask = 8 (ENEMY_HITBOX)
5. Check `invincibility_timer` - có thể đang trong iframe
6. Đảm bảo signal `damage_received` được connect

### Collision không hoạt động
1. Đảm bảo Area2D có CollisionShape2D với shape được set
2. Check `monitoring = true` (cho Area2D detect collision)
3. Check `monitorable = true` (cho Area2D có thể bị detect)
4. Verify collision layers và masks khớp nhau

---

## File References

| File | Mô tả |
|------|-------|
| [sense/entities/player/player.gd](../sense/entities/player/player.gd) | Player controller |
| [sense/entities/player/character_stats.gd](../sense/entities/player/character_stats.gd) | Player stats resource |
| [sense/entities/enemies/skeleton/skeleton.gd](../sense/entities/enemies/skeleton/skeleton.gd) | Skeleton enemy |
| [sense/components/hitbox_component.gd](../sense/components/hitbox_component.gd) | Hitbox component |
| [sense/components/hurtbox_component.gd](../sense/components/hurtbox_component.gd) | Hurtbox component |
| [sense/components/health_component.gd](../sense/components/health_component.gd) | Health component |
| [sense/components/buff_component.gd](../sense/components/buff_component.gd) | Timed stat buffs |
| [sense/components/passive_effect_processor.gd](../sense/components/passive_effect_processor.gd) | On-hit/on-damage passive effects |
| [sense/components/skill_component.gd](../sense/components/skill_component.gd) | Equipment-bound active skills |
| [sense/skills/skill_executor.gd](../sense/skills/skill_executor.gd) | Skill hitbox spawning & VFX |
| [sense/skills/skill_data.gd](../sense/skills/skill_data.gd) | Skill resource definitions |
| [sense/skills/skill_database.gd](../sense/skills/skill_database.gd) | Skill registry (Autoload) |
| [sense/globals/collision_layers.gd](../sense/globals/collision_layers.gd) | Collision layer constants |
