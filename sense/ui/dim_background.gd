extends ColorRect
class_name DimBackground

## Semi-transparent background overlay for popup UIs
## Emits signal when clicked to allow closing popups

signal dim_clicked(event: InputEvent)

func _ready() -> void:
	# Cover the entire screen
	anchor_right = 1.0
	anchor_bottom = 1.0
	
	# Semi-transparent black
	color = Color(0, 0, 0, 0.5)
	
	# Enable mouse input
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	gui_input.connect(_on_gui_input)

func _on_gui_input(event: InputEvent) -> void:
	dim_clicked.emit(event)
