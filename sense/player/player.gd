extends CharacterBody2D

@export var speed: float = 120.0
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var last_dir: Vector2 = Vector2.DOWN
var is_attacking: bool = false

func _physics_process(_delta: float) -> void:
	var move_dir: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	is_attacking = Input.is_action_pressed("character_attack")

	velocity = move_dir * speed
	move_and_slide()

	if move_dir != Vector2.ZERO:
		last_dir = move_dir

	if is_attacking:
		_play_attack_animation(move_dir)
	else:
		_play_move_or_idle_animation(move_dir)

func _play_move_or_idle_animation(dir: Vector2) -> void:
	var is_moving := dir != Vector2.ZERO
	var key := _direction_to_key(dir if is_moving else last_dir)
	var prefix := "move_" if is_moving else "idle_"
	var anim_name := prefix + key

	if anim_name == "move_right_down" and not anim.sprite_frames.has_animation(anim_name):
		if anim.sprite_frames.has_animation("move_rigt_down"):
			anim_name = "move_rigt_down"

	if not anim.sprite_frames.has_animation(anim_name):
		return

	anim.speed_scale = 2.0
	if anim.animation != anim_name:
		anim.play(anim_name)

func _play_attack_animation(dir: Vector2) -> void:
	var source_dir := dir if dir != Vector2.ZERO else last_dir
	var key := _direction_to_attack_key(source_dir)
	var anim_name := "attack_" + key

	# Support typo in SpriteFrames: attach_up instead of attack_up.
	if anim_name == "attack_up" and not anim.sprite_frames.has_animation(anim_name):
		if anim.sprite_frames.has_animation("attach_up"):
			anim_name = "attach_up"

	if not anim.sprite_frames.has_animation(anim_name):
		return

	anim.speed_scale = 2.0
	if anim.animation != anim_name or not anim.is_playing():
		anim.play(anim_name)

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
