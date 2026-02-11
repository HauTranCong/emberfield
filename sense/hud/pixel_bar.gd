@tool
class_name PixelBar
extends Control

## Pixel art style health/mana bar component

signal value_changed(current: float, maximum: float)

@export_category("Bar Settings")
@export var bar_type: BarType = BarType.HEALTH:
	set(value):
		bar_type = value
		_update_bar_colors()
		queue_redraw()

@export var current_value: float = 100.0:
	set(value):
		current_value = clampf(value, 0.0, max_value)
		value_changed.emit(current_value, max_value)
		queue_redraw()

@export var max_value: float = 100.0:
	set(value):
		max_value = maxf(value, 1.0)
		current_value = minf(current_value, max_value)
		queue_redraw()

@export var show_text: bool = true:
	set(value):
		show_text = value
		queue_redraw()

enum BarType { HEALTH, MANA }

# Colors for different bar types
var _fill_color: Color
var _fill_highlight: Color
var _fill_shadow: Color
var _bg_color: Color
var _border_color: Color
var _border_highlight: Color
var _border_shadow: Color
var _icon_primary: Color
var _icon_secondary: Color

# Stone frame colors
const STONE_LIGHT := Color(0.65, 0.6, 0.55, 1.0)
const STONE_MID := Color(0.45, 0.42, 0.38, 1.0)
const STONE_DARK := Color(0.3, 0.28, 0.25, 1.0)
const STONE_SHADOW := Color(0.2, 0.18, 0.15, 1.0)

# Bar dimensions
const FRAME_SIZE := 4
const ICON_SIZE := 20
const ICON_OFFSET := 6


func _ready() -> void:
	_update_bar_colors()
	custom_minimum_size = Vector2(200, 28)


func _update_bar_colors() -> void:
	match bar_type:
		BarType.HEALTH:
			_fill_color = Color(0.85, 0.15, 0.1, 1.0)
			_fill_highlight = Color(1.0, 0.4, 0.35, 1.0)
			_fill_shadow = Color(0.5, 0.08, 0.05, 1.0)
			_bg_color = Color(0.15, 0.08, 0.08, 1.0)
			_icon_primary = Color(0.9, 0.15, 0.15, 1.0)
			_icon_secondary = Color(0.6, 0.1, 0.1, 1.0)
		BarType.MANA:
			_fill_color = Color(0.2, 0.4, 0.9, 1.0)
			_fill_highlight = Color(0.4, 0.6, 1.0, 1.0)
			_fill_shadow = Color(0.1, 0.2, 0.5, 1.0)
			_bg_color = Color(0.08, 0.08, 0.18, 1.0)
			_icon_primary = Color(0.3, 0.5, 1.0, 1.0)
			_icon_secondary = Color(0.15, 0.25, 0.6, 1.0)


func _draw() -> void:
	var bar_rect := get_rect()
	bar_rect.position = Vector2.ZERO
	
	# Draw stone frame background
	_draw_stone_frame(bar_rect)
	
	# Calculate inner bar area
	var inner_rect := Rect2(
		bar_rect.position.x + FRAME_SIZE + ICON_SIZE + ICON_OFFSET,
		bar_rect.position.y + FRAME_SIZE,
		bar_rect.size.x - FRAME_SIZE * 2 - ICON_SIZE - ICON_OFFSET - 4,
		bar_rect.size.y - FRAME_SIZE * 2
	)
	
	# Draw bar background
	draw_rect(inner_rect, _bg_color)
	
	# Draw bar fill
	var fill_percent := current_value / max_value if max_value > 0 else 0.0
	var fill_rect := Rect2(
		inner_rect.position.x + 2,
		inner_rect.position.y + 2,
		(inner_rect.size.x - 4) * fill_percent,
		inner_rect.size.y - 4
	)
	
	if fill_rect.size.x > 0:
		# Main fill
		draw_rect(fill_rect, _fill_color)
		
		# Highlight (top part)
		var highlight_rect := Rect2(
			fill_rect.position.x,
			fill_rect.position.y,
			fill_rect.size.x,
			fill_rect.size.y * 0.4
		)
		draw_rect(highlight_rect, _fill_highlight)
		
		# Shadow (bottom part)
		var shadow_rect := Rect2(
			fill_rect.position.x,
			fill_rect.position.y + fill_rect.size.y * 0.7,
			fill_rect.size.x,
			fill_rect.size.y * 0.3
		)
		draw_rect(shadow_rect, _fill_shadow)
	
	# Draw icon
	_draw_icon(Vector2(bar_rect.position.x + FRAME_SIZE + 2, bar_rect.position.y + FRAME_SIZE + 1))
	
	# Draw text
	if show_text:
		_draw_text(inner_rect)


