extends CanvasLayer

## Global notification manager - shows toast-style messages from anywhere
## Usage: NotificationManager.show_notification("Message", NotificationManager.Type.SUCCESS)

enum Type { INFO, SUCCESS, ERROR, WARNING }

const MAX_VISIBLE := 5
const DEFAULT_DURATION := 2.5

var _container: VBoxContainer


func _ready() -> void:
	layer = 100
	_container = VBoxContainer.new()
	_container.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_container.offset_top = 10.0
	_container.offset_left = 300.0
	_container.offset_right = -300.0
	_container.add_theme_constant_override("separation", 4)
	_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_container)


func show_notification(text: String, type: Type = Type.INFO, duration: float = DEFAULT_DURATION) -> void:
	# Remove oldest if at max
	if _container.get_child_count() >= MAX_VISIBLE:
		var oldest := _container.get_child(0)
		oldest.queue_free()

	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(6)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0

	match type:
		Type.SUCCESS:
			style.bg_color = Color(0.1, 0.4, 0.1, 0.9)
			style.border_color = Color(0.2, 0.7, 0.2, 1.0)
		Type.ERROR:
			style.bg_color = Color(0.5, 0.1, 0.1, 0.9)
			style.border_color = Color(0.8, 0.2, 0.2, 1.0)
		Type.WARNING:
			style.bg_color = Color(0.5, 0.4, 0.1, 0.9)
			style.border_color = Color(0.8, 0.7, 0.2, 1.0)
		_:
			style.bg_color = Color(0.15, 0.15, 0.2, 0.9)
			style.border_color = Color(0.4, 0.4, 0.5, 1.0)

	style.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 14)
	panel.add_child(label)

	panel.modulate.a = 0.0
	_container.add_child(panel)

	var tween := create_tween()
	# Fade in
	tween.tween_property(panel, "modulate:a", 1.0, 0.2)
	# Wait
	tween.tween_interval(duration)
	# Fade out
	tween.tween_property(panel, "modulate:a", 0.0, 0.3)
	tween.tween_callback(panel.queue_free)


func show_success(text: String) -> void:
	show_notification(text, Type.SUCCESS)


func show_error(text: String) -> void:
	show_notification(text, Type.ERROR)


func show_warning(text: String) -> void:
	show_notification(text, Type.WARNING)


func show_info(text: String) -> void:
	show_notification(text, Type.INFO)
