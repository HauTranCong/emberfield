extends Node2D
## Main scene - Entry point and orchestrator
##
## Responsibilities:
##   - Register all maps with SceneTransitionService
##   - Initialize services
##   - Setup HUD

@onready var player: CharacterBody2D = $Player
@onready var hud: CanvasLayer = $HUD


func _ready() -> void:
	# Initialize scene transition service
	SceneTransitionService.initialize(self, player)
	
	# Register all maps (add new maps here)
	SceneTransitionService.register_map("town", "res://sense/maps/town/town.tscn")
	SceneTransitionService.register_map("dungeon", "res://sense/maps/dungeon/dungeon_map.tscn")
	# Future maps:
	# SceneTransitionService.register_map("forest", "res://sense/maps/forest/forest.tscn")
	# SceneTransitionService.register_map("boss_arena", "res://sense/maps/boss/boss_arena.tscn")
	
	# Load initial map
	SceneTransitionService.load_initial_map("town")
	
	# Setup HUD
	_setup_hud()
	
	# Connect pause event
	GameEvent.request_ui_pause.connect(_on_request_ui_pause)


func _setup_hud() -> void:
	if hud == null:
		return
	
	if player.has_method("get") and player.get("stats") != null:
		hud.setup(player.stats)
	
	hud.setup_minimap(player, self)


func _on_request_ui_pause(is_open: bool) -> void:
	get_tree().paused = is_open
