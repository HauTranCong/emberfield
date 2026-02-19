extends CharacterBody2D
## Player character controller với hệ thống state machine.
## Xử lý di chuyển, tấn công, nhận damage và animations.
##
## ╔══════════════════════════════════════════════════════════════════════════════╗
## ║                           STATE MACHINE DIAGRAM                              ║
## ╠══════════════════════════════════════════════════════════════════════════════╣
## ║                                                                              ║
## ║                         ┌─────────────────────────┐                          ║
## ║                         │        [DEATH]          │                          ║
## ║                         │   • HP = 0 → Game Over  │                          ║
## ║                         │   • Disable all input   │                          ║
## ║                         └─────────────────────────┘                          ║
## ║                                    ▲                                         ║
## ║                                    │ HP <= 0 (từ bất kỳ state)               ║
## ║    ┌───────────────────────────────┴───────────────────────────────┐         ║
## ║    │                                                               │         ║
## ║    │  ┌─────────────┐                      ┌─────────────┐         │         ║
## ║    │  │    IDLE     │ ◄──── no input ───── │    MOVE     │         │         ║
## ║    │  │             │ ───── has input ───► │             │         │         ║
## ║    │  │  • v = 0    │                      │  • v = dir  │         │         ║
## ║    │  │  • waiting  │                      │    * speed  │         │         ║
## ║    │  └──────┬──────┘                      └──────┬──────┘         │         ║
## ║    │         │                                    │                │         ║
## ║    │         │ attack_pressed                     │ attack_pressed │         ║
## ║    │         │                                    │                │         ║
## ║    │         ▼                                    ▼                │         ║
## ║    │  ┌─────────────────────────────────────────────────────────┐  │         ║
## ║    │  │                      ATTACK                             │  │         ║
## ║    │  │   • v = 0 (đứng yên khi đánh)                           │  │         ║
## ║    │  │   • Bật hitbox theo hướng last_dir                      │  │         ║
## ║    │  │   • Animation xong → tắt hitbox → về IDLE               │  │         ║
## ║    │  └─────────────────────────────────────────────────────────┘  │         ║
## ║    │                                                               │         ║
## ║    └───────────────────────────────────────────────────────────────┘         ║
## ║                                                                              ║
## ╠══════════════════════════════════════════════════════════════════════════════╣
## ║                         COMPONENT INTERACTION                                ║
## ╠══════════════════════════════════════════════════════════════════════════════╣
## ║                                                                              ║
## ║  [Player Body]           [Hitbox]                [Hurtbox]                   ║
## ║  Layer 2: PLAYER         Layer 7: PLAYER_HITBOX   Layer 5: PLAYER_HURTBOX    ║
## ║  Mask: WORLD|NPC|        Mask: ENEMY_HURTBOX      Mask: ENEMY_HITBOX         ║
## ║        INTERACTABLE|           │                        │                    ║
## ║        PICKUP                  │                        │                    ║
## ║       │                        ▼                        ▼                    ║
## ║       │                  Gây damage cho          Nhận damage từ              ║
## ║       ▼                  Enemy khi attack       Enemy attack                 ║
## ║  Va chạm tường,                │                        │                    ║
## ║  NPC, shop, pickup             ▼                        ▼                    ║
## ║                        [Enemy Hurtbox]         [Enemy Hitbox]                ║
## ║                        → damage_received       → _on_hurtbox_damage_received ║
## ║                        → health -= X           → health -= 15                ║
## ║                                                → iframe 0.5s                 ║
## ║                                                                              ║
## ╚══════════════════════════════════════════════════════════════════════════════╝

# =============================================================================
# ENUMS & CONSTANTS
# =============================================================================

## Các trạng thái của nhân vật:
## - IDLE: Đứng yên, chờ input. Nếu có move input → MOVE, attack → ATTACK
## - MOVE: Di chuyển theo input với stats.move_speed. Attack có thể cancel
## - ATTACK: Đứng yên, chờ animation xong. Bật hitbox gây damage
## - DEATH: Chết, không xử lý input, chờ respawn
enum State { IDLE, MOVE, ATTACK, DEATH }

