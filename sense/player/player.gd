extends CharacterBody2D

@export var speed: float = 120.0
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var last_dir: Vector2 = Vector2.DOWN

func _physics_process(_delta: float) -> void:
	var dir: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	velocity = dir * speed
	move_and_slide()

	if dir != Vector2.ZERO:
		last_dir = dir

	_play_animation(dir)

func _play_animation(dir: Vector2) -> void:
	var is_moving := dir != Vector2.ZERO
	var key := _direction_to_key(dir if is_moving else last_dir)
	var prefix := "move_" if is_moving else "idle_"
	var anim_name := prefix + key

	# Fix typo: move_rigt_down (nếu bạn lỡ đặt sai)
	if anim_name == "move_right_down" and not anim.sprite_frames.has_animation(anim_name):
		if anim.sprite_frames.has_animation("move_rigt_down"):
			anim_name = "move_rigt_down"

	if not anim.sprite_frames.has_animation(anim_name):
		return

	if anim.animation != anim_name:
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
