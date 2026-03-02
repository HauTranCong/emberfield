class_name ItemSpawner
extends Node

## Item Spawner - Utility class to spawn GameItem instances
##
## Usage:
## ItemSpawner.spawn_item(get_tree(), global_position, "health_potion", 1)
## ItemSpawner.spawn_from_loot_table(get_tree(), global_position, loot_table)
## ItemSpawner.spawn_gold(get_tree(), global_position, 100)
## ItemSpawner.spawn_health(get_tree(), global_position, 25)

const GameItemScene := preload("res://sense/items/game_item.tscn")


## Spawn a single item drop
static func spawn_item(
	tree: SceneTree,
	spawn_position: Vector2,
	item_id: String,
	quantity: int = 1,
	scatter_origin: Vector2 = Vector2.ZERO,
	pickup_mode: GameItem.PickupMode = GameItem.PickupMode.AUTO
) -> GameItem:
	if item_id.is_empty() or quantity <= 0:
		return null
	
	var game_item: GameItem = GameItemScene.instantiate()
	game_item.global_position = spawn_position
	game_item.setup_item(item_id, quantity)
	game_item.pickup_mode = pickup_mode
	
	# Add to current scene using call_deferred to avoid physics query flush error
	tree.current_scene.call_deferred("add_child", game_item)
	
	# Apply scatter after adding to scene
	if scatter_origin != Vector2.ZERO:
		game_item.scatter_from(scatter_origin)
	
	return game_item


## Spawn gold coins
static func spawn_gold(
	tree: SceneTree,
	spawn_position: Vector2,
	amount: int,
	scatter_origin: Vector2 = Vector2.ZERO,
	pickup_mode: GameItem.PickupMode = GameItem.PickupMode.MAGNET
) -> Array[GameItem]:
	var spawned: Array[GameItem] = []
	
	if amount <= 0:
		return spawned
	
	# Determine how many gold piles to spawn (max 5)
	var pile_count := mini(ceili(amount / 10.0), 5)
	var gold_per_pile := amount / pile_count
	var remainder := amount % pile_count
	
	for i in range(pile_count):
		var pile_amount := gold_per_pile
		if i == 0:
			pile_amount += remainder
		
		var offset := Vector2(
			randf_range(-15, 15),
			randf_range(-15, 15)
		)
		
		var game_item: GameItem = GameItemScene.instantiate()
		game_item.global_position = spawn_position + offset
		game_item.setup_gold(pile_amount)
		game_item.pickup_mode = pickup_mode
		
		tree.current_scene.call_deferred("add_child", game_item)
		
		if scatter_origin != Vector2.ZERO:
			game_item.scatter_from(scatter_origin)
		
		spawned.append(game_item)
	
	return spawned


## Spawn health pickup
static func spawn_health(
	tree: SceneTree,
	spawn_position: Vector2,
	heal_amount: int,
	scatter_origin: Vector2 = Vector2.ZERO,
	pickup_mode: GameItem.PickupMode = GameItem.PickupMode.AUTO
) -> GameItem:
	if heal_amount <= 0:
		return null
	
	var game_item: GameItem = GameItemScene.instantiate()
	game_item.global_position = spawn_position
	game_item.setup_health(heal_amount)
	game_item.pickup_mode = pickup_mode
	
	tree.current_scene.call_deferred("add_child", game_item)
	
	if scatter_origin != Vector2.ZERO:
		game_item.scatter_from(scatter_origin)
	
	return game_item


## Spawn stamina pickup
static func spawn_stamina(
	tree: SceneTree,
	spawn_position: Vector2,
	stamina_amount: int,
	scatter_origin: Vector2 = Vector2.ZERO
) -> GameItem:
	if stamina_amount <= 0:
		return null
	
	var game_item: GameItem = GameItemScene.instantiate()
	game_item.global_position = spawn_position
	game_item.setup_stamina(stamina_amount)
	
	tree.current_scene.call_deferred("add_child", game_item)
	
	if scatter_origin != Vector2.ZERO:
		game_item.scatter_from(scatter_origin)
	
	return game_item


