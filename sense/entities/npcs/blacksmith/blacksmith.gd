extends Node2D
@onready var interaction_area: InteractionArea = $interaction_area

var npc_name: String = "blacksmith"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	interaction_area.interact = Callable(self, "_on_interact")

func _on_interact() -> void:
	print("Player is interacting with ", npc_name)