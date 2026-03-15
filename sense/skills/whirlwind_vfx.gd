## Whirlwind VFX — Simple rotating rectangle effect
## Spawned by SkillExecutor, auto-frees after animation completes
extends Node2D

@onready var color_rect: ColorRect = $ColorRect
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	# Start spin animation immediately
	animation_player.play("spin")
	# Auto-free when animation finishes
	animation_player.animation_finished.connect(_on_animation_finished)


func _on_animation_finished(_anim_name: String) -> void:
	queue_free()
