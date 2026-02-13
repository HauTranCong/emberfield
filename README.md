# 🔥 Emberfield

<p align="center">
  <img src="icon.svg" alt="Emberfield Logo" width="128" height="128">
</p>

## 📖 Giới thiệu

**Emberfield** là một dự án game 2D được phát triển bằng **Godot Engine 4.6**. Game theo phong cách pixel art với hệ thống combat, NPC, cửa hàng và khám phá thế giới.

### ✨ Tính năng chính

- 🎮 **Hệ thống Player**: Di chuyển, tấn công, tương tác với NPC
- ⚔️ **Combat System**: Hệ thống Hitbox/Hurtbox component-based (reusable)
- 🏪 **Cửa hàng**: General Shop, Blacksmith
- 👾 **Kẻ thù**: Skeleton với nhiều animations (idle, walk, attack, death)
- 🗺️ **Maps**: Town map với tileset đa dạng
- 🧩 **Component System**: Reusable components cho Health, Hitbox, Hurtbox

### 🎯 Thông số kỹ thuật

- **Engine**: Godot 4.6
- **Độ phân giải**: 1280x720
- **Rendering**: GL Compatibility (Pixel Perfect)
- **Physics**: 2D với hệ thống collision layer chuẩn hóa
- **Architecture**: Component-based, modular structure

---

## 📁 Cấu trúc thư mục

```
emberfield/
│
├── 📄 project.godot              # File cấu hình dự án Godot
├── 📄 LAYER_AND_MASK_STANDARDS.md # Tài liệu chuẩn collision layer
├── 📄 README.md                  # Tài liệu dự án
├── 📄 icon.svg                   # Icon của game
│
├── 📂 assets/                    # Tài nguyên đồ họa
│   ├── 📂 blacksmith/            # Sprites cho thợ rèn
│   ├── 📂 enemies/               # Sprites kẻ thù
│   │   └── 📂 skeleton_hammer/   # Skeleton với búa
│   │       ├── 📂 attack/        # Animation tấn công (8 hướng)
│   │       ├── 📂 death/         # Animation chết
│   │       ├── 📂 idle/          # Animation đứng yên (8 hướng)
│   │       └── 📂 walk/          # Animation di chuyển (8 hướng)
│   ├── 📂 Shop/                  # Sprites cửa hàng
│   │   └── 📂 General-shop/      # Merchant Cart & Merchant Man
│   ├── 📂 soldiers/              # Sprites nhân vật chính (Player)
│   │   ├── 📂 attack/            # Animation tấn công (4 hướng)
│   │   ├── 📂 idle/              # Animation đứng yên (4 hướng)
│   │   └── 📂 walk/              # Animation di chuyển (4 hướng)
│   └── 📂 tilesets/              # Tileset cho map
│       ├── TX Plant.png          # Cây cối
│       ├── TX Props.png          # Props trang trí
│       ├── TX Struct.png         # Công trình
│       ├── TX Tileset Grass.png  # Tileset cỏ
│       ├── TX Tileset Stone Ground.png # Tileset đá
│       └── TX Tileset Wall.png   # Tileset tường
│
└── 📂 sense/                     # Source code & Scenes
    ├── 📄 main.gd                # Script chính (game entry point)
    ├── 📄 Main.tscn              # Scene chính
    │
    ├── 📂 components/            # ⭐ Reusable Components
    │   ├── health_component.gd   # Hệ thống HP (attach to Node)
    │   ├── hitbox_component.gd   # Vùng gây damage (attach to Area2D)
    │   └── hurtbox_component.gd  # Vùng nhận damage (attach to Area2D)
    │
    ├── 📂 entities/              # Tất cả game entities
    │   ├── 📂 player/            # Player character
    │   │   ├── character_stats.gd    # Resource: stats (HP, stamina, damage)
    │   │   ├── player.gd             # Player controller & state machine
    │   │   └── player.tscn           # Player scene
    │   │
    │   ├── 📂 enemies/           # Kẻ thù
    │   │   └── 📂 skeleton/
    │   │       └── skeleton.tscn     # Skeleton enemy scene
    │   │
    │   └── 📂 npcs/              # Non-playable characters
    │       ├── 📂 blacksmith/
    │       │   ├── black_smith_area.gd   # Blacksmith interaction logic
    │       │   └── blacksmith.tscn       # Blacksmith scene
    │       │
    │       └── 📂 merchant/
    │           ├── general_goods.gd      # Shop logic
    │           └── general_goods.tscn    # Merchant shop scene
    │
    ├── 📂 globals/               # Autoload scripts (Singletons)
    │   └── collision_layers.gd   # Định nghĩa collision layers enum
    │
    ├── 📂 maps/                  # Game levels/maps
    │   └── town.tscn             # Bản đồ thị trấn chính
    │
    └── 📂 ui/                    # User Interface
        └── 📂 hud/
            ├── hud.gd            # HUD controller
            ├── hud.tscn          # HUD scene (health bar, minimap)
            └── pixel_bar.gd      # Pixel art progress bar component
```

