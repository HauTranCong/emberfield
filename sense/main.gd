extends Node2D
## Main scene controller — manages game state flow:
##   TITLE  →  LOADING  →  GAMEPLAY
## No tree pausing; each phase shows/hides the appropriate layers.

# ── Game State ─────────────────────────────────────────
enum GameState { TITLE, LOADING, GAMEPLAY }
var current_state: GameState = GameState.TITLE

# ── Gameplay nodes (always in scene tree for easy get_node) ──
@onready var town: Node2D = $Town
@onready var player: Node2D = $Player
@onready var hud: CanvasLayer = $HUD
@onready var skeleton: Node2D = $Skeleton

# ── UI layers ──────────────────────────────────────────
@onready var title_layer: CanvasLayer = $TitleLayer
@onready var title_screen: Control = $TitleLayer/TitleScreen
@onready var loading_screen: CanvasLayer = $LoadingScreen

func _ready() -> void:
	GameEvent.request_ui_pause.connect(_on_request_ui_pause)

	# Wire signals
	title_screen.play_online_requested.connect(_on_play_online_requested)
	loading_screen.loading_finished.connect(_on_loading_finished)

	# Start in TITLE state
	_enter_state(GameState.TITLE)


# ── State Machine ──────────────────────────────────────

func _enter_state(new_state: GameState) -> void:
	current_state = new_state
	match new_state:
		GameState.TITLE:
			_set_gameplay_visible(false)
			title_layer.visible = true
			loading_screen.visible = false

		GameState.LOADING:
			_set_gameplay_visible(false)
			title_layer.visible = false
			loading_screen.start_loading()

		GameState.GAMEPLAY:
			title_layer.visible = false
			loading_screen.visible = false
			_start_gameplay()


# ── Signal Handlers ────────────────────────────────────

func _on_play_online_requested() -> void:
	if current_state != GameState.TITLE:
		return
	_enter_state(GameState.LOADING)

func _on_loading_finished() -> void:
	if current_state != GameState.LOADING:
		return
	# Apply backend data to player stats before entering gameplay
	_apply_user_data(BackendService.user_data)
	_enter_state(GameState.GAMEPLAY)


# ── Gameplay Setup ─────────────────────────────────────

func _start_gameplay() -> void:
	_set_gameplay_visible(true)

	if town == null or player == null:
		push_error("Assign town & player in Inspector")
		return

	# Spawn: prioritize Spawn marker, otherwise center of town
	var spawn: Node2D = town.get_node_or_null("Spawn") as Node2D
	if spawn != null:
		player.global_position = spawn.global_position
	else:
		var town_rect: Rect2 = _get_town_world_rect(town)
		if town_rect.size != Vector2.ZERO:
			player.global_position = town_rect.get_center()

	# Setup HUD with player stats
	if hud != null and player.has_method("get") and player.get("stats") != null:
		hud.setup(player.stats)

	# Setup minimap — pass self to share the same world_2d
	if hud != null:
		hud.setup_minimap(player, self)


func _apply_user_data(data: Dictionary) -> void:
	if data.is_empty():
		return
	# Apply backend-provided stats to the player's CharacterStats resource.
	# Extend this as your backend schema grows.
	if player and player.get("stats") != null:
		var stats: CharacterStats = player.stats
		if data.has("gold"):
			stats.gold = data["gold"]
		if data.has("max_health"):
			stats.max_health = data["max_health"]
			stats.current_health = data["max_health"]
		if data.has("attack_damage"):
			stats.attack_damage = data["attack_damage"]
		if data.has("defense"):
			stats.defense = data["defense"]


func _set_gameplay_visible(is_visible: bool) -> void:
	town.visible = is_visible
	player.visible = is_visible
	skeleton.visible = is_visible
	hud.visible = is_visible
	# Disable player input processing when not in gameplay
	player.set_process(is_visible)
	player.set_physics_process(is_visible)
	player.set_process_input(is_visible)


func _get_town_world_rect(root: Node) -> Rect2:
	var found: bool = false
	var union_world: Rect2 = Rect2()

	var layers: Array[TileMapLayer] = []
	_collect_tilemap_layers(root, layers)

	for layer: TileMapLayer in layers:
		var used: Rect2i = layer.get_used_rect()
		if used.size == Vector2i.ZERO:
			continue

		var cell: Vector2i = layer.tile_set.tile_size

		var left: float = float(used.position.x * cell.x)
		var top: float = float(used.position.y * cell.y)
		var right: float = float((used.position.x + used.size.x) * cell.x)
		var bottom: float = float((used.position.y + used.size.y) * cell.y)

		var r_local: Rect2 = Rect2(Vector2(left, top), Vector2(right - left, bottom - top))

		var p1: Vector2 = layer.to_global(r_local.position)
		var p2: Vector2 = layer.to_global(r_local.position + Vector2(r_local.size.x, 0.0))
		var p3: Vector2 = layer.to_global(r_local.position + Vector2(0.0, r_local.size.y))
		var p4: Vector2 = layer.to_global(r_local.position + r_local.size)

		var min_x: float = min(p1.x, p2.x, p3.x, p4.x)
		var max_x: float = max(p1.x, p2.x, p3.x, p4.x)
		var min_y: float = min(p1.y, p2.y, p3.y, p4.y)
		var max_y: float = max(p1.y, p2.y, p3.y, p4.y)

		var r_world: Rect2 = Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))

		if not found:
			union_world = r_world
			found = true
		else:
			union_world = union_world.merge(r_world)

	return union_world if found else Rect2()


func _collect_tilemap_layers(node: Node, out_layers: Array[TileMapLayer]) -> void:
	for child: Node in node.get_children():
		var layer: TileMapLayer = child as TileMapLayer
		if layer != null:
			out_layers.append(layer)
		_collect_tilemap_layers(child, out_layers)

#  Signal handler for UI pause request
func _on_request_ui_pause(is_open: bool) -> void:
	if is_open:
		get_tree().paused = true
	else:
		get_tree().paused = false
