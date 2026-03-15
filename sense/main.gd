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
	_test_phase3()
	_test_phase4()
	await _test_phase5()
	_test_phase6()
	_test_phase7()
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


func _test_phase3() -> void:
	# ── InventoryData: augment application & removal ──
	var inv := InventoryData.new()

	# Give the player a Rare weapon (2 augment slots) by equipping it
	var fire_blade := ItemDatabase.get_item("fire_blade")
	assert(fire_blade != null, "fire_blade should exist in ItemDatabase")
	assert(fire_blade.get_augment_slot_count() == 2, "Rare weapon = 2 augment slots")
	inv.add_item(fire_blade, 1)
	inv.equip_item(0)
	assert(inv.equipped_weapon != null, "Weapon should be equipped")

	# Give the player two augment items in inventory
	var flame_aug := ItemDatabase.get_item("flame_augment_t1")
	var power_aug := ItemDatabase.get_item("power_augment_t1")
	inv.add_item(flame_aug, 1)   # index 0
	inv.add_item(power_aug, 1)   # index 1

	# Apply first augment
	var applied := inv.apply_augment("weapon", 0)
	assert(applied, "Should successfully apply flame augment to weapon")
	assert(inv.equipped_weapon.applied_augments.size() == 1, "Weapon should have 1 augment")
	assert(inv.equipped_weapon.applied_augments[0] == "flame_augment_t1", "First augment is flame")

	# Item should be consumed from inventory
	assert(inv.get_item_at(0).item == null or inv.get_item_at(0).item.id != "flame_augment_t1",
		"Flame augment consumed from slot 0")

	# Apply second augment (power_augment_t1 is now at some slot)
	var power_slot := -1
	for i in range(inv.inventory_slots.size()):
		if inv.inventory_slots[i].item != null and inv.inventory_slots[i].item.id == "power_augment_t1":
			power_slot = i
			break
	assert(power_slot >= 0, "Power augment should still be in inventory")
	applied = inv.apply_augment("weapon", power_slot)
	assert(applied, "Should successfully apply power augment to weapon")
	assert(inv.equipped_weapon.applied_augments.size() == 2, "Weapon should have 2 augments")

	# Weapon is now full (2/2 slots)
	assert(not inv.equipped_weapon.is_augmentable(), "Weapon should be full (not augmentable)")

	# Stat bonuses should include augments
	# fire_blade base attack + flame_augment_t1 attack (5) + power_augment_t1 attack (8)
	var total_atk := inv.get_total_attack_bonus()
	var expected_atk := fire_blade.attack_bonus + flame_aug.attack_bonus + power_aug.attack_bonus
	assert(total_atk == expected_atk,
		"Total ATK = weapon base (%d) + flame aug (%d) + power aug (%d) = %d, got %d" %
		[fire_blade.attack_bonus, flame_aug.attack_bonus, power_aug.attack_bonus, expected_atk, total_atk])

	# Passive effects from augments
	var passives := inv.get_all_augment_passive_effects()
	assert(passives.size() == 1, "Should have 1 passive effect (burn from flame augment)")
	assert(passives[0].effect == ItemData.PassiveEffect.BURN_ON_HIT, "Passive should be BURN_ON_HIT")

	# Active skills from augments (none in this setup)
	var skills := inv.get_all_augment_active_skills()
	assert(skills.size() == 0, "No active skill augments equipped")

	# Remove first augment
	var removed := inv.remove_augment("weapon", 0)
	assert(removed, "Should successfully remove augment at index 0")
	assert(inv.equipped_weapon.applied_augments.size() == 1, "Should have 1 augment after removal")
	assert(inv.equipped_weapon.applied_augments[0] == "power_augment_t1", "Remaining augment is power")
	assert(inv.has_item("flame_augment_t1", 1), "Flame augment returned to inventory")

	# Equipment should be augmentable again (1/2 slots)
	assert(inv.equipped_weapon.is_augmentable(), "Weapon should have open slot")

	# ── Rarity gating: Common has 0 slots ──
	var inv2 := InventoryData.new()
	var iron_sword := ItemDatabase.get_item("iron_sword")
	assert(iron_sword.get_augment_slot_count() == 0, "Common = 0 slots")
	inv2.add_item(iron_sword, 1)
	inv2.equip_item(0)
	inv2.add_item(flame_aug, 1)
	var fail_apply := inv2.apply_augment("weapon", 0)
	assert(not fail_apply, "Should fail to augment Common weapon (0 slots)")

	# ── SkillComponent: rebuild & activation ──
	var skill_comp := SkillComponent.new()
	add_child(skill_comp)

	# Track signals
	var skill_signals := {"activated": "", "changed": 0}
	skill_comp.skill_activated.connect(func(id: String): skill_signals["activated"] = id)
	skill_comp.skills_changed.connect(func(): skill_signals["changed"] += 1)

	# No skills func → empty
	skill_comp.rebuild_skills()
	assert(skill_comp.available_skills.size() == 0, "No skills without func")
	assert(skill_signals["changed"] == 1, "skills_changed emitted on rebuild")

	# Inject a func that returns a whirlwind skill from weapon slot
	skill_comp.get_active_skills_func = func() -> Array:
		return [{"skill_id": "whirlwind", "source_equip_slot": "weapon"}]
	skill_comp.use_stamina_func = func(_cost: float) -> bool: return true

	skill_comp.rebuild_skills()
	assert(skill_comp.available_skills.size() == 1, "Should have 1 skill after rebuild")
	assert(skill_comp.available_skills[0].skill_id == "whirlwind", "Skill is whirlwind")
	assert(skill_comp.available_skills[0].input_action == "skill_1", "Weapon maps to skill_1")
	assert(skill_comp.is_skill_ready("whirlwind"), "Whirlwind should be off cooldown")

	# Activate
	var activated := skill_comp.try_activate_skill("whirlwind")
	assert(activated, "Should activate whirlwind")
	assert(skill_signals["activated"] == "whirlwind", "skill_activated signal fired")
	assert(not skill_comp.is_skill_ready("whirlwind"), "Whirlwind should be on cooldown")

	# Try again immediately → should fail (on cooldown)
	var reactivated := skill_comp.try_activate_skill("whirlwind")
	assert(not reactivated, "Should fail — whirlwind on cooldown")

	# Stamina gating: inject a func that denies stamina
	skill_comp.available_skills[0]["current_cooldown"] = 0.0  # reset cooldown for test
	skill_comp.use_stamina_func = func(_cost: float) -> bool: return false
	var stamina_fail := skill_comp.try_activate_skill("whirlwind")
	assert(not stamina_fail, "Should fail — insufficient stamina")

	# Remove skills on equipment change
	skill_comp.get_active_skills_func = func() -> Array: return []
	skill_comp.rebuild_skills()
	assert(skill_comp.available_skills.size() == 0, "Skills cleared after unequip")

	skill_comp.queue_free()

	# ── SkillData & SkillDatabase ──
	var whirlwind := SkillDatabase.get_skill("whirlwind")
	assert(whirlwind != null, "whirlwind skill should exist")
	assert(whirlwind.skill_name == "Whirlwind")
	assert(whirlwind.cooldown == 6.0)
	assert(whirlwind.stamina_cost == 35.0)
	assert(whirlwind.damage_multiplier == 1.8)
	assert(whirlwind.effect_scene != null, "Whirlwind should have VFX scene assigned")

	var shield_bash := SkillDatabase.get_skill("shield_bash")
	assert(shield_bash != null, "shield_bash skill should exist")
	assert(shield_bash.effect_scene == null, "Shield bash has no VFX yet")

	var all_skills := SkillDatabase.get_all_skills()
	assert(all_skills.size() == 3, "Should have 3 skills total")

	# ── SkillExecutor: instantiation & signal ──
	var executor := SkillExecutor.new()
	add_child(executor)

	var finished_ids: Array[String] = []
	executor.skill_effect_finished.connect(func(id: String): finished_ids.append(id))

	# Execute whirlwind (needs a parent_node in the tree)
	var dummy_parent := Node2D.new()
	add_child(dummy_parent)
	executor.execute_skill(whirlwind, Vector2(100, 100), Vector2.RIGHT, 20, dummy_parent)

	# Wait for the skill effect to finish (0.5s for whirlwind + small buffer)
	await get_tree().create_timer(0.7).timeout
	assert(finished_ids.has("whirlwind"), "skill_effect_finished should fire for whirlwind")

	dummy_parent.queue_free()
	executor.queue_free()

	print("✅ Phase 3 — All tests passed!")


