class_name GameItem
extends Area2D

## Unified Game Item - Single reusable scene for all item types
##
## ╔═══════════════════════════════════════════════════════════════════════════╗
## ║                         GAME ITEM SYSTEM                                  ║
## ╠═══════════════════════════════════════════════════════════════════════════╣
## ║                                                                           ║
## ║  PickupMode:    AUTO | INTERACT | PROXIMITY | MAGNET                      ║
## ║  VisualStyle:   STATIC | BOB | SPARKLE | ROTATE                           ║
## ║  ContentType:   ITEM | GOLD | HEALTH | STAMINA | XP | MULTI_ITEM          ║
## ║                                                                           ║
## ║  Examples:                                                                ║
## ║  ─────────────────────────────────────────────────────────────────────    ║
## ║  Enemy Drop:  pickup=AUTO, visual=BOB, content=ITEM                       ║
## ║  Quest Item:  pickup=INTERACT, visual=SPARKLE, content=ITEM               ║
## ║  Gold Coin:   pickup=MAGNET, visual=ROTATE, content=GOLD                  ║
## ║  Health Orb:  pickup=MAGNET, visual=BOB, content=HEALTH                   ║
## ║  Chest:       pickup=INTERACT, visual=STATIC, content=MULTI_ITEM          ║
## ║                                                                           ║
## ╚═══════════════════════════════════════════════════════════════════════════╝

# ═══════════════════════════════════════════════════════════════════════════════
# SIGNALS
# ═══════════════════════════════════════════════════════════════════════════════

signal collected(content_type: ContentType, item_id: String, quantity: int)
signal chest_opened(contents: Array[Dictionary])

# ═══════════════════════════════════════════════════════════════════════════════
# ENUMS
# ═══════════════════════════════════════════════════════════════════════════════

enum PickupMode {
	AUTO,       ## Tự động nhặt khi chạm
	INTERACT,   ## Cần nhấn phím interact
	PROXIMITY,  ## Nhặt khi đứng gần một lúc
	MAGNET      ## Tự động hút về player
}

enum VisualStyle {
	STATIC,     ## Đứng yên
	BOB,        ## Nhấp nhô lên xuống
	SPARKLE,    ## Lấp lánh (cho quest items)
	ROTATE      ## Xoay (cho coins)
}

enum ContentType {
	ITEM,       ## Vật phẩm từ ItemDatabase
	GOLD,       ## Tiền vàng
	HEALTH,     ## Hồi máu trực tiếp
	STAMINA,    ## Hồi stamina
	XP,         ## Kinh nghiệm
	MULTI_ITEM  ## Nhiều items (chest)
}

# ═══════════════════════════════════════════════════════════════════════════════
# EXPORTS - BEHAVIOR
# ═══════════════════════════════════════════════════════════════════════════════

@export_category("Pickup Behavior")
@export var pickup_mode: PickupMode = PickupMode.AUTO
@export var pickup_delay: float = 0.3
@export var magnet_range: float = 80.0
@export var magnet_speed: float = 200.0
@export var proximity_time: float = 0.5

@export_category("Visual Style")
@export var visual_style: VisualStyle = VisualStyle.BOB
@export var bob_height: float = 4.0
@export var bob_speed: float = 3.0
@export var rotation_speed: float = 2.0
@export var sparkle_intensity: float = 0.5

@export_category("Content - Single Item")
@export var content_type: ContentType = ContentType.ITEM
@export var item_id: String = ""
@export var quantity: int = 1
@export var value: int = 0  ## For GOLD, HEALTH, STAMINA, XP

@export_category("Content - Multi Item (Chest)")
## Array of {item_id: String, quantity: int}
@export var contents: Array[Dictionary] = []
@export var loot_table: LootTable = null
@export var gold_amount: int = 0
@export var gold_range: Vector2i = Vector2i(0, 0)

@export_category("Spawn Settings")
@export var scatter_on_spawn: bool = false
@export var scatter_force: float = 80.0
@export var one_time_only: bool = true
@export var respawn_time: float = 0.0
@export var lifetime: float = 0.0  ## 0 = infinite

@export_category("Interaction")
@export var show_label: bool = false
@export var custom_label: String = ""
@export var locked: bool = false
@export var required_key_id: String = ""

# ═══════════════════════════════════════════════════════════════════════════════
# INTERNAL STATE
# ═══════════════════════════════════════════════════════════════════════════════

