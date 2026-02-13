extends CharacterBody2D
## Player character controller với hệ thống state machine.
## Xử lý di chuyển, tấn công, nhận damage và animations.

# =============================================================================
# ENUMS & CONSTANTS
# =============================================================================

## Các trạng thái của nhân vật
enum State { IDLE, MOVE, ATTACK, DEATH }

## Offset vị trí hitbox theo từng hướng di chuyển
const HITBOX_OFFSETS := {
	"up": Vector2(0, -15),
	"down": Vector2(0, 20),
	"left": Vector2(-20, 0),
	"right": Vector2(20, 0),
	"left_up": Vector2(-15, -15),
	"left_down": Vector2(-15, 15),
	"right_up": Vector2(15, -15),
	"right_down": Vector2(15, 15)
}

# =============================================================================
# EXPORTS
# =============================================================================

## Resource chứa các chỉ số của nhân vật (HP, stamina, damage, speed...)
@export var stats: CharacterStats

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

# =============================================================================
# LIFECYCLE METHODS
# =============================================================================

func _ready() -> void:
	# Tạo stats mặc định nếu chưa được assign trong Inspector
	if stats == null:
		stats = CharacterStats.new()
	
	# Kết nối signals từ stats
	stats.died.connect(_on_died)
	
	# Kết nối animation signal
	anim.animation_finished.connect(_on_animation_finished)
	
	# Setup Attack Hitbox - mặc định tắt, chỉ bật khi tấn công
	attack_hitbox.monitoring = false
	attack_hitbox.body_entered.connect(_on_attack_hit)
	
	# Setup Hurtbox - nhận damage từ enemy
	hurtbox.area_entered.connect(_on_hurtbox_area_entered)


func _physics_process(delta: float) -> void:
	# Không xử lý gì nếu đã chết
	if current_state == State.DEATH:
		_state_death()
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

## Bật hitbox khi bắt đầu tấn công
## Di chuyển hitbox đến vị trí theo hướng nhân vật đang nhìn
func _enable_attack_hitbox() -> void:
	var key := _direction_to_key(last_dir)
	
	# Đặt vị trí hitbox theo hướng
	if HITBOX_OFFSETS.has(key):
		attack_hitbox.position = HITBOX_OFFSETS[key]
	
	# Xoay hitbox theo hướng (quan trọng cho đòn chéo)
	var angle := last_dir.angle()
	attack_hitbox.rotation = angle + PI / 2
	
	# Bật collision detection
	attack_hitbox.monitoring = true


## Tắt hitbox sau khi đòn tấn công kết thúc
func _disable_attack_hitbox() -> void:
	attack_hitbox.monitoring = false


## Callback khi hitbox chạm vào target
## @param body: Node bị hitbox chạm vào
func _on_attack_hit(body: Node2D) -> void:
	# Chỉ gây damage nếu target có method take_damage (duck typing)
	if body.has_method("take_damage"):
		body.take_damage(stats.attack_damage)


# =============================================================================
# HURTBOX (DEFENSE) - Vùng nhận damage
# =============================================================================

## Callback khi có Area2D (enemy hitbox) chạm vào hurtbox
## @param area: Area2D của enemy (thường là hitbox của enemy)
func _on_hurtbox_area_entered(area: Area2D) -> void:
	# Bỏ qua nếu đang bất tử hoặc đã chết
	if invincibility_timer > 0 or current_state == State.DEATH:
		return
	
	# Lấy damage từ enemy (nếu có)
	var damage := _get_damage_from_area(area)
	if damage > 0:
		_apply_damage(damage)


## Trích xuất damage từ Area2D của enemy
## @param area: Area2D chạm vào hurtbox
## @return: Số damage, 0 nếu không xác định được
func _get_damage_from_area(area: Area2D) -> int:
	var parent := area.get_parent()
	
	# Cách 1: Parent có property attack_damage
	if parent and "attack_damage" in parent:
		return parent.attack_damage
	
	# Cách 2: Parent có stats resource với attack_damage
	if parent and "stats" in parent and parent.stats:
		return parent.stats.attack_damage
	
	# Cách 3: Area có metadata damage
	if area.has_meta("damage"):
		return area.get_meta("damage")
	
	return 0


## Áp dụng damage lên nhân vật và kích hoạt iframe
## @param damage: Số damage nhận vào
func _apply_damage(damage: int) -> void:
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