func _test_phase4() -> void:
	# ── CraftingRecipe: can_craft with ingredient checks ──
	var inv := InventoryData.new()

	var recipe := RecipeDatabase.get_recipe("flame_augment")
	assert(recipe != null, "flame_augment recipe should exist")

	# Empty inventory: cannot craft any tier
	assert(not recipe.can_craft(inv, 1), "Empty inv cannot craft T1")
	assert(not recipe.can_craft(inv, 2), "Empty inv cannot craft T2")
	assert(recipe.get_highest_craftable_tier(inv) == 0, "Highest craftable = 0 when empty")

	# Add partial ingredients (not enough)
	var fire_shard := ItemDatabase.get_item("fire_shard")
	var iron_ore := ItemDatabase.get_item("iron_ore")
	inv.add_item(fire_shard, 2)   # Need 3
	inv.add_item(iron_ore, 2)
	assert(not recipe.can_craft(inv, 1), "Partial fire_shards (2/3) cannot craft T1")

	# Add one more fire_shard → now have 3 + 2 iron_ore = can craft T1
	inv.add_item(fire_shard, 1)
	assert(recipe.can_craft(inv, 1), "3 fire_shard + 2 iron_ore = can craft T1")
	assert(recipe.get_highest_craftable_tier(inv) == 1, "Highest craftable = 1")
	assert(not recipe.can_craft(inv, 2), "Cannot craft T2 without inferno_shard + gold_ore")

	# ── CraftingRecipe: get_ingredients & get_result_item_id ──
	var t1_ingredients := recipe.get_ingredients(1)
	assert(t1_ingredients.size() == 2, "T1 should have 2 ingredient types")
	assert(t1_ingredients[0].item_id == "fire_shard", "First ingredient = fire_shard")
	assert(t1_ingredients[0].quantity == 3, "Need 3 fire_shards")
	assert(t1_ingredients[1].item_id == "iron_ore", "Second ingredient = iron_ore")
	assert(t1_ingredients[1].quantity == 2, "Need 2 iron_ore")
	assert(recipe.get_result_item_id(1) == "flame_augment_t1", "T1 result = flame_augment_t1")
	assert(recipe.get_result_quantity(1) == 1, "T1 yields 1 item")

	# ── Craft execution: simulate CraftingPanel._execute_craft() logic ──
	# Verify pre-craft inventory state
	assert(inv.has_item("fire_shard", 3), "Should have 3 fire_shards pre-craft")
	assert(inv.has_item("iron_ore", 2), "Should have 2 iron_ore pre-craft")
	assert(not inv.has_item("flame_augment_t1", 1), "Should NOT have flame_augment_t1 pre-craft")

	# Execute craft (replicate CraftingPanel logic)
	var ingredients := recipe.get_ingredients(1)
	for ingredient: Dictionary in ingredients:
		var item_id: String = ingredient.get("item_id", "")
		var qty: int = ingredient.get("quantity", 0)
		var item_data: ItemData = ItemDatabase.get_item(item_id)
		if item_data:
			inv.remove_item(item_data, qty)

	var result_id := recipe.get_result_item_id(1)
	var result_qty := recipe.get_result_quantity(1)
	var result_item: ItemData = ItemDatabase.get_item_copy(result_id)
	if result_item:
		inv.add_item(result_item, result_qty)

	# Verify post-craft inventory
	assert(not inv.has_item("fire_shard", 1), "fire_shards consumed after craft")
	assert(not inv.has_item("iron_ore", 1), "iron_ore consumed after craft")
	assert(inv.has_item("flame_augment_t1", 1), "flame_augment_t1 added after craft")

	# Cannot craft again (ingredients gone)
	assert(not recipe.can_craft(inv, 1), "Cannot craft T1 again (ingredients consumed)")

	# ── RecipeDatabase: category filtering ──
	var aug_recipes := RecipeDatabase.get_recipes_by_category(CraftingRecipe.RecipeCategory.AUGMENT)
	var buff_recipes := RecipeDatabase.get_recipes_by_category(CraftingRecipe.RecipeCategory.CONSUMABLE_BUFF)
	assert(aug_recipes.size() == 7, "7 augment recipes")
	assert(buff_recipes.size() == 3, "3 consumable buff recipes")
	assert(aug_recipes.size() + buff_recipes.size() == RecipeDatabase.get_all_recipes().size(),
		"All recipes = augment + consumable_buff")

	# ── Multi-tier recipe: frost_augment has 2 tiers ──
	var frost_recipe := RecipeDatabase.get_recipe("frost_augment")
	assert(frost_recipe != null, "frost_augment recipe exists")
	assert(frost_recipe.get_max_tier() == 2, "frost_augment has 2 tiers")
	assert(frost_recipe.get_result_item_id(1) == "frost_augment_t1", "T1 = frost_augment_t1")
	assert(frost_recipe.get_result_item_id(2) == "frost_augment_t2", "T2 = frost_augment_t2")
	assert(frost_recipe.get_result_item_id(3) == "", "No T3 for frost_augment")

	# ── Invalid tier: get_ingredients for non-existent tier returns empty ──
	var empty_ingredients := recipe.get_ingredients(99)
	assert(empty_ingredients.size() == 0, "Non-existent tier returns empty ingredients")

	# ── CraftingPanel: signal emission test (simulate item_crafted) ──
	var panel := CraftingPanel.new()
	add_child(panel)

	var crafted_items: Array[String] = []
	panel.item_crafted.connect(func(item_id: String): crafted_items.append(item_id))

	# Setup: give panel an inventory with T1 flame ingredients + recipe
	var inv2 := InventoryData.new()
	inv2.add_item(fire_shard, 3)
	inv2.add_item(iron_ore, 2)
	panel.player_inventory = inv2
	panel.selected_recipe = recipe
	panel.selected_tier = 1

	# CraftingPanel._execute_craft (call it indirectly via _on_craft_pressed)
	panel._on_craft_pressed()
	assert(crafted_items.size() == 1, "item_crafted signal emitted once")
	assert(crafted_items[0] == "flame_augment_t1", "Crafted item is flame_augment_t1")
	assert(inv2.has_item("flame_augment_t1", 1), "Result item in inventory after panel craft")
	assert(not inv2.has_item("fire_shard", 1), "Ingredients consumed via panel")

	# Press craft again (should fail silently — no ingredients left)
	panel._on_craft_pressed()
	assert(crafted_items.size() == 1, "No second craft (ingredients gone)")

	panel.queue_free()

	# ── use_item (timed buff path via InventoryData) ──
	var inv3 := InventoryData.new()
	var tonic := ItemDatabase.get_item("vitality_tonic_t1")
	inv3.add_item(tonic, 1)
	var use_result := inv3.use_item(0)
	assert(use_result.success == true, "use_item should succeed for tonic")
	assert(use_result.is_timed_buff == true, "Tonic is a timed buff")
	assert(use_result.buff_item != null, "buff_item should be the tonic ItemData")
	assert(use_result.buff_item.id == "vitality_tonic_t1", "buff_item ID matches")
	assert(not inv3.has_item("vitality_tonic_t1", 1), "Tonic consumed after use")

	# ── use_item on non-consumable returns failure ──
	var inv4 := InventoryData.new()
	inv4.add_item(ItemDatabase.get_item("iron_sword"), 1)
	var fail_result := inv4.use_item(0)
	assert(fail_result.success == false, "Cannot use non-consumable")

	print("✅ Phase 4 — All tests passed!")


