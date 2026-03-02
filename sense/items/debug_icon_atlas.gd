@tool
extends Control

## Debug tool để xem sprite sheet và xác định row/col cho icons
## Mở scene này và chạy để xem vị trí các icons
## SCROLL để xem toàn bộ sprite sheet

@export_range(8, 64) var icon_size: int = 32  # Thay đổi trong Inspector nếu cần
@export_range(1, 4) var zoom: int = 2

@export var sprite_sheet_path: String = "res://assets/items/item_icons.png"
@export_range(1, 64) var columns: int = 16
@export var show_grid: bool = true
@export var show_numbers: bool = true
@export var highlight_row: int = -1
@export var highlight_col: int = -1

var sprite_sheet: Texture2D
var hovered_row: int = -1
var hovered_col: int = -1
var info_label: Label = null

func _ready() -> void:
	_load_sprite_sheet()
	mouse_default_cursor_shape = Control.CURSOR_CROSS
	
	# Find info label in parent
	var parent := get_parent()
	if parent:
		var root := parent.get_parent()
		if root:
			info_label = root.get_node_or_null("%InfoLabel")


func _load_sprite_sheet() -> void:
	if ResourceLoader.exists(sprite_sheet_path):
		sprite_sheet = load(sprite_sheet_path)
		if sprite_sheet:
			# Set minimum size so ScrollContainer knows how big we are
			custom_minimum_size = Vector2(
				sprite_sheet.get_width() * zoom + 50,  # Extra space for row numbers
				sprite_sheet.get_height() * zoom + 80  # Extra space for col numbers + info
			)
			queue_redraw()
			var rows := ceili(sprite_sheet.get_height() / float(icon_size))
			print("[DebugAtlas] Loaded sprite sheet: %dx%d pixels" % [sprite_sheet.get_width(), sprite_sheet.get_height()])
			print("[DebugAtlas] Grid: %d columns, %d rows" % [columns, rows])
			print("[DebugAtlas] Total icons: %d" % [columns * rows])


func _draw() -> void:
	if sprite_sheet == null:
		draw_string(ThemeDB.fallback_font, Vector2(10, 30), "No sprite sheet loaded!", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.RED)
		draw_string(ThemeDB.fallback_font, Vector2(10, 50), "Set sprite_sheet_path in Inspector", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.YELLOW)
		return
	
	var sheet_width := sprite_sheet.get_width()
	var sheet_height := sprite_sheet.get_height()
	var rows := ceili(sheet_height / float(icon_size))
	
	# Offset to make room for row/col numbers
	var offset := Vector2(30, 20)
	
	# Draw sprite sheet (zoomed) with offset
	draw_texture_rect(sprite_sheet, Rect2(offset.x, offset.y, sheet_width * zoom, sheet_height * zoom), false)
	
	# Draw grid
	if show_grid:
		var grid_color := Color(0.3, 0.3, 0.8, 0.5)
		
		# Vertical lines
		for col in range(columns + 1):
			var x := offset.x + col * icon_size * zoom
			draw_line(Vector2(x, offset.y), Vector2(x, offset.y + sheet_height * zoom), grid_color, 1.0)
		
		# Horizontal lines
		for row in range(rows + 1):
			var y := offset.y + row * icon_size * zoom
			draw_line(Vector2(offset.x, y), Vector2(offset.x + sheet_width * zoom, y), grid_color, 1.0)
	
	# Draw row/col numbers
	if show_numbers:
		var font := ThemeDB.fallback_font
		var font_size := 10
		
		# Column numbers (top)
		for col in range(columns):
			var x := offset.x + col * icon_size * zoom + 4
			draw_string(font, Vector2(x, offset.y - 5), str(col), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.CYAN)
		
		# Row numbers (left)
		for row in range(rows):
			var y := offset.y + row * icon_size * zoom + 14
			draw_string(font, Vector2(2, y), str(row), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.CYAN)
	
	# Highlight hovered cell
	if hovered_row >= 0 and hovered_col >= 0:
		var rect := Rect2(
			offset.x + hovered_col * icon_size * zoom,
			offset.y + hovered_row * icon_size * zoom,
			icon_size * zoom,
			icon_size * zoom
		)
		draw_rect(rect, Color.YELLOW, false, 3.0)
	
	# Highlight specific cell from Inspector
	if highlight_row >= 0 and highlight_col >= 0:
		var rect := Rect2(
			offset.x + highlight_col * icon_size * zoom,
			offset.y + highlight_row * icon_size * zoom,
			icon_size * zoom,
			icon_size * zoom
		)
		draw_rect(rect, Color.RED, false, 3.0)


func _gui_input(event: InputEvent) -> void:
	var offset := Vector2(30, 20)
	
	if event is InputEventMouseMotion:
		var pos: Vector2 = event.position - offset
		hovered_col = int(pos.x / (icon_size * zoom))
		hovered_row = int(pos.y / (icon_size * zoom))
		
		# Bounds check
		if hovered_col < 0 or hovered_row < 0:
			hovered_col = -1
			hovered_row = -1
		
		# Update info label
		if info_label and hovered_row >= 0 and hovered_col >= 0:
			var index := hovered_row * columns + hovered_col
			info_label.text = 'Row: %d, Col: %d | Index: %d | Code: Vector2i(%d, %d)' % [hovered_row, hovered_col, index, hovered_row, hovered_col]
		
		queue_redraw()
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if hovered_row >= 0 and hovered_col >= 0:
			var code := '"item_name": Vector2i(%d, %d),' % [hovered_row, hovered_col]
			DisplayServer.clipboard_set(code)
			print("Copied to clipboard: ", code)
			print("Use in ICONS dictionary:")
			print('  "%s": Vector2i(%d, %d),' % ["your_item_name", hovered_row, hovered_col])
			if info_label:
				info_label.text = "COPIED: " + code


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		hovered_row = -1
		hovered_col = -1
		queue_redraw()
