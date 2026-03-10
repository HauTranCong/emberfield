extends Node2D
class_name DungeonLevel
## Manages dungeon gameplay - renders current room, handles door transitions
##
## Flow:
## 1. Generate layout via DungeonGenerator
## 2. Render current room with TileMapLayer
## 3. Enemies spawn in uncleaned rooms → doors lock until all defeated
## 4. Player walks into door → transition to adjacent room
##
## Room Locking:
##   Enter uncleaned room → enemies spawn → doors sealed with wall tiles
##   Kill all enemies → room.cleared = true → doors re-open
##   Re-enter cleared room → no enemies, doors stay open

const TILE_SIZE := 16
const RETURN_PORTAL_SCENE := preload("res://sense/maps/dungeon/return_portal.tscn")
const SKELETON_SCENE := preload("res://sense/entities/enemies/skeleton/skeleton.tscn")

## Room size settings (adjustable in Inspector)
@export_group("Room Settings")
@export var use_viewport_size := false ## If true, room fills screen. If false, use custom size
@export var custom_room_width := 50 ## Room width in tiles (when use_viewport_size=false)
@export var custom_room_height := 35 ## Room height in tiles (when use_viewport_size=false)

## Door dimensions (centered on each wall)
@export_group("Door Settings")
@export var door_width := 4 ## tiles wide for top/bottom doors
@export var door_height := 4 ## tiles tall for left/right doors

@onready var floor_layer: TileMapLayer = $FloorLayer
@onready var wall_layer: TileMapLayer = $WallLayer
@onready var camera: Camera2D = $Camera2D

## Reference to global player (from Main scene)
var player: CharacterBody2D
var _hud: CanvasLayer = null

var generator: DungeonGenerator
var current_room_pos: Vector2i
var return_portal: Node2D = null

## Enemy tracking for room locking
var _active_enemies: Array[Node2D] = []
var _doors_locked: bool = false

## Dynamic room size
var room_width: int
var room_height: int


func _ready() -> void:
	# Get global player from Main scene (in "player" group)
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player == null:
		push_error("DungeonLevel: No player found in 'player' group!")
		return
	
	# Use CameraService to switch to dungeon camera (room-bounded)
	CameraService.use_custom_camera(camera, player, CameraService.Mode.ROOM)
	
	# Calculate room size
	if use_viewport_size:
		var viewport_size = get_viewport_rect().size
		room_width = int(viewport_size.x / TILE_SIZE)
		room_height = int(viewport_size.y / TILE_SIZE)
	else:
		room_width = custom_room_width
		room_height = custom_room_height
	
	print("Room size: %dx%d tiles (%dx%d px)" % [room_width, room_height, room_width * TILE_SIZE, room_height * TILE_SIZE])
	
	# Generate dungeon
	generator = DungeonGenerator.new()
	generator.num_rooms = 8
	generator.generate()
	generator.print_map()
	
	# Start in first room
	current_room_pos = generator.get_start_pos()
	_render_room(current_room_pos)
	
	# Center player at room center
	player.global_position = _room_center()
	
	# Setup HUD dungeon minimap
	_setup_hud_minimap()


func _setup_hud_minimap() -> void:
	# Find HUD in tree
	_hud = get_tree().get_first_node_in_group("hud") as CanvasLayer
	if _hud == null:
		# Try to find by name
		var main = get_tree().get_first_node_in_group("main")
		if main:
			_hud = main.get_node_or_null("HUD")
	
	if _hud and _hud.has_method("show_dungeon_minimap"):
		_hud.show_dungeon_minimap()
		_hud.update_dungeon_minimap(generator.rooms, current_room_pos)


func _exit_tree() -> void:
	# Clean up active enemies
	_clear_active_enemies()
	
	# Clear room bounds before restoring camera
	CameraService.clear_room_bounds()
	
	# Restore player camera via CameraService
	CameraService.restore_player_camera()
	
	# Restore world minimap in HUD
	if _hud and _hud.has_method("show_world_minimap"):
		_hud.show_world_minimap()


func _render_room(pos: Vector2i) -> void:
	floor_layer.clear()
	wall_layer.clear()
	_clear_return_portal()
	_clear_active_enemies()
	_doors_locked = false
	
	var room = generator.rooms[pos] as DungeonGenerator.Room
	
	# Draw floor (source_id=1 because TileSet has sources/1)
	for x in range(room_width):
		for y in range(room_height):
			floor_layer.set_cell(Vector2i(x, y), 1, Vector2i(0, 0))
	
	# Draw walls with doors
	_draw_walls(room.doors)
	
	# Place structures inside the room
	_place_structures(room)
	
	# Set room tint based on type
	_apply_room_tint(room.type)
	_spawn_return_portal_if_end_room(room)
	
	# Spawn enemies and lock doors if room not yet cleared
	_spawn_room_enemies(room)
	
	# Set camera bounds to room dimensions
	CameraService.set_room_bounds(Rect2(
		Vector2.ZERO,
		Vector2(room_width * TILE_SIZE, room_height * TILE_SIZE)
	))


