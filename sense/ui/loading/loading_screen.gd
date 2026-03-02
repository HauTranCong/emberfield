extends CanvasLayer
## Loading screen shown between title and gameplay.
## Displays a status label and a progress bar (indeterminate style).

signal loading_finished

@onready var status_label: Label = $CenterContainer/VBoxContainer/StatusLabel
@onready var progress_bar: ProgressBar = $CenterContainer/VBoxContainer/ProgressBar

var _tween: Tween

func _ready() -> void:
	visible = false

## Show loading screen and begin the backend auth + data pipeline.
func start_loading() -> void:
	visible = true
	_set_status("Connecting to server...")
	_start_progress_animation()
	_run_pipeline()

func _run_pipeline() -> void:
	# Step 1: Authenticate
	_set_status("Authenticating...")
	BackendService.authenticate("player", "password")
	var auth_result: Array = await BackendService.auth_completed
	var auth_ok: bool = auth_result[0]
	var auth_msg: String = auth_result[1]

	if not auth_ok:
		_set_status("Login failed: %s" % auth_msg)
		_stop_progress_animation()
		# Let the player see the error, then go back
		await get_tree().create_timer(2.0).timeout
		visible = false
		return

	_set_status(auth_msg)

	# Step 2: Load user data
	_set_status("Loading world data...")
	BackendService.load_user_data()
	var data_ok: bool = await BackendService.user_data_loaded

	if not data_ok:
		_set_status("Failed to load game data.")
		_stop_progress_animation()
		await get_tree().create_timer(2.0).timeout
		visible = false
		return

	_set_status("Entering world...")
	await get_tree().create_timer(0.4).timeout

	_stop_progress_animation()
	visible = false
	loading_finished.emit()

func _set_status(text: String) -> void:
	if status_label:
		status_label.text = text

func _start_progress_animation() -> void:
	if not progress_bar:
		return
	progress_bar.value = 0.0
	_tween = create_tween().set_loops()
	_tween.tween_property(progress_bar, "value", 100.0, 1.5)
	_tween.tween_property(progress_bar, "value", 0.0, 1.5)

func _stop_progress_animation() -> void:
	if _tween:
		_tween.kill()
		_tween = null
	if progress_bar:
		progress_bar.value = 100.0
