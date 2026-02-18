extends Area2D
class_name InteractionArea

@export var action_name: String = "interact"
@export var global_position_area: Vector2
@export var interact: Callable = func() -> void:
	pass
@export var on_enter: Callable = func(_body: Node2D) -> void:
	pass
@export var on_exit: Callable = func(_body: Node2D) -> void:
	pass

func _ready() -> void:
	# Interactable area: Layer INTERACTABLE, Mask: PLAYER
	collision_layer = CollisionLayers.Layer.INTERACTABLE
	collision_mask = CollisionLayers.Layer.PLAYER
	interact = _on_interact

func _on_body_entered(body: Node2D) -> void:	
	InteractionManager.register_area(self)
	print("InteractionArea ready at global position: ", body.global_position)
	global_position_area = body.global_position
	on_enter.call(body)

func _on_body_exited(body: Node2D) -> void:
	InteractionManager.unregister_area(self)
	on_exit.call(body)

func _on_interact() -> void:
	print("Player is interacting with ", action_name)
