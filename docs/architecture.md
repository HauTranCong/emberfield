# Emberfield Architecture UML

## Class Diagram - System Overview

```mermaid
classDiagram
    direction TB
    
    %% ═══════════════════════════════════════════════════════════════
    %% CORE COMPONENTS
    %% ═══════════════════════════════════════════════════════════════
    
    class HealthComponent {
        +int max_health
        +int current_health
        +signal health_changed(current, maximum)
        +signal died()
        +take_damage(amount) int
        +heal(amount)
        +reset()
        +is_dead() bool
        +get_health_percent() float
    }
    
    class HitboxComponent {
        +int damage
        +float knockback_force
        +bool check_line_of_sight
        +bool monitoring
        +signal hit_landed(hurtbox)
        -_on_area_entered(area)
        -_has_clear_line_of_sight(target) bool
    }
    
    class HurtboxComponent {
        +float invincibility_time
        +bool can_take_damage
        +signal damage_received(amount, knockback, from_position)
        +take_damage(amount, knockback, from_position)
        +reset()
    }
    
    class ShopComponent {
        +signal purchase_successful(item, remaining_gold)
        +signal purchase_failed(reason, item)
        +process_purchase(item) bool
        +get_player_gold() int
    }
    
    class InteractionManager {
        +Array active_areas
        +bool can_interact
        +register_area(area)
        +unregister_area(area)
    }
    
    %% ═══════════════════════════════════════════════════════════════
    %% ENTITIES
    %% ═══════════════════════════════════════════════════════════════
    
    class Player {
        <<CharacterBody2D>>
        +CharacterStats stats
        +InventoryData inventory
        +State current_state
        +Vector2 last_direction
        -AnimatedSprite2D anim
        -HitboxComponent attack_hitbox
        -HurtboxComponent hurtbox
        +_physics_process(delta)
        -_handle_input()
        -_change_state(new_state)
        -_enable_attack_hitbox()
    }
    
    class Skeleton {
        <<CharacterBody2D>>
        +State current_state
        +Node2D player_ref
        -HealthComponent health_component
        -HitboxComponent hitbox
        -HurtboxComponent hurtbox
        -AnimatedSprite2D anim
        +_physics_process(delta)
        -_state_idle()
        -_state_patrol()
        -_state_chase()
        -_state_attack()
    }
    
    class NPC {
        <<CharacterBody2D>>
        +ShopComponent shop
        +InteractionArea interaction_area
    }
    
    %% ═══════════════════════════════════════════════════════════════
    %% ITEM SYSTEM
    %% ═══════════════════════════════════════════════════════════════
    
    class GameItem {
        <<Area2D>>
        +PickupMode pickup_mode
        +VisualStyle visual_style
        +ContentType content_type
        +String item_id
        +int quantity
        +signal collected(content_type, item_id, quantity)
        -_on_body_entered(body)
        -_pickup()
    }
    
    class ItemData {
        <<Resource>>
        +String id
        +String name
        +Texture2D icon
        +ItemType type
        +int stack_size
    }
    
    class InventoryData {
        <<Resource>>
        +Array inventory_slots
        +int gold
        +ItemData equipped_weapon
        +ItemData equipped_armor
        +signal inventory_changed()
        +signal gold_changed(amount)
        +add_item(item, quantity) int
        +remove_item(slot_index, quantity)
    }
    
    %% ═══════════════════════════════════════════════════════════════
    %% UI SYSTEM
    %% ═══════════════════════════════════════════════════════════════
    
    class HUD {
        <<CanvasLayer>>
        -PixelBar health_bar
        -PixelBar stamina_bar
        -Camera2D minimap_camera
        +setup(character_stats)
        -_on_health_changed()
        -_on_stamina_changed()
    }
    
    class InventoryPanel {
        <<Control>>
        +InventoryData inventory_data
        -_update_slots()
        -_on_slot_clicked(index)
    }
    
    %% ═══════════════════════════════════════════════════════════════
    %% GLOBALS
    %% ═══════════════════════════════════════════════════════════════
    
    class CollisionLayers {
        <<Autoload>>
        +WORLD = 1
        +PLAYER = 2
        +ENEMY = 4
        +NPC = 8
        +PLAYER_HURTBOX = 16
        +ENEMY_HURTBOX = 32
        +PLAYER_HITBOX = 64
        +ENEMY_HITBOX = 128
        +INTERACTABLE = 256
        +PICKUP = 512
    }
    
    class GameEvent {
        <<Autoload>>
        +signal request_ui_pause(is_open)
    }
    
    class CharacterStats {
        <<Resource>>
        +int max_health
        +int current_health
        +float max_stamina
        +float current_stamina
        +int attack_damage
        +float move_speed
        +signal health_changed(current, max)
        +signal stamina_changed(current, max)
    }
    
    %% ═══════════════════════════════════════════════════════════════
    %% RELATIONSHIPS
    %% ═══════════════════════════════════════════════════════════════
    
    %% Player Composition
    Player *-- HitboxComponent : attack_hitbox
    Player *-- HurtboxComponent : hurtbox
    Player *-- CharacterStats : stats
    Player o-- InventoryData : inventory
    
    %% Enemy Composition
    Skeleton *-- HealthComponent
    Skeleton *-- HitboxComponent : hitbox
    Skeleton *-- HurtboxComponent : hurtbox
    
    %% NPC Composition
    NPC *-- ShopComponent
    
    %% Combat Interactions
    HitboxComponent ..> HurtboxComponent : area_entered
    HurtboxComponent ..> HealthComponent : damage_received
    
    %% UI Connections
    HUD ..> CharacterStats : observes
    InventoryPanel ..> InventoryData : displays
    
    %% Item System
    GameItem ..> InventoryData : collected → add_item
    GameItem o-- ItemData : references
    InventoryData o-- ItemData : contains
    
    %% Global Usage
    Player ..> CollisionLayers : uses
    Skeleton ..> CollisionLayers : uses
    GameItem ..> CollisionLayers : uses
```