# =============================================================================
# DEBUG VISUALIZATION
# =============================================================================
## Bật/tắt debug visualization trong Inspector
@export var debug_draw_enabled: bool = false

## Màu sắc tương ứng với từng state để dễ nhận biết
const STATE_COLORS := {
	State.IDLE: Color.CYAN,       # Xanh dương - đang chờ
	State.MOVE: Color.GREEN,      # Xanh lá - đang di chuyển
	State.ATTACK: Color.RED,      # Đỏ - đang tấn công
	State.DEATH: Color.BLACK      # Đen - đã chết
}

const STATE_NAMES := {
	State.IDLE: "IDLE",
	State.MOVE: "MOVE",
	State.ATTACK: "ATTACK",
	State.DEATH: "DEATH"
}

## ┌─────────────────────────────────────────────────────────────────┐
## │              HITBOX OFFSET DIAGRAM (8 hướng)                    │
## │                                                                 │
## │                  left_up      up      right_up                  │
## │                   (-15,-15) (0,-15)   (15,-15)                  │
## │                        \      │      /                          │
## │                         \     │     /                           │
## │                          \    │    /                            │
## │             left ─────────[PLAYER]───────── right               │
## │           (-20,0)         /    │    \         (20,0)            │
## │                          /     │     \                          │
## │                         /      │      \                         │
## │                  left_down   down   right_down                  │
## │                   (-15,15)  (0,20)   (15,15)                    │
## │                                                                 │
## │  Hitbox sẽ được đặt ở vị trí offset tương ứng với hướng        │
## │  mà player đang quay mặt khi thực hiện attack                   │
## └─────────────────────────────────────────────────────────────────┘
const HITBOX_OFFSETS := {
	"up": Vector2(0, -15),         # Tấn công lên trên
	"down": Vector2(0, 20),        # Tấn công xuống dưới
	"left": Vector2(-20, 0),       # Tấn công sang trái
	"right": Vector2(20, 0),       # Tấn công sang phải
	"left_up": Vector2(-15, -15),  # Tấn công chéo trái-trên
	"left_down": Vector2(-15, 15), # Tấn công chéo trái-dưới
	"right_up": Vector2(15, -15),  # Tấn công chéo phải-trên
	"right_down": Vector2(15, 15)  # Tấn công chéo phải-dưới
}

# =============================================================================
# EXPORTS
# =============================================================================

## Resource chứa các chỉ số của nhân vật (HP, stamina, damage, speed...)
@export var stats: CharacterStats

# =============================================================================
# INVENTORY
# =============================================================================

## Player's inventory data
var inventory: InventoryData
## Inventory panel UI reference
var inventory_panel: Node = null

# =============================================================================
# NODE REFERENCES
# =============================================================================

## AnimatedSprite2D để hiển thị animations
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
## Hitbox - vùng gây damage khi tấn công
@onready var attack_hitbox: Area2D = $Hitbox
## Hurtbox - vùng nhận damage từ enemy
@onready var hurtbox: Area2D = $Hurtbox

# =============================================================================
# STATE VARIABLES
# =============================================================================

## Hướng di chuyển cuối cùng (dùng cho animation và hitbox)
var last_dir: Vector2 = Vector2.DOWN
## Trạng thái hiện tại của nhân vật
var current_state: State = State.IDLE
## Thời gian bất tử sau khi nhận damage (iframe)
var invincibility_timer: float = 0.0
## Thời gian bất tử tối đa (giây)
var invincibility_duration: float = 0.5
## Theo dõi trạng thái hitbox cho visualization
var hitbox_active: bool = false

# =============================================================================
# LIFECYCLE METHODS
# =============================================================================