func _draw_stone_frame(rect: Rect2) -> void:
	# Outer shadow
	draw_rect(Rect2(rect.position.x + 1, rect.position.y + 1, rect.size.x, rect.size.y), STONE_SHADOW)
	
	# Main stone background
	draw_rect(rect, STONE_MID)
	
	# Top highlight
	draw_rect(Rect2(rect.position.x, rect.position.y, rect.size.x, 2), STONE_LIGHT)
	draw_rect(Rect2(rect.position.x, rect.position.y, 2, rect.size.y), STONE_LIGHT)
	
	# Bottom shadow
	draw_rect(Rect2(rect.position.x, rect.position.y + rect.size.y - 2, rect.size.x, 2), STONE_DARK)
	draw_rect(Rect2(rect.position.x + rect.size.x - 2, rect.position.y, 2, rect.size.y), STONE_DARK)
	
	# Corner details (pixel art style)
	# Top-left corner highlight
	draw_rect(Rect2(rect.position.x, rect.position.y, 4, 4), STONE_LIGHT)
	draw_rect(Rect2(rect.position.x + 2, rect.position.y + 2, 2, 2), STONE_MID)
	
	# Bottom-right corner shadow
	draw_rect(Rect2(rect.position.x + rect.size.x - 4, rect.position.y + rect.size.y - 4, 4, 4), STONE_DARK)
	draw_rect(Rect2(rect.position.x + rect.size.x - 4, rect.position.y + rect.size.y - 4, 2, 2), STONE_MID)
	
	# Inner border
	var inner := Rect2(
		rect.position.x + FRAME_SIZE - 1,
		rect.position.y + FRAME_SIZE - 1,
		rect.size.x - (FRAME_SIZE - 1) * 2,
		rect.size.y - (FRAME_SIZE - 1) * 2
	)
	draw_rect(inner, STONE_SHADOW, false, 1.0)


func _draw_icon(pos: Vector2) -> void:
	match bar_type:
		BarType.HEALTH:
			_draw_heart(pos)
		BarType.MANA:
			_draw_crystal(pos)


func _draw_heart(pos: Vector2) -> void:
	# Pixel art heart shape
	var pixels := [
		# Row 0 (top)
		Vector2(2, 0), Vector2(3, 0), Vector2(6, 0), Vector2(7, 0),
		# Row 1
		Vector2(1, 1), Vector2(2, 1), Vector2(3, 1), Vector2(4, 1),
		Vector2(5, 1), Vector2(6, 1), Vector2(7, 1), Vector2(8, 1),
		# Row 2
		Vector2(0, 2), Vector2(1, 2), Vector2(2, 2), Vector2(3, 2),
		Vector2(4, 2), Vector2(5, 2), Vector2(6, 2), Vector2(7, 2),
		Vector2(8, 2), Vector2(9, 2),
		# Row 3
		Vector2(0, 3), Vector2(1, 3), Vector2(2, 3), Vector2(3, 3),
		Vector2(4, 3), Vector2(5, 3), Vector2(6, 3), Vector2(7, 3),
		Vector2(8, 3), Vector2(9, 3),
		# Row 4
		Vector2(1, 4), Vector2(2, 4), Vector2(3, 4), Vector2(4, 4),
		Vector2(5, 4), Vector2(6, 4), Vector2(7, 4), Vector2(8, 4),
		# Row 5
		Vector2(2, 5), Vector2(3, 5), Vector2(4, 5), Vector2(5, 5),
		Vector2(6, 5), Vector2(7, 5),
		# Row 6
		Vector2(3, 6), Vector2(4, 6), Vector2(5, 6), Vector2(6, 6),
		# Row 7 (bottom)
		Vector2(4, 7), Vector2(5, 7),
	]
	
	# Highlight pixels (lighter)
	var highlight := [
		Vector2(2, 1), Vector2(3, 1),
		Vector2(1, 2), Vector2(2, 2),
	]
	
	# Draw heart shadow
	for p in pixels:
		draw_rect(Rect2(pos.x + p.x * 1.6 + 1, pos.y + p.y * 1.6 + 1, 2, 2), _icon_secondary)
	
	# Draw main heart
	for p in pixels:
		draw_rect(Rect2(pos.x + p.x * 1.6, pos.y + p.y * 1.6, 2, 2), _icon_primary)
	
	# Draw highlight
	for p in highlight:
		draw_rect(Rect2(pos.x + p.x * 1.6, pos.y + p.y * 1.6, 2, 2), Color(1.0, 0.6, 0.6, 1.0))


