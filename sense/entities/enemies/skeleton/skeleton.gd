extends CharacterBody2D
## Skeleton Enemy - Basic melee enemy with patrol and chase behavior
##
## ╔══════════════════════════════════════════════════════════════════════════════╗
## ║                           STATE MACHINE DIAGRAM                              ║
## ╠══════════════════════════════════════════════════════════════════════════════╣
## ║                                                                              ║
## ║                    ┌─────────────────────────────────────┐                   ║
## ║                    │           [DEATH]                   │                   ║
## ║                    │    • HP = 0 → queue_free()          │                   ║
## ║                    │    • Disable all collisions         │                   ║
## ║                    └─────────────────────────────────────┘                   ║
## ║                                   ▲                                          ║
## ║                                   │ HP <= 0 (từ bất kỳ state nào)            ║
## ║    ┌──────────────────────────────┴──────────────────────────────┐           ║
## ║    │                                                             │           ║
## ║    │  ┌─────────┐    timer >= 2s    ┌──────────┐                 │           ║
## ║    │  │  IDLE   │ ─────────────────►│  PATROL  │                 │           ║
## ║    │  │         │◄───────────────── │          │                 │           ║
## ║    │  │ • v = 0 │    timer >= 2s    │ • random │                 │           ║
## ║    │  │ • wait  │                   │   move   │                 │           ║
## ║    │  └────┬────┘                   └────┬─────┘                 │           ║
## ║    │       │                             │                       │           ║
## ║    │       │ see_player                  │ see_player            │           ║
## ║    │       │ (dist <= 150)               │ (dist <= 150)         │           ║
## ║    │       ▼                             ▼                       │           ║
## ║    │  ┌─────────────────────────────────────┐                    │           ║
## ║    │  │              CHASE                  │                    │           ║
## ║    │  │   • Di chuyển về phía player        │                    │           ║
## ║    │  │   • Speed = 50 (nhanh hơn patrol)   │                    │           ║
## ║    │  │   • Cập nhật hướng liên tục         │                    │           ║
## ║    │  └──────────────┬──────────────────────┘                    │           ║
## ║    │                 │                                           │           ║
## ║    │                 │ dist <= 30 (ATTACK_RANGE)                 │           ║
## ║    │                 ▼                                           │           ║
## ║    │  ┌─────────────────────────────────────┐                    │           ║
## ║    │  │              ATTACK                 │                    │           ║
## ║    │  │   • Dừng di chuyển (v = 0)          │                    │           ║
## ║    │  │   • Play attack animation           │                    │           ║
## ║    │  │   • Delay 0.8s → Enable hitbox      │                    │           ║
## ║    │  │   • Animation done → back to CHASE  │                    │           ║
## ║    │  └─────────────────────────────────────┘                    │           ║
## ║    │                                                             │           ║
## ║    └─────────────────────────────────────────────────────────────┘           ║
## ║                                                                              ║
## ╠══════════════════════════════════════════════════════════════════════════════╣
## ║                         COMPONENT INTERACTION                                ║
## ╠══════════════════════════════════════════════════════════════════════════════╣
## ║                                                                              ║
## ║  [Skeleton Body]         [Hitbox]              [Hurtbox]                     ║
## ║  Layer 3: ENEMY          Layer 8: ENEMY_HITBOX  Layer 6: ENEMY_HURTBOX       ║
## ║  Mask: WORLD             Mask: PLAYER_HURTBOX   Mask: PLAYER_HITBOX          ║
## ║       │                        │                      │                      ║
## ║       │                        │                      │                      ║
## ║       ▼                        ▼                      ▼                      ║
## ║  Va chạm tường           Gây damage cho        Nhận damage từ                ║
## ║  và terrain              Player khi attack    Player attack                  ║
## ║                                │                      │                      ║
## ║                                ▼                      ▼                      ║
## ║                     [Player Hurtbox]        [Player Hitbox]                  ║
## ║                     → damage_received       → damage Skeleton                ║
## ║                     → health -= 15          → health -= X                    ║
## ║                     → knockback             → flash red                      ║
## ║                                                                              ║
## ╚══════════════════════════════════════════════════════════════════════════════╝

# =============================================================================
# ENUMS & CONSTANTS
# =============================================================================