---

## Combat System - Sequence Diagram

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

## State Machine Diagrams

### Player State Machine

```mermaid
stateDiagram-v2
    [*] --> IDLE
    
    IDLE --> MOVE : has_input
    IDLE --> ATTACK : attack_pressed
    IDLE --> DEATH : HP <= 0
    
    MOVE --> IDLE : no_input
    MOVE --> ATTACK : attack_pressed
    MOVE --> DEATH : HP <= 0
    
    ATTACK --> IDLE : animation_finished
    ATTACK --> DEATH : HP <= 0
    
    DEATH --> [*]
    
    note right of IDLE : velocity = 0\nwaiting for input
    note right of MOVE : velocity = direction * speed\ncan be cancelled by attack
    note right of ATTACK : velocity = 0\nhitbox enabled\nanimation plays
    note right of DEATH : disable input\ngame over
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

## Component Interaction - Node Hierarchy

```mermaid
graph TD
    subgraph Player["Player (CharacterBody2D)"]
        PA[AnimatedSprite2D]
        PC[CollisionShape2D]
        PStats[CharacterStats Resource]
        
        subgraph PHitbox["Hitbox (Area2D)"]
            PHC[CollisionShape2D]
        end
        
        subgraph PHurtbox["Hurtbox (Area2D)"]
            PHUC[CollisionShape2D]
        end
    end
    
    subgraph Enemy["Skeleton (CharacterBody2D)"]
        EA[AnimatedSprite2D]
        EC[CollisionShape2D]
        EHC[HealthComponent]
        EHB[HealthBar]
        
        subgraph EHitbox["Hitbox (Area2D)"]
            EHitC[CollisionShape2D]
        end
        
        subgraph EHurtbox["Hurtbox (Area2D)"]
            EHurtC[CollisionShape2D]
        end
    end
    
    PHitbox -.->|"Layer 7 → Mask 6"| EHurtbox
    EHitbox -.->|"Layer 8 → Mask 5"| PHurtbox
    
    style PHitbox fill:#ff6b6b
    style PHurtbox fill:#4ecdc4
    style EHitbox fill:#ff6b6b
    style EHurtbox fill:#4ecdc4
```

---

## Collision Layer System

```mermaid
graph LR
    subgraph Layers["Collision Layers"]
        L1["Layer 1: WORLD"]
        L2["Layer 2: PLAYER"]
        L3["Layer 3: ENEMY"]
        L4["Layer 4: NPC"]
        L5["Layer 5: PLAYER_HURTBOX"]
        L6["Layer 6: ENEMY_HURTBOX"]
        L7["Layer 7: PLAYER_HITBOX"]
        L8["Layer 8: ENEMY_HITBOX"]
        L9["Layer 9: INTERACTABLE"]
        L10["Layer 10: PICKUP"]
    end
    
    subgraph Masks["Mask Relationships"]
        M1["Player Body"]
        M2["Enemy Body"]
        M3["Player Hitbox"]
        M4["Enemy Hitbox"]
    end
    
    L2 --> M1
    L3 --> M2
    L7 --> M3
    L8 --> M4
    
    M1 -.->|mask| L1
    M1 -.->|mask| L3
    M1 -.->|mask| L4
    M1 -.->|mask| L8
    M1 -.->|mask| L9
    M1 -.->|mask| L10
    
    M2 -.->|mask| L1
    M2 -.->|mask| L7
    
    M3 -.->|mask| L6
    M4 -.->|mask| L5