func _ready() -> void:
	# Player collision: Layer PLAYER, Mask: WORLD | NPC | INTERACTABLE | PICKUP
	# Note: Không mask ENEMY - damage xử lý qua Hitbox/Hurtbox, không qua body collision
	collision_layer = CollisionLayers.Layer.PLAYER
	collision_mask = (
		CollisionLayers.Layer.WORLD |
		CollisionLayers.Layer.NPC |
		CollisionLayers.Layer.INTERACTABLE |
		CollisionLayers.Layer.PICKUP
	)
	
	# Tạo stats mặc định nếu chưa có
	if stats == null:
		stats = CharacterStats.new()
	
	# Initialize inventory system
	_setup_inventory()
	
	# Kết nối signals từ stats
	stats.died.connect(_on_died)
	
	# Kết nối animation signal
	anim.animation_finished.connect(_on_animation_finished)
	
	# Setup Attack Hitbox - dùng HitboxComponent
	attack_hitbox.collision_layer = CollisionLayers.Layer.PLAYER_HITBOX
	attack_hitbox.collision_mask = CollisionLayers.Layer.ENEMY_HURTBOX
	attack_hitbox.damage = stats.attack_damage if stats else 10
	attack_hitbox.monitoring = false
	# print("[PLAYER] Hitbox - Layer: ", attack_hitbox.collision_layer, " Mask: ", attack_hitbox.collision_mask)
	
	# Setup Hurtbox - dùng HurtboxComponent, kết nối signal damage_received
	hurtbox.collision_layer = CollisionLayers.Layer.PLAYER_HURTBOX
	hurtbox.collision_mask = CollisionLayers.Layer.ENEMY_HITBOX
	hurtbox.damage_received.connect(_on_hurtbox_damage_received)
	# print("[PLAYER] Hurtbox - Layer: ", hurtbox.collision_layer, " Mask: ", hurtbox.collision_mask)


func _physics_process(delta: float) -> void:
	# Không xử lý gì nếu đã chết
	if current_state == State.DEATH:
		_state_death()
		return
	
	# Check inventory toggle input
	if Input.is_action_just_pressed("open_inventory"):
		_toggle_inventory()
		return
	
	# Skip other processing if inventory is open
	if inventory_panel != null and inventory_panel.visible:
		return
	
	# Hồi stamina theo thời gian
	stats.regen_stamina(delta)
	
	# Cập nhật thời gian bất tử (iframe sau khi nhận damage)
	if invincibility_timer > 0:
		invincibility_timer -= delta
		# Hiệu ứng nhấp nháy khi đang bất tử
		anim.modulate.a = 0.5 if fmod(invincibility_timer * 10, 1.0) > 0.5 else 1.0
	else:
		anim.modulate.a = 1.0
	
	# State machine - xử lý logic theo trạng thái hiện tại
	match current_state:
		State.IDLE:
			_state_idle()
		State.MOVE:
			_state_move()
		State.ATTACK:
			_state_attack()
	
	# Request redraw cho debug visualization
	if debug_draw_enabled:
		queue_redraw()


# =============================================================================
# STATE MACHINE FUNCTIONS
# =============================================================================

## Xử lý trạng thái IDLE - đứng yên, chờ input
func _state_idle() -> void:
	velocity = Vector2.ZERO
	move_and_slide()
	
	# Ưu tiên 1: Kiểm tra input tấn công
	if Input.is_action_just_pressed("character_attack"):
		_change_state(State.ATTACK)
		return
	
	# Ưu tiên 2: Kiểm tra input di chuyển
	var move_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if move_dir != Vector2.ZERO:
		last_dir = move_dir
		_change_state(State.MOVE)
		return
	
	# Không có input -> phát animation idle
	_play_idle_animation()



## Xử lý trạng thái MOVE - di chuyển theo input
func _state_move() -> void:
	var move_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# Ưu tiên 1: Kiểm tra input tấn công (cancel movement)
	if Input.is_action_just_pressed("character_attack"):
		velocity = Vector2.ZERO
		move_and_slide()
		_change_state(State.ATTACK)
		return
	
	# Kiểm tra nếu không còn input di chuyển -> về IDLE
	if move_dir == Vector2.ZERO:
		velocity = Vector2.ZERO
		move_and_slide()
		_change_state(State.IDLE)
		return
	
	# Thực hiện di chuyển
	last_dir = move_dir
	velocity = move_dir * stats.move_speed
	move_and_slide()
	_play_move_animation()


## Xử lý trạng thái ATTACK - thực hiện đòn tấn công
## Nhân vật đứng yên, đợi animation kết thúc rồi về IDLE
func _state_attack() -> void:
	# Khóa di chuyển trong khi tấn công
	velocity = Vector2.ZERO
	move_and_slide()
	# Animation đang chạy, khi xong sẽ gọi _on_animation_finished


