extends StaticBody2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: InteractionArea = $interaction_area
@export var ui_scene = preload("res://sense/entities/npcs/merchant/UI.tscn")

var npc_name: String = "general goods merchant"
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	anim.play("idle")
	interaction_area.interact = Callable(self, "_on_interact")

func _on_interact() -> void:
	print("Player is interacting with ", npc_name)
	var hud = get_tree().root.get_node("Main/HUD")
	if hud.has_node("ShopUI"):
		return
	var ui_instance: Node = ui_scene.instantiate()
	ui_instance.name = "ShopUI" 
	hud.add_child(ui_instance)
