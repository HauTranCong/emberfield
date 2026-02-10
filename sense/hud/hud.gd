extends CanvasLayer

@onready var health_bar: ProgressBar = $MarginContainer/VBoxContainer/HealthContainer/HealthBar
@onready var stamina_bar: ProgressBar = $MarginContainer/VBoxContainer/StaminaContainer/StaminaBar
@onready var health_label: Label = $MarginContainer/VBoxContainer/HealthContainer/HealthBar/Label
@onready var stamina_label: Label = $MarginContainer/VBoxContainer/StaminaContainer/StaminaBar/Label

# Status effect icons
@onready var icon_speed: Control = $StatusIconsContainer/IconsFlow/SpeedIcon
@onready var icon_heal: Control = $StatusIconsContainer/IconsFlow/HealIcon
@onready var icon_shield: Control = $StatusIconsContainer/IconsFlow/ShieldIcon
@onready var icon_poison: Control = $StatusIconsContainer/IconsFlow/PoisonIcon
@onready var icon_burn: Control = $StatusIconsContainer/IconsFlow/BurnIcon
@onready var icon_freeze: Control = $StatusIconsContainer/IconsFlow/FreezeIcon

# Minimap
@onready var minimap_camera: Camera2D = $MinimapContainer/MarginContainer/SubViewportContainer/SubViewport/MinimapCamera
@onready var minimap_viewport: SubViewport = $MinimapContainer/MarginContainer/SubViewportContainer/SubViewport

var stats: CharacterStats
var player: Node2D  # Reference to player for minimap


func _ready() -> void:
	# Ẩn tất cả icon khi bắt đầu
	# hide_all_status_icons()
	# enable_all_status_icons()
	show_shield_icon(true)


func setup(character_stats: CharacterStats) -> void:
	stats = character_stats
	
	# Kết nối signals
	stats.health_changed.connect(_on_health_changed)
	stats.stamina_changed.connect(_on_stamina_changed)
	
	# Cập nhật giá trị ban đầu
	_on_health_changed(stats.current_health, stats.max_health)
	_on_stamina_changed(stats.current_stamina, stats.max_stamina)


func _on_health_changed(current: int, maximum: int) -> void:
	health_bar.max_value = maximum
	health_bar.value = current
	health_label.text = "%d / %d" % [current, maximum]


func _on_stamina_changed(current: float, maximum: float) -> void:
	stamina_bar.max_value = maximum
	stamina_bar.value = current
	stamina_label.text = "%d / %d" % [int(current), int(maximum)]


# === STATUS ICON FUNCTIONS ===

func hide_all_status_icons() -> void:
	icon_speed.visible = false
	icon_heal.visible = false
	icon_shield.visible = false
	icon_poison.visible = false
	icon_burn.visible = false
	icon_freeze.visible = false



func enable_all_status_icons() -> void:
	icon_speed.visible = true
	icon_heal.visible = true
	icon_shield.visible = true
	icon_poison.visible = true
	icon_burn.visible = true
	icon_freeze.visible = true


func show_speed_icon(value: bool = true) -> void:
	icon_speed.visible = value


func show_heal_icon(value: bool = true) -> void:
	icon_heal.visible = value


func show_shield_icon(value: bool = true) -> void:
	icon_shield.visible = value


func show_poison_icon(value: bool = true) -> void:
	icon_poison.visible = value


func show_burn_icon(value: bool = true) -> void:
	icon_burn.visible = value


func show_freeze_icon(value: bool = true) -> void:
	icon_freeze.visible = value


func set_status_icon(icon_name: String, value: bool) -> void:
	match icon_name:
		"speed":
			show_speed_icon(value)
		"heal":
			show_heal_icon(value)
		"shield":
			show_shield_icon(value)
		"poison":
			show_poison_icon(value)
		"burn":
			show_burn_icon(value)
		"freeze":
			show_freeze_icon(value)


# === MINIMAP FUNCTIONS ===

func setup_minimap(player_node: Node2D, world: Node2D) -> void:
	player = player_node
	
	# Share the same world_2d so minimap sees the game world
	# This avoids duplicating nodes which causes infinite loops
	if world != null and minimap_viewport != null:
		minimap_viewport.world_2d = world.get_world_2d()


func _process(_delta: float) -> void:
	# Update minimap camera to follow player
	if player != null and minimap_camera != null:
		minimap_camera.global_position = player.global_position
