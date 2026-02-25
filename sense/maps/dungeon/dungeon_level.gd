extends Node2D
class_name DungeonLevel
## Manages dungeon gameplay - renders current room, handles door transitions
##
## Flow:
## 1. Generate layout via DungeonGenerator
## 2. Render current room with TileMapLayer
## 3. Player walks into door → transition to adjacent room

const TILE_SIZE := 16
const RETURN_PORTAL_SCENE := preload("res://sense/maps/dungeon/return_portal.tscn")

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

## Dynamic room size
var room_width: int
var room_height: int


func _ready() -> void:
	# Get global player from Main scene (in "player" group)
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player == null:
		push_error("DungeonLevel: No player found in 'player' group!")
		return
	
	# Use CameraService to switch to dungeon camera (follows player)
	CameraService.use_custom_camera(camera, player, CameraService.Mode.FOLLOW)
	
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
	# Restore player camera via CameraService
	CameraService.restore_player_camera()
	
	# Restore world minimap in HUD
	if _hud and _hud.has_method("show_world_minimap"):
		_hud.show_world_minimap()


func _render_room(pos: Vector2i) -> void:
	floor_layer.clear()
	wall_layer.clear()
	_clear_return_portal()
	
	var room = generator.rooms[pos] as DungeonGenerator.Room
	
	# Draw floor (source_id=1 because TileSet has sources/1)
	for x in range(room_width):
		for y in range(room_height):
			floor_layer.set_cell(Vector2i(x, y), 1, Vector2i(0, 0))
	
	# Draw walls with doors
	_draw_walls(room.doors)
	
	# Set room tint based on type
	_apply_room_tint(room.type)
	_spawn_return_portal_if_end_room(room)


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
	
	return_portal = RETURN_PORTAL_SCENE.instantiate() as Node2D
	add_child(return_portal)
	return_portal.global_position = _room_center() + Vector2(0, TILE_SIZE * 4)


func _process(_delta: float) -> void:
	_check_door_collision()


func _check_door_collision() -> void:
	if player == null:
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
