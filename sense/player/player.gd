extends CharacterBody2D

enum State { IDLE, MOVE, ATTACK, DEATH }

@export var stats: CharacterStats
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_hitbox: Area2D = $AttackHitbox

var last_dir: Vector2 = Vector2.DOWN
var current_state: State = State.IDLE
var hitbox_offsets := {
	"up": Vector2(0, -20),
	"down": Vector2(0, 20),
	"left": Vector2(-20, 0),
	"right": Vector2(20, 0),
	"left_up": Vector2(-14, -14),
	"left_down": Vector2(-14, 14),
	"right_up": Vector2(14, -14),
	"right_down": Vector2(14, 14)
}

func _ready() -> void:
	# Tạo stats mặc định nếu chưa có
	if stats == null:
		stats = CharacterStats.new()
	stats.died.connect(_on_died)
	
	anim.animation_finished.connect(_on_animation_finished)
	attack_hitbox.monitoring = false
	attack_hitbox.body_entered.connect(_on_attack_hit)


func _physics_process(delta: float) -> void:
	# Hồi stamina
	if current_state != State.DEATH:
		stats.regen_stamina(delta)
	
	match current_state:
		State.IDLE:
			_state_idle()
		State.MOVE:
			_state_move()
		State.ATTACK:
			_state_attack()
		State.DEATH:
			_state_death()


func _state_idle() -> void:
	velocity = Vector2.ZERO
	move_and_slide()
	
	# Check transitions
	if Input.is_action_just_pressed("character_attack"):
		_change_state(State.ATTACK)
		return
	
	var move_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if move_dir != Vector2.ZERO:
		last_dir = move_dir
		_change_state(State.MOVE)
		return
	
	_play_idle_animation()



func _state_move() -> void:
	var move_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# Check transitions
	if Input.is_action_just_pressed("character_attack"):
		velocity = Vector2.ZERO
		move_and_slide()
		_change_state(State.ATTACK)
		return
	
	if move_dir == Vector2.ZERO:
		velocity = Vector2.ZERO
		move_and_slide()
		_change_state(State.IDLE)
		return
	
	# Move
	last_dir = move_dir
	velocity = move_dir * stats.move_speed
	move_and_slide()
	_play_move_animation()


func _state_attack() -> void:
	# Không di chuyển khi attack
	velocity = Vector2.ZERO
	move_and_slide()
	# Animation đang chạy, đợi _on_animation_finished


func _state_death() -> void:
	velocity = Vector2.ZERO
	# Không làm gì, chờ animation death kết thúc


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


func _on_animation_finished() -> void:
	match current_state:
		State.ATTACK:
			# Tắt hitbox khi attack xong
			_disable_attack_hitbox()
			_change_state(State.IDLE)
		State.DEATH:
			# Death animation xong, có thể emit signal hoặc queue_free
			pass


# === ATTACK HITBOX ===
func _enable_attack_hitbox() -> void:
	var key := _direction_to_key(last_dir)
	if hitbox_offsets.has(key):
		attack_hitbox.position = hitbox_offsets[key]
	# Xoay hitbox theo hướng diagonal
	var angle := last_dir.angle()
	attack_hitbox.rotation = angle + PI / 2
	attack_hitbox.monitoring = true


func _disable_attack_hitbox() -> void:
	attack_hitbox.monitoring = false


func _on_attack_hit(body: Node2D) -> void:
	# Kiểm tra nếu body là enemy
	if body.has_method("take_damage"):
		body.take_damage(stats.attack_damage)


# === ANIMATION FUNCTIONS ===
func _play_idle_animation() -> void:
	var key := _direction_to_key(last_dir)
	var anim_name := "idle_" + key
	
	if not anim.sprite_frames.has_animation(anim_name):
		return
	
	anim.speed_scale = 2.0
	if anim.animation != anim_name:
		anim.play(anim_name)


func _play_move_animation() -> void:
	var key := _direction_to_key(last_dir)
	var anim_name := "move_" + key

	# Support typo in SpriteFrames
	if anim_name == "move_right_down" and not anim.sprite_frames.has_animation(anim_name):
		if anim.sprite_frames.has_animation("move_rigt_down"):
			anim_name = "move_rigt_down"

	if not anim.sprite_frames.has_animation(anim_name):
		return

	anim.speed_scale = 2.0
	if anim.animation != anim_name:
		anim.play(anim_name)


func _play_attack_animation() -> void:
	var key := _direction_to_attack_key(last_dir)
	var anim_name := "attack_" + key

	# Support typo in SpriteFrames: attach_up instead of attack_up.
	if anim_name == "attack_up" and not anim.sprite_frames.has_animation(anim_name):
		if anim.sprite_frames.has_animation("attach_up"):
			anim_name = "attach_up"

	if not anim.sprite_frames.has_animation(anim_name):
		_change_state(State.IDLE)
		return

	# Bật hitbox khi attack
	_enable_attack_hitbox()
	
	# Tắt loop để animation_finished được gọi
	anim.sprite_frames.set_animation_loop(anim_name, false)
	anim.speed_scale = 4.0
	anim.play(anim_name)


func _play_death_animation() -> void:
	var key := _direction_to_attack_key(last_dir)
	var anim_name := "death_" + key
	
	# Fallback nếu không có animation theo hướng
	if not anim.sprite_frames.has_animation(anim_name):
		if anim.sprite_frames.has_animation("death"):
			anim_name = "death"
		else:
			return
	
	anim.speed_scale = 1.0
	anim.play(anim_name)


# === DIRECTION HELPERS ===
func _direction_to_key(d: Vector2) -> String:
	var ax := absf(d.x)
	var ay := absf(d.y)

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

	if ay >= ax:
		return "up" if d.y < 0 else "down"
	else:
		return "left" if d.x < 0 else "right"


func _direction_to_attack_key(d: Vector2) -> String:
	var ax := absf(d.x)
	var ay := absf(d.y)

	if ay >= ax:
		return "up" if d.y < 0 else "down"
	return "left" if d.x < 0 else "right"


func _on_died() -> void:
	die()

	
# === PUBLIC FUNCTIONS ===
func die() -> void:
	if current_state != State.DEATH:
		_change_state(State.DEATH)


func is_dead() -> bool:
	return current_state == State.DEATH


func take_damage(amount: int) -> void:
	if current_state == State.DEATH:
		return
	stats.take_damage(amount)


