extends Control
@onready var label: Label = $Label
var text_content: String = "Welcome to Tho Ty Nam Son General Store! What can i help you today"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	label.text = text_content

func _on_control_mouse_entered() -> void:
	text_content = "This item have a price of 100 gold. Do you want to buy it?"
	label.text = text_content

func _on_control_mouse_exited() -> void:
	text_content = "Welcome to Tho Ty Nam Son General Store! What can i help you today"
	label.text = text_content

func _on_button_pressed() -> void:
	GameEvent.request_ui_pause.emit(false) # Unpause the game when closing the shop UI
	queue_free()
