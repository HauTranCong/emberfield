class_name DungeonGenerator
extends RefCounted
## Simple Binding of Isaac style dungeon generator
##
## Grid-based: mỗi cell trong grid là 1 room
## Rooms connect qua doors ở 4 cạnh
##
##     [2]
##      |
## [1]-[0]-[3]
##      |
##     [4]

enum RoomType { START, NORMAL, BOSS, TREASURE }
enum Dir { UP, DOWN, LEFT, RIGHT }

## Room data structure
class Room:
	var pos: Vector2i          # Grid position
	var type: RoomType         # Room type
	var doors: Array[Dir] = [] # Connected directions
	
	func _init(p: Vector2i, t: RoomType = RoomType.NORMAL):
		pos = p
		type = t

## Generated rooms: grid_pos -> Room
var rooms: Dictionary = {}

## Configuration
var num_rooms: int = 8


## Generate dungeon layout
func generate() -> void:
	rooms.clear()
	
	# 1. Create start room at center
	var start = Vector2i(5, 5)
	rooms[start] = Room.new(start, RoomType.START)
	
	# 2. Expand from start using random walk
	var to_expand: Array[Vector2i] = [start]
	
	while rooms.size() < num_rooms and to_expand.size() > 0:
		var current = to_expand.pick_random()
		var dir = _get_random_empty_direction(current)
		
		if dir == -1:
			to_expand.erase(current)
			continue
		
		# Create new room
		var new_pos = current + _dir_offset(dir)
		rooms[new_pos] = Room.new(new_pos)
		
		# Connect rooms
		rooms[current].doors.append(dir)
		rooms[new_pos].doors.append(_opposite(dir))
		
		to_expand.append(new_pos)
	
	# 3. Assign special rooms to dead-ends
	_assign_special_rooms()
	
	print("Generated %d rooms" % rooms.size())


## Get random direction that leads to empty cell
func _get_random_empty_direction(pos: Vector2i) -> int:
	var valid: Array[int] = []
	for dir in [Dir.UP, Dir.DOWN, Dir.LEFT, Dir.RIGHT]:
		var next = pos + _dir_offset(dir)
		if not rooms.has(next):
			valid.append(dir)
	
	if valid.is_empty():
		return -1
	return valid.pick_random()


## Direction to grid offset
func _dir_offset(dir: int) -> Vector2i:
	match dir:
		Dir.UP: return Vector2i(0, -1)
		Dir.DOWN: return Vector2i(0, 1)
		Dir.LEFT: return Vector2i(-1, 0)
		Dir.RIGHT: return Vector2i(1, 0)
	return Vector2i.ZERO


## Opposite direction
func _opposite(dir: int) -> int:
	match dir:
		Dir.UP: return Dir.DOWN
		Dir.DOWN: return Dir.UP
		Dir.LEFT: return Dir.RIGHT
		Dir.RIGHT: return Dir.LEFT
	return dir


## Assign boss/treasure to dead-end rooms
func _assign_special_rooms() -> void:
	var dead_ends: Array[Vector2i] = []
	var start_pos: Vector2i
	
	for pos in rooms:
		var room = rooms[pos] as Room
		if room.type == RoomType.START:
			start_pos = pos
		elif room.doors.size() == 1:
			dead_ends.append(pos)
	
	if dead_ends.is_empty():
		return
	
	# Furthest dead-end = boss
	var boss_pos = dead_ends[0]
	var max_dist = 0.0
	for pos in dead_ends:
		var dist = Vector2(pos - start_pos).length()
		if dist > max_dist:
			max_dist = dist
			boss_pos = pos
	
	rooms[boss_pos].type = RoomType.BOSS
	dead_ends.erase(boss_pos)
	
	# Random dead-end = treasure
	if dead_ends.size() > 0:
		var treasure_pos = dead_ends.pick_random()
		rooms[treasure_pos].type = RoomType.TREASURE


## Get start room position
func get_start_pos() -> Vector2i:
	for pos in rooms:
		if rooms[pos].type == RoomType.START:
			return pos
	return Vector2i(5, 5)


## Debug print
func print_map() -> void:
	print("=== Dungeon Map ===")
	for pos in rooms:
		var room = rooms[pos] as Room
		var type_name = ["START", "NORMAL", "BOSS", "TREASURE"][room.type]
		print("%s: %s, doors: %s" % [pos, type_name, room.doors])
