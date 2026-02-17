extends Node2D

@onready var interaction_area: InteractionArea = $interaction_area
@onready var anim: AnimationPlayer = $AnimationPlayer

var npc_name: String = "portal"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	interaction_area.interact = Callable(self, "_on_interact")
	interaction_area.on_enter = Callable(self, "_on_interaction_area_body_entered")
	interaction_area.on_exit = Callable(self, "_on_interaction_area_body_exited")

func _on_interact() -> void:
	print("Player is interacting with ", npc_name)


func _on_interaction_area_body_entered(body: Node2D) -> void:
	anim.play("on_enter")


func _on_interaction_area_body_exited(body: Node2D) -> void:
	anim.play("on_exit")
