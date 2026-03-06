extends Node2D
## Main scene - Entry point and orchestrator
##
## Responsibilities:
##   - Register all maps with SceneTransitionService
##   - Initialize services
##   - Setup HUD

@onready var player: CharacterBody2D = $Player
@onready var hud: CanvasLayer = $HUD


func _ready() -> void:
	_test_phase1()
	_test_phase2()
	# Initialize camera service with player
	CameraService.use_player_camera(player)
	
	# Initialize scene transition service
	SceneTransitionService.initialize(self, player)
	
	# Register all maps (add new maps here)
	SceneTransitionService.register_map("town", "res://sense/maps/town/town.tscn")
	SceneTransitionService.register_map("dungeon", "res://sense/maps/dungeon/dungeon_map.tscn")
	# Future maps:
	# SceneTransitionService.register_map("forest", "res://sense/maps/forest/forest.tscn")
	# SceneTransitionService.register_map("boss_arena", "res://sense/maps/boss/boss_arena.tscn")
	
	# Load initial map
	SceneTransitionService.load_initial_map("town")
	
	# Setup HUD
	_setup_hud()
	
	# Connect pause event
	GameEvent.request_ui_pause.connect(_on_request_ui_pause)


func _setup_hud() -> void:
	if hud == null:
		return
	
	if player.has_method("get") and player.get("stats") != null:
		hud.setup(player.stats)
	
	hud.setup_minimap(player, self)


func _on_request_ui_pause(is_open: bool) -> void:
	get_tree().paused = is_open


func _test_phase1() -> void:
	# Test new item types exist
	var shard = ItemDatabase.get_item("fire_shard")
	assert(shard != null, "fire_shard should exist")
	assert(shard.item_type == ItemData.ItemType.SEGMENT)
	assert(shard.is_crafting_material())
	
	var aug = ItemDatabase.get_item("flame_augment_t1")
	assert(aug != null, "flame_augment_t1 should exist")
	assert(aug.item_type == ItemData.ItemType.AUGMENT)
	assert(aug.is_augment())
	assert(!aug.is_timed_buff())
	
	var tonic = ItemDatabase.get_item("vitality_tonic_t1")
	assert(tonic.is_timed_buff())
	assert(tonic.is_consumable())
	
	# Test augment slots by rarity
	var common_sword = ItemDatabase.get_item("iron_sword")
	assert(common_sword.get_augment_slot_count() == 0, "Common = 0 slots")
	var rare_blade = ItemDatabase.get_item("fire_blade")
	assert(rare_blade.get_augment_slot_count() == 2, "Rare = 2 slots")
	
	# Test recipe database
	var recipe = RecipeDatabase.get_recipe("flame_augment")
	assert(recipe != null, "flame_augment recipe should exist")
	assert(recipe.get_max_tier() == 3)
	assert(recipe.get_result_item_id(1) == "flame_augment_t1")
	
	var all_recipes = RecipeDatabase.get_all_recipes()
	assert(all_recipes.size() == 10, "Should have 10 recipes")
	
	var aug_recipes = RecipeDatabase.get_recipes_by_category(CraftingRecipe.RecipeCategory.AUGMENT)
	assert(aug_recipes.size() == 7, "Should have 7 augment recipes")
	
	print("✅ Phase 1 — All tests passed!")