var _is_collected: bool = false
var _can_pickup: bool = false
var _player_in_range: bool = false
var _player_ref: Node2D = null
var _bob_time: float = 0.0
var _proximity_timer: float = 0.0
var _velocity: Vector2 = Vector2.ZERO
var _friction: float = 5.0

# ═══════════════════════════════════════════════════════════════════════════════
# NODE REFERENCES
# ═══════════════════════════════════════════════════════════════════════════════

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var label: Label = $Label
@onready var shadow: Sprite2D = $Shadow

# ═══════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	# Setup collision - Layer 10 (Pickup), Mask 2 (Player)
	collision_layer = 1 << 9
	collision_mask = 1 << 1
	
	# Setup collision shape if missing
	if collision and collision.shape == null:
		var shape := CircleShape2D.new()
		shape.radius = 12.0
		collision.shape = shape
	
	# Connect signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Initialize visuals
	_update_icon()
	_setup_label()
	
	# Random offset for bob/rotate
	_bob_time = randf() * TAU
	
	# Pickup delay
	if pickup_delay > 0:
		await get_tree().create_timer(pickup_delay).timeout
	_can_pickup = true
	
	# Lifetime
	if lifetime > 0:
		await get_tree().create_timer(lifetime).timeout
		if not _is_collected:
			_fade_out()


func _physics_process(delta: float) -> void:
	if _is_collected:
		return
	
	# Apply scatter velocity
	if _velocity.length() > 1.0:
		position += _velocity * delta
		_velocity = _velocity.lerp(Vector2.ZERO, _friction * delta)
	
	# Visual animations
	_process_visual(delta)
	
	# Magnet behavior
	if pickup_mode == PickupMode.MAGNET and _player_ref and is_instance_valid(_player_ref):
		_process_magnet(delta)
	
	# Proximity pickup
	if pickup_mode == PickupMode.PROXIMITY and _player_in_range:
		_proximity_timer += delta
		if _proximity_timer >= proximity_time and _can_pickup:
			_collect(_player_ref)


func _input(event: InputEvent) -> void:
	if _is_collected or not _player_in_range or not _can_pickup:
		return
	
	if pickup_mode == PickupMode.INTERACT:
		if event.is_action_pressed("character_interact"):
			_collect(_player_ref)

# ═══════════════════════════════════════════════════════════════════════════════
# VISUAL PROCESSING
# ═══════════════════════════════════════════════════════════════════════════════

func _process_visual(delta: float) -> void:
	if sprite == null:
		return
	
	match visual_style:
		VisualStyle.BOB:
			_bob_time += delta * bob_speed
			sprite.position.y = sin(_bob_time) * bob_height
		
		VisualStyle.ROTATE:
			sprite.rotation += rotation_speed * delta
			_bob_time += delta * bob_speed
			sprite.position.y = sin(_bob_time) * (bob_height * 0.5)
		
		VisualStyle.SPARKLE:
			_bob_time += delta * bob_speed
			sprite.position.y = sin(_bob_time) * (bob_height * 0.5)
			# Sparkle effect
			var sparkle := 0.8 + sin(_bob_time * 2) * sparkle_intensity * 0.2
			sprite.modulate.a = sparkle


func _process_magnet(delta: float) -> void:
	var distance := global_position.distance_to(_player_ref.global_position)
	
	if distance <= magnet_range:
		var direction := (_player_ref.global_position - global_position).normalized()
		# Accelerate as it gets closer
		var speed_multiplier := 1.0 + (1.0 - distance / magnet_range) * 2.0
		global_position += direction * magnet_speed * speed_multiplier * delta
		
		# Auto collect when very close
		if distance < 15 and _can_pickup:
			_collect(_player_ref)

# ═══════════════════════════════════════════════════════════════════════════════
# COLLISION HANDLERS
# ═══════════════════════════════════════════════════════════════════════════════

func _on_body_entered(body: Node2D) -> void:
	if _is_collected:
		return
	
	if body.is_in_group("player") or body.name == "Player":
		_player_in_range = true
		_player_ref = body
		_proximity_timer = 0.0
		
		# Show interaction prompt
		if pickup_mode == PickupMode.INTERACT:
			_show_interact_prompt(true)
		
		# Auto pickup
		if pickup_mode == PickupMode.AUTO and _can_pickup:
			_collect(body)


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		_player_in_range = false
		_proximity_timer = 0.0
		_show_interact_prompt(false)

