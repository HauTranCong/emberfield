extends Node2D

@onready var player = get_tree().get_first_node_in_group("player")
@onready var label: Label = $Label


const base_text = "Press [E] to "
const offset_Y_interactArea = 50

var active_areas = []
var can_interact: bool = true

func register_area(area: InteractionArea) -> void:
	active_areas.push_back(area)
	print("Player entered " + area.action_name + " area")
	print(active_areas)

func unregister_area(area: InteractionArea) -> void:
	var index = active_areas.find(area)
	if index != -1:
		active_areas.remove_at(index)
	print("Player exited " + area.action_name + " area")

func _process(delta: float) -> void:
	if active_areas.size() > 0 and can_interact:
		# If only one area, show that one. If multiple, sort by distance and show closest
		if active_areas.size() > 1:
			active_areas.sort_custom(_sort_by_distance)
		
		label.text = base_text + active_areas[0].action_name
		
		# Position label above the interactable object
		var target_pos = active_areas[0].global_position_area
		target_pos.y = target_pos.y - offset_Y_interactArea # label_Y offset
		target_pos.x = target_pos.x - label.get_rect().size.x / 2  # Center the label horizontally
		label.global_position = target_pos
		
		label.show()
	else:
		label.hide()


func _sort_by_distance(area1, area2) -> bool:
	print("Comparing distances: ", area1.action_name, " and ", area2.action_name)
	var area1_to_player = player.global_position.distance_to(area1.global_position_area)
	var area2_to_player = player.global_position.distance_to(area2.global_position_area)
	return area1_to_player < area2_to_player

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("character_interact") and can_interact:
		print("Player pressed interact")
		if active_areas.size() > 0:
			can_interact = false
			label.hide()

			await active_areas[0].interact.call()

			can_interact = true
