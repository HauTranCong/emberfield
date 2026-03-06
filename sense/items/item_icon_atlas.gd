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

## Default icon position for items without defined icons
const DEFAULT_ICON := Vector2i(0, 2)  # bag icon as default

## Predefined icon positions (row, col) - customize based on your sheet
const ICONS := {
	# === DEFAULT ===
	"default": Vector2i(0, 2),  # bag icon
	
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
	
	"bone": Vector2i(17, 9),

	"iron_ore": Vector2i(17, 1),
	
	# === ROW 3: Weapons (Swords) ===
	"sword_iron": Vector2i(5, 1),
	
	# === ROW 4: Armor/Helmets ===
	"leather_armor": Vector2i(7, 5),
	
	# === ROW 6: Potions ===
	"potion_red": Vector2i(9, 0),
	
	# === CURRENCY ===
	"gold_coin": Vector2i(12, 7),

	# === SEGMENT ITEMS (placeholder positions — update when pixel art is created) ===
	"fire_shard": Vector2i(1, 2),          # Reuse gem_green slot for now
	"frost_shard": Vector2i(1, 2),         # Reuse gem_green slot
	"power_fragment": Vector2i(1, 2),      # Reuse gem_green slot
	"spirit_essence": Vector2i(1, 2),      # Reuse gem_green slot
	"venom_gland": Vector2i(1, 2),         # Reuse gem_green slot
	"herb_segment": Vector2i(1, 2),        # Reuse gem_green slot
	"inferno_shard": Vector2i(1, 2),       # Reuse gem_green slot
	"blizzard_shard": Vector2i(1, 2),      # Reuse gem_green slot
	"greater_power_fragment": Vector2i(1, 2),  # Reuse gem_green slot
	"hellfire_shard": Vector2i(1, 2),      # Reuse gem_green slot

	# === AUGMENT ITEMS (placeholder positions — update when pixel art is created) ===
	"flame_augment": Vector2i(0, 1),       # Reuse scroll slot
	"frost_augment": Vector2i(0, 1),       # Reuse scroll slot
	"power_augment": Vector2i(0, 1),       # Reuse scroll slot
	"lifesteal_augment": Vector2i(0, 1),   # Reuse scroll slot
	"crit_augment": Vector2i(0, 1),        # Reuse scroll slot
	"whirlwind_augment": Vector2i(0, 1),   # Reuse scroll slot
	"shield_bash_augment": Vector2i(0, 1), # Reuse scroll slot

	# === TIMED BUFF ITEMS (placeholder positions — update when pixel art is created) ===
	"vitality_tonic": Vector2i(9, 0),      # Reuse potion_red slot
	"speed_elixir": Vector2i(9, 1),        # Reuse blue potion slot
	"defense_brew": Vector2i(9, 0),        # Reuse potion_red slot
}


## Get a predefined icon by name (returns default if not found)
static func get_named_icon(icon_name: String) -> AtlasTexture:
	if not ICONS.has(icon_name):
		push_warning("ItemIconAtlas: Unknown icon name '%s', using default" % icon_name)
		return get_icon(DEFAULT_ICON.x, DEFAULT_ICON.y)
	
	var pos: Vector2i = ICONS[icon_name]
	return get_icon(pos.x, pos.y)


## Get the default icon
static func get_default_icon() -> AtlasTexture:
	return get_icon(DEFAULT_ICON.x, DEFAULT_ICON.y)


## Helper: Print all available icon names
static func get_available_icons() -> Array[String]:
	var names: Array[String] = []
	for key in ICONS.keys():
		names.append(key)
	return names