func _test_phase2() -> void:
	# ── BuffComponent: apply / aggregate / refresh / clear ──
	var buff_comp := BuffComponent.new()
	add_child(buff_comp)

	# Track signal emissions (use arrays — GDScript lambdas capture by value, not reference)
	var counters := {"buffs_changed": 0}
	var last_applied := [""]
	var last_expired := [""]
	buff_comp.buffs_changed.connect(func(): counters["buffs_changed"] += 1)
	buff_comp.buff_applied.connect(func(data: Dictionary): last_applied[0] = data.get("id", ""))
	buff_comp.buff_expired.connect(func(id: String): last_expired[0] = id)

	# Apply a timed buff
	var tonic := ItemDatabase.get_item("vitality_tonic_t1")
	buff_comp.apply_buff(tonic)
	assert(buff_comp.active_buffs.size() == 1, "Should have 1 active buff")
	assert(buff_comp.get_total_buff_health() == 20, "Vitality tonic T1 gives +20 HP")
	assert(buff_comp.get_total_buff_attack() == 0, "Tonic gives no attack")
	assert(counters["buffs_changed"] == 1, "buffs_changed should fire once")
	assert(last_applied[0] == "vitality_tonic_t1", "buff_applied signal should carry correct id")

	# Apply a second different buff
	var speed_elixir := ItemDatabase.get_item("speed_elixir_t1")
	buff_comp.apply_buff(speed_elixir)
	assert(buff_comp.active_buffs.size() == 2, "Should have 2 active buffs")
	assert(buff_comp.get_total_buff_speed() == 20.0, "Speed elixir T1 gives +20 speed")
	assert(buff_comp.get_total_buff_health() == 20, "HP still +20 from tonic")

	# Refresh same buff (no stack, just reset duration)
	buff_comp.apply_buff(tonic)
	assert(buff_comp.active_buffs.size() == 2, "Still 2 buffs (refresh, not stack)")
	assert(buff_comp.get_total_buff_health() == 20, "HP stays +20 (no double stack)")

	# Remove one buff manually
	buff_comp.remove_buff("speed_elixir_t1")
	assert(buff_comp.active_buffs.size() == 1, "Should have 1 buff after removal")
	assert(buff_comp.get_total_buff_speed() == 0.0, "Speed bonus gone")
	assert(last_expired[0] == "speed_elixir_t1", "buff_expired signal should fire")

	# Passive effects from buffs (none for tonics, but test the query)
	var passive_effects := buff_comp.get_active_passive_effects()
	assert(passive_effects.size() == 0, "Tonics have no passive effects")

	# Clear all
	buff_comp.clear_all_buffs()
	assert(buff_comp.active_buffs.size() == 0, "All buffs cleared")
	assert(buff_comp.get_total_buff_health() == 0, "HP bonus cleared")

	buff_comp.queue_free()

	# ── CharacterStats: buff integration ──
	var stats := CharacterStats.new()
	stats.base_attack_damage = 10
	stats.base_defense = 5
	stats.base_max_health = 100
	stats.base_move_speed = 120.0

	assert(stats.attack_damage == 10, "Base attack without buffs")
	assert(stats.defense == 5, "Base defense without buffs")
	assert(stats.max_health == 100, "Base HP without buffs")
	assert(stats.move_speed == 120.0, "Base speed without buffs")

	# Simulate buff application via a new BuffComponent
	var buff_comp2 := BuffComponent.new()
	add_child(buff_comp2)

	var defense_brew := ItemDatabase.get_item("defense_brew_t1")
	buff_comp2.apply_buff(defense_brew)
	buff_comp2.apply_buff(tonic)

	stats.apply_buff_bonuses(buff_comp2)
	assert(stats.attack_damage == 10, "Attack unchanged by defense brew + tonic")
	assert(stats.defense == 5 + 8, "Defense = 5 base + 8 brew")
	assert(stats.max_health == 100 + 20, "HP = 100 base + 20 tonic")

	# Clear buff bonuses
	stats.clear_buff_bonuses()
	assert(stats.attack_damage == 10, "Attack back to base after clear")
	assert(stats.defense == 5, "Defense back to base after clear")
	assert(stats.max_health == 100, "HP back to base after clear")

	buff_comp2.queue_free()

	# ── PassiveEffectProcessor: crit calculation ──
	var processor := PassiveEffectProcessor.new()
	add_child(processor)

	# Without any effects, damage should pass through unchanged
	var no_effects_func := func() -> Array[Dictionary]:
		var arr: Array[Dictionary] = []
		return arr
	processor.get_passive_effects_func = no_effects_func
	assert(processor.calculate_crit_damage(50) == 50, "No crit effects = base damage")

	# With 100% crit chance, should always double
	var crit_100_func := func() -> Array[Dictionary]:
		var arr: Array[Dictionary] = [{"effect": ItemData.PassiveEffect.CRIT_CHANCE, "value": 100.0}]
		return arr
	processor.get_passive_effects_func = crit_100_func
	assert(processor.calculate_crit_damage(50) == 100, "100% crit = 2x damage")

	# With 0% crit chance, should never crit
	var crit_0_func := func() -> Array[Dictionary]:
		var arr: Array[Dictionary] = [{"effect": ItemData.PassiveEffect.CRIT_CHANCE, "value": 0.0}]
		return arr
	processor.get_passive_effects_func = crit_0_func
	assert(processor.calculate_crit_damage(50) == 50, "0% crit = base damage")

	processor.queue_free()

	print("✅ Phase 2 — All tests passed!")
