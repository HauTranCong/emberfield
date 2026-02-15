# Hitbox Component - Reusable attack hitbox
# Attach to Area2D node, configure collision shape separately per entity
##
## ┌─────────────────────────────────────────────────────────────────────────────┐
## │                        LINE OF SIGHT CHECK                                  │
## ├─────────────────────────────────────────────────────────────────────────────┤
## │                                                                             │
## │  Trước khi gây damage, kiểm tra có vật cản (tường) giữa attacker và target  │
## │                                                                             │
## │         [Attacker] ─────────── Raycast ─────────── [Target]                 │
## │              │                    │                    │                    │
## │              │                    ▼                    │                    │
## │              │              ┌─────────┐                │                    │
## │              │              │  WALL   │                │                    │
## │              │              │ (blocked)│               │                    │
## │              │              └─────────┘                │                    │
## │              │                                         │                    │
## │              │  Nếu raycast hit WORLD layer → NO DAMAGE                     │
## │              │  Nếu raycast không hit gì → DEAL DAMAGE                      │
## │                                                                             │
## └─────────────────────────────────────────────────────────────────────────────┘
class_name HitboxComponent
extends Area2D

## Damage dealt when hitting a hurtbox
@export var damage: int = 10
## Force applied to target on hit
@export var knockback_force: float = 100.0
## Enable line of sight check (raycast to check for walls between attacker and target)
@export var check_line_of_sight: bool = true

## Emitted when this hitbox hits a hurtbox
signal hit_landed(hurtbox: Area2D)

func _ready() -> void:
	# Layer/Mask should be set in scene inspector based on entity type:
	# Player: Layer 7 (PLAYER_HITBOX), Mask: Layer 6 (ENEMY_HURTBOX)
	# Enemy: Layer 8 (ENEMY_HITBOX), Mask: Layer 5 (PLAYER_HURTBOX)
	area_entered.connect(_on_area_entered)
	# Default disabled, enable during attack
	monitoring = false


func _on_area_entered(area: Area2D) -> void:
	## ┌─────────────────────────────────────────────────────────────────────────┐
	## │ Callback khi Area2D khác đi vào vùng hitbox                             │
	## │                                                                         │
	## │ Flow:                                                                   │
	## │ 1. Check area có phải HurtboxComponent không (has take_damage method)   │
	## │ 2. Nếu bật LOS check → raycast kiểm tra có tường chắn không             │
	## │ 3. Nếu OK → gọi take_damage() và emit signal hit_landed                 │
	## └─────────────────────────────────────────────────────────────────────────┘
	
	# Kiểm tra area có phải là HurtboxComponent không
	# Thay vì check class_name, check method để linh hoạt hơn
	if area.has_method("take_damage"):
		
		# ════════════════════════════════════════════════════════════════════
		# LINE OF SIGHT CHECK
		# ════════════════════════════════════════════════════════════════════
		# Mục đích: Ngăn chém xuyên tường
		# 
		# Ví dụ tình huống bị block:
		#     [Player]     [Wall]     [Enemy]
		#         ├──────────┼──────────┤
		#         │  Raycast │ blocked  │
		#         └──────────┴──────────┘
		#     → Player KHÔNG thể gây damage cho Enemy
		#
		# Ví dụ tình huống được phép:
		#     [Player]               [Enemy]
		#         ├────────────────────┤
		#         │   Clear LOS        │
		#         └────────────────────┘
		#     → Player CÓ THỂ gây damage cho Enemy
		# ════════════════════════════════════════════════════════════════════
		if check_line_of_sight and not _has_clear_line_of_sight(area):
			# Có vật cản (tường) giữa attacker và target
			# → Bỏ qua, không gây damage
			# print("[HITBOX] Attack blocked by wall!")
			return
		
		# ════════════════════════════════════════════════════════════════════
		# GÂY DAMAGE
		# ════════════════════════════════════════════════════════════════════
		# Gọi take_damage trên HurtboxComponent của target
		# Parameters:
		#   - damage: Số damage gây ra
		#   - knockback_force: Lực đẩy lùi
		#   - global_position: Vị trí nguồn damage (dùng để tính hướng knockback)
		area.take_damage(damage, knockback_force, global_position)
		
		# Emit signal để parent biết đã hit thành công
		# Có thể dùng cho: combo counter, sound effects, visual effects...
		hit_landed.emit(area)