## Xử lý trạng thái DEATH - nhân vật đã chết
func _state_death() -> void:
	velocity = Vector2.ZERO
	# Không xử lý input, chờ animation death kết thúc hoặc respawn


# =============================================================================
# STATE TRANSITION
# =============================================================================

## Chuyển sang trạng thái mới và phát animation tương ứng
func _change_state(new_state: State) -> void:
	current_state = new_state
	match new_state:
		State.IDLE:
			_play_idle_animation()
		State.MOVE:
			_play_move_animation()
		State.ATTACK:
			_play_attack_animation()
		State.DEATH:
			_play_death_animation()


## Callback khi animation kết thúc
func _on_animation_finished() -> void:
	match current_state:
		State.ATTACK:
			# Tắt hitbox và quay về trạng thái IDLE
			_disable_attack_hitbox()
			_change_state(State.IDLE)
		State.DEATH:
			# Death animation xong - có thể emit signal để xử lý game over
			pass


# =============================================================================
# HITBOX (ATTACK) - Vùng gây damage
# =============================================================================

## ┌─────────────────────────────────────────────────────────────────────────────┐
## │ ENABLE ATTACK HITBOX                                                        │
## │ ─────────────────────────────────────────────────────────────────────────── │
## │ Được gọi khi bắt đầu attack animation                                       │
## │                                                                             │
## │ Flow:                                                                       │
## │ 1. Lấy direction key từ last_dir (8 hướng)                                 │
## │ 2. Đặt position từ HITBOX_OFFSETS dictionary                               │
## │ 3. Xoay hitbox theo góc của last_dir                                       │
## │ 4. Gọi hitbox.activate() để bắt đầu detect collision                       │
## └─────────────────────────────────────────────────────────────────────────────┘
func _enable_attack_hitbox() -> void:
	var key := _direction_to_key(last_dir)
	
	# Step 1: Đặt vị trí hitbox theo hướng tấn công
	if HITBOX_OFFSETS.has(key):
		attack_hitbox.position = HITBOX_OFFSETS[key]
	
	# Step 2: Xoay hitbox theo hướng (để shape đúng hướng)
	var angle := last_dir.angle()  # Góc trong radians
	attack_hitbox.rotation = angle + PI / 2  # +90 độ để align đúng
	
	# Step 3: Kích hoạt hitbox - bắt đầu detect collision với EnemyHurtbox
	attack_hitbox.activate()
	hitbox_active = true  # Track cho debug visualization


## ┌─────────────────────────────────────────────────────────────────────────────┐
## │ DISABLE ATTACK HITBOX                                                       │
## │ ─────────────────────────────────────────────────────────────────────────── │
## │ Được gọi khi animation attack kết thúc                                      │
## │ Tắt monitoring để không gây damage nữa                                      │
## └─────────────────────────────────────────────────────────────────────────────┘
func _disable_attack_hitbox() -> void:
	attack_hitbox.deactivate()
	hitbox_active = false  # Track cho debug visualization


# =============================================================================
# HURTBOX (DEFENSE) - Vùng nhận damage
# =============================================================================

## Callback khi HurtboxComponent nhận damage từ HitboxComponent
## @param amount: Số damage nhận vào
## @param knockback: Lực đẩy lùi  
## @param from_position: Vị trí nguồn damage
func _on_hurtbox_damage_received(amount: int, knockback: float, from_position: Vector2) -> void:
	# print("[PLAYER] _on_hurtbox_damage_received! Amount: ", amount)
	# Bỏ qua nếu đang bất tử hoặc đã chết
	if invincibility_timer > 0 or current_state == State.DEATH:
		# print("[PLAYER] Blocked by invincibility or death state")
		return
	
	_apply_damage(amount)


## Áp dụng damage lên nhân vật và kích hoạt iframe
## @param damage: Số damage nhận vào
func _apply_damage(damage: int) -> void:
	# print("[PLAYER] _apply_damage: ", damage)
	# Gọi take_damage trong stats (sẽ emit signal health_changed)
	stats.take_damage(damage)
	
	# Bật thời gian bất tử (iframe) để tránh bị hit liên tục
	invincibility_timer = invincibility_duration


