class_name DungeonTileStructure
extends RefCounted
## Library of pre-defined structures from your tileset atlases
##
## Each structure = a rectangle region in your tileset PNG
## Atlas coordinates come from:
##   WallLayer  → TX Tileset Wall.png        (source_id = 0)
##   FloorLayer → TX Tileset Stone Ground.png (source_id = 1)
##
## To find coordinates: open TileSet in Godot editor, hover over tiles
## to see their atlas position (column, row)


# ── WALL STRUCTURES (from TX Tileset Wall.png) ──────────────────────

## Large wall block: atlas (2,2) to (7,9) = 6x8 tiles
static func wall_block_large() -> TilesetStructure:
	return TilesetStructure.new(TilesetStructure.Layer.WALL, Vector2i(2, 2), Vector2i(7, 9))

## Wall panel: atlas (9,2) to (16,8) = 8x7 tiles
static func wall_panel() -> TilesetStructure:
	return TilesetStructure.new(TilesetStructure.Layer.WALL, Vector2i(9, 2), Vector2i(16, 8))

## Small pillar: atlas (24,2) to (27,9) = 4x8 tiles
static func pillar() -> TilesetStructure:
	return TilesetStructure.new(TilesetStructure.Layer.WALL, Vector2i(24, 2), Vector2i(27, 9))

## Wide low wall: atlas (2,12) to (9,15) = 8x4 tiles
static func low_wall() -> TilesetStructure:
	return TilesetStructure.new(TilesetStructure.Layer.WALL, Vector2i(2, 12), Vector2i(9, 15))

## Small block A: atlas (2,18) to (5,21) = 4x4 tiles
static func small_block_a() -> TilesetStructure:
	return TilesetStructure.new(TilesetStructure.Layer.WALL, Vector2i(2, 18), Vector2i(5, 21))

## Small block B: atlas (8,18) to (11,21) = 4x4 tiles
static func small_block_b() -> TilesetStructure:
	return TilesetStructure.new(TilesetStructure.Layer.WALL, Vector2i(8, 18), Vector2i(11, 21))

## Button/switch: atlas (12,12) to (13,13) = 2x2 tiles
static func button() -> TilesetStructure:
	return TilesetStructure.new(TilesetStructure.Layer.WALL, Vector2i(12, 12), Vector2i(13, 13))


# ── FLOOR STRUCTURES (from TX Tileset Stone Ground.png) ─────────────

## Floor patch: atlas (0,0) to (3,3) = 4x4 tiles
static func floor_patch() -> TilesetStructure:
	return TilesetStructure.new(TilesetStructure.Layer.FLOOR, Vector2i(0, 0), Vector2i(3, 3))


# ── HELPER: Get random wall structure ───────────────────────────────

static func get_random_wall_structure() -> TilesetStructure:
	var choices: Array[Callable] = [
		wall_block_large,
		# wall_panel,
		# pillar,
		# low_wall,
		# small_block_a,
		# small_block_b,
	]
	return choices.pick_random().call()