func _draw_crystal(pos: Vector2) -> void:
	# Pixel art crystal/gem shape
	var pixels := [
		# Top point
		Vector2(4, 0), Vector2(5, 0),
		# Row 1
		Vector2(3, 1), Vector2(4, 1), Vector2(5, 1), Vector2(6, 1),
		# Row 2
		Vector2(2, 2), Vector2(3, 2), Vector2(4, 2), Vector2(5, 2),
		Vector2(6, 2), Vector2(7, 2),
		# Row 3
		Vector2(1, 3), Vector2(2, 3), Vector2(3, 3), Vector2(4, 3),
		Vector2(5, 3), Vector2(6, 3), Vector2(7, 3), Vector2(8, 3),
		# Row 4
		Vector2(0, 4), Vector2(1, 4), Vector2(2, 4), Vector2(3, 4),
		Vector2(4, 4), Vector2(5, 4), Vector2(6, 4), Vector2(7, 4),
		Vector2(8, 4), Vector2(9, 4),
		# Row 5
		Vector2(1, 5), Vector2(2, 5), Vector2(3, 5), Vector2(4, 5),
		Vector2(5, 5), Vector2(6, 5), Vector2(7, 5), Vector2(8, 5),
		# Row 6
		Vector2(2, 6), Vector2(3, 6), Vector2(4, 6), Vector2(5, 6),
		Vector2(6, 6), Vector2(7, 6),
		# Row 7
		Vector2(3, 7), Vector2(4, 7), Vector2(5, 7), Vector2(6, 7),
		# Bottom point
		Vector2(4, 8), Vector2(5, 8),
	]
	
	# Highlight pixels
	var highlight := [
		Vector2(3, 1), Vector2(4, 1),
		Vector2(2, 2), Vector2(3, 2),
		Vector2(1, 3), Vector2(2, 3),
		Vector2(1, 4), Vector2(2, 4),
	]
	
	# Draw crystal shadow
	for p in pixels:
		draw_rect(Rect2(pos.x + p.x * 1.6 + 1, pos.y + p.y * 1.6 + 1, 2, 2), _icon_secondary)
	
	# Draw main crystal
	for p in pixels:
		draw_rect(Rect2(pos.x + p.x * 1.6, pos.y + p.y * 1.6, 2, 2), _icon_primary)
	
	# Draw highlight
	for p in highlight:
		draw_rect(Rect2(pos.x + p.x * 1.6, pos.y + p.y * 1.6, 2, 2), Color(0.6, 0.8, 1.0, 1.0))


func _draw_text(bar_rect: Rect2) -> void:
	var font := ThemeDB.fallback_font
	var font_size := 11
	
	# Draw label (HP or MP)
	var label_text := "HP" if bar_type == BarType.HEALTH else "MP"
	var label_pos := Vector2(bar_rect.position.x + 4, bar_rect.position.y + bar_rect.size.y / 2 + 4)
	
	# Shadow
	draw_string(font, label_pos + Vector2(1, 1), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.BLACK)
	# Main text
	draw_string(font, label_pos, label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
	
	# Draw value text
	var value_text := "%d / %d" % [int(current_value), int(max_value)]
	var text_width := font.get_string_size(value_text, HORIZONTAL_ALIGNMENT_RIGHT, -1, font_size).x
	var value_pos := Vector2(bar_rect.position.x + bar_rect.size.x - text_width - 4, bar_rect.position.y + bar_rect.size.y / 2 + 4)
	
	# Shadow
	draw_string(font, value_pos + Vector2(1, 1), value_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.BLACK)
	# Main text
	draw_string(font, value_pos, value_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)


## Set both current and max values at once
func set_values(current: float, maximum: float) -> void:
	max_value = maximum
	current_value = current


## Get the current percentage (0.0 - 1.0)
func get_percentage() -> float:
	return current_value / max_value if max_value > 0 else 0.0
