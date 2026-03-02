extends Control
class_name DungeonMinimap
## Dungeon room-layout minimap for HUD
##
## Draws the dungeon room grid showing:
## - All generated rooms
## - Room types (color-coded)
## - Current room highlight
## - Connections between rooms

const CELL_SIZE := 14
const CELL_GAP := 2
const CONNECTION_WIDTH := 2.0

## Dungeon data
var rooms: Dictionary = {} ## grid_pos → room data
var current_room_pos: Vector2i = Vector2i.ZERO
var min_grid: Vector2i = Vector2i.ZERO
var max_grid: Vector2i = Vector2i.ZERO

## Room type colors
const ROOM_COLORS := {
	0: Color(0.3, 0.7, 0.3), # START - Green
	1: Color(0.4, 0.4, 0.5), # NORMAL - Gray
	2: Color(0.8, 0.2, 0.2), # BOSS - Red
	3: Color(0.9, 0.8, 0.2), # TREASURE - Gold
}

## Direction offsets
const DIR_OFFSETS := {
	0: Vector2i(0, -1), # UP
	1: Vector2i(0, 1), # DOWN
	2: Vector2i(-1, 0), # LEFT
	3: Vector2i(1, 0), # RIGHT
}


func _ready() -> void:
	# Start hidden
	visible = false


## Update dungeon data and redraw
func update_dungeon(dungeon_rooms: Dictionary, current_pos: Vector2i) -> void:
	rooms = dungeon_rooms
	current_room_pos = current_pos
	_calculate_bounds()
	queue_redraw()


## Update only current room position
func update_current_room(pos: Vector2i) -> void:
	current_room_pos = pos
	queue_redraw()


## Show the dungeon minimap
func show_minimap() -> void:
	visible = true
	queue_redraw()


## Hide the dungeon minimap
func hide_minimap() -> void:
	visible = false


## Clear dungeon data so next dungeon visit starts fresh
func clear_dungeon() -> void:
	rooms.clear()
	current_room_pos = Vector2i.ZERO
	min_grid = Vector2i.ZERO
	max_grid = Vector2i.ZERO
	queue_redraw()


func _calculate_bounds() -> void:
	if rooms.is_empty():
		return
	
	min_grid = Vector2i(999, 999)
	max_grid = Vector2i(-999, -999)
	
	for pos in rooms:
		min_grid.x = mini(min_grid.x, pos.x)
		min_grid.y = mini(min_grid.y, pos.y)
		max_grid.x = maxi(max_grid.x, pos.x)
		max_grid.y = maxi(max_grid.y, pos.y)


func _draw() -> void:
	if rooms.is_empty():
		return
	
	var grid_width = max_grid.x - min_grid.x + 1
	var grid_height = max_grid.y - min_grid.y + 1
	
	# Calculate centering offset
	var total_width = grid_width * (CELL_SIZE + CELL_GAP) - CELL_GAP
	var total_height = grid_height * (CELL_SIZE + CELL_GAP) - CELL_GAP
	var offset = Vector2(
		(size.x - total_width) / 2.0,
		(size.y - total_height) / 2.0
	)
	
	# Draw each room
	for pos in rooms:
		var room = rooms[pos]
		var cell_pos = offset + Vector2(
			(pos.x - min_grid.x) * (CELL_SIZE + CELL_GAP),
			(pos.y - min_grid.y) * (CELL_SIZE + CELL_GAP)
		)
		
		var cell_rect = Rect2(cell_pos, Vector2(CELL_SIZE, CELL_SIZE))
		
		# Get room type color
		var room_type: int = room.type if room is Object and "type" in room else 1
		var color = ROOM_COLORS.get(room_type, ROOM_COLORS[1])
		
		# Highlight current room
		if pos == current_room_pos:
			draw_rect(cell_rect.grow(2), Color.WHITE)
		
		# Draw room
		draw_rect(cell_rect, color)
		
		# Draw connections
		_draw_connections(pos, room, cell_pos)


func _draw_connections(_pos: Vector2i, room, cell_pos: Vector2) -> void:
	var center = cell_pos + Vector2(CELL_SIZE / 2.0, CELL_SIZE / 2.0)
	
	# Get doors array
	var doors: Array = []
	if room is Object and "doors" in room:
		doors = room.doors
	
	for dir in doors:
		var dir_offset = DIR_OFFSETS.get(dir, Vector2i.ZERO)
		var line_end = center + Vector2(dir_offset) * (CELL_SIZE + CELL_GAP) * 0.5
		draw_line(center, line_end, Color(0.6, 0.6, 0.6), CONNECTION_WIDTH)