func _draw_walls(doors: Array) -> void:
	var door_dirs = doors as Array[DungeonGenerator.Dir]
	var wall_atlas = Vector2i(2, 2)
	
	# Door positions (centered)
	var door_x_start = room_width / 2 - door_width / 2
	var door_x_end = door_x_start + door_width - 1
	var door_y_start = room_height / 2 - door_height / 2
	var door_y_end = door_y_start + door_height - 1
	
	# Top wall
	for x in range(room_width):
		var is_door = DungeonGenerator.Dir.UP in door_dirs and x >= door_x_start and x <= door_x_end
		if not is_door:
			wall_layer.set_cell(Vector2i(x, 0), 0, wall_atlas)
	
	# Bottom wall  
	for x in range(room_width):
		var is_door = DungeonGenerator.Dir.DOWN in door_dirs and x >= door_x_start and x <= door_x_end
		if not is_door:
			wall_layer.set_cell(Vector2i(x, room_height - 1), 0, wall_atlas)
	
	# Left wall
	for y in range(room_height):
		var is_door = DungeonGenerator.Dir.LEFT in door_dirs and y >= door_y_start and y <= door_y_end
		if not is_door:
			wall_layer.set_cell(Vector2i(0, y), 0, wall_atlas)
	
	# Right wall
	for y in range(room_height):
		var is_door = DungeonGenerator.Dir.RIGHT in door_dirs and y >= door_y_start and y <= door_y_end
		if not is_door:
			wall_layer.set_cell(Vector2i(room_width - 1, y), 0, wall_atlas)


# ── Structure Placement ─────────────────────────────────────────────

## Source IDs must match dungeon_map.tscn TileSet configuration
const WALL_SOURCE_ID := 0   # WallLayer → TX Tileset Wall.png
const FLOOR_SOURCE_ID := 1  # FloorLayer → TX Tileset Stone Ground.png


func _place_structures(room: DungeonGenerator.Room) -> void:
	## Place random structures in NORMAL rooms only
	## START, BOSS, TREASURE rooms stay clean
	if room.type != DungeonGenerator.RoomType.NORMAL:
		return
	
	# Safe area: 3 tiles away from walls to avoid blocking doors
	var safe_bounds := Rect2i(3, 3, room_width - 6, room_height - 6)
	
	# Place 1-2 random structures
	var count := randi_range(1, 2)
	var placed_rects: Array[Rect2i] = []
	
	for i in range(count):
		var structure := DungeonTileStructure.get_random_wall_structure()
		_try_place_structure(structure, safe_bounds, placed_rects)


func _try_place_structure(
	structure: TilesetStructure,
	bounds: Rect2i,
	placed_rects: Array[Rect2i],
	max_attempts: int = 20,
) -> bool:
	## Try to place a structure randomly without overlapping others
	var max_x := bounds.size.x - structure.size.x
	var max_y := bounds.size.y - structure.size.y
	
	if max_x <= 0 or max_y <= 0:
		return false  # Structure too big for bounds
	
	for _attempt in range(max_attempts):
		var pos := Vector2i(
			bounds.position.x + randi() % max_x,
			bounds.position.y + randi() % max_y,
		)
		
		# Check overlap with already-placed structures (1 tile padding)
		var rect := Rect2i(pos, structure.size)
		var overlaps := false
		for existing in placed_rects:
			if rect.intersects(existing.grow(1)):
				overlaps = true
				break
		
		if not overlaps:
			_stamp_structure(structure, pos)
			placed_rects.append(rect)
			return true
	
	return false  # Could not find valid position


func _stamp_structure(structure: TilesetStructure, world_pos: Vector2i) -> void:
	## Stamp all tiles of a structure onto the correct TileMapLayer
	for x in range(structure.size.x):
		for y in range(structure.size.y):
			var atlas_coord := structure.get_atlas_at(Vector2i(x, y))
			var tile_pos := world_pos + Vector2i(x, y)
			
			match structure.layer:
				TilesetStructure.Layer.FLOOR:
					floor_layer.set_cell(tile_pos, FLOOR_SOURCE_ID, atlas_coord)
				TilesetStructure.Layer.WALL:
					wall_layer.set_cell(tile_pos, WALL_SOURCE_ID, atlas_coord)


func _apply_room_tint(type: DungeonGenerator.RoomType) -> void:
	match type:
		DungeonGenerator.RoomType.START:
			modulate = Color.WHITE
		DungeonGenerator.RoomType.BOSS:
			modulate = Color(1.0, 0.7, 0.7) # Red tint
		DungeonGenerator.RoomType.TREASURE:
			modulate = Color(1.0, 1.0, 0.7) # Yellow tint
		_:
			modulate = Color.WHITE


