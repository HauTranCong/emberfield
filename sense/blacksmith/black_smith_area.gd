extends Area2D

var player_in_area: bool = false

func _ready() -> void:
	# Interactable area: Layer INTERACTABLE, Mask: PLAYER
	collision_layer = CollisionLayers.Layer.INTERACTABLE
	collision_mask = CollisionLayers.Layer.PLAYER

func _on_body_exited(body: Node2D) -> void:
	# Check if body is on Player layer
	if body.collision_layer & CollisionLayers.Layer.PLAYER:
		player_in_area = false
		print("Player exited blacksmith area")

func _on_body_entered(body: Node2D) -> void:
	# Check if body is on Player layer
	if body.collision_layer & CollisionLayers.Layer.PLAYER:
		player_in_area = true
		print("Player entered blacksmith area")

func _unhandled_input(event: InputEvent) -> void:
	if player_in_area and event.is_action_pressed("character_interact_smith"):
		print("Player is interacting with blacksmith")