# =============================================================================
# ANIMATION FUNCTIONS
# =============================================================================

## Phát animation idle theo hướng hiện tại
func _play_idle_animation() -> void:
	var key := _direction_to_key(last_dir)
	var anim_name := "idle_" + key
	
	if not anim.sprite_frames.has_animation(anim_name):
		return
	
	anim.speed_scale = 2.0
	if anim.animation != anim_name:
		anim.play(anim_name)


## Phát animation di chuyển theo hướng hiện tại
func _play_move_animation() -> void:
	var key := _direction_to_key(last_dir)
	var anim_name := "move_" + key

	# Workaround: Hỗ trợ typo trong SpriteFrames (move_rigt_down)
	if anim_name == "move_right_down" and not anim.sprite_frames.has_animation(anim_name):
		if anim.sprite_frames.has_animation("move_rigt_down"):
			anim_name = "move_rigt_down"

	if not anim.sprite_frames.has_animation(anim_name):
		return

	anim.speed_scale = 2.0
	if anim.animation != anim_name:
		anim.play(anim_name)


## Phát animation tấn công và bật hitbox
func _play_attack_animation() -> void:
	var key := _direction_to_attack_key(last_dir)
	var anim_name := "attack_" + key

	# Workaround: Hỗ trợ typo trong SpriteFrames (attach_up thay vì attack_up)
	if anim_name == "attack_up" and not anim.sprite_frames.has_animation(anim_name):
		if anim.sprite_frames.has_animation("attach_up"):
			anim_name = "attach_up"

	# Nếu không có animation -> quay về IDLE
	if not anim.sprite_frames.has_animation(anim_name):
		_change_state(State.IDLE)
		return

	# Bật hitbox để gây damage
	_enable_attack_hitbox()
	
	# Tắt loop để animation_finished signal được emit khi xong
	anim.sprite_frames.set_animation_loop(anim_name, false)
	anim.speed_scale = 4.0
	anim.play(anim_name)


## Phát animation chết
func _play_death_animation() -> void:
	var key := _direction_to_attack_key(last_dir)
	var anim_name := "death_" + key
	
	# Fallback: Nếu không có animation theo hướng, dùng animation "death" chung
	if not anim.sprite_frames.has_animation(anim_name):
		if anim.sprite_frames.has_animation("death"):
			anim_name = "death"
		else:
			return
	
	anim.speed_scale = 1.0
	anim.play(anim_name)


# =============================================================================
# DIRECTION HELPERS
# =============================================================================

## Chuyển đổi vector hướng thành key string (hỗ trợ 8 hướng)
## @param d: Vector2 hướng di chuyển
## @return: String key (up, down, left, right, left_up, left_down, right_up, right_down)
func _direction_to_key(d: Vector2) -> String:
	var ax := absf(d.x)
	var ay := absf(d.y)

	# Kiểm tra nếu là hướng chéo (cả x và y đều có giá trị đáng kể)
	var diagonal := ax > 0.01 and ay > 0.01

	if diagonal:
		if d.x < 0 and d.y < 0:
			return "left_up"
		elif d.x < 0 and d.y > 0:
			return "left_down"
		elif d.x > 0 and d.y < 0:
			return "right_up"
		else:
			return "right_down"

	# Hướng chính (4 hướng) - ưu tiên trục có giá trị lớn hơn
	if ay >= ax:
		return "up" if d.y < 0 else "down"
	else:
		return "left" if d.x < 0 else "right"


## Chuyển đổi vector hướng thành key string cho attack (chỉ 4 hướng)
## Attack animation thường chỉ có 4 hướng chính
## @param d: Vector2 hướng
## @return: String key (up, down, left, right)
func _direction_to_attack_key(d: Vector2) -> String:
	var ax := absf(d.x)
	var ay := absf(d.y)

	# Ưu tiên trục có giá trị lớn hơn
	if ay >= ax:
		return "up" if d.y < 0 else "down"
	return "left" if d.x < 0 else "right"


## Callback khi stats emit signal died
func _on_died() -> void:
	die()


# =============================================================================
# PUBLIC FUNCTIONS - API cho các script khác gọi vào
# =============================================================================