func _room_center() -> Vector2:
	return Vector2(room_width * TILE_SIZE / 2.0, room_height * TILE_SIZE / 2.0)


func _clear_return_portal() -> void:
	if return_portal != null and is_instance_valid(return_portal):
		return_portal.queue_free()
	return_portal = null


func _spawn_return_portal_if_end_room(room: DungeonGenerator.Room) -> void:
	if room.type != DungeonGenerator.RoomType.BOSS:
		return
	# Only show portal after boss room is cleared
	if not room.cleared:
		return
	
	return_portal = RETURN_PORTAL_SCENE.instantiate() as Node2D
	add_child(return_portal)
	return_portal.global_position = _room_center() + Vector2(0, TILE_SIZE * 4)


# ── Enemy Spawning & Room Locking ───────────────────────────────────

## Get enemy count for a room based on distance from START (difficulty scaling)
## Distance 1 = 2 enemies, distance 2 = 2-3, distance 3+ = 3
func _get_enemy_count_for_room(room: DungeonGenerator.Room) -> int:
	match room.type:
		DungeonGenerator.RoomType.START, DungeonGenerator.RoomType.TREASURE:
			return 0
		DungeonGenerator.RoomType.BOSS:
			return 1
		DungeonGenerator.RoomType.NORMAL:
			var start_pos := generator.get_start_pos()
			var dist := Vector2(room.pos - start_pos).length()
			if dist <= 1.0:
				return 2
			elif dist <= 2.0:
				return randi_range(2, 3)
			else:
				return 3
	return 0


## Spawn enemies in current room and lock doors if needed
func _spawn_room_enemies(room: DungeonGenerator.Room) -> void:
	if room.cleared:
		return
	
	var count := _get_enemy_count_for_room(room)
	if count <= 0:
		return
	
	# Safe area for enemy placement (3 tiles from walls, avoids doors)
	var safe_bounds := Rect2i(4, 4, room_width - 8, room_height - 8)
	
	for i in range(count):
		var enemy := SKELETON_SCENE.instantiate() as Node2D
		add_child(enemy)
		
		# Random position within safe bounds
		var spawn_x := randi_range(safe_bounds.position.x, safe_bounds.end.x) * TILE_SIZE
		var spawn_y := randi_range(safe_bounds.position.y, safe_bounds.end.y) * TILE_SIZE
		
		# BOSS room: single enemy at center
		if room.type == DungeonGenerator.RoomType.BOSS:
			enemy.global_position = _room_center()
		else:
			enemy.global_position = Vector2(spawn_x, spawn_y)
		
		_active_enemies.append(enemy)
		enemy.tree_exiting.connect(_on_enemy_removed.bind(enemy))
	
	# Lock doors while enemies are alive
	_lock_doors()


## Called when an enemy is removed from tree (death or cleanup)
func _on_enemy_removed(enemy: Node2D) -> void:
	_active_enemies.erase(enemy)
	
	# Check if all enemies defeated — defer to avoid modifying tree during tree_exiting
	if _active_enemies.is_empty() and _doors_locked:
		call_deferred("_on_all_enemies_defeated")


## Deferred callback when all enemies in the current room are dead
func _on_all_enemies_defeated() -> void:
	var room = generator.rooms[current_room_pos] as DungeonGenerator.Room
	room.cleared = true
	_unlock_doors()
	
	# Spawn return portal in boss room after clearing
	if room.type == DungeonGenerator.RoomType.BOSS:
		_spawn_return_portal_if_end_room(room)
	
	print("Room %s cleared!" % current_room_pos)


## Free all active enemies (for room transitions)
func _clear_active_enemies() -> void:
	for enemy in _active_enemies:
		if is_instance_valid(enemy):
			# Disconnect signal to avoid triggering _on_enemy_removed during cleanup
			var bound_callable := _on_enemy_removed.bind(enemy)
			if enemy.tree_exiting.is_connected(bound_callable):
				enemy.tree_exiting.disconnect(bound_callable)
			enemy.queue_free()
	_active_enemies.clear()