## State Machine States:
## - IDLE: Đứng yên, đợi 2 giây rồi chuyển sang PATROL. Nếu thấy player → CHASE
## - PATROL: Di chuyển ngẫu nhiên với tốc độ chậm (30). Nếu thấy player → CHASE
## - CHASE: Đuổi theo player với tốc độ nhanh (50). Nếu đủ gần → ATTACK
## - ATTACK: Dừng lại, chơi animation tấn công, kích hoạt hitbox sau delay
## - DEATH: Chết, vô hiệu hóa collision, xóa sau 1 giây
enum State { IDLE, PATROL, CHASE, ATTACK, DEATH }

const SPEED := 30.0           ## Tốc độ di chuyển khi PATROL (pixels/second)
const CHASE_SPEED := 50.0     ## Tốc độ đuổi theo player khi CHASE (nhanh hơn 67%)
const DETECTION_RANGE := 150.0 ## Bán kính phát hiện player (pixels) - vòng tròn xanh
const ATTACK_RANGE := 30.0    ## Khoảng cách để bắt đầu tấn công (pixels) - vòng tròn đỏ
const PATROL_WAIT_TIME := 2.0 ## Thời gian đợi giữa các state IDLE/PATROL (seconds)
const HITBOX_DELAY := 0.8     ## Delay trước khi hitbox active (sync với animation)

# =============================================================================
# DEBUG VISUALIZATION
# =============================================================================
## Bật/tắt debug visualization trong Inspector
@export var debug_draw_enabled: bool = false

## Màu sắc tương ứng với từng state để dễ nhận biết
const STATE_COLORS := {
	State.IDLE: Color.GRAY,       # Xám - không làm gì
	State.PATROL: Color.YELLOW,   # Vàng - đang tuần tra
	State.CHASE: Color.ORANGE,    # Cam - đang đuổi
	State.ATTACK: Color.RED,      # Đỏ - đang tấn công
	State.DEATH: Color.BLACK      # Đen - đã chết
}

const STATE_NAMES := {
	State.IDLE: "IDLE",
	State.PATROL: "PATROL", 
	State.CHASE: "CHASE",
	State.ATTACK: "ATTACK",
	State.DEATH: "DEATH"
}

## ┌─────────────────────────────────────────────────────────────┐
## │              HITBOX OFFSET DIAGRAM (8 hướng)                │
## │                                                             │
## │                    left_up    up    right_up                │
## │                      (-18,-18) (0,-25) (18,-18)             │
## │                           \    │    /                       │
## │                            \   │   /                        │
## │                             \  │  /                         │
## │               left ─────────[ENEMY]───────── right          │
## │             (-25,0)         /  │  \         (25,0)          │
## │                            /   │   \                        │
## │                           /    │    \                       │
## │                    left_down  down  right_down              │
## │                     (-18,18) (0,25) (18,18)                 │
## │                                                             │
## │  Hitbox sẽ được đặt ở vị trí offset tương ứng với hướng     │
## │  mà skeleton đang quay mặt khi thực hiện attack             │
## └─────────────────────────────────────────────────────────────┘
const HITBOX_OFFSETS := {
	"up": Vector2(0, -25),        # Tấn công lên trên
	"down": Vector2(0, 25),       # Tấn công xuống dưới  
	"left": Vector2(-25, 0),      # Tấn công sang trái
	"right": Vector2(25, 0),      # Tấn công sang phải
	"left_up": Vector2(-18, -18), # Tấn công chéo trái-trên
	"left_down": Vector2(-18, 18),# Tấn công chéo trái-dưới
	"right_up": Vector2(18, -18), # Tấn công chéo phải-trên
	"right_down": Vector2(18, 18) # Tấn công chéo phải-dưới
}

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_component: HealthComponent = $HealthComponent
@onready var health_bar: ProgressBar = $HealthBar
@onready var hitbox: HitboxComponent = $Hitbox
@onready var hurtbox: HurtboxComponent = $Hurtbox

# =============================================================================
# LOOT TABLE
# =============================================================================
## Loot table cho skeleton - định nghĩa drops khi chết
@export var loot_table: LootTable = null

# =============================================================================
# STATE VARIABLES
# =============================================================================