## Giết nhân vật - chuyển sang trạng thái DEATH
## Được gọi từ bên ngoài hoặc khi HP về 0
func die() -> void:
	if current_state != State.DEATH:
		_change_state(State.DEATH)


## Kiểm tra nhân vật đã chết chưa
## @return: true nếu đang ở trạng thái DEATH
func is_dead() -> bool:
	return current_state == State.DEATH


## Nhận damage từ bên ngoài (enemy gọi vào)
## Có hỗ trợ iframe - không nhận damage liên tục
## @param amount: Số damage nhận vào
func take_damage(amount: int) -> void:
	# Bỏ qua nếu đã chết hoặc đang bất tử
	if current_state == State.DEATH:
		return
	if invincibility_timer > 0:
		return
	
	# Áp dụng damage thông qua hệ thống internal
	_apply_damage(amount)


## Hồi máu cho nhân vật
## @param amount: Số HP hồi
func heal(amount: int) -> void:
	if current_state != State.DEATH:
		stats.heal(amount)


## Reset nhân vật về trạng thái ban đầu (dùng cho respawn)
func reset_player() -> void:
	stats.reset()
	invincibility_timer = 0.0
	anim.modulate.a = 1.0
	_change_state(State.IDLE)


# =============================================================================
# INVENTORY FUNCTIONS
# =============================================================================

## Initialize inventory system
func _setup_inventory() -> void:
	# Create inventory data
	inventory = InventoryData.new()
	inventory.gold = 500  # Starting gold
	
	# Connect equipment change signal to update stats
	inventory.equipment_changed.connect(_on_equipment_changed)
	
	# Load inventory panel scene
	var inventory_scene := preload("res://sense/ui/inventory/inventory_panel.tscn")
	inventory_panel = inventory_scene.instantiate()
	add_child(inventory_panel)
	inventory_panel.setup(inventory)
	
	# Connect item use signal from inventory panel
	if inventory_panel.has_signal("item_used"):
		inventory_panel.item_used.connect(_on_item_used)
	
	# Add some starter items for testing
	_add_starter_items()


## Add starter items for testing
func _add_starter_items() -> void:
	# Get items from ItemDatabase (which has atlas icons configured)
	var health_potion := ItemDatabase.get_item("health_potion")
	if health_potion:
		inventory.add_item(health_potion, 5)
	
	var iron_sword := ItemDatabase.get_item("iron_sword")
	if iron_sword:
		inventory.add_item(iron_sword, 1)
	
	var leather_armor := ItemDatabase.get_item("leather_armor")
	if leather_armor:
		inventory.add_item(leather_armor, 1)
	
	var iron_ore := ItemDatabase.get_item("iron_ore")
	if iron_ore:
		inventory.add_item(iron_ore, 23)


## Toggle inventory panel visibility
func _toggle_inventory() -> void:
	if inventory_panel != null:
		inventory_panel.toggle_inventory()


## Get player's inventory data (for external access)
func get_inventory() -> InventoryData:
	return inventory


## Add item to player inventory
func add_to_inventory(item: ItemData, quantity: int = 1) -> int:
	if inventory != null:
		return inventory.add_item(item, quantity)
	return quantity


## Add gold to player
func add_gold(amount: int) -> void:
	if inventory != null:
		inventory.gold += amount


## Called when equipment changes - update player stats
func _on_equipment_changed(_slot_type: String) -> void:
	if stats != null and inventory != null:
		stats.apply_equipment_bonuses(inventory)
		# Update hitbox damage with new attack stat
		if attack_hitbox != null:
			attack_hitbox.damage = stats.attack_damage


## Called when player uses an item from inventory
func _on_item_used(result: Dictionary) -> void:
	if result.success and stats != null:
		# Apply heal
		if result.heal_amount > 0:
			stats.heal(result.heal_amount)
			print("[PLAYER] Used item: healed ", result.heal_amount, " HP")
		
		# Apply stamina restore
		if result.stamina_restore > 0:
			stats.restore_stamina(result.stamina_restore)
			print("[PLAYER] Used item: restored ", result.stamina_restore, " stamina")


## Heal player from pickup
func heal_from_pickup(amount: int) -> void:
	if stats != null:
		stats.heal(amount)


