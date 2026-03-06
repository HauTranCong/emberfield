extends CanvasLayer

## Reusable confirmation dialog - modal popup with Yes/No
## Usage: ConfirmDialog.show_confirm("Sell Iron Sword for 50G?", on_yes_callback)

signal confirmed
signal cancelled

var _panel: PanelContainer
var _label: Label
var _yes_btn: Button
var _no_btn: Button
var _dim: ColorRect
var _callback: Callable


func _ready() -> void:
	layer = 101

	_dim = ColorRect.new()
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.color = Color(0, 0, 0, 0.4)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.visible = false
	_dim.gui_input.connect(_on_dim_input)
	add_child(_dim)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.offset_left = -180.0
	_panel.offset_right = 180.0
	_panel.offset_top = -60.0
	_panel.offset_bottom = 60.0
	_panel.visible = false

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.11, 0.15, 0.95)
	style.border_color = Color(0.5, 0.45, 0.35, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	_panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	_panel.add_child(vbox)

	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(_label)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_row)

	_yes_btn = Button.new()
	_yes_btn.text = "Yes"
	_yes_btn.custom_minimum_size = Vector2(80, 32)
	_yes_btn.pressed.connect(_on_yes)
	btn_row.add_child(_yes_btn)

	_no_btn = Button.new()
	_no_btn.text = "No"
	_no_btn.custom_minimum_size = Vector2(80, 32)
	_no_btn.pressed.connect(_on_no)
	btn_row.add_child(_no_btn)

	add_child(_panel)


func show_confirm(message: String, on_confirmed: Callable = Callable()) -> void:
	_label.text = message
	_callback = on_confirmed
	_dim.visible = true
	_panel.visible = true
	_no_btn.grab_focus()


func _hide_dialog() -> void:
	_dim.visible = false
	_panel.visible = false
	_callback = Callable()


func _on_yes() -> void:
	var cb := _callback
	_hide_dialog()
	confirmed.emit()
	if cb.is_valid():
		cb.call()


func _on_no() -> void:
	_hide_dialog()
	cancelled.emit()


func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_on_no()