# ═══════════════════════════════════════════════════════════════════════════════
# COLLECTION LOGIC
# ═══════════════════════════════════════════════════════════════════════════════

func _collect(collector: Node2D) -> void:
	if _is_collected:
		return
	
	# Check lock (async because _try_unlock may show message)
	if locked and not await _try_unlock(collector):
		return
	
	_is_collected = true
	
	# Process based on content type
	match content_type:
		ContentType.ITEM:
			_collect_item(collector)
		ContentType.GOLD:
			_collect_gold(collector)
		ContentType.HEALTH:
			_collect_health(collector)
		ContentType.STAMINA:
			_collect_stamina(collector)
		ContentType.XP:
			_collect_xp(collector)
		ContentType.MULTI_ITEM:
			_collect_multi_item(collector)
	
	# Emit signal
	collected.emit(content_type, item_id, quantity if content_type == ContentType.ITEM else value)
	
	# Cleanup
	_play_collect_effect()


func _collect_item(collector: Node2D) -> void:
	if item_id.is_empty():
		return
	
	var inventory := _get_inventory(collector)
	if inventory == null:
		return
	
	var item: ItemData = ItemDatabase.get_item(item_id)
	if item == null:
		push_warning("GameItem: Item '%s' not found in database" % item_id)
		return
	
	var remaining := inventory.add_item(item, quantity)
	
	# Spawn excess as new item
	if remaining > 0:
		var excess := GameItem.create_item(item_id, remaining)
		excess.global_position = global_position + Vector2(randf_range(-10, 10), randf_range(-10, 10))
		get_tree().current_scene.call_deferred("add_child", excess)


func _collect_gold(collector: Node2D) -> void:
	var inventory := _get_inventory(collector)
	if inventory:
		var amount := value if value > 0 else gold_amount
		inventory.gold += amount


func _collect_health(collector: Node2D) -> void:
	# Try player method first
	if collector.has_method("heal_from_pickup"):
		collector.heal_from_pickup(value)
		return
	
	# Try HealthComponent
	var health_comp: HealthComponent = collector.get_node_or_null("HealthComponent")
	if health_comp:
		health_comp.heal(value)
		return
	
	# Try direct method
	if collector.has_method("heal"):
		collector.heal(value)


func _collect_stamina(collector: Node2D) -> void:
	if collector.has_method("restore_stamina_from_pickup"):
		collector.restore_stamina_from_pickup(value)
	elif collector.has_method("restore_stamina"):
		collector.restore_stamina(value)
	elif collector.has_method("add_stamina"):
		collector.add_stamina(value)


func _collect_xp(collector: Node2D) -> void:
	if collector.has_method("add_xp"):
		collector.add_xp(value)
	elif collector.has_method("add_experience"):
		collector.add_experience(value)
	elif collector.has_method("gain_xp"):
		collector.gain_xp(value)


func _collect_multi_item(collector: Node2D) -> void:
	var inventory := _get_inventory(collector)
	if inventory == null:
		return
	
	var all_items: Array[Dictionary] = []
	
	# Add gold
	var total_gold := gold_amount
	if gold_range.y > gold_range.x:
		total_gold += randi_range(gold_range.x, gold_range.y)
	if total_gold > 0:
		inventory.gold += total_gold
		all_items.append({"item_id": "gold", "quantity": total_gold})
	
	# Add fixed contents
	for content in contents:
		var content_id: String = content.get("item_id", "")
		var content_qty: int = content.get("quantity", 1)
		if not content_id.is_empty():
			_add_item_to_inventory(inventory, content_id, content_qty)
			all_items.append(content.duplicate())
	
	# Add loot table drops
	if loot_table:
		var drops := loot_table.roll()
		for drop in drops:
			var drop_id: String = drop.get("item_id", "")
			var drop_qty: int = drop.get("quantity", 1)
			if not drop_id.is_empty():
				_add_item_to_inventory(inventory, drop_id, drop_qty)
				all_items.append(drop)
		
		# Loot table gold
		var loot_gold := loot_table.roll_gold()
		if loot_gold > 0:
			inventory.gold += loot_gold
			all_items.append({"item_id": "gold", "quantity": loot_gold})
	
	chest_opened.emit(all_items)