## Restore stamina from pickup
func restore_stamina_from_pickup(amount: float) -> void:
	if stats != null:
		stats.restore_stamina(amount)


## Add XP from pickup
func add_xp(amount: int) -> void:
	# TODO: Implement XP/leveling system
	print("[PLAYER] Gained ", amount, " XP")


# =============================================================================
# DEBUG VISUALIZATION
# =============================================================================
## ┌────────────────────────────────────────────────────────────────────────────┐
## │                      DEBUG DRAW VISUALIZATION                              │
## │                                                                            │
## │  Hiển thị khi debug_draw_enabled = true:                                  │
## │  • Vòng tròn state color: Màu theo state hiện tại                        │
## │  • Đường chỉ hướng: last_dir (hướng nhìn/di chuyển)                       │
## │  • Vị trí Hitbox: Hình vuông vàng khi đang attack                        │
## │  • Iframe indicator: Vòng tròn xanh khi đang bất tử                       │
## │  • Velocity vector: Đường xanh lá hiển thị hướng di chuyển               │
## └────────────────────────────────────────────────────────────────────────────┘

func _draw() -> void:
	if not debug_draw_enabled:
		return
	
	var state_color: Color = STATE_COLORS.get(current_state, Color.WHITE)
	
	# Vẽ vòng tròn trạng thái ở trung tâm
	draw_arc(Vector2.ZERO, 12, 0, TAU, 32, state_color, 2.0)
	
	# Vẽ hướng nhìn (last_dir)
	var direction_line := last_dir * 30
	draw_line(Vector2.ZERO, direction_line, state_color, 3.0)
	draw_circle(direction_line, 4, state_color)
	
	# Vẽ velocity vector (hướng di chuyển thực tế)
	if velocity.length() > 1:
		var vel_normalized := velocity.normalized() * 25
		draw_line(Vector2.ZERO, vel_normalized, Color.LIME, 2.0)
		# Mũi tên nhỏ ở cuối
		var arrow_size := 6.0
		var arrow_angle := velocity.angle()
		var arrow_p1 := vel_normalized + Vector2.from_angle(arrow_angle + PI * 0.8) * arrow_size
		var arrow_p2 := vel_normalized + Vector2.from_angle(arrow_angle - PI * 0.8) * arrow_size
		draw_line(vel_normalized, arrow_p1, Color.LIME, 2.0)
		draw_line(vel_normalized, arrow_p2, Color.LIME, 2.0)
	
	# Vẽ hitbox position khi attack
	if hitbox_active and attack_hitbox:
		var hitbox_pos := attack_hitbox.position
		# Hình vuông vàng với viền
		draw_rect(Rect2(hitbox_pos - Vector2(12, 12), Vector2(24, 24)), Color.YELLOW, false, 2.0)
		# X đỏ ở giữa để đánh dấu điểm tấn công
		draw_line(hitbox_pos + Vector2(-6, -6), hitbox_pos + Vector2(6, 6), Color.RED, 2.0)
		draw_line(hitbox_pos + Vector2(6, -6), hitbox_pos + Vector2(-6, 6), Color.RED, 2.0)
	
	# Vẽ indicator khi đang bất tử (iframe)
	if invincibility_timer > 0:
		# Vòng tròn xanh dương nhấp nháy
		var alpha := 0.5 + 0.5 * sin(invincibility_timer * 20)
		var iframe_color := Color(0.3, 0.5, 1.0, alpha)
		draw_arc(Vector2.ZERO, 18, 0, TAU, 32, iframe_color, 3.0)
		# Hiển thị thời gian còn lại
		var time_text := "%.1fs" % invincibility_timer
		draw_string(ThemeDB.fallback_font, Vector2(-15, -25), time_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 10, iframe_color)
	
	# Vẽ các vị trí hitbox có thể (8 hướng) - mờ
	for key in HITBOX_OFFSETS:
		var offset: Vector2 = HITBOX_OFFSETS[key]
		var dot_color := Color(0.5, 0.5, 0.5, 0.3)  # Xám mờ
		if hitbox_active and attack_hitbox.position == offset:
			dot_color = Color.YELLOW  # Vàng sáng nếu đang active
		draw_circle(offset, 3, dot_color)