var current_state: State = State.IDLE  ## State hiện tại trong state machine
var last_direction: Vector2 = Vector2.DOWN  ## Hướng cuối cùng (dùng cho animation & hitbox)
var player: Node2D = null  ## Reference đến Player node
var patrol_timer: float = 0.0  ## Bộ đếm thời gian cho IDLE/PATROL
var hitbox_active: bool = false  ## Theo dõi trạng thái hitbox cho visualization

# =============================================================================
# LIFECYCLE METHODS
# =============================================================================

func _ready() -> void:
	# print("[SKELETON] _ready called")
	# Layer 3 (Enemy), Mask: World only
	# Note: Không mask PLAYER - damage xử lý qua Hitbox/Hurtbox, không qua body collision
	collision_layer = CollisionLayers.Layer.ENEMY
	collision_mask = CollisionLayers.Layer.WORLD
	# print("[SKELETON] Body - Layer: ", collision_layer, " Mask: ", collision_mask)
	
	# Setup hitbox - Layer 8 (EnemyHitbox), Mask: Layer 5 (PlayerHurtbox)
	if hitbox:
		hitbox.collision_layer = CollisionLayers.Layer.ENEMY_HITBOX
		hitbox.collision_mask = CollisionLayers.Layer.PLAYER_HURTBOX
		hitbox.damage = 15
		hitbox.knockback_force = 80.0
		# print("[SKELETON] Hitbox - Layer: ", hitbox.collision_layer, " Mask: ", hitbox.collision_mask)
	
	# Setup hurtbox - Layer 6 (EnemyHurtbox), Mask: Layer 7 (PlayerHitbox)
	if hurtbox:
		hurtbox.collision_layer = CollisionLayers.Layer.ENEMY_HURTBOX
		hurtbox.collision_mask = CollisionLayers.Layer.PLAYER_HITBOX
		hurtbox.damage_received.connect(_on_damage_received)
		# print("[SKELETON] Hurtbox - Layer: ", hurtbox.collision_layer, " Mask: ", hurtbox.collision_mask)
	
	# Setup health component
	if health_component:
		health_component.health_changed.connect(_on_health_changed)
		health_component.died.connect(_on_died)
		_update_health_bar()
	
	# Connect animation signal for attack loop
	anim.animation_finished.connect(_on_animation_finished)
	
	# Find player reference
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	
	# Start idle animation
	_play_animation("idle")


func _physics_process(delta: float) -> void:
	## ┌──────────────────────────────────────────────────────────┐
	## │ PHYSICS PROCESS - Chạy mỗi physics frame (~60 FPS)      │
	## │                                                          │
	## │ Flow: Check death → Process current state → Move         │
	## └──────────────────────────────────────────────────────────┘
	
	# Nếu đã chết, không xử lý gì nữa
	if current_state == State.DEATH:
		return
	
	# State machine - xử lý logic theo state hiện tại
	# Mỗi state có thể thay đổi velocity và chuyển sang state khác
	match current_state:
		State.IDLE:
			_process_idle(delta)    # Đứng yên, đợi, check player
		State.PATROL:
			_process_patrol(delta)  # Di chuyển ngẫu nhiên
		State.CHASE:
			_process_chase(delta)   # Đuổi theo player
		State.ATTACK:
			pass  # Animation đang chạy, không di chuyển
	
	# Áp dụng velocity và xử lý va chạm với World
	move_and_slide()
	
	# Request redraw cho debug visualization
	if debug_draw_enabled:
		queue_redraw()

# =============================================================================
# STATE PROCESSING
# =============================================================================
## ┌────────────────────────────────────────────────────────────────────────┐
## │                    STATE PROCESSING FUNCTIONS                          │
## │                                                                        │
## │  Mỗi function xử lý logic của 1 state cụ thể:                         │
## │  - Cập nhật velocity (di chuyển)                                       │
## │  - Check điều kiện chuyển state                                        │
## │  - Update animation                                                    │
## └────────────────────────────────────────────────────────────────────────┘

