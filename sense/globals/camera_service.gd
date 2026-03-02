extends Node
## Global Camera Service - Centralizes all camera management
##
## Usage:
##   CameraService.set_follow_target(player)
##   CameraService.set_mode(CameraService.Mode.FOLLOW)
##   CameraService.set_mode(CameraService.Mode.STATIC, room_center)
##
## Camera settings are defined here as single source of truth

## Camera modes
enum Mode {
	FOLLOW,     ## Camera follows target (default for town)
	STATIC,     ## Camera stays at fixed position (optional for rooms)
	ROOM,       ## Camera follows but clamped to room bounds
}

## === CAMERA SETTINGS (Single Source of Truth) ===
const DEFAULT_ZOOM := Vector2(2, 2)
const POSITION_SMOOTHING_ENABLED := true
const POSITION_SMOOTHING_SPEED := 10.0

## Internal state
var _camera: Camera2D = null
var _target: Node2D = null
var _mode: Mode = Mode.FOLLOW
var _static_position: Vector2 = Vector2.ZERO
var _room_bounds: Rect2 = Rect2()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(_delta: float) -> void:
	if _camera == null or not _camera.enabled:
		return
	
	match _mode:
		Mode.FOLLOW:
			_update_follow()
		Mode.STATIC:
			_camera.global_position = _static_position
		Mode.ROOM:
			_update_room_follow()


func _update_follow() -> void:
	if _target == null or not is_instance_valid(_target):
		return
	_camera.global_position = _target.global_position


func _update_room_follow() -> void:
	if _target == null or not is_instance_valid(_target):
		return
	
	var target_pos = _target.global_position
	
	# Clamp to room bounds if set
	if _room_bounds.size != Vector2.ZERO:
		var half_view = get_viewport().get_visible_rect().size / _camera.zoom / 2.0
		target_pos.x = clampf(target_pos.x, _room_bounds.position.x + half_view.x, _room_bounds.end.x - half_view.x)
		target_pos.y = clampf(target_pos.y, _room_bounds.position.y + half_view.y, _room_bounds.end.y - half_view.y)
	
	_camera.global_position = target_pos


#region Public API

## Initialize with a camera node (call this when camera changes)
func set_camera(cam: Camera2D) -> void:
	_camera = cam
	if _camera:
		_apply_default_settings()


## Set the target to follow
func set_follow_target(target: Node2D) -> void:
	_target = target


## Set camera mode
func set_mode(mode: Mode, position: Vector2 = Vector2.ZERO) -> void:
	_mode = mode
	if mode == Mode.STATIC:
		_static_position = position


## Set room bounds for ROOM mode
func set_room_bounds(bounds: Rect2) -> void:
	_room_bounds = bounds


## Clear room bounds
func clear_room_bounds() -> void:
	_room_bounds = Rect2()


## Get current camera
func get_camera() -> Camera2D:
	return _camera


## Get current mode
func get_mode() -> Mode:
	return _mode


## Apply default settings to current camera
func _apply_default_settings() -> void:
	if _camera == null:
		return
	_camera.zoom = DEFAULT_ZOOM
	_camera.position_smoothing_enabled = POSITION_SMOOTHING_ENABLED
	_camera.position_smoothing_speed = POSITION_SMOOTHING_SPEED


## Use player's camera as the main camera
func use_player_camera(player: Node2D) -> void:
	var player_cam = player.get_node_or_null("Camera2D") as Camera2D
	if player_cam:
		set_camera(player_cam)
		set_follow_target(player)
		player_cam.enabled = true
		set_mode(Mode.FOLLOW)


## Use a custom camera (e.g., dungeon camera)
func use_custom_camera(cam: Camera2D, target: Node2D, mode: Mode = Mode.FOLLOW) -> void:
	# Disable player camera if exists
	if _target:
		var player_cam = _target.get_node_or_null("Camera2D") as Camera2D
		if player_cam:
			player_cam.enabled = false
	
	set_camera(cam)
	set_follow_target(target)
	cam.enabled = true
	set_mode(mode)


## Restore player camera (call when leaving custom camera area)
func restore_player_camera() -> void:
	if _target:
		use_player_camera(_target)

#endregion