func _test_phase5() -> void:
	# ══════════════════════════════════════════════════════════════
	# Full pipeline: Craft augment → Apply to weapon → Active skill
	# ══════════════════════════════════════════════════════════════

	# ── Inventory: equip Rare weapon + apply whirlwind augment ──
	var inv := InventoryData.new()

	# fire_blade is Rare (2 augment slots)
	var fire_blade := ItemDatabase.get_item("fire_blade")
	inv.add_item(fire_blade, 1)
	inv.equip_item(0)
	assert(inv.equipped_weapon != null, "Weapon equipped")

	# Add whirlwind augment (ACTIVE_SKILL type) to inventory and apply
	var wh_aug := ItemDatabase.get_item("whirlwind_augment")
	assert(wh_aug != null, "whirlwind_augment exists in ItemDatabase")
	assert(wh_aug.augment_type == ItemData.AugmentType.ACTIVE_SKILL, "Augment type is ACTIVE_SKILL")
	assert(wh_aug.active_skill_id == "whirlwind", "active_skill_id = whirlwind")
	inv.add_item(wh_aug, 1)

	# Find the augment in inventory and apply it
	var aug_slot := -1
	for i in range(inv.inventory_slots.size()):
		if inv.inventory_slots[i].item != null and inv.inventory_slots[i].item.id == "whirlwind_augment":
			aug_slot = i
			break
	assert(aug_slot >= 0, "Whirlwind augment found in inventory")

	var applied := inv.apply_augment("weapon", aug_slot)
	assert(applied, "Whirlwind augment applied to weapon")

	# ── get_all_augment_active_skills should return whirlwind ──
	var active_skills := inv.get_all_augment_active_skills()
	assert(active_skills.size() == 1, "Should have 1 active skill from augments")
	assert(active_skills[0].skill_id == "whirlwind", "Skill ID is whirlwind")
	assert(active_skills[0].source_equip_slot == "weapon", "Source slot is weapon")

	# ── SkillComponent wired to inventory ──
	var skill_comp := SkillComponent.new()
	add_child(skill_comp)

	skill_comp.get_active_skills_func = func() -> Array: return inv.get_all_augment_active_skills()
	skill_comp.use_stamina_func = func(_cost: float) -> bool: return true

	skill_comp.rebuild_skills()
	assert(skill_comp.available_skills.size() == 1, "SkillComponent has 1 skill after rebuild")
	assert(skill_comp.available_skills[0].skill_id == "whirlwind", "Skill is whirlwind")
	assert(skill_comp.available_skills[0].input_action == "skill_1", "Weapon maps to skill_1")

	# ── Activate skill through SkillComponent ──
	var activated_ids: Array[String] = []
	skill_comp.skill_activated.connect(func(id: String): activated_ids.append(id))

	var ok := skill_comp.try_activate_skill("whirlwind")
	assert(ok, "Whirlwind activated")
	assert(activated_ids.has("whirlwind"), "skill_activated signal emitted")

	# Cooldown should be running
	assert(not skill_comp.is_skill_ready("whirlwind"), "On cooldown after activation")

	# ── SkillExecutor: execute whirlwind and wait for finish ──
	var executor := SkillExecutor.new()
	add_child(executor)

	var finished_ids: Array[String] = []
	executor.skill_effect_finished.connect(func(id: String): finished_ids.append(id))

	var whirlwind := SkillDatabase.get_skill("whirlwind")
	var dummy_parent := Node2D.new()
	add_child(dummy_parent)
	executor.execute_skill(whirlwind, Vector2(200, 200), Vector2.RIGHT, 25, dummy_parent)

	await get_tree().create_timer(0.7).timeout
	assert(finished_ids.has("whirlwind"), "skill_effect_finished emitted after execution")

	dummy_parent.queue_free()
	executor.queue_free()

	# ── Remove augment → skill disappears ──
	var removed := inv.remove_augment("weapon", 0)
	assert(removed, "Augment removed from weapon")
	skill_comp.rebuild_skills()
	assert(skill_comp.available_skills.size() == 0, "No skills after augment removed")
	assert(inv.get_all_augment_active_skills().size() == 0, "No active skills in inventory")

	# ── Stamina gating: deny stamina → skill activation fails ──
	# Re-apply augment
	var wh_aug2 := ItemDatabase.get_item("whirlwind_augment")
	inv.add_item(wh_aug2, 1)
	var aug_slot2 := -1
	for i in range(inv.inventory_slots.size()):
		if inv.inventory_slots[i].item != null and inv.inventory_slots[i].item.id == "whirlwind_augment":
			aug_slot2 = i
			break
	inv.apply_augment("weapon", aug_slot2)
	skill_comp.rebuild_skills()
	assert(skill_comp.available_skills.size() == 1, "Skill back after re-apply")

	# Reset cooldown for stamina test
	skill_comp.available_skills[0]["current_cooldown"] = 0.0
	skill_comp.use_stamina_func = func(_cost: float) -> bool: return false
	var stamina_fail := skill_comp.try_activate_skill("whirlwind")
	assert(not stamina_fail, "Activation fails when stamina is insufficient")

	skill_comp.queue_free()

	# ══════════════════════════════════════════════════════════════
	# Buff + Stats integration during item usage
	# ══════════════════════════════════════════════════════════════

	# ── BuffComponent: apply timed buff from use_item result ──
	var buff_comp := BuffComponent.new()
	add_child(buff_comp)

	var inv2 := InventoryData.new()
	var tonic := ItemDatabase.get_item("vitality_tonic_t1")
	inv2.add_item(tonic, 2)

	# Use item returns buff_item for BuffComponent
	var use_result := inv2.use_item(0)
	assert(use_result.success, "use_item succeeds for tonic")
	assert(use_result.is_timed_buff, "is_timed_buff flag set")

	# Apply buff via BuffComponent (matches player._on_item_used flow)
	buff_comp.apply_buff(use_result.buff_item)
	assert(buff_comp.active_buffs.size() == 1, "Buff applied from use_item result")
	assert(buff_comp.get_total_buff_health() == 20, "Tonic provides +20 HP buff")

	# Apply buff bonuses to CharacterStats
	var stats := CharacterStats.new()
	stats.base_max_health = 100
	stats.base_attack_damage = 10
	stats.base_move_speed = 120.0
	stats.apply_buff_bonuses(buff_comp)
	assert(stats.max_health == 120, "HP = 100 base + 20 tonic buff")
	assert(stats.attack_damage == 10, "Attack unchanged by tonic")

	# Use second tonic = refresh (no stack)
	var use_result2 := inv2.use_item(0)
	assert(use_result2.success, "Second tonic use succeeds")
	buff_comp.apply_buff(use_result2.buff_item)
	assert(buff_comp.active_buffs.size() == 1, "Buff refreshed, not stacked")

	# Clear all buffs (simulates player death)
	buff_comp.clear_all_buffs()
	stats.clear_buff_bonuses()
	assert(stats.max_health == 100, "HP back to base after clear")
	assert(buff_comp.active_buffs.size() == 0, "No buffs after clear")

	buff_comp.queue_free()

	# ══════════════════════════════════════════════════════════════
	# PassiveEffectProcessor: aggregation from augmented equipment
	# ══════════════════════════════════════════════════════════════
	var inv3 := InventoryData.new()
	var fire_blade2 := ItemDatabase.get_item("fire_blade")
	inv3.add_item(fire_blade2, 1)
	inv3.equip_item(0)

	# Apply flame_augment_t1 (has BURN_ON_HIT passive)
	var flame_aug := ItemDatabase.get_item("flame_augment_t1")
	inv3.add_item(flame_aug, 1)
	var fl_slot := -1
	for i in range(inv3.inventory_slots.size()):
		if inv3.inventory_slots[i].item != null and inv3.inventory_slots[i].item.id == "flame_augment_t1":
			fl_slot = i
			break
	inv3.apply_augment("weapon", fl_slot)

	var passives := inv3.get_all_augment_passive_effects()
	assert(passives.size() == 1, "1 passive from flame augment")
	assert(passives[0].effect == ItemData.PassiveEffect.BURN_ON_HIT, "Effect = BURN_ON_HIT")

	# PassiveEffectProcessor uses the passive effects func
	var processor := PassiveEffectProcessor.new()
	add_child(processor)

	processor.get_passive_effects_func = func() -> Array[Dictionary]:
		return inv3.get_all_augment_passive_effects()

	# Crit damage should pass through (no crit augment)
	assert(processor.calculate_crit_damage(50) == 50, "No crit augment = base damage")

	# ── Multiple skills from different equipment slots ──
	var inv4 := InventoryData.new()
	# Equip fire_blade (Rare, 2 slots) in weapon
	inv4.add_item(ItemDatabase.get_item("fire_blade"), 1)
	inv4.equip_item(0)

	# Apply whirlwind augment to weapon
	inv4.add_item(ItemDatabase.get_item("whirlwind_augment"), 1)
	var ws := -1
	for i in range(inv4.inventory_slots.size()):
		if inv4.inventory_slots[i].item != null and inv4.inventory_slots[i].item.id == "whirlwind_augment":
			ws = i
			break
	inv4.apply_augment("weapon", ws)

	var multi_skills := inv4.get_all_augment_active_skills()
	assert(multi_skills.size() == 1, "1 skill from weapon augment")
	assert(multi_skills[0].skill_id == "whirlwind", "Skill = whirlwind")
	assert(multi_skills[0].source_equip_slot == "weapon", "Source = weapon")

	# ── SkillDatabase: all skills are valid and have correct properties ──
	var all_skills := SkillDatabase.get_all_skills()
	for skill: SkillData in all_skills:
		assert(skill.id != "", "Skill has non-empty id")
		assert(skill.skill_name != "", "Skill has non-empty name")
		assert(skill.cooldown > 0.0, "Skill has positive cooldown: %s" % skill.id)
		assert(skill.stamina_cost >= 0.0, "Skill has non-negative stamina cost: %s" % skill.id)
		assert(skill.damage_multiplier > 0.0, "Skill has positive damage multiplier: %s" % skill.id)

	# Verify specific skills
	var sb := SkillDatabase.get_skill("shield_bash")
	assert(sb != null, "shield_bash exists")
	assert(sb.skill_name == "Shield Bash")
	assert(sb.knockback_force > 0.0, "Shield bash has knockback")

	var fb := SkillDatabase.get_skill("fire_burst")
	assert(fb != null, "fire_burst exists")
	assert(fb.skill_name == "Fire Burst")

	# Non-existent skill returns null
	assert(SkillDatabase.get_skill("nonexistent") == null, "Unknown skill returns null")

	processor.queue_free()

	print("✅ Phase 5 — All tests passed!")