## ┌─────────────────────────────────────────────────────────────────────────┐
## │ IDLE STATE                                                              │
## │ ─────────────────────────────────────────────────────────────────────── │
## │ • velocity = 0 (đứng yên)                                               │
## │ • Đếm thời gian chờ                                                     │
## │ • Transitions:                                                          │
## │   → CHASE: nếu thấy player (distance <= DETECTION_RANGE)               │
## │   → PATROL: nếu đã chờ đủ PATROL_WAIT_TIME (2 giây)                    │
## └─────────────────────────────────────────────────────────────────────────┘
func _process_idle(delta: float) -> void:
	velocity = Vector2.ZERO  # Đứng yên
	patrol_timer += delta     # Đếm thời gian
	
	# Priority 1: Nếu thấy player → đuổi theo ngay
	if _can_see_player():
		_change_state(State.CHASE)
	# Priority 2: Đã chờ đủ lâu → bắt đầu tuần tra
	elif patrol_timer >= PATROL_WAIT_TIME:
		patrol_timer = 0.0
		_change_state(State.PATROL)


## ┌─────────────────────────────────────────────────────────────────────────┐
## │ PATROL STATE                                                            │
## │ ─────────────────────────────────────────────────────────────────────── │
## │ • Di chuyển ngẫu nhiên với SPEED = 30                                   │
## │ • Chọn hướng random khi bắt đầu hoặc khi dừng                          │
## │ • Transitions:                                                          │
## │   → CHASE: nếu thấy player                                             │
## │   → IDLE: nếu đã tuần tra đủ PATROL_WAIT_TIME                          │
## └─────────────────────────────────────────────────────────────────────────┘
func _process_patrol(delta: float) -> void:
	# Priority 1: Nếu thấy player → đuổi theo ngay
	if _can_see_player():
		_change_state(State.CHASE)
		return
	
	# Nếu đang đứng yên → chọn hướng ngẫu nhiên mới
	if velocity.length() < 1.0:
		var random_dir := Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		velocity = random_dir * SPEED
		last_direction = random_dir
		_play_move_animation()
	
	# Đếm thời gian tuần tra
	patrol_timer += delta
	if patrol_timer >= PATROL_WAIT_TIME:
		patrol_timer = 0.0
		_change_state(State.IDLE)  # Nghỉ ngơi


## ┌─────────────────────────────────────────────────────────────────────────┐
## │ CHASE STATE                                                             │
## │ ─────────────────────────────────────────────────────────────────────── │
## │ • Di chuyển về phía player với CHASE_SPEED = 50                        │
## │ • Cập nhật hướng liên tục theo vị trí player                           │
## │ • Transitions:                                                          │
## │   → IDLE: nếu player quá xa (> DETECTION_RANGE * 1.5 = 225)           │
## │   → ATTACK: nếu đủ gần để đánh (distance <= ATTACK_RANGE = 30)        │
## │   → IDLE: nếu player không còn valid                                   │
## └─────────────────────────────────────────────────────────────────────────┘
func _process_chase(_delta: float) -> void:
	# Safety check: player còn tồn tại không
	if not player or not is_instance_valid(player):
		_change_state(State.IDLE)
		return
	
	var distance := global_position.distance_to(player.global_position)
	
	# Check 1: Player chạy quá xa → bỏ cuộc
	if distance > DETECTION_RANGE * 1.5:  # 225 pixels
		_change_state(State.IDLE)
		return
	
	# Check 2: Đủ gần để tấn công → ATTACK
	if distance <= ATTACK_RANGE:  # 30 pixels
		_change_state(State.ATTACK)
		return
	
	# Tiếp tục đuổi: tính hướng và di chuyển
	var direction := (player.global_position - global_position).normalized()
	velocity = direction * CHASE_SPEED
	last_direction = direction  # Lưu hướng cho animation và hitbox
	_play_move_animation()

# =============================================================================
# HELPER METHODS
# =============================================================================

func _can_see_player() -> bool:
	if not player or not is_instance_valid(player):
		return false
	return global_position.distance_to(player.global_position) <= DETECTION_RANGE


func _change_state(new_state: State) -> void:
	current_state = new_state
	
	match new_state:
		State.IDLE:
			velocity = Vector2.ZERO
			_play_animation("idle")
		State.PATROL:
			patrol_timer = 0.0
		State.CHASE:
			pass
		State.ATTACK:
			velocity = Vector2.ZERO
			_perform_attack()
		State.DEATH:
			velocity = Vector2.ZERO
			_play_animation("death")


