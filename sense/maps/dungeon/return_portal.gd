extends Node2D

@onready var interaction_area: InteractionArea = $interaction_area

var portal_name: String = "return_portal"


func _ready() -> void:
	interaction_area.interact = Callable(self , "_on_interact")


func _on_interact() -> void:
	print("Player is interacting with ", portal_name)
	SceneTransitionService.go_to_town()