```

---

## Item System Flow

```mermaid
---
id: 2ab9a48e-f90c-40f9-8a7c-9c2fb67626bd
---
flowchart TD
    subgraph Spawn["Item Spawning"]
        A[Enemy Death] --> B[LootTable.roll]
        B --> C[ItemSpawner.spawn]
        C --> D[GameItem Instance]
    end
    
    subgraph Pickup["Item Pickup"]
        D --> E{Pickup Mode?}
        E -->|AUTO| F[body_entered → pickup]
        E -->|INTERACT| G[press E → pickup]
        E -->|MAGNET| H[attract to player → pickup]
        E -->|PROXIMITY| I[wait timer → pickup]
    end
    
    subgraph Process["Item Processing"]
        F & G & H & I --> J{Content Type?}
        J -->|ITEM| K[InventoryData.add_item]
        J -->|GOLD| L[InventoryData.gold += value]
        J -->|HEALTH| M[Player.heal]
        J -->|XP| N[Player.add_xp]
    end
    
    subgraph UI["UI Update"]
        K --> O[inventory_changed signal]
        L --> P[gold_changed signal]
        O --> Q[InventoryPanel update]
        P --> R[HUD gold display update]
    end
```

---

## Inventory System Structure

```mermaid
classDiagram
    class InventoryData {
        +INVENTORY_SIZE: 32
        +inventory_slots: Array~Dictionary~
        +gold: int
        +equipped_helmet: ItemData
        +equipped_armor: ItemData
        +equipped_weapon: ItemData
        +equipped_shield: ItemData
        +equipped_boots: ItemData
        +equipped_accessory_1: ItemData
        +equipped_accessory_2: ItemData
        +add_item(item, quantity) int
        +remove_item(slot_index, quantity)
        +equip_item(slot_index)
        +unequip_item(slot_type)
    }
    
    class ItemData {
        +id: String
        +name: String
        +description: String
        +icon: Texture2D
        +type: ItemType
        +stack_size: int
        +stats: Dictionary
    }
    
    class ItemDatabase {
        +items: Dictionary~String, ItemData~
        +get_item(id) ItemData
        +get_all_items() Array
    }
    
    class InventoryPanel {
        +inventory_data: InventoryData
        +slot_nodes: Array~InventorySlotUI~
        +_update_display()
        +_on_slot_clicked(index)
        +_on_item_dropped(from, to)
    }
    
    class InventorySlotUI {
        +slot_index: int
        +item_icon: TextureRect
        +quantity_label: Label
        +set_item(item, quantity)
        +clear()
    }
    
    InventoryData "1" *-- "*" ItemData : contains
    ItemDatabase "1" --> "*" ItemData : provides
    InventoryPanel "1" --> "1" InventoryData : displays
    InventoryPanel "1" *-- "32" InventorySlotUI : has slots
```

---

## File Structure Overview

```
sense/
├── main.gd                    # Game entry point
├── Main.tscn
│
├── components/                # Reusable components
│   ├── health_component.gd    # HP management
│   ├── hitbox_component.gd    # Deal damage
│   ├── hurtbox_component.gd   # Receive damage
│   ├── shop_component.gd      # Purchase logic
│   └── interaction_manager/   # E to interact
│
├── entities/
│   ├── player/
│   │   ├── player.gd          # State machine, input
│   │   ├── player.tscn
│   │   └── character_stats.gd # Stats resource
│   │
│   ├── enemies/
│   │   └── skeleton/
│   │       ├── skeleton.gd    # AI state machine
│   │       └── skeleton.tscn
│   │
│   └── npcs/
│       ├── blacksmith/
│       └── merchant/
│
├── globals/                   # Autoloads
│   ├── collision_layers.gd    # Layer enum
│   └── game_event.gd          # Global signals
│
├── items/
│   ├── game_item.gd           # Pickup item class
│   ├── item_spawner.gd        # Spawn items
│   └── loot_table.gd          # Drop rates
│
├── ui/
│   ├── hud/
│   │   ├── hud.gd             # Health/stamina bars
│   │   └── pixel_bar.gd       # Custom bar component
│   │
│   └── inventory/
│       ├── inventory_data.gd   # Data model
│       ├── inventory_panel.gd  # UI controller
│       ├── item_data.gd        # Item resource
│       └── item_database.gd    # Item registry
│
└── maps/
    └── town.tscn              # Game world
```