func _perform_attack() -> void:
	# print("[SKELETON] _perform_attack called!")
	# Cập nhật hướng về phía player trước khi tấn công
	if player and is_instance_valid(player):
		last_direction = (player.global_position - global_position).normalized()
	
	_play_attack_animation()
	
	# Delay hitbox để xuất hiện ở giữa/cuối animation
	await get_tree().create_timer(HITBOX_DELAY).timeout
	
	# Kiểm tra còn trong state ATTACK không (có thể bị interrupt)
	if current_state == State.ATTACK:
		_enable_attack_hitbox()


## ┌─────────────────────────────────────────────────────────────────────────┐
## │ ENABLE ATTACK HITBOX                                                    │
## │ ─────────────────────────────────────────────────────────────────────── │
## │ Được gọi sau HITBOX_DELAY (0.8s) kể từ khi bắt đầu attack              │
## │                                                                         │
## │ Flow:                                                                   │
## │ 1. Lấy direction key từ last_direction (8 hướng)                       │
## │ 2. Đặt position từ HITBOX_OFFSETS dictionary                           │
## │ 3. Xoay hitbox theo góc của last_direction                             │
## │ 4. Gọi hitbox.activate() để bắt đầu detect collision                   │
## └─────────────────────────────────────────────────────────────────────────┘
func _enable_attack_hitbox() -> void:
	if not hitbox:
		return
	
	var key := _get_direction_key()  # "up", "down", "left_up", etc.
	
	# Step 1: Đặt vị trí hitbox theo hướng tấn công
	if HITBOX_OFFSETS.has(key):
		hitbox.position = HITBOX_OFFSETS[key]
	
	# Step 2: Xoay hitbox theo hướng (để shape đúng hướng)
	var angle := last_direction.angle()  # Góc trong radians
	hitbox.rotation = angle + PI / 2     # +90 độ để align đúng
	
	# Step 3: Kích hoạt hitbox - bắt đầu detect collision với PlayerHurtbox
	hitbox.activate()
	hitbox_active = true  # Track cho debug visualization


## ┌─────────────────────────────────────────────────────────────────────────┐
## │ DISABLE ATTACK HITBOX                                                   │
## │ ─────────────────────────────────────────────────────────────────────── │
## │ Được gọi khi animation attack kết thúc                                  │
## │ Tắt monitoring để không gây damage nữa                                  │
## └─────────────────────────────────────────────────────────────────────────┘
func _disable_attack_hitbox() -> void:
	if hitbox:
		hitbox.deactivate()
		hitbox_active = false  # Track cho debug visualization


func _play_animation(anim_name: String) -> void:
	var dir_suffix := _get_direction_suffix()
	var full_name := anim_name + "_" + dir_suffix
	
	if anim.sprite_frames.has_animation(full_name):
		anim.play(full_name)
	elif anim.sprite_frames.has_animation(anim_name):
		anim.play(anim_name)


func _play_move_animation() -> void:
	_play_animation("move")


func _play_attack_animation() -> void:
	_play_animation("attack")


## Lấy key hướng cho hitbox offset (8 hướng)
func _get_direction_key() -> String:
	var x := last_direction.x
	var y := last_direction.y
	
	# Xác định hướng dựa trên góc
	if abs(x) < 0.3:  # Gần như thẳng đứng
		return "up" if y < 0 else "down"
	elif abs(y) < 0.3:  # Gần như ngang
		return "left" if x < 0 else "right"
	else:  # Chéo
		if x < 0:
			return "left_up" if y < 0 else "left_down"
		else:
			return "right_up" if y < 0 else "right_down"


## Lấy suffix hướng cho animation (4 hướng cơ bản)
func _get_direction_suffix() -> String:
	if abs(last_direction.x) > abs(last_direction.y):
		return "right" if last_direction.x > 0 else "left"
	else:
		return "down" if last_direction.y > 0 else "up"


func _update_health_bar() -> void:
	if health_bar and health_component:
		health_bar.max_value = health_component.max_health
		health_bar.value = health_component.current_health

# =============================================================================
# SIGNAL CALLBACKS
# =============================================================================

func _on_damage_received(amount: int, _knockback: float, _from_position: Vector2) -> void:
	# print("[SKELETON] _on_damage_received! Amount: ", amount)
	if health_component:
		# print("[SKELETON] Current HP before: ", health_component.current_health)
		health_component.take_damage(amount)
		# print("[SKELETON] Current HP after: ", health_component.current_health)
		# Flash effect
		anim.modulate = Color.RED
		await get_tree().create_timer(0.1).timeout
		anim.modulate = Color.WHITE