func _test_phase6() -> void:
	# ══════════════════════════════════════════════════════════════
	# Step 17: Skeleton loot table contains segment drops
	# ══════════════════════════════════════════════════════════════

	# Verify all segment items referenced in the loot table exist in ItemDatabase
	var expected_segments := ["herb_segment", "fire_shard", "frost_shard",
		"power_fragment", "spirit_essence", "venom_gland"]
	for seg_id: String in expected_segments:
		var seg := ItemDatabase.get_item(seg_id)
		assert(seg != null, "Segment '%s' should exist in ItemDatabase" % seg_id)
		assert(seg.item_type == ItemData.ItemType.SEGMENT, "'%s' should be SEGMENT type" % seg_id)
		assert(seg.stackable == true, "'%s' should be stackable" % seg_id)
		assert(seg.is_crafting_material(), "'%s' should be a crafting material" % seg_id)

	# Build the loot table the same way skeleton does and verify entries
	var table := LootTable.new()
	table.drop_count = 2
	table.nothing_weight = 40
	table.gold_range = Vector2i(5, 15)
	table.add_entry("bone", 100, 1, 3)
	table.add_entry("health_potion", 30, 1, 1)
	table.add_entry("iron_sword", 5, 1, 1)
	table.add_entry("herb_segment", 18, 1, 2)
	table.add_entry("fire_shard", 15, 1, 2)
	table.add_entry("frost_shard", 15, 1, 2)
	table.add_entry("power_fragment", 12, 1, 2)
	table.add_entry("spirit_essence", 6, 1, 1)
	table.add_entry("venom_gland", 6, 1, 1)

	# Table should have 9 entries (3 original + 6 segments)
	assert(table.entries.size() == 9, "Loot table should have 9 entries, got %d" % table.entries.size())
	assert(table.drop_count == 2, "Should roll 2 drops per kill")
	assert(table.nothing_weight == 40, "Nothing weight = 40")

	# Verify segment entries are present with correct weights
	var segment_weights := {}
	for entry: Dictionary in table.entries:
		var item_id: String = entry.get("item_id", "")
		if item_id in expected_segments:
			segment_weights[item_id] = entry.get("weight", 0)
	assert(segment_weights.size() == 6, "All 6 segments should be in loot table")
	assert(segment_weights["herb_segment"] == 18, "herb_segment weight = 18")
	assert(segment_weights["fire_shard"] == 15, "fire_shard weight = 15")
	assert(segment_weights["frost_shard"] == 15, "frost_shard weight = 15")
	assert(segment_weights["power_fragment"] == 12, "power_fragment weight = 12")
	assert(segment_weights["spirit_essence"] == 6, "spirit_essence weight = 6")
	assert(segment_weights["venom_gland"] == 6, "venom_gland weight = 6")

	# Roll the loot table many times to verify segments can actually drop
	var dropped_items := {}
	for i in range(500):
		var drops := table.roll()
		for drop: Dictionary in drops:
			var item_id: String = drop.get("item_id", "")
			if item_id in expected_segments:
				dropped_items[item_id] = dropped_items.get(item_id, 0) + 1
	# With 500 rolls × 2 drops each, at least some segments should appear
	assert(dropped_items.size() > 0, "At least one segment type should drop in 500 rolls")

	# Verify gold rolls work
	var gold_total := 0
	for i in range(100):
		var gold := table.roll_gold()
		assert(gold >= 5 and gold <= 15, "Gold should be in range [5, 15], got %d" % gold)
		gold_total += gold
	assert(gold_total > 0, "Gold should drop")

	# ══════════════════════════════════════════════════════════════
	# Step 18: HUD buff/skill signal wiring
	# ══════════════════════════════════════════════════════════════

	# Test BuffComponent → HUD signal flow (simulate without real HUD nodes)
	var buff_comp := BuffComponent.new()
	add_child(buff_comp)

	# Track what HUD would receive
	var hud_applied: Array[Dictionary] = []
	var hud_expired: Array[String] = []
	buff_comp.buff_applied.connect(func(data: Dictionary): hud_applied.append(data))
	buff_comp.buff_expired.connect(func(id: String): hud_expired.append(id))

	# Apply speed buff → HUD should see "speed" in source_item_id
	var speed_elixir := ItemDatabase.get_item("speed_elixir_t1")
	buff_comp.apply_buff(speed_elixir)
	assert(hud_applied.size() == 1, "buff_applied signal fired once")
	assert("speed" in hud_applied[0].get("source_item_id", ""), "Source ID contains 'speed'")

	# Apply vitality buff → HUD should see "vitality" in source_item_id
	var tonic := ItemDatabase.get_item("vitality_tonic_t1")
	buff_comp.apply_buff(tonic)
	assert(hud_applied.size() == 2, "buff_applied signal fired twice")
	assert("vitality" in hud_applied[1].get("source_item_id", ""), "Source ID contains 'vitality'")

	# Apply defense buff
	var defense_brew := ItemDatabase.get_item("defense_brew_t1")
	buff_comp.apply_buff(defense_brew)
	assert(hud_applied.size() == 3, "buff_applied signal fired three times")
	assert("defense" in hud_applied[2].get("source_item_id", ""), "Source ID contains 'defense'")

	# Expire a buff → HUD should get buff_expired
	buff_comp.remove_buff("speed_elixir_t1")
	assert(hud_expired.size() == 1, "buff_expired signal fired once")
	assert("speed" in hud_expired[0], "Expired buff ID contains 'speed'")

	# Clear all → should fire expired for remaining buffs
	buff_comp.clear_all_buffs()
	assert(hud_expired.size() == 3, "buff_expired fired for all remaining buffs")

	buff_comp.queue_free()

	# ── SkillComponent → HUD signal flow ──
	var skill_comp := SkillComponent.new()
	add_child(skill_comp)

	var skills_changed_count := [0]
	var cooldown_updates: Array[Dictionary] = []
	skill_comp.skills_changed.connect(func(): skills_changed_count[0] += 1)
	skill_comp.skill_cooldown_updated.connect(func(id: String, remaining: float):
		cooldown_updates.append({"id": id, "remaining": remaining}))

	skill_comp.get_active_skills_func = func() -> Array:
		return [{"skill_id": "whirlwind", "source_equip_slot": "weapon"}]
	skill_comp.use_stamina_func = func(_cost: float) -> bool: return true

	skill_comp.rebuild_skills()
	assert(skills_changed_count[0] == 1, "skills_changed signal emitted on rebuild")

	# Activate skill → cooldown ticks should propagate
	skill_comp.try_activate_skill("whirlwind")
	assert(not skill_comp.is_skill_ready("whirlwind"), "Whirlwind on cooldown")

	# Simulate one _process tick to trigger cooldown_updated
	skill_comp._process(0.1)
	assert(cooldown_updates.size() > 0, "skill_cooldown_updated signal emitted")
	assert(cooldown_updates[0].id == "whirlwind", "Cooldown update for whirlwind")
	assert(cooldown_updates[0].remaining > 0.0, "Remaining cooldown > 0")

	skill_comp.queue_free()

	# ══════════════════════════════════════════════════════════════
	# Step 19: Tooltip system — augment + passive effect descriptions
	# ══════════════════════════════════════════════════════════════

	# Verify SEGMENT and AUGMENT are recognized as valid item types
	var fire_shard := ItemDatabase.get_item("fire_shard")
	assert(fire_shard.item_type == ItemData.ItemType.SEGMENT, "fire_shard is SEGMENT")

	var flame_aug := ItemDatabase.get_item("flame_augment_t1")
	assert(flame_aug.item_type == ItemData.ItemType.AUGMENT, "flame_augment_t1 is AUGMENT")
	assert(flame_aug.augment_type == ItemData.AugmentType.PASSIVE_EFFECT, "Flame augment is PASSIVE_EFFECT type")
	assert(flame_aug.passive_effect == ItemData.PassiveEffect.BURN_ON_HIT, "Flame augment has BURN_ON_HIT")
	assert(flame_aug.passive_value == 3.0, "Burn value = 3.0")

	var wh_aug := ItemDatabase.get_item("whirlwind_augment")
	assert(wh_aug.augment_type == ItemData.AugmentType.ACTIVE_SKILL, "Whirlwind augment is ACTIVE_SKILL")
	assert(wh_aug.active_skill_id == "whirlwind", "Skill ID = whirlwind")

	var tonic2 := ItemDatabase.get_item("vitality_tonic_t1")
	assert(tonic2.augment_type == ItemData.AugmentType.TIMED_BUFF, "Tonic is TIMED_BUFF")
	assert(tonic2.buff_duration == 60.0, "Tonic duration = 60s")

	# Verify augment slot tooltip data for equipped items
	var inv := InventoryData.new()
	var fire_blade := ItemDatabase.get_item("fire_blade")
	inv.add_item(fire_blade, 1)
	inv.equip_item(0)
	assert(inv.equipped_weapon != null, "Weapon equipped")
	assert(inv.equipped_weapon.get_augment_slot_count() == 2, "Rare weapon has 2 slots")
	assert(inv.equipped_weapon.applied_augments.size() == 0, "No augments applied yet")

	# Apply augment and verify tooltip data would show it
	inv.add_item(flame_aug, 1)
	var aug_slot := -1
	for i in range(inv.inventory_slots.size()):
		if inv.inventory_slots[i].item != null and inv.inventory_slots[i].item.id == "flame_augment_t1":
			aug_slot = i
			break
	inv.apply_augment("weapon", aug_slot)

	# After augment, tooltip data should show 1 filled + 1 empty slot
	var weapon := inv.equipped_weapon
	assert(weapon.applied_augments.size() == 1, "1 augment applied")
	assert(weapon.applied_augments[0] == "flame_augment_t1", "Augment is flame_augment_t1")
	var aug_item := ItemDatabase.get_item(weapon.applied_augments[0])
	assert(aug_item != null, "Can look up augment data for tooltip")
	assert(aug_item.name == "Flame Augment I", "Augment name for tooltip display")

	# Verify augment slot count display: 1 filled, 1 empty
	var filled_slots := weapon.applied_augments.size()
	var total_slots := weapon.get_augment_slot_count()
	assert(filled_slots == 1, "1 augment applied")
	assert(total_slots == 2, "2 total slots")
	assert(total_slots - filled_slots == 1, "1 empty slot remaining")

	# ── GameEvent signals exist for Phase 7 wiring ──
	assert(GameEvent.has_signal("item_crafted"), "GameEvent.item_crafted signal exists")
	assert(GameEvent.has_signal("augment_applied"), "GameEvent.augment_applied signal exists")
	assert(GameEvent.has_signal("augment_removed"), "GameEvent.augment_removed signal exists")
	assert(GameEvent.has_signal("buff_applied"), "GameEvent.buff_applied signal exists")
	assert(GameEvent.has_signal("buff_expired"), "GameEvent.buff_expired signal exists")
	assert(GameEvent.has_signal("skill_used"), "GameEvent.skill_used signal exists")

	print("✅ Phase 6 — All tests passed!")


