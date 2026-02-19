class_name ItemIconAtlas
extends Resource

## Item Icon Atlas - Extract individual icons from a sprite sheet
##
## ╔═══════════════════════════════════════════════════════════════════════╗
## ║                         SPRITE SHEET LAYOUT                           ║
## ╠═══════════════════════════════════════════════════════════════════════╣
## ║                                                                       ║
## ║  Frame index calculation:                                             ║
## ║  index = row * columns + column                                       ║
## ║                                                                       ║
## ║  Example (16 columns):                                                ║
## ║  ┌────┬────┬────┬────┬────┬─────┐                                    ║
## ║  │ 0  │ 1  │ 2  │ 3  │ 4  │ ... │  Row 0                             ║
## ║  ├────┼────┼────┼────┼────┼─────┤                                    ║
## ║  │ 16 │ 17 │ 18 │ 19 │ 20 │ ... │  Row 1                             ║
## ║  ├────┼────┼────┼────┼────┼─────┤                                    ║
## ║  │ 32 │ 33 │ 34 │ 35 │ 36 │ ... │  Row 2                             ║
## ║  └────┴────┴────┴────┴────┴─────┘                                    ║
## ║                                                                       ║
## ║  Usage:                                                               ║
## ║  var icon = ItemIconAtlas.get_icon(5, 3)  # row 5, col 3             ║
## ║  var icon = ItemIconAtlas.get_icon_by_index(83)                      ║
## ║                                                                       ║
## ╚═══════════════════════════════════════════════════════════════════════╝

## The sprite sheet texture
static var sprite_sheet: Texture2D = null

## Icon size in pixels
static var icon_size := Vector2i(16, 16)

## Number of columns in the sprite sheet
static var columns: int = 16

## Number of rows in the sprite sheet  
static var rows: int = 30

## Cache for created AtlasTextures
static var _icon_cache: Dictionary = {}


## Initialize the atlas with a sprite sheet
static func init(sheet: Texture2D, size: Vector2i = Vector2i(16, 16), cols: int = 16) -> void:
	sprite_sheet = sheet
	icon_size = size
	columns = cols
	if sheet:
		rows = ceili(sheet.get_height() / float(size.y))
	_icon_cache.clear()


## Get icon by row and column
static func get_icon(row: int, col: int) -> AtlasTexture:
	if sprite_sheet == null:
		push_error("ItemIconAtlas: sprite_sheet not initialized! Call init() first.")
		return null
	
	var key := "%d_%d" % [row, col]
	if _icon_cache.has(key):
		return _icon_cache[key]
	
	var atlas := AtlasTexture.new()
	atlas.atlas = sprite_sheet
	atlas.region = Rect2(
		col * icon_size.x,
		row * icon_size.y,
		icon_size.x,
		icon_size.y
	)
	
	_icon_cache[key] = atlas
	return atlas


## Get icon by linear index (left to right, top to bottom)
static func get_icon_by_index(index: int) -> AtlasTexture:
	var row := index / columns
	var col := index % columns
	return get_icon(row, col)


## Convert row, col to index
static func to_index(row: int, col: int) -> int:
	return row * columns + col


## Convert index to row, col
static func to_row_col(index: int) -> Vector2i:
	return Vector2i(index / columns, index % columns)


## ═══════════════════════════════════════════════════════════════════════════
## PREDEFINED ICON INDICES (Update these based on your sprite sheet layout)
## ═══════════════════════════════════════════════════════════════════════════
##
## Sprite sheet: 512x867 pixels, 32x32 icons, 16 columns
## Đếm từ 0: Row 0 = hàng đầu tiên, Col 0 = cột đầu tiên
##
## ┌─────────────────────────────────────────────────────────────────────────┐
## │  Col:  0    1    2    3    4    5    6    7    8    9   10   11  ...   │
## │  Row 0: helmet scroll bag  heart...                                    │
## │  Row 1: arrow  boot  gem   cape ...                                    │
## │  Row 2: bag    ball  bone  flask...                                    │
## │  Row 3: sword  mace  axe   wand ...                                    │
## │  ...                                                                   │
## └─────────────────────────────────────────────────────────────────────────┘

## Predefined icon positions (row, col) - customize based on your sheet
const ICONS := {
	# === ROW 0: Status/Misc ===
	"helmet_horned": Vector2i(0, 0),
	"scroll": Vector2i(0, 1),
	"bag": Vector2i(0, 2),
	"heart": Vector2i(0, 4),
	"gamepad": Vector2i(0, 5),
	"skull": Vector2i(0, 8),
	"brain": Vector2i(0, 6),
	
	# === ROW 1: Arrows/Misc ===
	"arrow": Vector2i(1, 0),
	"boot_green": Vector2i(1, 1),
	"gem_green": Vector2i(1, 2),
	"cape_red": Vector2i(1, 3),
	"cape_blue": Vector2i(1, 4),
	
	"iron_ore": Vector2i(17, 1),
	
	# === ROW 3: Weapons (Swords) ===
	"sword_iron": Vector2i(5, 1),
	
	# === ROW 4: Armor/Helmets ===
	"leather_armor": Vector2i(7, 5),
	
	# === ROW 6: Potions ===
	"potion_red": Vector2i(9, 0),
	
	# === CURRENCY ===
	"gold_coin": Vector2i(12, 7),
}


## Get a predefined icon by name
static func get_named_icon(icon_name: String) -> AtlasTexture:
	if not ICONS.has(icon_name):
		push_warning("ItemIconAtlas: Unknown icon name '%s'" % icon_name)
		return null
	
	var pos: Vector2i = ICONS[icon_name]
	return get_icon(pos.x, pos.y)


## Helper: Print all available icon names
static func get_available_icons() -> Array[String]:
	var names: Array[String] = []
	for key in ICONS.keys():
		names.append(key)
	return names
