extends Control

signal play_online_requested

@onready var menu_buttons: VBoxContainer = $CenterContainer/VBoxContainer/MenuButtons
@onready var play_online_button: Button = $CenterContainer/VBoxContainer/MenuButtons/PlayOnlineButton
@onready var settings_button: Button = $CenterContainer/VBoxContainer/MenuButtons/SettingsButton
@onready var quit_button: Button = $CenterContainer/VBoxContainer/MenuButtons/QuitButton
@onready var settings_dialog: AcceptDialog = $SettingsDialog

#region Private API

func _ready() -> void:
	_wire_buttons()
	_prepare_intro()
	await _play_intro_animation()
	_show_menu()

func _wire_buttons() -> void:
	play_online_button.pressed.connect(_on_play_online_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _prepare_intro() -> void:
	menu_buttons.visible = false

func _play_intro_animation() -> void:
	var tween := create_tween()
	tween.tween_interval(0.15)
	await tween.finished

func _show_menu() -> void:
	menu_buttons.visible = true
	play_online_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if not menu_buttons.visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_W:
			_focus_previous_button()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_S:
			_focus_next_button()
			get_viewport().set_input_as_handled()

func _focusable_buttons() -> Array[Button]:
	var buttons: Array[Button] = []
	for child in menu_buttons.get_children():
		if child is Button and child.visible and not child.disabled:
			buttons.append(child)
	return buttons

func _focus_next_button() -> void:
	var buttons := _focusable_buttons()
	if buttons.is_empty():
		return
	var current := get_viewport().gui_get_focus_owner()
	var index := buttons.find(current)
	var next_index := 0 if index == -1 else (index + 1) % buttons.size()
	buttons[next_index].grab_focus()

func _focus_previous_button() -> void:
	var buttons := _focusable_buttons()
	if buttons.is_empty():
		return
	var current := get_viewport().gui_get_focus_owner()
	var index := buttons.find(current)
	var previous_index := buttons.size() - 1 if index == -1 else (index - 1 + buttons.size()) % buttons.size()
	buttons[previous_index].grab_focus()

func _on_play_online_pressed() -> void:
	emit_signal("play_online_requested")

func _on_settings_pressed() -> void:
	settings_dialog.dialog_text = "Settings UI is coming soon."
	settings_dialog.popup_centered()

func _on_quit_pressed() -> void:
	get_tree().quit()

#endregion