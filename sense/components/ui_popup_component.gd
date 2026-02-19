extends Node
class_name UIPopupComponent

## Reusable component for opening UI scenes when interacting with NPCs/objects
## Usage: Add as child node to NPC, set ui_scene, then call open_ui() from interact callback

@export var ui_scene: PackedScene
@export var ui_node_name: String = "PopupUI"  # Prevents duplicate UI instances
@export var close_on_exit: bool = true  # Auto-close UI when player leaves interaction area

## Opens the UI scene in the HUD. Returns the instantiated UI node if successful, null if failed
func open_ui(init_data: Dictionary = {}) -> Node:
	if not ui_scene:
		push_error("UIPopupComponent: No UI scene assigned!")
		return null
	
	var hud = get_tree().root.get_node_or_null("Main/HUD")
	if not hud:
		push_error("UIPopupComponent: Could not find HUD node!")
		return null
	
	# Prevent duplicate UI instances
	if hud.has_node(ui_node_name):
		print("UIPopupComponent: UI already open, ignoring interaction")
		return null
	
	# Instantiate and add UI to HUD
	var ui_instance: Node = ui_scene.instantiate()
	ui_instance.name = ui_node_name
	hud.add_child(ui_instance)
	
	# Initialize with data if the UI has an init method
	if init_data and ui_instance.has_method("initialize"):
		ui_instance.initialize(init_data)
	
	# Show the popup if it has a show_popup method
	if ui_instance.has_method("show_popup"):
		ui_instance.show_popup()
	
	print("UIPopupComponent: Opened ", ui_node_name)
	return ui_instance

## Alternative: Open UI with custom name (for multiple different UIs)
func open_ui_with_name(custom_name: String, init_data: Dictionary = {}) -> Node:
	var original_name = ui_node_name
	ui_node_name = custom_name
	var result = open_ui(init_data)
	ui_node_name = original_name
	return result

## Closes the UI if it exists in the HUD
func hide_popup() -> bool:
	var hud = get_tree().root.get_node_or_null("Main/HUD")
	if not hud:
		return false
	
	var ui_instance = hud.get_node_or_null(ui_node_name)
	if ui_instance:
		# Call hide_popup method if exists, otherwise just remove
		if ui_instance.has_method("hide_popup"):
			ui_instance.hide_popup()
		else:
			ui_instance.queue_free()
		print("UIPopupComponent: Closed ", ui_node_name)
		return true
	return false

## Automatically sets up close-on-exit behavior for InteractionArea
func setup_auto_close(interaction_area: InteractionArea) -> void:
	if close_on_exit and interaction_area:
		interaction_area.on_exit = func(_body: Node2D):
			hide_popup()