func _add_item_to_inventory(inventory: InventoryData, p_item_id: String, qty: int) -> void:
	var item: ItemData = ItemDatabase.get_item(p_item_id)
	if item:
		var remaining := inventory.add_item(item, qty)
		if remaining > 0:
			# Spawn excess
			var excess := GameItem.create_item(p_item_id, remaining)
			excess.global_position = global_position + Vector2(0, 20)
			get_tree().current_scene.call_deferred("add_child", excess)

# ═══════════════════════════════════════════════════════════════════════════════
# HELPER METHODS
# ═══════════════════════════════════════════════════════════════════════════════

func _get_inventory(node: Node2D) -> InventoryData:
	if node.has_method("get_inventory"):
		return node.get_inventory()
	return null


func _try_unlock(collector: Node2D) -> bool:
	if required_key_id.is_empty():
		locked = false
		return true
	
	var inventory := _get_inventory(collector)
	if inventory and inventory.has_item(required_key_id, 1):
		var key_item: ItemData = ItemDatabase.get_item(required_key_id)
		if key_item:
			inventory.remove_item(key_item, 1)
		locked = false
		return true
	
	# Show "need key" message
	if label:
		label.visible = true
		label.text = "Need key!"
		await get_tree().create_timer(1.0).timeout
		if not _is_collected:
			_show_interact_prompt(_player_in_range)
	
	return false


func _update_icon() -> void:
	if sprite == null:
		return
	
	# Reset scale and modulate
	sprite.scale = Vector2.ONE
	sprite.modulate = Color.WHITE
	
	match content_type:
		ContentType.ITEM:
			var icon: Texture2D = null
			if not item_id.is_empty() and ItemDatabase:
				var item: ItemData = ItemDatabase.get_item(item_id)
				if item:
					icon = item.get_icon()
			
			# Use default icon if item not found or has no icon
			if icon == null:
				icon = ItemIconAtlas.get_default_icon()
				push_warning("GameItem: Using default icon for item_id '%s'" % item_id)
			
			if icon:
				sprite.texture = icon
				sprite.scale = Vector2(0.5, 0.5)  # Scale down items
		
		ContentType.GOLD:
			# Get gold coin icon from atlas
			var gold_icon := ItemIconAtlas.get_named_icon("gold_coin")
			if gold_icon:
				sprite.texture = gold_icon
			sprite.scale = Vector2(0.5, 0.5)  # Scale down gold
			sprite.modulate = Color(1.0, 0.95, 0.7)  # Subtle gold tint
		
		ContentType.HEALTH:
			# Get heart icon from atlas
			var health_icon := ItemIconAtlas.get_named_icon("heart")
			if health_icon:
				sprite.texture = health_icon
			sprite.scale = Vector2(0.5, 0.5)  # Scale down
			sprite.modulate = Color(1.0, 0.4, 0.4)  # Red tint
		
		ContentType.STAMINA:
			# Get stamina icon from atlas (using gem for now)
			var stamina_icon := ItemIconAtlas.get_named_icon("gem_green")
			if stamina_icon:
				sprite.texture = stamina_icon
			sprite.scale = Vector2(0.5, 0.5)  # Scale down
			sprite.modulate = Color(0.4, 0.9, 1.0)  # Blue tint
		
		ContentType.XP:
			# Get XP icon from atlas (using brain for now)
			var xp_icon := ItemIconAtlas.get_named_icon("brain")
			if xp_icon:
				sprite.texture = xp_icon
			sprite.scale = Vector2(0.5, 0.5)  # Scale down
			sprite.modulate = Color(0.5, 1.0, 0.6)  # Green tint


func _setup_label() -> void:
	if label == null:
		return
	
	label.visible = show_label
	if show_label and custom_label.is_empty():
		if not item_id.is_empty() and ItemDatabase:
			var item: ItemData = ItemDatabase.get_item(item_id)
			if item:
				label.text = item.name
	elif not custom_label.is_empty():
		label.text = custom_label


func _show_interact_prompt(should_show: bool) -> void:
	if label == null:
		return
	
	if should_show:
		label.visible = true
		match content_type:
			ContentType.MULTI_ITEM:
				label.text = "[E] Open" if not locked else "[E] Locked"
			_:
				label.text = "[E] Pick up"
	else:
		label.visible = show_label
		if show_label:
			_setup_label()


