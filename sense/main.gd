extends Node2D

@onready var town: Node2D = $Town
@onready var player: Node2D = $Player
@onready var hud: CanvasLayer = $HUD


const DUNGEON_MAP_SCENE := preload("res://sense/maps/dungeon/dungeon_map.tscn")
const FADE_DURATION := 0.25

var dungeon: Node2D
var active_map: String = SceneTransitionService.MAP_TOWN
var is_transitioning: bool = false
var fade_rect: ColorRect


func _ready() -> void:
	# One-time setup:
	# 1) connect pause + transition events
	# 2) build fade overlay
	# 3) place player in town spawn
	# 4) initialize HUD/minimap
	GameEvent.request_ui_pause.connect(_on_request_ui_pause)
	SceneTransitionService.transition_requested.connect(_on_transition_requested)

	_setup_fade_layer()
	_spawn_in_town()

	if hud != null and player.has_method("get") and player.get("stats") != null:
		hud.setup(player.stats)
	if hud != null:
		hud.setup_minimap(player, self )


func _on_transition_requested(target_map: String) -> void:
	# Ignore invalid or duplicate requests while a transition is already running.
	if is_transitioning or target_map == active_map:
		return
	if target_map != SceneTransitionService.MAP_TOWN and target_map != SceneTransitionService.MAP_DUNGEON:
		return

	await _change_map_with_fade(target_map)


func _change_map_with_fade(target_map: String) -> void:
	# Core transition sequence:
	# emit start -> fade out -> swap map/spawn -> fade in -> emit complete
	is_transitioning = true
	SceneTransitionService.transition_started.emit(active_map, target_map)

	await _fade_to(1.0)
	if target_map == SceneTransitionService.MAP_DUNGEON:
		_show_dungeon()
	else:
		_show_town()
	await _fade_to(0.0)

	SceneTransitionService.transition_completed.emit(active_map)
	is_transitioning = false


func _show_dungeon() -> void:
	# Ensure dungeon exists, make it active, and place player at DungeonSpawn.
	if dungeon == null:
		dungeon = DUNGEON_MAP_SCENE.instantiate() as Node2D
		dungeon.name = "Dungeon"

	if town.get_parent() == self:
		remove_child(town)
	if dungeon.get_parent() != self:
		add_child(dungeon)
	move_child(dungeon, 0)

	var spawn: Node2D = dungeon.get_node_or_null("DungeonSpawn") as Node2D
	if spawn != null:
		player.global_position = spawn.global_position

	active_map = SceneTransitionService.MAP_DUNGEON


func _show_town() -> void:
	# Restore town as active map and reuse town spawn logic.
	if dungeon != null and dungeon.get_parent() == self:
		remove_child(dungeon)
	if town.get_parent() != self:
		add_child(town)
	move_child(town, 0)

	_spawn_in_town()
	active_map = SceneTransitionService.MAP_TOWN


func _spawn_in_town() -> void:
	# Town owns its spawn rules through get_spawn_position().
	if town.has_method("get_spawn_position"):
		var spawn_position: Variant = town.call("get_spawn_position")
		if spawn_position is Vector2:
			player.global_position = spawn_position


func _setup_fade_layer() -> void:
	# Full-screen black overlay on a high CanvasLayer for transition fade.
	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 100
	add_child(fade_layer)

	fade_rect = ColorRect.new()
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.color = Color(0, 0, 0, 1)
	fade_rect.modulate.a = 0.0
	fade_layer.add_child(fade_rect)


func _fade_to(alpha: float) -> void:
	# Tween alpha between 0 (clear) and 1 (fully black).
	var tween := get_tree().create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(fade_rect, "modulate:a", alpha, FADE_DURATION)
	await tween.finished


func _on_request_ui_pause(is_open: bool) -> void:
	get_tree().paused = is_open