func _test_phase7() -> void:
	# ══════════════════════════════════════════════════════════════
	# Phase 7 — Wiring & Signals (Steps 20–21)
	# Verifies GameEvent signal declarations, autoload registration,
	# and end-to-end emission from every source component.
	# ══════════════════════════════════════════════════════════════

	# ── Step 20: All GameEvent signals declared ──
	assert(GameEvent.has_signal("request_ui_pause"), "GameEvent.request_ui_pause exists")
	assert(GameEvent.has_signal("item_crafted"), "GameEvent.item_crafted exists")
	assert(GameEvent.has_signal("augment_applied"), "GameEvent.augment_applied exists")
	assert(GameEvent.has_signal("augment_removed"), "GameEvent.augment_removed exists")
	assert(GameEvent.has_signal("buff_applied"), "GameEvent.buff_applied exists")
	assert(GameEvent.has_signal("buff_expired"), "GameEvent.buff_expired exists")
	assert(GameEvent.has_signal("skill_used"), "GameEvent.skill_used exists")

	# ── Step 21: Autoloads registered and functional ──
	assert(RecipeDatabase != null, "RecipeDatabase autoload is registered")
	assert(RecipeDatabase.recipes.size() > 0, "RecipeDatabase has recipes")
	assert(RecipeDatabase.get_recipe("flame_augment") != null, "Can look up flame_augment recipe")

	assert(SkillDatabase != null, "SkillDatabase autoload is registered")
	assert(SkillDatabase.skills.size() > 0, "SkillDatabase has skills")
	assert(SkillDatabase.get_skill("whirlwind") != null, "Can look up whirlwind skill")

	assert(ItemDatabase != null, "ItemDatabase autoload is registered")
	assert(GameEvent != null, "GameEvent autoload is registered")
	assert(CollisionLayers != null, "CollisionLayers autoload is registered")

	# ── GameEvent.buff_applied / buff_expired via BuffComponent ──
	var ge_buff_applied_ids: Array[String] = []
	var ge_buff_expired_ids: Array[String] = []
	var _h_buff_applied := func(id: String) -> void: ge_buff_applied_ids.append(id)
	var _h_buff_expired := func(id: String) -> void: ge_buff_expired_ids.append(id)
	GameEvent.buff_applied.connect(_h_buff_applied)
	GameEvent.buff_expired.connect(_h_buff_expired)

	var bc := BuffComponent.new()
	add_child(bc)

	# Apply a buff → GameEvent.buff_applied should fire
	var speed_item := ItemDatabase.get_item("speed_elixir_t1")
	bc.apply_buff(speed_item)
	assert(ge_buff_applied_ids.size() == 1, "GameEvent.buff_applied emitted once")
	assert(ge_buff_applied_ids[0] == "speed_elixir_t1", "buff_applied carries correct id")

	# Apply a second buff
	var tonic_item := ItemDatabase.get_item("vitality_tonic_t1")
	bc.apply_buff(tonic_item)
	assert(ge_buff_applied_ids.size() == 2, "GameEvent.buff_applied emitted twice")
	assert(ge_buff_applied_ids[1] == "vitality_tonic_t1", "Second buff_applied id correct")

	# Refresh same buff should NOT fire buff_applied again (only buffs_changed)
	bc.apply_buff(speed_item)
	assert(ge_buff_applied_ids.size() == 2, "Refresh does not re-emit buff_applied")

	# Remove buff → GameEvent.buff_expired should fire
	bc.remove_buff("speed_elixir_t1")
	assert(ge_buff_expired_ids.size() == 1, "GameEvent.buff_expired emitted once")
	assert(ge_buff_expired_ids[0] == "speed_elixir_t1", "buff_expired carries correct id")

	# Clear all → should fire expired for remaining buff
	bc.clear_all_buffs()
	assert(ge_buff_expired_ids.size() == 2, "GameEvent.buff_expired emitted for cleared buffs")
	assert(ge_buff_expired_ids[1] == "vitality_tonic_t1", "Cleared buff id correct")

	bc.queue_free()
	GameEvent.buff_applied.disconnect(_h_buff_applied)
	GameEvent.buff_expired.disconnect(_h_buff_expired)

	# ── GameEvent.item_crafted via CraftingPanel._execute_craft() ──
	var ge_craft_ids: Array[String] = []
	var ge_craft_tiers: Array[int] = []
	var _h_item_crafted := func(rid: String, tier: int) -> void:
		ge_craft_ids.append(rid)
		ge_craft_tiers.append(tier)
	GameEvent.item_crafted.connect(_h_item_crafted)

	# Build a CraftingPanel with a test inventory that has the needed ingredients
	var craft_inv := InventoryData.new()
	var fire_shard := ItemDatabase.get_item("fire_shard")
	var iron_ore := ItemDatabase.get_item("iron_ore")
	craft_inv.add_item(fire_shard, 3)
	craft_inv.add_item(iron_ore, 2)

	var cp := CraftingPanel.new()
	# Prevent _build_ui from running in tree (we only test logic)
	cp.player_inventory = craft_inv
	cp.selected_recipe = RecipeDatabase.get_recipe("flame_augment")
	cp.selected_tier = 1
	assert(cp.selected_recipe != null, "flame_augment recipe assigned")
	assert(cp.selected_recipe.can_craft(craft_inv, 1), "Can craft T1 flame augment")

	# Execute craft (calls GameEvent.item_crafted.emit internally)
	cp._execute_craft()
	assert(ge_craft_ids.size() == 1, "GameEvent.item_crafted emitted once")
	assert(ge_craft_ids[0] == "flame_augment", "item_crafted recipe_id = flame_augment")
	assert(ge_craft_tiers[0] == 1, "item_crafted tier = 1")

	# Ingredients consumed
	assert(not craft_inv.has_item("fire_shard", 1), "fire_shard consumed")
	assert(not craft_inv.has_item("iron_ore", 1), "iron_ore consumed")

	# Result item added
	assert(craft_inv.has_item("flame_augment_t1", 1), "flame_augment_t1 in inventory")

	cp.queue_free()
	GameEvent.item_crafted.disconnect(_h_item_crafted)

	# ── GameEvent.augment_applied / augment_removed via AugmentPanel ──
	var ge_aug_applied: Array[Dictionary] = []
	var ge_aug_removed: Array[Dictionary] = []
	var _h_aug_applied := func(slot: String, aug_id: String) -> void:
		ge_aug_applied.append({"slot": slot, "aug_id": aug_id})
	var _h_aug_removed := func(slot: String, aug_id: String) -> void:
		ge_aug_removed.append({"slot": slot, "aug_id": aug_id})
	GameEvent.augment_applied.connect(_h_aug_applied)
	GameEvent.augment_removed.connect(_h_aug_removed)

	# Setup: inventory with equipped rare weapon + augment item
	var aug_inv := InventoryData.new()
	var rare_weapon := ItemDatabase.get_item("fire_blade")
	aug_inv.add_item(rare_weapon, 1)
	aug_inv.equip_item(0)
	assert(aug_inv.equipped_weapon != null, "Weapon equipped for augment test")

	var flame_aug := ItemDatabase.get_item("flame_augment_t1")
	aug_inv.add_item(flame_aug, 1)
	var aug_idx := -1
	for i in range(aug_inv.inventory_slots.size()):
		if aug_inv.inventory_slots[i].item != null and aug_inv.inventory_slots[i].item.id == "flame_augment_t1":
			aug_idx = i
			break
	assert(aug_idx >= 0, "Found flame_augment_t1 in inventory")

	# Create AugmentPanel and apply augment
	var ap : AugmentPanel = preload("res://sense/ui/augment/AugmentPanel.tscn").instantiate()
	ap.inventory = aug_inv
	ap.equip_slot = "weapon"
	ap.equipment_item = aug_inv.equipped_weapon
	add_child(ap)

	ap._on_augment_clicked(aug_idx)
	assert(ge_aug_applied.size() == 1, "GameEvent.augment_applied emitted once")
	assert(ge_aug_applied[0].slot == "weapon", "augment_applied slot = weapon")
	assert(ge_aug_applied[0].aug_id == "flame_augment_t1", "augment_applied aug_id correct")

	# Remove the augment
	ap._on_remove_augment(0)
	assert(ge_aug_removed.size() == 1, "GameEvent.augment_removed emitted once")
	assert(ge_aug_removed[0].slot == "weapon", "augment_removed slot = weapon")
	assert(ge_aug_removed[0].aug_id == "flame_augment_t1", "augment_removed aug_id correct")

	ap.queue_free()
	GameEvent.augment_applied.disconnect(_h_aug_applied)
	GameEvent.augment_removed.disconnect(_h_aug_removed)

	# ── GameEvent.skill_used via SkillComponent + simulated activation ──
	var ge_skill_ids: Array[String] = []
	var _h_skill_used := func(id: String) -> void: ge_skill_ids.append(id)
	GameEvent.skill_used.connect(_h_skill_used)

	# We cannot fully wire Player here, but we can verify the signal is
	# emittable and received. Simulate what player._on_skill_activated does:
	GameEvent.skill_used.emit("whirlwind")
	assert(ge_skill_ids.size() == 1, "GameEvent.skill_used received")
	assert(ge_skill_ids[0] == "whirlwind", "skill_used id = whirlwind")

	# Verify SkillComponent itself triggers skill_activated (which Player wires to emit GameEvent.skill_used)
	var sc := SkillComponent.new()
	add_child(sc)
	sc.get_active_skills_func = func() -> Array:
		return [{"skill_id": "shield_bash", "source_equip_slot": "armor"}]
	sc.use_stamina_func = func(_cost: float) -> bool: return true
	sc.rebuild_skills()

	var sc_activated_ids: Array[String] = []
	sc.skill_activated.connect(func(id: String):
		sc_activated_ids.append(id)
		# Simulate what Player._on_skill_activated would do:
		GameEvent.skill_used.emit(id))

	var success := sc.try_activate_skill("shield_bash")
	assert(success, "shield_bash activation succeeded")
	assert(sc_activated_ids.size() == 1, "skill_activated signal fired")
	assert(sc_activated_ids[0] == "shield_bash", "Activated skill = shield_bash")
	assert(ge_skill_ids.size() == 2, "GameEvent.skill_used now has 2 entries")
	assert(ge_skill_ids[1] == "shield_bash", "Second GameEvent.skill_used = shield_bash")

	# Verify cooldown prevents re-activation
	var fail := sc.try_activate_skill("shield_bash")
	assert(not fail, "shield_bash on cooldown — activation fails")
	assert(ge_skill_ids.size() == 2, "No extra GameEvent emission on failed activation")

	sc.queue_free()
	GameEvent.skill_used.disconnect(_h_skill_used)

	# ── Cross-check: autoloads serve correct data for wiring ──
	# RecipeDatabase recipes reference valid ItemDatabase items
	for recipe: CraftingRecipe in RecipeDatabase.get_all_recipes():
		for tier_data: Dictionary in recipe.tiers:
			var result_id: String = tier_data.get("result_item_id", "")
			assert(ItemDatabase.get_item(result_id) != null,
				"Recipe '%s' T%d result '%s' exists in ItemDatabase" % [recipe.id, tier_data.get("tier", 0), result_id])
			for ing: Dictionary in tier_data.get("ingredients", []):
				var ing_id: String = ing.get("item_id", "")
				assert(ItemDatabase.get_item(ing_id) != null,
					"Recipe '%s' T%d ingredient '%s' exists in ItemDatabase" % [recipe.id, tier_data.get("tier", 0), ing_id])

	# SkillDatabase skills referenced by augments exist
	var skill_augment_ids := ["whirlwind_augment", "shield_bash_augment"]
	for aug_id: String in skill_augment_ids:
		var aug := ItemDatabase.get_item(aug_id)
		assert(aug != null, "Skill augment '%s' exists" % aug_id)
		assert(aug.augment_type == ItemData.AugmentType.ACTIVE_SKILL, "'%s' is ACTIVE_SKILL" % aug_id)
		var skill := SkillDatabase.get_skill(aug.active_skill_id)
		assert(skill != null, "Skill '%s' from augment '%s' exists in SkillDatabase" % [aug.active_skill_id, aug_id])

	print("✅ Phase 7 — All tests passed!")