func _play_collect_effect() -> void:
	if sprite == null:
		_finish_collection()
		return
	
	var tween := create_tween()
	tween.set_parallel(true)
	
	match content_type:
		ContentType.MULTI_ITEM:
			# Chest open effect
			tween.tween_property(sprite, "scale:y", 0.7, 0.1)
			tween.chain().tween_property(sprite, "scale:y", 1.0, 0.1)
		_:
			# Normal pickup effect
			tween.tween_property(sprite, "scale", Vector2(1.3, 1.3), 0.1)
			tween.tween_property(sprite, "modulate:a", 0.0, 0.15)
			tween.tween_property(sprite, "position:y", sprite.position.y - 15, 0.15)
	
	if shadow:
		tween.tween_property(shadow, "modulate:a", 0.0, 0.1)
	
	tween.chain().tween_callback(_finish_collection)


func _finish_collection() -> void:
	if one_time_only or content_type != ContentType.MULTI_ITEM:
		queue_free()
	elif respawn_time > 0:
		visible = false
		await get_tree().create_timer(respawn_time).timeout
		_respawn()


func _respawn() -> void:
	_is_collected = false
	_can_pickup = true
	visible = true
	if sprite:
		sprite.modulate.a = 1.0
		sprite.position = Vector2.ZERO
	_update_icon()  # Restore correct scale and icon
	if shadow:
		shadow.modulate.a = 0.3


func _fade_out() -> void:
	if sprite:
		var tween := create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
		tween.tween_callback(queue_free)
	else:
		queue_free()


## Scatter from a point (for enemy drops)
func scatter_from(origin: Vector2) -> void:
	var direction := (global_position - origin).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	_velocity = direction * scatter_force + Vector2(randf_range(-20, 20), randf_range(-20, 20))

# ═══════════════════════════════════════════════════════════════════════════════
# SETUP METHODS
# ═══════════════════════════════════════════════════════════════════════════════

## Setup as item drop
func setup_item(p_item_id: String, p_quantity: int = 1) -> void:
	content_type = ContentType.ITEM
	item_id = p_item_id
	quantity = p_quantity
	_update_icon()


## Setup as gold pickup
func setup_gold(amount: int) -> void:
	content_type = ContentType.GOLD
	value = amount
	pickup_mode = PickupMode.MAGNET
	visual_style = VisualStyle.ROTATE
	_update_icon()


## Setup as health pickup
func setup_health(amount: int) -> void:
	content_type = ContentType.HEALTH
	value = amount
	pickup_mode = PickupMode.MAGNET
	visual_style = VisualStyle.BOB
	_update_icon()


## Setup as chest
## Can accept either Array[String] of item_ids or Array[Dictionary] with {item_id, quantity}
func setup_chest(p_contents: Array = [], p_gold: int = 0, p_requires_key: bool = false, p_key_id: String = "") -> void:
	content_type = ContentType.MULTI_ITEM
	gold_amount = p_gold
	locked = p_requires_key
	required_key_id = p_key_id
	pickup_mode = PickupMode.INTERACT
	visual_style = VisualStyle.STATIC
	
	# Convert simple string array to dictionary format
	contents.clear()
	for entry in p_contents:
		if entry is String:
			contents.append({"item_id": entry, "quantity": 1})
		elif entry is Dictionary:
			contents.append(entry)
	
	_update_icon()


## Add item to chest contents
func add_to_chest(p_item_id: String, p_quantity: int = 1) -> void:
	contents.append({"item_id": p_item_id, "quantity": p_quantity})

# ═══════════════════════════════════════════════════════════════════════════════
# STATIC FACTORY METHODS
# ═══════════════════════════════════════════════════════════════════════════════

static func create_item(p_item_id: String, p_quantity: int = 1) -> GameItem:
	var item := preload("res://sense/items/game_item.tscn").instantiate() as GameItem
	item.setup_item(p_item_id, p_quantity)
	return item


static func create_gold(amount: int) -> GameItem:
	var item := preload("res://sense/items/game_item.tscn").instantiate() as GameItem
	item.setup_gold(amount)
	return item


static func create_health(amount: int) -> GameItem:
	var item := preload("res://sense/items/game_item.tscn").instantiate() as GameItem
	item.setup_health(amount)
	return item


static func create_chest(p_contents: Array[Dictionary] = [], p_gold: int = 0) -> GameItem:
	var item := preload("res://sense/items/game_item.tscn").instantiate() as GameItem
	item.setup_chest(p_contents, p_gold)
	return item
