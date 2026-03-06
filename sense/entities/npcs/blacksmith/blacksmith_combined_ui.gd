extends Control
class_name BlacksmithCombinedUI

## Combined side-by-side layout: SmithShopPopup (left) + InventoryPanel (right)
## Opened by UIPopupComponent when player interacts with the Blacksmith.
##
## Scene tree (set in blacksmith_combined_ui.tscn):
##   BlacksmithCombinedUI (Control, Full Rect)
##   ├── Dim (ColorRect, Full Rect)
##   └── CenterContainer (Full Rect)
##       └── HBoxContainer
##           ├── SmithShopPopup  ← shop items list
##           └── InventoryPanel  ← player's inventory + equipment

@onready var dim: DimBackground = $Dim
@onready var smith_popup: SmithShopPopup = $CenterContainer/HBoxContainer/SmithShopPopup
@onready var inventory_panel: InventoryPanel = $CenterContainer/HBoxContainer/InventoryPanel


func _ready() -> void:
	visible = false

	# Close everything when shop's X button is pressed
	smith_popup.close_requested.connect(hide_popup)

	# Close when dim background is clicked
	if dim and dim.has_signal("dim_clicked"):
		dim.dim_clicked.connect(_on_dim_clicked)

	# ESC to close
	set_process_input(true)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		hide_popup()
		get_viewport().set_input_as_handled()


## Called by UIPopupComponent after instantiation (data = {items, owner})
func initialize(data: Dictionary) -> void:
	# --- Shop panel ---
	if smith_popup:
		smith_popup.initialize(data)

	# --- Inventory panel: connect to player's inventory data ---
	if inventory_panel:
		var player = get_tree().get_first_node_in_group("player")
		if player and player.get("inventory"):
			inventory_panel.setup(player.inventory)


func show_popup() -> void:
	visible = true
	smith_popup.show_popup()
	if inventory_panel:
		inventory_panel.open_inventory()


func hide_popup() -> void:
	visible = false
	queue_free()


func _on_dim_clicked(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		hide_popup()