func _on_health_changed(current: int, maximum: int) -> void:
	_update_health_bar()
	# Show health bar when damaged
	if health_bar:
		health_bar.visible = current < maximum


func _on_died() -> void:
	_change_state(State.DEATH)
	# Disable collisions
	collision_layer = 0
	collision_mask = 0
	if hitbox:
		hitbox.monitoring = false
	if hurtbox:
		hurtbox.monitoring = false
	
	# Spawn loot drops
	_spawn_drops()
	
	# Remove after death animation
	await get_tree().create_timer(1.0).timeout
	queue_free()


func _on_animation_finished() -> void:
	## Callback khi animation kết thúc
	## Quan trọng cho ATTACK state: cần cleanup hitbox và chuyển state
	if current_state == State.ATTACK:
		_disable_attack_hitbox()
		# Nếu còn thấy player → tiếp tục đuổi, không thì nghỉ
		_change_state(State.CHASE if _can_see_player() else State.IDLE)


# =============================================================================
# DEBUG VISUALIZATION
# =============================================================================
## ┌────────────────────────────────────────────────────────────────────────┐
## │                      DEBUG DRAW VISUALIZATION                          │
## │                                                                        │
## │  Hiển thị khi debug_draw_enabled = true:                              │
## │  • Vòng tròn XANH LÁ: DETECTION_RANGE (150px) - phạm vi phát hiện    │
## │  • Vòng tròn ĐỎ: ATTACK_RANGE (30px) - phạm vi tấn công              │
## │  • Đường thẳng đến Player (nếu đang CHASE)                            │
## │  • Vị trí Hitbox (hình vuông vàng khi active)                         │
## │  • Text hiển thị state hiện tại                                       │
## └────────────────────────────────────────────────────────────────────────┘

func _draw() -> void:
	if not debug_draw_enabled:
		return
	
	var state_color: Color = STATE_COLORS.get(current_state, Color.WHITE)
	
	# Vẽ DETECTION_RANGE - vòng tròn xanh lá (viền)
	draw_arc(Vector2.ZERO, DETECTION_RANGE, 0, TAU, 64, Color.GREEN, 1.0)
	
	# Vẽ ATTACK_RANGE - vòng tròn đỏ (viền)
	draw_arc(Vector2.ZERO, ATTACK_RANGE, 0, TAU, 32, Color.RED, 2.0)
	
	# Vẽ đường đến player nếu đang CHASE hoặc ATTACK
	if player and is_instance_valid(player) and current_state in [State.CHASE, State.ATTACK]:
		var to_player := player.global_position - global_position
		draw_line(Vector2.ZERO, to_player, Color.ORANGE, 2.0)
	
	# Vẽ hướng di chuyển/nhìn
	var direction_line := last_direction * 40
	draw_line(Vector2.ZERO, direction_line, state_color, 3.0)
	draw_circle(direction_line, 4, state_color)
	
	# Vẽ hitbox position khi attack
	if hitbox_active and hitbox:
		var hitbox_pos := hitbox.position
		draw_rect(Rect2(hitbox_pos - Vector2(10, 10), Vector2(20, 20)), Color.YELLOW, false, 2.0)
		draw_circle(hitbox_pos, 5, Color.YELLOW)


# =============================================================================
# LOOT DROPS
# =============================================================================

## Spawn drops when enemy dies
func _spawn_drops() -> void:
	# Use default loot table if none assigned
	if loot_table == null:
		loot_table = _create_default_loot_table()
	
	# Spawn items from loot table
	ItemSpawner.spawn_enemy_drops(get_tree(), global_position, loot_table)


## Create default loot table for skeleton
func _create_default_loot_table() -> LootTable:
	var table := LootTable.new()
	table.drop_count = 2
	table.nothing_weight = 40
	table.gold_range = Vector2i(5, 15)
	
	# Add possible drops
	table.add_entry("bone", 100, 1, 3)          # Common: bones
	table.add_entry("health_potion", 30, 1, 1)  # Rare: health potion
	table.add_entry("iron_sword", 5, 1, 1)      # Very rare: weapon
	
	return table
