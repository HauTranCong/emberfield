extends Node2D

@onready var interaction_area: InteractionArea = $interaction_area
@onready var anim: AnimationPlayer = $AnimationPlayer

var npc_name: String = "portal"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	interaction_area.interact = Callable(self, "_on_interact")
	# Connect to signals from script instead editor
	interaction_area.player_entered.connect(_on_player_entered)
	interaction_area.player_exited.connect(_on_player_exited)

func _on_interact() -> void:
	print("Player is interacting with ", npc_name)


func _on_player_entered() -> void:
	# print("Player entered interaction area of ", npc_name)
	anim.play("on_enter")


func _on_player_exited() -> void:
	# print("Player exited interaction area of ", npc_name)
	anim.play("on_exit")