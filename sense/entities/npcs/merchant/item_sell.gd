extends Control
@onready var outline: TextureRect = $Outline
@onready var background_item: TextureRect = $BackgroundItem
var hovering: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hovering = false
	outline.visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP

func _on_mouse_exited() -> void:
	hovering = false
	outline.visible = false
	print ("Mouse exited")
	
func _on_mouse_entered() -> void:
	hovering = true
	outline.visible = true
	print ("Mouse entered")

func _input(event: InputEvent) -> void:
	if hovering and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		queue_free()
