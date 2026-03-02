# Godot Collision Layer & Mask Standards

## Layer Definition (Tầng va chạm)

| Layer | Tên | Mô tả |
|-------|-----|-------|
| 1 | World/Environment | Tường, obstacles, terrain |
| 2 | Player | Player character |
| 3 | Enemy | Enemies |
| 4 | NPC | NPCs (thương nhân, dân làng...) |
| 5 | PlayerHurtbox | Vùng player có thể nhận damage |
| 6 | EnemyHurtbox | Vùng enemy có thể nhận damage |
| 7 | PlayerHitbox | Vùng tấn công của player |
| 8 | EnemyHitbox | Vùng tấn công của enemy |
| 9 | Interactable | Cửa hàng, chest, door... |
| 10 | Pickup | Items có thể nhặt |

---

## Entity Configuration (Cấu hình cho từng Entity)

### Player
```
Layer: 2 (Player)
Mask: 1 (World), 3 (Enemy), 4 (NPC), 8 (EnemyHitbox), 9 (Interactable), 10 (Pickup)
```

### Enemy
```
Layer: 3 (Enemy)
Mask: 1 (World), 2 (Player), 3 (Enemy - nếu muốn enemy đáy nhau), 7 (PlayerHitbox)
```

### NPC
```
Layer: 4 (NPC)
Mask: 1 (World), 2 (Player)
```

### Interactable (Cửa hàng / Shop / Chest / Door)
```
Layer: 9 (Interactable)
Mask: 2 (Player) - chỉ cần detect player
```

### Player Attack Hitbox (Area2D)
```
Layer: 7 (PlayerHitbox)
Mask: 6 (EnemyHurtbox)
```

### Enemy Attack Hitbox (Area2D)
```
Layer: 8 (EnemyHitbox)
Mask: 5 (PlayerHurtbox)
```

### Pickup Item
```
Layer: 10 (Pickup)
Mask: 2 (Player)
```

---

## Quy tắc khi tạo Entity mới

1. **Xác định loại entity**: Player, Enemy, NPC, Interactable, hay Pickup
2. **Gán Layer đúng**: Dựa vào bảng Layer Definition
3. **Cấu hình Mask**: Chọn các layer mà entity cần phát hiện collision
4. **Cho các Hitbox/Hurtbox**: Luôn tạo trên layer 7 (Player) hoặc 8 (Enemy) với mask phù hợp
5. **Kiểm tra**: Đảm bảo collision chỉ xảy ra giữa các layer có mặt trong Mask

---

## Ví dụ áp dụng

**Tạo Enemy mới:**
- Collision node: Layer 3, Mask: 1, 2, 7
- Attack Hitbox (Area2D): Layer 8, Mask: 5

**Tạo Shop/NPC:**
- Collision node: Layer 4, Mask: 1, 2
- Không cần Hitbox

**Tạo Chest:**
- Collision node: Layer 9, Mask: 2
- Không cần Hitbox

---

## Lưu ý

- Luôn kiểm tra Layer & Mask khi tạo object mới
- Layer và Mask phải synchronized để collision hoạt động đúng
- Để test collision: sử dụng Physics2D Debugger trong Godot