## Spawn XP orb
static func spawn_xp(
	tree: SceneTree,
	spawn_position: Vector2,
	xp_amount: int,
	scatter_origin: Vector2 = Vector2.ZERO
) -> GameItem:
	if xp_amount <= 0:
		return null
	
	var game_item: GameItem = GameItemScene.instantiate()
	game_item.global_position = spawn_position
	game_item.setup_xp(xp_amount)
	
	tree.current_scene.call_deferred("add_child", game_item)
	
	if scatter_origin != Vector2.ZERO:
		game_item.scatter_from(scatter_origin)
	
	return game_item


## Spawn items from a loot table
static func spawn_from_loot_table(
	tree: SceneTree,
	spawn_position: Vector2,
	loot_table: LootTable,
	scatter_origin: Vector2 = Vector2.ZERO
) -> Array[GameItem]:
	var spawned: Array[GameItem] = []
	
	if loot_table == null:
		return spawned
	
	# Roll drops
	var drops := loot_table.roll()
	
	# Spawn each drop with slight position offset
	for i in range(drops.size()):
		var drop_data: Dictionary = drops[i]
		var offset := Vector2(
			randf_range(-10, 10),
			randf_range(-10, 10)
		)
		
		var game_item := spawn_item(
			tree,
			spawn_position + offset,
			drop_data.item_id,
			drop_data.quantity,
			scatter_origin if scatter_origin != Vector2.ZERO else spawn_position
		)
		
		if game_item:
			spawned.append(game_item)
	
	return spawned


## Spawn from enemy death (combines loot table + gold + xp)
static func spawn_enemy_drops(
	tree: SceneTree,
	enemy_position: Vector2,
	loot_table: LootTable,
	xp_amount: int = 0
) -> Dictionary:
	var result := {
		"items": [] as Array[GameItem],
		"gold_amount": 0,
		"xp_amount": 0
	}
	
	if loot_table == null:
		return result
	
	# Spawn items
	result.items = spawn_from_loot_table(tree, enemy_position, loot_table, enemy_position)
	
	# Spawn gold
	var gold_amount := loot_table.roll_gold()
	if gold_amount > 0:
		result.gold_amount = gold_amount
		var gold_drops := spawn_gold(tree, enemy_position, gold_amount, enemy_position)
		result.items.append_array(gold_drops)
	
	# Spawn XP orb
	if xp_amount > 0:
		result.xp_amount = xp_amount
		var xp_orb := spawn_xp(tree, enemy_position, xp_amount, enemy_position)
		if xp_orb:
			result.items.append(xp_orb)
	
	return result


## Spawn a chest with items
static func spawn_chest(
	tree: SceneTree,
	spawn_position: Vector2,
	item_ids: Array = [],
	gold: int = 0,
	requires_key: bool = false,
	key_item_id: String = ""
) -> GameItem:
	var game_item: GameItem = GameItemScene.instantiate()
	game_item.global_position = spawn_position
	game_item.setup_chest(item_ids, gold, requires_key, key_item_id)
	
	tree.current_scene.call_deferred("add_child", game_item)
	
	return game_item


## Spawn world item (static item placed in world, requires interaction)
static func spawn_world_item(
	tree: SceneTree,
	spawn_position: Vector2,
	item_id: String,
	quantity: int = 1
) -> GameItem:
	if item_id.is_empty() or quantity <= 0:
		return null
	
	var game_item: GameItem = GameItemScene.instantiate()
	game_item.global_position = spawn_position
	game_item.setup_item(item_id, quantity)
	game_item.pickup_mode = GameItem.PickupMode.INTERACT
	game_item.visual_style = GameItem.VisualStyle.STATIC
	
	tree.current_scene.call_deferred("add_child", game_item)
	
	return game_item
