extends StaticBody2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: InteractionArea = $interaction_area
@onready var ui_popup: UIPopupComponent = $UIPopupComponent
@onready var shop: ShopComponent = $ShopComponent  # Will be recognized after Godot reloads

var npc_name: String = "general goods merchant"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	anim.play("idle")
	interaction_area.interact = Callable(self, "_on_interact")
	# Auto-close shop when player exits area (general approach for all NPCs)
	if ui_popup:
		ui_popup.setup_auto_close(interaction_area)

func _on_interact() -> void:
	print("Player is interacting with ", npc_name)
	ui_popup.open_ui()

## Called by shop UI when player clicks Buy button
func _on_purchase_requested(item: Dictionary) -> void:
	# Delegate to ShopComponent (general approach for all shops)
	shop.process_purchase(item)