---

## 🧩 Component System

Dự án sử dụng **Component-based Architecture** để tái sử dụng code:

### Cách sử dụng Components

**1. HealthComponent** - Attach vào bất kỳ Node nào cần HP:
```gdscript
@onready var health: HealthComponent = $HealthComponent

func _ready():
    health.died.connect(_on_died)
    health.health_changed.connect(_on_health_changed)
```

**2. HitboxComponent** - Attach vào Area2D, tự định nghĩa CollisionShape:
```gdscript
@onready var hitbox: HitboxComponent = $AttackHitbox

func attack():
    hitbox.activate()
    await get_tree().create_timer(0.2).timeout
    hitbox.deactivate()
```

**3. HurtboxComponent** - Attach vào Area2D, tự định nghĩa CollisionShape:
```gdscript
@onready var hurtbox: HurtboxComponent = $Hurtbox

func _ready():
    hurtbox.damage_received.connect(_on_damage_received)
```

### Ví dụ cấu trúc Entity
```
Player (CharacterBody2D)
├── Sprite2D
├── CollisionShape2D
├── HealthComponent (Node)          ← Attach health_component.gd
├── Hurtbox (HurtboxComponent)      ← Attach hurtbox_component.gd
│   └── CollisionShape2D            ← Shape riêng cho entity
└── AttackHitbox (HitboxComponent)  ← Attach hitbox_component.gd
    └── CollisionShape2D            ← Shape riêng cho attack
```

---

## 🎮 Điều khiển

| Phím | Hành động |
|------|-----------|
| `W` `A` `S` `D` hoặc Arrow Keys | Di chuyển |
| `A` (Physical Key) | Tấn công |
| `E` | Tương tác với Blacksmith |

---

## 🔧 Collision Layer System

Dự án sử dụng hệ thống collision layer chuẩn hóa:

| Layer | Tên | Mô tả |
|-------|-----|-------|
| 1 | World | Tường, obstacles, terrain |
| 2 | Player | Nhân vật người chơi |
| 3 | Enemy | Kẻ thù |
| 4 | NPC | NPCs (thương nhân, dân làng) |
| 5 | PlayerHurtbox | Vùng player nhận damage |
| 6 | EnemyHurtbox | Vùng enemy nhận damage |
| 7 | PlayerHitbox | Vùng tấn công của player |
| 8 | EnemyHitbox | Vùng tấn công của enemy |
| 9 | Interactable | Shop, chest, door |
| 10 | Pickup | Items có thể nhặt |

> 📚 Xem chi tiết tại [LAYER_AND_MASK_STANDARDS.md](LAYER_AND_MASK_STANDARDS.md)

---

## 🚀 Cài đặt & Chạy

1. **Clone repository:**
   ```bash
   git clone https://github.com/your-username/emberfield.git
   ```

2. **Mở project:**
   - Mở Godot Engine 4.6
   - Import project từ thư mục `emberfield`

3. **Chạy game:**
   - Nhấn `F5` hoặc nút Play

---

## 📝 Ghi chú phát triển

- Tất cả sprites sử dụng pixel art style
- Rendering được tối ưu cho pixel perfect display
- Collision system được thiết kế để dễ mở rộng
- **Component-based architecture** cho dễ teamwork, tránh conflict
- Mỗi entity tự định nghĩa CollisionShape, reuse logic từ components

---

## 👥 Teamwork Guidelines

### Phân công theo Module
| Module | Folder | Mô tả |
|--------|--------|-------|
| Player | `sense/entities/player/` | Character controller, stats |
| Enemies | `sense/entities/enemies/` | AI, behaviors, stats |
| NPCs | `sense/entities/npcs/` | Dialogue, shop logic |
| UI | `sense/ui/` | HUD, menus, popups |
| Maps | `sense/maps/` | Levels, tilemaps |
| Components | `sense/components/` | Shared reusable components |

### Quy tắc tránh Conflict
1. **Không edit `Main.tscn`** trực tiếp - load scenes động
2. **Tách map lớn** thành các area nhỏ
3. **Mỗi người một module** - không chồng chéo
4. **Dùng UIDs** của Godot để tránh path conflict

---

## 📄 License

*Chưa có license cụ thể*

---

<p align="center">
  Made with ❤️ using Godot Engine
</p>