## ┌─────────────────────────────────────────────────────────────────────────────┐
## │                     LINE OF SIGHT CHECK FUNCTION                            │
## ├─────────────────────────────────────────────────────────────────────────────┤
## │                                                                             │
## │  Sử dụng Raycast để kiểm tra có vật cản giữa attacker và target không       │
## │                                                                             │
## │  ┌─────────────────────────────────────────────────────────────────────┐    │
## │  │                        RAYCAST DIAGRAM                              │    │
## │  │                                                                     │    │
## │  │    Attacker                                           Target        │    │
## │  │    Position                                          Position       │    │
## │  │       ●═══════════════════════════════════════════════════●         │    │
## │  │       │                                                   │         │    │
## │  │       │              ┌─────────────┐                      │         │    │
## │  │       │              │    WALL     │                      │         │    │
## │  │       │              │  (Layer 1)  │                      │         │    │
## │  │       │              └─────────────┘                      │         │    │
## │  │       │                    ▲                              │         │    │
## │  │       │                    │                              │         │    │
## │  │       │              Raycast HIT!                         │         │    │
## │  │       │              → return false                       │         │    │
## │  │       │              → NO DAMAGE                          │         │    │
## │  │                                                                     │    │
## │  └─────────────────────────────────────────────────────────────────────┘    │
## │                                                                             │
## │  Chỉ check WORLD layer (Layer 1) - tường, bệ đá, obstacles                  │
## │  KHÔNG check các layer khác như ENEMY, PLAYER, NPC...                       │
## │                                                                             │
## └─────────────────────────────────────────────────────────────────────────────┘
##
## @param target: Area2D - HurtboxComponent của target
## @return: bool - true nếu KHÔNG có vật cản (clear line of sight)
##                 false nếu CÓ vật cản (blocked)
func _has_clear_line_of_sight(target: Area2D) -> bool:
	# ════════════════════════════════════════════════════════════════════════
	# STEP 1: Lấy PhysicsDirectSpaceState2D để thực hiện raycast
	# ════════════════════════════════════════════════════════════════════════
	# PhysicsDirectSpaceState2D cho phép query physics space synchronously
	# (không cần đợi physics frame như RayCast2D node)
	var space_state := get_world_2d().direct_space_state
	if not space_state:
		# Fallback: Nếu không thể lấy space state, cho phép damage
		# Điều này hiếm khi xảy ra, chỉ khi node chưa trong scene tree
		return true
	
	# ════════════════════════════════════════════════════════════════════════
	# STEP 2: Xác định vị trí bắt đầu và kết thúc của raycast
	# ════════════════════════════════════════════════════════════════════════
	# 
	#   attacker_pos                              target_pos
	#        ●────────────────────────────────────────●
	#        │                                        │
	#   Vị trí của             Raycast           Vị trí của
	#   Parent node                              Hurtbox
	#   (Player/Enemy)                           của target
	#
	var attacker_pos: Vector2
	if get_parent():
		# Lấy vị trí của parent (Player hoặc Enemy body)
		# KHÔNG dùng hitbox.global_position vì hitbox có offset
		attacker_pos = get_parent().global_position
	else:
		# Fallback nếu không có parent
		attacker_pos = global_position
	
	# Vị trí của target (hurtbox của enemy/player bị đánh)
	var target_pos := target.global_position
	
	# ════════════════════════════════════════════════════════════════════════
	# STEP 3: Tạo Raycast Query Parameters
	# ════════════════════════════════════════════════════════════════════════
	var query := PhysicsRayQueryParameters2D.create(attacker_pos, target_pos)
	
	# ┌─────────────────────────────────────────────────────────────────────┐
	# │ COLLISION MASK = 1 (WORLD layer only)                              │
	# │                                                                     │
	# │ Chỉ detect collision với:                                          │
	# │   - Tường (walls)                                                  │
	# │   - Bệ đá (stone platforms)                                        │
	# │   - Obstacles                                                      │
	# │   - Terrain colliders                                              │
	# │                                                                     │
	# │ KHÔNG detect:                                                       │
	# │   - Player (Layer 2)                                               │
	# │   - Enemy (Layer 3)                                                │
	# │   - NPC (Layer 4)                                                  │
	# │   - Các Area2D khác                                                │
	# └─────────────────────────────────────────────────────────────────────┘
	query.collision_mask = 1  # Bit 1 = WORLD layer
	
	# ════════════════════════════════════════════════════════════════════════
	# STEP 4: Exclude các object không muốn raycast hit
	# ════════════════════════════════════════════════════════════════════════
	# 
	# Cần exclude:
	#   1. Parent của hitbox (attacker) - vì raycast bắt đầu từ vị trí này
	#   2. Hitbox chính nó
	#   3. Parent của target (target body) - vì đây là đích đến
	#
	# Nếu không exclude, raycast có thể hit chính attacker hoặc target
	#
	var exclude_rids: Array[RID] = []
	
	# Exclude attacker body
	if get_parent() is CollisionObject2D:
		exclude_rids.append(get_parent().get_rid())
	
	# Exclude hitbox (self)
	exclude_rids.append(get_rid())
	
	# Exclude target body
	if target.get_parent() is CollisionObject2D:
		exclude_rids.append(target.get_parent().get_rid())
	
	query.exclude = exclude_rids
	
	# ════════════════════════════════════════════════════════════════════════
	# STEP 5: Thực hiện Raycast và kiểm tra kết quả
	# ════════════════════════════════════════════════════════════════════════
	var result := space_state.intersect_ray(query)
	
	# ┌─────────────────────────────────────────────────────────────────────┐
	# │ RESULT INTERPRETATION                                               │
	# │                                                                     │
	# │ result.is_empty() == true:                                         │
	# │   → Raycast KHÔNG hit bất kỳ WORLD collider nào                    │
	# │   → Đường đi clear, có thể gây damage                              │
	# │   → return TRUE                                                    │
	# │                                                                     │
	# │ result.is_empty() == false:                                        │
	# │   → Raycast HIT một WORLD collider (tường/bệ đá)                   │
	# │   → Có vật cản, KHÔNG gây damage                                   │
	# │   → return FALSE                                                   │
	# │                                                                     │
	# │ Result dictionary keys (khi hit):                                  │
	# │   - position: Vector2 - điểm va chạm                               │
	# │   - normal: Vector2 - normal của surface                           │
	# │   - collider: Object - object bị hit                               │
	# │   - collider_id: int - instance ID                                 │
	# │   - rid: RID - resource ID                                         │
	# │   - shape: int - shape index                                       │
	# └─────────────────────────────────────────────────────────────────────┘
	
	if result.is_empty():
		return true  # ✅ Clear line of sight - cho phép damage
	else:
		# ❌ Blocked by wall - không cho phép damage
		# Uncomment dòng dưới để debug xem bị chặn bởi object nào
		# print("[HITBOX] LOS blocked by: ", result.collider.name if result.collider else "unknown")
		return false


## Call this to enable hitbox (during attack animation)
func activate() -> void:
	# print("[HITBOX] Activated! Layer: ", collision_layer, " Mask: ", collision_mask)
	monitoring = true


## Call this to disable hitbox (after attack ends)
func deactivate() -> void:
	monitoring = false
