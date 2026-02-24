extends Node

signal transition_requested(target_map: String)
signal transition_started(from_map: String, to_map: String)
signal transition_completed(active_map: String)

const MAP_TOWN := "town"
const MAP_DUNGEON := "dungeon"


func go_to_dungeon() -> void:
	transition_requested.emit(MAP_DUNGEON)


func go_to_town() -> void:
	transition_requested.emit(MAP_TOWN)