## Seal door openings with wall tiles so player cannot leave
func _lock_doors() -> void:
	_doors_locked = true
	var room = generator.rooms[current_room_pos] as DungeonGenerator.Room
	var wall_atlas = Vector2i(2, 2)
	
	var door_x_start = room_width / 2 - door_width / 2
	var door_x_end = door_x_start + door_width - 1
	var door_y_start = room_height / 2 - door_height / 2
	var door_y_end = door_y_start + door_height - 1
	
	for dir in room.doors:
		match dir:
			DungeonGenerator.Dir.UP:
				for x in range(door_x_start, door_x_end + 1):
					wall_layer.set_cell(Vector2i(x, 0), 0, wall_atlas)
			DungeonGenerator.Dir.DOWN:
				for x in range(door_x_start, door_x_end + 1):
					wall_layer.set_cell(Vector2i(x, room_height - 1), 0, wall_atlas)
			DungeonGenerator.Dir.LEFT:
				for y in range(door_y_start, door_y_end + 1):
					wall_layer.set_cell(Vector2i(0, y), 0, wall_atlas)
			DungeonGenerator.Dir.RIGHT:
				for y in range(door_y_start, door_y_end + 1):
					wall_layer.set_cell(Vector2i(room_width - 1, y), 0, wall_atlas)


## Remove wall tiles from door openings to restore passage
func _unlock_doors() -> void:
	_doors_locked = false
	var room = generator.rooms[current_room_pos] as DungeonGenerator.Room
	
	var door_x_start = room_width / 2 - door_width / 2
	var door_x_end = door_x_start + door_width - 1
	var door_y_start = room_height / 2 - door_height / 2
	var door_y_end = door_y_start + door_height - 1
	
	for dir in room.doors:
		match dir:
			DungeonGenerator.Dir.UP:
				for x in range(door_x_start, door_x_end + 1):
					wall_layer.erase_cell(Vector2i(x, 0))
			DungeonGenerator.Dir.DOWN:
				for x in range(door_x_start, door_x_end + 1):
					wall_layer.erase_cell(Vector2i(x, room_height - 1))
			DungeonGenerator.Dir.LEFT:
				for y in range(door_y_start, door_y_end + 1):
					wall_layer.erase_cell(Vector2i(0, y))
			DungeonGenerator.Dir.RIGHT:
				for y in range(door_y_start, door_y_end + 1):
					wall_layer.erase_cell(Vector2i(room_width - 1, y))


func _process(_delta: float) -> void:
	_check_door_collision()


## Force-collect all GameItem drops in the current room before transitioning
func _auto_collect_items() -> void:
	if player == null:
		return
	for child in get_children():
		if child is GameItem and not child._is_collected:
			child._collect(player)


func _check_door_collision() -> void:
	if player == null or _doors_locked:
		return
	var room = generator.rooms[current_room_pos] as DungeonGenerator.Room
	var player_tile = Vector2i(player.global_position / TILE_SIZE)
	
	# Check each door direction
	for dir in room.doors:
		if _is_at_door(player_tile, dir):
			_go_to_room(dir)
			return


func _is_at_door(tile: Vector2i, dir: DungeonGenerator.Dir) -> bool:
	var door_x_start = room_width / 2 - door_width / 2
	var door_x_end = door_x_start + door_width - 1
	var door_y_start = room_height / 2 - door_height / 2
	var door_y_end = door_y_start + door_height - 1
	
	match dir:
		DungeonGenerator.Dir.UP:
			return tile.y <= 0 and tile.x >= door_x_start and tile.x <= door_x_end
		DungeonGenerator.Dir.DOWN:
			return tile.y >= room_height - 1 and tile.x >= door_x_start and tile.x <= door_x_end
		DungeonGenerator.Dir.LEFT:
			return tile.x <= 0 and tile.y >= door_y_start and tile.y <= door_y_end
		DungeonGenerator.Dir.RIGHT:
			return tile.x >= room_width - 1 and tile.y >= door_y_start and tile.y <= door_y_end
	return false


func _go_to_room(dir: DungeonGenerator.Dir) -> void:
	var offset = generator._dir_offset(dir)
	var new_pos = current_room_pos + offset
	
	if not generator.rooms.has(new_pos):
		return
	
	# Auto-collect all dropped items before leaving the room
	_auto_collect_items()
	
	current_room_pos = new_pos
	_render_room(new_pos)
	
	# Teleport player to opposite door (center of room, offset from wall)
	var center_x = room_width / 2 * TILE_SIZE
	var center_y = room_height / 2 * TILE_SIZE
	match dir:
		DungeonGenerator.Dir.UP:
			player.global_position = Vector2(center_x, (room_height - 3) * TILE_SIZE)
		DungeonGenerator.Dir.DOWN:
			player.global_position = Vector2(center_x, 3 * TILE_SIZE)
		DungeonGenerator.Dir.LEFT:
			player.global_position = Vector2((room_width - 3) * TILE_SIZE, center_y)
		DungeonGenerator.Dir.RIGHT:
			player.global_position = Vector2(3 * TILE_SIZE, center_y)
	
	# Update HUD minimap
	if _hud and _hud.has_method("update_dungeon_current_room"):
		_hud.update_dungeon_current_room(current_room_pos)
	
	print("Entered room at %s" % new_pos)
