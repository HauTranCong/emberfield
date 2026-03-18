# Segment Crafting & Equipment Augmentation System

> **Architecture principle**: Every new system is a **decoupled component** (`extends Node` or `extends Resource`).
> Components communicate exclusively through **signals** — never by calling methods on siblings directly.
> The owner entity (e.g. Player) wires signals in `_ready()`. This keeps components independently testable,
> reusable across entity types (Player today, NPC companion tomorrow), and trivial to add/remove.

---

## Overview

Build a tiered recipe crafting system where players combine existing materials + new magical segment drops at a world crafting station to produce two kinds of items:

1. **Permanent Augments** — slotted into equipment to boost stats, grant passive on-hit effects, or unlock active skills
2. **Consumable Buffs** — timed stat boosts consumed from inventory

Equipment augment slot count is determined by item rarity (Common=0 → Legendary=4).
Active skills are **equipment-bound** — wearing an augmented piece grants the skill; unequipping removes it.

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                         SYSTEM OVERVIEW                                      │
│                                                                              │
│   [Enemy drops Segments]                                                     │
│          │                                                                   │
│          ▼                                                                   │
│   ┌─────────────┐    ┌──────────────┐    ┌─────────────────────────────┐     │
│   │  Inventory   │───▶│  Crafting    │───▶│  Augment (permanent)       │     │
│   │  (segments + │    │  Station     │    │  - Slot into equipment     │     │
│   │   materials) │    │  (recipes)   │    │  - Stat boost / passive /  │     │
│   └─────────────┘    └──────────────┘    │    active skill             │     │
│                            │              └─────────────────────────────┘     │
│                            │                                                 │
│                            ▼                                                 │
│                      ┌─────────────────────────────────────────┐             │
│                      │  Consumable Buff (timed)                │             │
│                      │  - Use from inventory                   │             │
│                      │  - Temporary stat boost                 │             │
│                      │  - Duration countdown on HUD            │             │
│                      └─────────────────────────────────────────┘             │
│                                                                              │
│   ┌──────────────────────────────────────────────────────────────────────┐   │
│   │                    COMPONENT WIRING (Player)                         │   │
│   │                                                                      │   │
│   │   Player (CharacterBody2D)                                           │   │
│   │   ├── CharacterStats        ◀── equipment_changed, buffs_changed     │   │
│   │   ├── HitboxComponent       ◀── PassiveEffectProcessor              │   │
│   │   ├── HurtboxComponent      ◀── PassiveEffectProcessor (thorns)     │   │
│   │   ├── BuffComponent (NEW)   ──▶ buffs_changed signal                │   │
│   │   ├── SkillComponent (NEW)  ──▶ skills_changed signal               │   │
│   │   └── InventoryData         ──▶ augments_changed signal             │   │
│   └──────────────────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## Design Decisions

| Decision | Rationale |
|---|---|
| **Item instancing** | Equipment gets `item.duplicate()` on first augment to create a unique `ItemData` instance. The original `ItemDatabase` template is never mutated. Augments persist through equip/unequip because they live on the duplicated instance. |
| **Equipment-bound skills** | No separate skill slot UI. Unequipping the augmented item removes the skill. Keeps skill acquisition tied to gear progression. |
| **Buff stacking** | Same `buff_id` refreshes duration (no stacking). Different buff types stack additively. Prevents trivial stat inflation. |
| **Non-destructive augment removal** | Extracting an augment returns the `AUGMENT` item to inventory. Encourages experimentation. |
| **Crafting at blacksmith** | Reuse existing blacksmith NPC's shop popup. Add a "Crafting" tab alongside "Buy/Sell" in `SmithShopPopup`. No separate CraftingStation entity needed. |
| **Both existing + new materials** | Existing `MATERIAL` items (iron_ore, gold_ore, monster_bone) and new `SEGMENT` drops are both valid crafting inputs. |
| **Tiered recipes** | Each recipe has T1/T2/T3 tiers. Higher tiers require rarer segments and produce stronger outputs. Player picks tier in crafting UI. |
| **Rarity-based augment slots** | Common=0, Uncommon=1, Rare=2, Epic=3, Legendary=4. Motivates seeking higher-rarity gear. |
| **Components are decoupled** | `BuffComponent`, `SkillComponent`, `PassiveEffectProcessor` are independent `Node`-based components. They don't reference each other directly — they communicate via signals through the owner entity. |

---

## Phase 1 — Data Model & Foundation

### Step 1. Extend `ItemData` → modify `sense/items/item_data.gd`

**Current state**: Has `enum ItemType { WEAPON, ARMOR, HELMET, BOOTS, SHIELD, ACCESSORY, CONSUMABLE, MATERIAL, QUEST }`, `enum ItemRarity`, export vars for stats/stacking/consumable effects, methods `is_equippable()`, `is_consumable()`, `get_icon()`, `get_rarity_color()`.

**Changes**:

#### 1a. Add two new `ItemType` values

```gdscript
enum ItemType {
    WEAPON, ARMOR, HELMET, BOOTS, SHIELD, ACCESSORY,
    CONSUMABLE, MATERIAL, QUEST,
    SEGMENT,   # NEW — magical crafting drops, stackable max 99
    AUGMENT    # NEW — crafted buff items, non-stackable, slotted into equipment
}
```

#### 1b. Add `AugmentType` enum (only relevant when `item_type == AUGMENT`)

```gdscript
enum AugmentType {
    NONE,            # Not an augment item
    STAT_BOOST,      # Pure stat increase (ATK, DEF, HP, SPD)
    PASSIVE_EFFECT,  # On-hit / on-damaged passive (life steal, burn, thorns, etc.)
    ACTIVE_SKILL,    # Grants an activatable skill when slotted
    TIMED_BUFF       # Consumable-style — used from inventory for temporary buff
}
```

#### 1c. Add `PassiveEffect` enum

```gdscript
enum PassiveEffect {
    NONE,
    LIFE_STEAL,     # Heal % of damage dealt
    CRIT_CHANCE,    # % chance for 2× damage
    THORNS,         # Reflect % damage back to attacker on hit received
    BURN_ON_HIT,    # Apply burn DoT on hit
    FREEZE_ON_HIT,  # Apply slow on hit
    POISON_ON_HIT   # Apply poison DoT on hit
}
```

#### 1d. Add new `@export` vars under a new category

```gdscript
@export_category("Augment Properties")
@export var augment_type: AugmentType = AugmentType.NONE
@export var passive_effect: PassiveEffect = PassiveEffect.NONE
@export var passive_value: float = 0.0          # e.g. 5.0 = 5% life steal, 10.0 = 10% crit
@export var active_skill_id: String = ""        # Links to SkillData.id (e.g. "whirlwind")
@export var buff_duration: float = 0.0          # > 0 means timed consumable buff; 0 = permanent augment

## Augments slotted into this equipment instance (array of augment item IDs)
## Only populated on duplicated equipment instances, never on ItemDatabase templates
var applied_augments: Array[String] = []
```

#### 1e. Add computed methods

```gdscript
## Returns how many augment slots this equipment has, based on rarity
## Only equippable items have slots. Common=0, Uncommon=1, Rare=2, Epic=3, Legendary=4
func get_augment_slot_count() -> int:
    if not is_equippable():
        return 0
    match rarity:
        ItemRarity.COMMON:    return 0
        ItemRarity.UNCOMMON:  return 1
        ItemRarity.RARE:      return 2
        ItemRarity.EPIC:      return 3
        ItemRarity.LEGENDARY: return 4
        _: return 0

## True if this equipment piece can accept augments (has at least 1 slot and isn't full)
func is_augmentable() -> bool:
    return get_augment_slot_count() > 0 and applied_augments.size() < get_augment_slot_count()

## True if this is a SEGMENT or MATERIAL (valid crafting input)
func is_crafting_material() -> bool:
    return item_type in [ItemType.SEGMENT, ItemType.MATERIAL]

## True if this is an AUGMENT item that can be slotted into equipment
func is_augment() -> bool:
    return item_type == ItemType.AUGMENT and augment_type != AugmentType.TIMED_BUFF

## True if this is a timed buff consumable (crafted via AUGMENT type but used like a consumable)
func is_timed_buff() -> bool:
    return item_type == ItemType.AUGMENT and augment_type == AugmentType.TIMED_BUFF
```

#### 1f. Update `is_consumable()` to also cover timed buffs

```gdscript
func is_consumable() -> bool:
    return item_type == ItemType.CONSUMABLE or is_timed_buff()
```

#### 1g. Update stacking logic in existing code

`SEGMENT` items: `stackable = true`, `max_stack = 99` (same as MATERIAL).
`AUGMENT` items: `stackable = false`, `max_stack = 1`.

---

### Step 2. Create `CraftingRecipe` resource → `sense/ui/crafting/crafting_recipe.gd` (NEW FILE)

A pure data resource with no scene dependencies. Validates ingredient availability against `InventoryData`.

```gdscript
class_name CraftingRecipe
extends Resource

## ╔════════════════════════════════════════════════════════════╗
## ║                  CRAFTING RECIPE                           ║
## ╠════════════════════════════════════════════════════════════╣
## ║  Each recipe has 1-3 tiers.                               ║
## ║  Higher tiers use rarer ingredients → stronger output.    ║
## ║                                                           ║
## ║  Recipe "flame_augment":                                  ║
## ║  ┌─────┬──────────────────────────┬───────────────────┐   ║
## ║  │ T1  │ 3× fire_shard + 2× iron │ flame_augment_t1  │   ║
## ║  │ T2  │ 3× inferno + 2× gold    │ flame_augment_t2  │   ║
## ║  │ T3  │ 3× hellfire + 1× m_bone │ flame_augment_t3  │   ║
## ║  └─────┴──────────────────────────┴───────────────────┘   ║
## ╚════════════════════════════════════════════════════════════╝

enum RecipeCategory {
    AUGMENT,         # Output is an AUGMENT item (permanent or active skill)
    CONSUMABLE_BUFF  # Output is a timed buff item
}

@export var id: String = ""
@export var recipe_name: String = ""
@export var description: String = ""
@export var category: RecipeCategory = RecipeCategory.AUGMENT

## Array of tier definitions. Each tier is a Dictionary:
## {
##   "tier": int,                                        # 1, 2, or 3
##   "ingredients": Array[Dictionary],                   # [{"item_id": "fire_shard", "quantity": 3}, ...]
##   "result_item_id": String,                           # ID in ItemDatabase (e.g. "flame_augment_t1")
##   "result_quantity": int                              # Usually 1
## }
@export var tiers: Array[Dictionary] = []


## Check if the player can craft a specific tier
func can_craft(inventory: InventoryData, tier: int) -> bool:
    var tier_data := _get_tier_data(tier)
    if tier_data.is_empty():
        return false
    for ingredient: Dictionary in tier_data.get("ingredients", []):
        var item_id: String = ingredient.get("item_id", "")
        var quantity: int = ingredient.get("quantity", 0)
        if not inventory.has_item(item_id, quantity):
            return false
    return true


## Returns the highest tier the player can currently craft (0 = none)
func get_highest_craftable_tier(inventory: InventoryData) -> int:
    var best := 0
    for tier_data: Dictionary in tiers:
        var t: int = tier_data.get("tier", 0)
        if can_craft(inventory, t):
            best = maxi(best, t)
    return best


## Get ingredient list for a specific tier (for UI display)
func get_ingredients(tier: int) -> Array[Dictionary]:
    var tier_data := _get_tier_data(tier)
    return tier_data.get("ingredients", []) as Array[Dictionary]


## Get result item ID for a specific tier
func get_result_item_id(tier: int) -> String:
    var tier_data := _get_tier_data(tier)
    return tier_data.get("result_item_id", "")


## Get result quantity for a specific tier
func get_result_quantity(tier: int) -> int:
    var tier_data := _get_tier_data(tier)
    return tier_data.get("result_quantity", 1)


## Get max tier available for this recipe
func get_max_tier() -> int:
    var max_t := 0
    for t: Dictionary in tiers:
        max_t = maxi(max_t, t.get("tier", 0))
    return max_t


func _get_tier_data(tier: int) -> Dictionary:
    for t: Dictionary in tiers:
        if t.get("tier", 0) == tier:
            return t
    return {}
```

---

### Step 3. Create `RecipeDatabase` → `sense/ui/crafting/recipe_database.gd` (NEW FILE, autoload)

Follows the same pattern as `ItemDatabase` (autoload, dictionary lookup, static data).

```gdscript
extends Node

## ╔════════════════════════════════════════════════════════════╗
## ║  RecipeDatabase — Autoload                                ║
## ║  Mirrors the ItemDatabase pattern:                        ║
## ║  - Dictionary of CraftingRecipe keyed by recipe_id        ║
## ║  - get_recipe(id) → CraftingRecipe                        ║
## ║  - get_recipes_by_category(cat) → Array[CraftingRecipe]   ║
## ╚════════════════════════════════════════════════════════════╝

var recipes: Dictionary = {}  # recipe_id: String → CraftingRecipe


func _ready() -> void:
    _create_recipes()


func get_recipe(recipe_id: String) -> CraftingRecipe:
    return recipes.get(recipe_id)


func get_all_recipes() -> Array:
    return recipes.values()


func get_recipes_by_category(category: CraftingRecipe.RecipeCategory) -> Array:
    var result: Array = []
    for recipe: CraftingRecipe in recipes.values():
        if recipe.category == category:
            result.append(recipe)
    return result


func _create_recipes() -> void:
    # === AUGMENT RECIPES ===

    _add_recipe("flame_augment", "Flame Augment", "Imbue equipment with fire.", CraftingRecipe.RecipeCategory.AUGMENT, [
        {"tier": 1, "ingredients": [{"item_id": "fire_shard", "quantity": 3}, {"item_id": "iron_ore", "quantity": 2}], "result_item_id": "flame_augment_t1", "result_quantity": 1},
        {"tier": 2, "ingredients": [{"item_id": "inferno_shard", "quantity": 3}, {"item_id": "gold_ore", "quantity": 2}], "result_item_id": "flame_augment_t2", "result_quantity": 1},
        {"tier": 3, "ingredients": [{"item_id": "hellfire_shard", "quantity": 3}, {"item_id": "monster_bone", "quantity": 1}], "result_item_id": "flame_augment_t3", "result_quantity": 1},
    ])

    _add_recipe("frost_augment", "Frost Augment", "Imbue equipment with ice.", CraftingRecipe.RecipeCategory.AUGMENT, [
        {"tier": 1, "ingredients": [{"item_id": "frost_shard", "quantity": 3}, {"item_id": "iron_ore", "quantity": 2}], "result_item_id": "frost_augment_t1", "result_quantity": 1},
        {"tier": 2, "ingredients": [{"item_id": "blizzard_shard", "quantity": 3}, {"item_id": "gold_ore", "quantity": 2}], "result_item_id": "frost_augment_t2", "result_quantity": 1},
    ])

    _add_recipe("power_augment", "Power Augment", "Raw strength increase.", CraftingRecipe.RecipeCategory.AUGMENT, [
        {"tier": 1, "ingredients": [{"item_id": "power_fragment", "quantity": 3}, {"item_id": "iron_ore", "quantity": 2}], "result_item_id": "power_augment_t1", "result_quantity": 1},
        {"tier": 2, "ingredients": [{"item_id": "greater_power_fragment", "quantity": 3}, {"item_id": "gold_ore", "quantity": 2}], "result_item_id": "power_augment_t2", "result_quantity": 1},
    ])

    _add_recipe("lifesteal_augment", "Lifesteal Augment", "Drain life on hit.", CraftingRecipe.RecipeCategory.AUGMENT, [
        {"tier": 1, "ingredients": [{"item_id": "spirit_essence", "quantity": 3}, {"item_id": "monster_bone", "quantity": 2}], "result_item_id": "lifesteal_augment_t1", "result_quantity": 1},
        {"tier": 2, "ingredients": [{"item_id": "spirit_essence", "quantity": 5}, {"item_id": "gold_ore", "quantity": 3}], "result_item_id": "lifesteal_augment_t2", "result_quantity": 1},
    ])

    _add_recipe("crit_augment", "Critical Augment", "Increase critical strike chance.", CraftingRecipe.RecipeCategory.AUGMENT, [
        {"tier": 1, "ingredients": [{"item_id": "power_fragment", "quantity": 2}, {"item_id": "monster_bone", "quantity": 3}], "result_item_id": "crit_augment_t1", "result_quantity": 1},
        {"tier": 2, "ingredients": [{"item_id": "greater_power_fragment", "quantity": 3}, {"item_id": "monster_bone", "quantity": 5}], "result_item_id": "crit_augment_t2", "result_quantity": 1},
    ])

    _add_recipe("whirlwind_augment", "Whirlwind Augment", "Grants the Whirlwind skill.", CraftingRecipe.RecipeCategory.AUGMENT, [
        {"tier": 1, "ingredients": [{"item_id": "power_fragment", "quantity": 5}, {"item_id": "fire_shard", "quantity": 3}, {"item_id": "monster_bone", "quantity": 3}], "result_item_id": "whirlwind_augment", "result_quantity": 1},
    ])

    _add_recipe("shield_bash_augment", "Shield Bash Augment", "Grants the Shield Bash skill.", CraftingRecipe.RecipeCategory.AUGMENT, [
        {"tier": 1, "ingredients": [{"item_id": "frost_shard", "quantity": 3}, {"item_id": "iron_ore", "quantity": 5}, {"item_id": "monster_bone", "quantity": 2}], "result_item_id": "shield_bash_augment", "result_quantity": 1},
    ])

    # === CONSUMABLE BUFF RECIPES ===

    _add_recipe("vitality_tonic", "Vitality Tonic", "Temporary max HP boost.", CraftingRecipe.RecipeCategory.CONSUMABLE_BUFF, [
        {"tier": 1, "ingredients": [{"item_id": "herb_segment", "quantity": 2}, {"item_id": "monster_bone", "quantity": 1}], "result_item_id": "vitality_tonic_t1", "result_quantity": 1},
        {"tier": 2, "ingredients": [{"item_id": "herb_segment", "quantity": 4}, {"item_id": "gold_ore", "quantity": 2}], "result_item_id": "vitality_tonic_t2", "result_quantity": 1},
    ])

    _add_recipe("speed_elixir", "Speed Elixir", "Temporary movement speed boost.", CraftingRecipe.RecipeCategory.CONSUMABLE_BUFF, [
        {"tier": 1, "ingredients": [{"item_id": "herb_segment", "quantity": 2}, {"item_id": "frost_shard", "quantity": 1}], "result_item_id": "speed_elixir_t1", "result_quantity": 1},
        {"tier": 2, "ingredients": [{"item_id": "herb_segment", "quantity": 4}, {"item_id": "blizzard_shard", "quantity": 2}], "result_item_id": "speed_elixir_t2", "result_quantity": 1},
    ])

    _add_recipe("defense_brew", "Defense Brew", "Temporary defense boost.", CraftingRecipe.RecipeCategory.CONSUMABLE_BUFF, [
        {"tier": 1, "ingredients": [{"item_id": "iron_ore", "quantity": 3}, {"item_id": "herb_segment", "quantity": 1}], "result_item_id": "defense_brew_t1", "result_quantity": 1},
        {"tier": 2, "ingredients": [{"item_id": "gold_ore", "quantity": 3}, {"item_id": "herb_segment", "quantity": 3}], "result_item_id": "defense_brew_t2", "result_quantity": 1},
    ])


## Helper to construct and register a recipe
func _add_recipe(id: String, recipe_name: String, desc: String, category: CraftingRecipe.RecipeCategory, tier_data: Array) -> void:
    var recipe := CraftingRecipe.new()
    recipe.id = id
    recipe.recipe_name = recipe_name
    recipe.description = desc
    recipe.category = category
    recipe.tiers.assign(tier_data)
    recipes[id] = recipe
```

Register as autoload in `project.godot`:
```ini
[autoload]
RecipeDatabase="*res://sense/ui/crafting/recipe_database.gd"
```

---

### Step 4. Add segment & augment items to `ItemDatabase` → modify `sense/items/item_database.gd`

**Current state**: 302 lines, `_create_sample_items()` builds all items with `_create_item()` helper. Items dictionary keyed by `id`.

Add the following item definitions inside `_create_sample_items()`, using the existing `_create_item(data: Dictionary) -> ItemData` helper pattern:

#### 4a. New SEGMENT items (enemy/world drops)

| ID | Name | Rarity | Description | buy_price | sell_price | Atlas |
|---|---|---|---|---|---|---|
| `fire_shard` | Fire Shard | COMMON | A warm crystalline fragment. | 15 | 5 | TBD |
| `frost_shard` | Frost Shard | COMMON | A cold crystalline fragment. | 15 | 5 | TBD |
| `power_fragment` | Power Fragment | COMMON | Pulses with raw energy. | 20 | 7 | TBD |
| `spirit_essence` | Spirit Essence | UNCOMMON | A wisp of spectral energy. | 30 | 10 | TBD |
| `venom_gland` | Venom Gland | UNCOMMON | Drips with potent toxin. | 25 | 8 | TBD |
| `herb_segment` | Herb Segment | COMMON | A fragrant healing herb. | 10 | 3 | TBD |
| `inferno_shard` | Inferno Shard | RARE | Blazing hot crystal. | 50 | 18 | TBD |
| `blizzard_shard` | Blizzard Shard | RARE | Freezing cold crystal. | 50 | 18 | TBD |
| `greater_power_fragment` | Greater Power Fragment | RARE | Surges with intense energy. | 60 | 22 | TBD |
| `hellfire_shard` | Hellfire Shard | EPIC | Burns with infernal flame. | 120 | 45 | TBD |

All SEGMENTs: `item_type = SEGMENT`, `stackable = true`, `max_stack = 99`.

#### 4b. New AUGMENT items (crafting outputs — permanent)

| ID | Name | Rarity | augment_type | passive_effect | passive_value | attack_bonus | defense_bonus | health_bonus | speed_bonus | active_skill_id |
|---|---|---|---|---|---|---|---|---|---|---|
| `flame_augment_t1` | Flame Augment I | UNCOMMON | PASSIVE_EFFECT | BURN_ON_HIT | 3.0 | 5 | 0 | 0 | 0 | — |
| `flame_augment_t2` | Flame Augment II | RARE | PASSIVE_EFFECT | BURN_ON_HIT | 5.0 | 12 | 0 | 0 | 0 | — |
| `flame_augment_t3` | Flame Augment III | EPIC | PASSIVE_EFFECT | BURN_ON_HIT | 8.0 | 20 | 0 | 0 | 0 | — |
| `frost_augment_t1` | Frost Augment I | UNCOMMON | PASSIVE_EFFECT | FREEZE_ON_HIT | 1.5 | 3 | 0 | 0 | 0 | — |
| `frost_augment_t2` | Frost Augment II | RARE | PASSIVE_EFFECT | FREEZE_ON_HIT | 3.0 | 8 | 0 | 0 | 0 | — |
| `power_augment_t1` | Power Augment I | UNCOMMON | STAT_BOOST | NONE | 0 | 8 | 0 | 0 | 0 | — |
| `power_augment_t2` | Power Augment II | RARE | STAT_BOOST | NONE | 0 | 15 | 0 | 0 | 0 | — |
| `lifesteal_augment_t1` | Lifesteal Augment I | UNCOMMON | PASSIVE_EFFECT | LIFE_STEAL | 5.0 | 0 | 0 | 0 | 0 | — |
| `lifesteal_augment_t2` | Lifesteal Augment II | RARE | PASSIVE_EFFECT | LIFE_STEAL | 10.0 | 0 | 0 | 0 | 0 | — |
| `crit_augment_t1` | Critical Augment I | UNCOMMON | PASSIVE_EFFECT | CRIT_CHANCE | 8.0 | 0 | 0 | 0 | 0 | — |
| `crit_augment_t2` | Critical Augment II | RARE | PASSIVE_EFFECT | CRIT_CHANCE | 15.0 | 0 | 0 | 0 | 0 | — |
| `whirlwind_augment` | Whirlwind Rune | EPIC | ACTIVE_SKILL | NONE | 0 | 5 | 0 | 0 | 0 | `"whirlwind"` |
| `shield_bash_augment` | Shield Bash Rune | EPIC | ACTIVE_SKILL | NONE | 0 | 0 | 5 | 0 | 0 | `"shield_bash"` |

All AUGMENTs: `item_type = AUGMENT`, `stackable = false`, `max_stack = 1`.

#### 4c. New AUGMENT items (crafting outputs — timed buffs)

| ID | Name | Rarity | augment_type | buff_duration | health_bonus | speed_bonus | defense_bonus |
|---|---|---|---|---|---|---|---|
| `vitality_tonic_t1` | Vitality Tonic I | UNCOMMON | TIMED_BUFF | 60.0 | 20 | 0 | 0 |
| `vitality_tonic_t2` | Vitality Tonic II | RARE | TIMED_BUFF | 90.0 | 50 | 0 | 0 |
| `speed_elixir_t1` | Speed Elixir I | UNCOMMON | TIMED_BUFF | 45.0 | 0 | 20.0 | 0 |
| `speed_elixir_t2` | Speed Elixir II | RARE | TIMED_BUFF | 60.0 | 0 | 40.0 | 0 |
| `defense_brew_t1` | Defense Brew I | UNCOMMON | TIMED_BUFF | 45.0 | 0 | 0 | 8 |
| `defense_brew_t2` | Defense Brew II | RARE | TIMED_BUFF | 60.0 | 0 | 0 | 15 |

Timed buffs: `item_type = AUGMENT`, `stackable = true`, `max_stack = 5` (allow small stacks of potions).

#### 4d. Add atlas icon mappings

In `sense/items/item_icon_atlas.gd` `ICONS` dictionary, add entries for each new item ID mapping to sprite sheet positions (row, col). Exact positions depend on the atlas layout — assign placeholder positions that will be finalized when pixel art is created.

---

## Phase 2 — Buff & Passive Effect System

### Step 5. Create `BuffComponent` → `sense/components/buff_component.gd` (NEW FILE)

**Architecture**: Pure `Node` component. Attached as child of any entity that can have buffs (Player today, NPCs/summons later). Communicates only via signals. The parent entity wires `buffs_changed` to `CharacterStats.apply_buff_bonuses()`.

```gdscript
class_name BuffComponent
extends Node

## ╔═══════════════════════════════════════════════════════════════════════╗
## ║                      BUFF COMPONENT                                   ║
## ╠═══════════════════════════════════════════════════════════════════════╣
## ║  Manages timed stat buffs. Decoupled from CharacterStats.             ║
## ║  The owner entity (Player) wires signals:                             ║
## ║                                                                       ║
## ║  BuffComponent.buffs_changed ──▶ Player._on_buffs_changed()           ║
## ║                                    └─▶ stats.apply_buff_bonuses(buff) ║
## ║                                                                       ║
## ║  BuffComponent.buff_applied  ──▶ HUD.show_buff_icon()                 ║
## ║  BuffComponent.buff_expired  ──▶ HUD.hide_buff_icon()                 ║
## ╚═══════════════════════════════════════════════════════════════════════╝

## Emitted when any buff starts (for HUD icon display)
signal buff_applied(buff_data: Dictionary)

## Emitted when a buff expires (for HUD icon removal)
signal buff_expired(buff_id: String)

## Emitted when the aggregate buff stats change (for CharacterStats recalc)
signal buffs_changed

## Active buffs array. Each entry:
## {
##   "id": String,              # Unique buff identifier (usually source item_id)
##   "source_item_id": String,  # ItemData.id that created this buff
##   "attack_bonus": int,
##   "defense_bonus": int,
##   "health_bonus": int,
##   "speed_bonus": float,
##   "passive_effect": ItemData.PassiveEffect,
##   "passive_value": float,
##   "remaining_time": float,   # Seconds remaining (-1 = permanent, from augments)
##   "total_duration": float    # Original duration (for UI progress bar)
## }
var active_buffs: Array[Dictionary] = []


func _process(delta: float) -> void:
    var expired_ids: Array[String] = []

    for buff: Dictionary in active_buffs:
        var remaining: float = buff.get("remaining_time", -1.0)
        if remaining < 0.0:
            continue  # Permanent buff (from augment), skip tick
        buff["remaining_time"] = remaining - delta
        if buff["remaining_time"] <= 0.0:
            expired_ids.append(buff.get("id", ""))

    if expired_ids.size() > 0:
        for buff_id: String in expired_ids:
            _remove_buff_internal(buff_id)
        buffs_changed.emit()


## Apply a timed buff from an ItemData (TIMED_BUFF augment type)
## If a buff with the same id already exists, refresh its duration (no stacking)
func apply_buff(item: ItemData) -> void:
    var buff_id := item.id

    # Check for existing buff → refresh duration
    for existing: Dictionary in active_buffs:
        if existing.get("id", "") == buff_id:
            existing["remaining_time"] = item.buff_duration
            existing["total_duration"] = item.buff_duration
            buffs_changed.emit()
            return

    # Create new buff entry
    var buff_data := {
        "id": buff_id,
        "source_item_id": item.id,
        "attack_bonus": item.attack_bonus,
        "defense_bonus": item.defense_bonus,
        "health_bonus": item.health_bonus,
        "speed_bonus": item.speed_bonus,
        "passive_effect": item.passive_effect,
        "passive_value": item.passive_value,
        "remaining_time": item.buff_duration,
        "total_duration": item.buff_duration,
    }

    active_buffs.append(buff_data)
    buff_applied.emit(buff_data)
    buffs_changed.emit()


## Manually remove a buff by id
func remove_buff(buff_id: String) -> void:
    _remove_buff_internal(buff_id)
    buffs_changed.emit()


## Clear all buffs (e.g. on death)
func clear_all_buffs() -> void:
    var ids: Array[String] = []
    for buff: Dictionary in active_buffs:
        ids.append(buff.get("id", ""))
    active_buffs.clear()
    for id: String in ids:
        buff_expired.emit(id)
    buffs_changed.emit()


# === STAT AGGREGATION (called by CharacterStats) ===

func get_total_buff_attack() -> int:
    var total := 0
    for buff: Dictionary in active_buffs:
        total += buff.get("attack_bonus", 0)
    return total

func get_total_buff_defense() -> int:
    var total := 0
    for buff: Dictionary in active_buffs:
        total += buff.get("defense_bonus", 0)
    return total

func get_total_buff_health() -> int:
    var total := 0
    for buff: Dictionary in active_buffs:
        total += buff.get("health_bonus", 0)
    return total

func get_total_buff_speed() -> float:
    var total := 0.0
    for buff: Dictionary in active_buffs:
        total += buff.get("speed_bonus", 0.0)
    return total


# === PASSIVE EFFECT QUERIES (called by PassiveEffectProcessor) ===

## Returns all active passive effects as Array[{effect: PassiveEffect, value: float}]
func get_active_passive_effects() -> Array[Dictionary]:
    var effects: Array[Dictionary] = []
    for buff: Dictionary in active_buffs:
        var effect: int = buff.get("passive_effect", ItemData.PassiveEffect.NONE)
        if effect != ItemData.PassiveEffect.NONE:
            effects.append({"effect": effect, "value": buff.get("passive_value", 0.0)})
    return effects


func _remove_buff_internal(buff_id: String) -> void:
    for i: int in range(active_buffs.size() - 1, -1, -1):
        if active_buffs[i].get("id", "") == buff_id:
            active_buffs.remove_at(i)
            buff_expired.emit(buff_id)
            return
```

---

### Step 6. Create `PassiveEffectProcessor` → `sense/components/passive_effect_processor.gd` (NEW FILE)

**Architecture**: Pure `Node` component. Bridges between combat events (hit_landed, damage_received) and passive effect logic.
Does **not** reference BuffComponent or InventoryData directly — instead, it queries aggregated passive effects from the owner entity via a `Callable` injected at setup time.

```gdscript
class_name PassiveEffectProcessor
extends Node

## ╔═══════════════════════════════════════════════════════════════════════╗
## ║                 PASSIVE EFFECT PROCESSOR                              ║
## ╠═══════════════════════════════════════════════════════════════════════╣
## ║  Decoupled combat-effect handler. Owner injects:                      ║
## ║  - get_passive_effects_func: Callable → Array[{effect, value}]        ║
## ║  - get_owner_stats_func: Callable → CharacterStats                    ║
## ║                                                                       ║
## ║  Owner wires HitboxComponent.hit_landed → on_hit_landed()             ║
## ║  Owner wires HurtboxComponent.damage_received → on_damage_received()  ║
## ║                                                                       ║
## ║  This component never imports BuffComponent or InventoryData.         ║
## ╚═══════════════════════════════════════════════════════════════════════╝

## Injected by owner — returns Array[Dictionary] of {effect: PassiveEffect, value: float}
var get_passive_effects_func: Callable

## Injected by owner — returns CharacterStats (for healing, etc.)
var get_owner_stats_func: Callable

## Injected by owner — returns the owner Node2D (for position-based effects)
var get_owner_node_func: Callable


## Called by owner when HitboxComponent.hit_landed fires
## Parameters: hurtbox = the HurtboxComponent that was hit, damage_dealt = int
func on_hit_landed(hurtbox: Area2D, damage_dealt: int) -> void:
    if get_passive_effects_func == null:
        return

    var effects: Array[Dictionary] = get_passive_effects_func.call()

    for entry: Dictionary in effects:
        var effect: int = entry.get("effect", ItemData.PassiveEffect.NONE)
        var value: float = entry.get("value", 0.0)

        match effect:
            ItemData.PassiveEffect.LIFE_STEAL:
                _apply_life_steal(damage_dealt, value)

            ItemData.PassiveEffect.CRIT_CHANCE:
                pass  # Crit is handled BEFORE damage in _calculate_damage(), not here

            ItemData.PassiveEffect.BURN_ON_HIT:
                _apply_dot_to_target(hurtbox, "burn", value)

            ItemData.PassiveEffect.FREEZE_ON_HIT:
                _apply_slow_to_target(hurtbox, value)

            ItemData.PassiveEffect.POISON_ON_HIT:
                _apply_dot_to_target(hurtbox, "poison", value)


## Called by owner when HurtboxComponent.damage_received fires
## Parameters: amount = damage taken, from_position = attacker position
func on_damage_received(amount: int, _knockback: float, from_position: Vector2) -> void:
    if get_passive_effects_func == null:
        return

    var effects: Array[Dictionary] = get_passive_effects_func.call()

    for entry: Dictionary in effects:
        var effect: int = entry.get("effect", ItemData.PassiveEffect.NONE)
        var value: float = entry.get("value", 0.0)

        match effect:
            ItemData.PassiveEffect.THORNS:
                _apply_thorns(amount, value, from_position)


## Check if crit should apply, returns modified damage
## Called by the owner BEFORE dealing damage (inside attack logic)
func calculate_crit_damage(base_damage: int) -> int:
    if get_passive_effects_func == null:
        return base_damage

    var effects: Array[Dictionary] = get_passive_effects_func.call()
    var total_crit_chance := 0.0

    for entry: Dictionary in effects:
        if entry.get("effect", 0) == ItemData.PassiveEffect.CRIT_CHANCE:
            total_crit_chance += entry.get("value", 0.0)

    # Roll crit
    if total_crit_chance > 0.0 and randf() * 100.0 < total_crit_chance:
        return base_damage * 2
    return base_damage


func _apply_life_steal(damage_dealt: int, percent: float) -> void:
    if get_owner_stats_func == null:
        return
    var stats: CharacterStats = get_owner_stats_func.call()
    var heal_amount := int(float(damage_dealt) * percent / 100.0)
    if heal_amount > 0:
        stats.heal(heal_amount)


func _apply_dot_to_target(hurtbox: Area2D, dot_type: String, damage_per_tick: float) -> void:
    # Find the HealthComponent on the target entity
    var target_entity := hurtbox.get_parent()
    if target_entity == null:
        return
    var health_comp: HealthComponent = _find_child_of_type(target_entity, "HealthComponent")
    if health_comp == null:
        return

    # Apply DoT via a lightweight timer (3 ticks, 1s apart)
    # TODO: Replace with a proper StatusEffectComponent on the enemy in future
    var ticks := 3
    var tick_damage := int(damage_per_tick)
    for i: int in range(ticks):
        if not is_instance_valid(target_entity):
            return
        await get_tree().create_timer(1.0).timeout
        if is_instance_valid(health_comp) and not health_comp.is_dead():
            health_comp.take_damage(tick_damage)


func _apply_slow_to_target(hurtbox: Area2D, slow_percent: float) -> void:
    # Reduce target's movement speed temporarily
    var target_entity := hurtbox.get_parent()
    if target_entity == null or not target_entity.has_method("apply_slow"):
        return
    target_entity.apply_slow(slow_percent, 2.0)  # 2 second slow


func _apply_thorns(damage_received: int, reflect_percent: float, from_position: Vector2) -> void:
    # Reflect damage back to attacker — find nearest enemy at from_position
    # This is a best-effort: raycast or area scan at from_position for enemy HealthComponent
    var reflect_damage := int(float(damage_received) * reflect_percent / 100.0)
    if reflect_damage <= 0:
        return

    if get_owner_node_func == null:
        return
    var owner_node: Node2D = get_owner_node_func.call()
    if owner_node == null:
        return

    # Find enemies near the attacker position
    var space_state := owner_node.get_world_2d().direct_space_state
    var query := PhysicsPointQueryParameters2D.new()
    query.position = from_position
    query.collision_mask = CollisionLayers.Layer.ENEMY
    query.collide_with_bodies = true
    var results := space_state.intersect_point(query, 1)

    for result: Dictionary in results:
        var collider: Object = result.get("collider")
        if collider is Node:
            var health_comp: HealthComponent = _find_child_of_type(collider as Node, "HealthComponent")
            if health_comp and not health_comp.is_dead():
                health_comp.take_damage(reflect_damage)
                return


## Utility: find first child node of a given class name
func _find_child_of_type(parent: Node, type_name: String) -> Node:
    for child: Node in parent.get_children():
        if child.get_class() == type_name or (child.get_script() and child.get_script().get_global_name() == type_name):
            return child
    return null
```

---

### Step 7. Integrate buffs into `CharacterStats` → modify `sense/entities/player/character_stats.gd`

**Current state**: Has `equipment_*_bonus` vars, computed properties return `base + equipment`.

**Changes**:

#### 7a. Add buff bonus vars alongside equipment vars

```gdscript
# === BUFF BONUSES (from BuffComponent) ===
var buff_attack_bonus: int = 0
var buff_defense_bonus: int = 0
var buff_health_bonus: int = 0
var buff_speed_bonus: float = 0.0
```

#### 7b. Update computed properties to include buff bonuses

```gdscript
var attack_damage: int:
    get:
        return base_attack_damage + equipment_attack_bonus + buff_attack_bonus

var defense: int:
    get:
        return base_defense + equipment_defense_bonus + buff_defense_bonus

var move_speed: float:
    get:
        return base_move_speed + equipment_speed_bonus + buff_speed_bonus

var max_health: int:
    get:
        return base_max_health + equipment_health_bonus + buff_health_bonus
```

#### 7c. Add `apply_buff_bonuses()` method

```gdscript
## Apply buff bonuses from BuffComponent — called when buffs_changed fires
func apply_buff_bonuses(buff_component: BuffComponent) -> void:
    if buff_component == null:
        return
    buff_attack_bonus = buff_component.get_total_buff_attack()
    buff_defense_bonus = buff_component.get_total_buff_defense()
    buff_health_bonus = buff_component.get_total_buff_health()
    buff_speed_bonus = buff_component.get_total_buff_speed()
    health_changed.emit(current_health, max_health)

## Clear all buff bonuses (e.g. on death)
func clear_buff_bonuses() -> void:
    buff_attack_bonus = 0
    buff_defense_bonus = 0
    buff_health_bonus = 0
    buff_speed_bonus = 0
    health_changed.emit(current_health, max_health)
```

#### 7d. Update the ASCII stat diagram comment

```
## ║  Final Stat = Base Stat + Equipment Bonus + Buff Bonus                ║
```

---

## Phase 3 — Equipment Augmentation System

### Step 8. Add augment management to `InventoryData` → modify `sense/ui/inventory/inventory_data.gd`

**Current state**: 400 lines. Has 7 equipment slot vars, `get_total_*_bonus()` methods that iterate equipped items.

**Changes**:

#### 8a. Add new signal

```gdscript
signal augments_changed(equip_slot: String)
```

#### 8b. Add `apply_augment()` method

```gdscript
## Apply an augment item to an equipped item's augment slot
## augment_inventory_index = index of the AUGMENT item in inventory_slots
## equip_slot = "weapon", "armor", "helmet", "boots", "shield", "accessory_1", "accessory_2"
## Returns true on success, false if slot full or invalid
func apply_augment(equip_slot: String, augment_inventory_index: int) -> bool:
    var augment_slot := get_item_at(augment_inventory_index)
    if augment_slot.item == null or not augment_slot.item.is_augment():
        return false

    var equipment: ItemData = get_equipped(equip_slot)
    if equipment == null:
        return false

    # Check if equipment has open augment slots
    if not equipment.is_augmentable():
        return false

    # Duplicate equipment on first augment to create unique instance
    # (so we don't mutate the ItemDatabase template)
    if equipment.applied_augments.size() == 0:
        var unique_equipment := equipment.duplicate() as ItemData
        unique_equipment.applied_augments = []
        _set_equipped(equip_slot, unique_equipment)
        equipment = unique_equipment

    # Add augment ID to equipment's applied_augments
    equipment.applied_augments.append(augment_slot.item.id)

    # Remove augment item from inventory
    remove_item_at(augment_inventory_index, 1)

    augments_changed.emit(equip_slot)
    equipment_changed.emit(equip_slot)
    inventory_changed.emit()
    return true
```

#### 8c. Add `remove_augment()` method

```gdscript
## Remove an augment from an equipped item and return it to inventory
## augment_index = index within equipment.applied_augments array
## Returns true on success (augment returned to inventory)
func remove_augment(equip_slot: String, augment_index: int) -> bool:
    var equipment: ItemData = get_equipped(equip_slot)
    if equipment == null:
        return false
    if augment_index < 0 or augment_index >= equipment.applied_augments.size():
        return false

    var augment_id: String = equipment.applied_augments[augment_index]
    var augment_item: ItemData = ItemDatabase.get_item(augment_id)
    if augment_item == null:
        return false

    # Add augment back to inventory (check for space first)
    var remaining := add_item(augment_item, 1)
    if remaining > 0:
        return false  # Inventory full

    # Remove from equipment's augment list
    equipment.applied_augments.remove_at(augment_index)

    augments_changed.emit(equip_slot)
    equipment_changed.emit(equip_slot)
    return true
```

#### 8d. Update `get_total_*_bonus()` methods to include augment stats

```gdscript
func get_total_attack_bonus() -> int:
    var total := 0
    for item: ItemData in [equipped_weapon, equipped_helmet, equipped_armor, equipped_boots,
                 equipped_shield, equipped_accessory_1, equipped_accessory_2]:
        if item != null:
            total += item.attack_bonus
            total += _get_augment_stat_sum(item, "attack_bonus")
    return total


## Helper: sum a stat field from all augments applied to an equipment item
func _get_augment_stat_sum(equipment: ItemData, stat_field: String) -> int:
    var total := 0
    for augment_id: String in equipment.applied_augments:
        var augment: ItemData = ItemDatabase.get_item(augment_id)
        if augment != null:
            total += augment.get(stat_field)
    return total
```

Apply the same pattern for `get_total_defense_bonus()`, `get_total_health_bonus()`, `get_total_speed_bonus()`.

#### 8e. Add passive effect aggregation method

```gdscript
## Collect all passive effects from augments on all equipped items
## Returns Array[Dictionary] of {effect: PassiveEffect, value: float}
func get_all_augment_passive_effects() -> Array[Dictionary]:
    var effects: Array[Dictionary] = []
    for item: ItemData in [equipped_weapon, equipped_helmet, equipped_armor, equipped_boots,
                 equipped_shield, equipped_accessory_1, equipped_accessory_2]:
        if item == null:
            continue
        for augment_id: String in item.applied_augments:
            var augment: ItemData = ItemDatabase.get_item(augment_id)
            if augment != null and augment.passive_effect != ItemData.PassiveEffect.NONE:
                effects.append({"effect": augment.passive_effect, "value": augment.passive_value})
    return effects
```

#### 8f. Add active skill collection method

```gdscript
## Collect all active skill IDs from augments on all equipped items
## Returns Array[Dictionary] of {skill_id: String, source_equip_slot: String}
func get_all_augment_active_skills() -> Array[Dictionary]:
    var skills: Array[Dictionary] = []
    var slot_names := ["weapon", "helmet", "armor", "boots", "shield", "accessory_1", "accessory_2"]
    var slot_items := [equipped_weapon, equipped_helmet, equipped_armor, equipped_boots,
                       equipped_shield, equipped_accessory_1, equipped_accessory_2]
    for i: int in range(slot_items.size()):
        var item: ItemData = slot_items[i]
        if item == null:
            continue
        for augment_id: String in item.applied_augments:
            var augment: ItemData = ItemDatabase.get_item(augment_id)
            if augment != null and augment.augment_type == ItemData.AugmentType.ACTIVE_SKILL:
                skills.append({"skill_id": augment.active_skill_id, "source_equip_slot": slot_names[i]})
    return skills
```

#### 8g. Update `use_item()` to handle timed buffs

```gdscript
func use_item(index: int) -> Dictionary:
    var slot := get_item_at(index)
    if slot.item == null:
        return {"success": false}

    # Handle regular consumables (existing logic)
    if slot.item.item_type == ItemData.ItemType.CONSUMABLE:
        var item: ItemData = slot.item
        var result := {
            "success": true,
            "heal_amount": item.heal_amount,
            "stamina_restore": item.stamina_restore,
            "effect_duration": item.effect_duration,
            "is_timed_buff": false
        }
        remove_item_at(index, 1)
        return result

    # Handle timed buff consumables (NEW)
    if slot.item.is_timed_buff():
        var item: ItemData = slot.item
        var result := {
            "success": true,
            "is_timed_buff": true,
            "buff_item": item,  # Pass full ItemData so BuffComponent can read it
            "heal_amount": 0,
            "stamina_restore": 0.0,
            "effect_duration": item.buff_duration
        }
        remove_item_at(index, 1)
        return result

    return {"success": false}
```

---

### Step 9. Create `SkillComponent` → `sense/components/skill_component.gd` (NEW FILE)

**Architecture**: Pure `Node` component. Does NOT import `InventoryData` or `BuffComponent`.
The owner injects a `Callable` that returns active skill data. It listens for rebuild triggers via signal.

```gdscript
class_name SkillComponent
extends Node

## ╔═══════════════════════════════════════════════════════════════════════╗
## ║                    SKILL COMPONENT                                    ║
## ╠═══════════════════════════════════════════════════════════════════════╣
## ║  Manages equipment-bound active skills. Decoupled design:             ║
## ║                                                                       ║
## ║  Owner injects:                                                       ║
## ║  - get_active_skills_func: Callable → Array[{skill_id, slot}]         ║
## ║  - use_stamina_func: Callable(float) → bool                           ║
## ║                                                                       ║
## ║  Owner calls rebuild_skills() when equipment/augments change.         ║
## ║                                                                       ║
## ║  Skill key mapping (based on source equipment slot):                  ║
## ║  ┌───────────────────┬───────┐                                        ║
## ║  │ weapon augment    │ Q key │                                        ║
## ║  │ armor augment     │ E key │                                        ║
## ║  │ helmet augment    │ R key │                                        ║
## ║  │ boots augment     │ F key │                                        ║
## ║  │ shield augment    │ Q key │ (fallback)                             ║
## ║  │ accessory_1       │ E key │ (fallback)                             ║
## ║  │ accessory_2       │ R key │ (fallback)                             ║
## ║  └───────────────────┴───────┘                                        ║
## ╚═══════════════════════════════════════════════════════════════════════╝

signal skill_activated(skill_id: String)
signal skill_cooldown_updated(skill_id: String, remaining: float)
signal skills_changed

## Injected by owner — returns Array[{skill_id: String, source_equip_slot: String}]
var get_active_skills_func: Callable

## Injected by owner — attempts to use stamina, returns bool
var use_stamina_func: Callable

## Current available skills with cooldown tracking
## Array[Dictionary]: {skill_id, source_equip_slot, cooldown, current_cooldown, input_action}
var available_skills: Array[Dictionary] = []

## Skill input action mapping by equipment slot
const SLOT_INPUT_MAP: Dictionary = {
    "weapon": "skill_1",      # Q key (define in project input map)
    "armor": "skill_2",       # E key
    "helmet": "skill_3",      # R key
    "boots": "skill_4",       # F key
    "shield": "skill_1",
    "accessory_1": "skill_2",
    "accessory_2": "skill_3",
}


func _process(delta: float) -> void:
    # Tick down cooldowns
    for skill: Dictionary in available_skills:
        var cd: float = skill.get("current_cooldown", 0.0)
        if cd > 0.0:
            skill["current_cooldown"] = maxf(0.0, cd - delta)
            skill_cooldown_updated.emit(skill.get("skill_id", ""), skill["current_cooldown"])


func _unhandled_input(event: InputEvent) -> void:
    for skill: Dictionary in available_skills:
        var input_action: String = skill.get("input_action", "")
        if input_action.is_empty():
            continue
        if event.is_action_pressed(input_action):
            try_activate_skill(skill.get("skill_id", ""))
            return


## Rebuild the available skills list from owner's data
## Called by owner when equipment_changed or augments_changed fires
func rebuild_skills() -> void:
    available_skills.clear()

    if get_active_skills_func == null:
        skills_changed.emit()
        return

    var raw_skills: Array = get_active_skills_func.call()
    for entry: Dictionary in raw_skills:
        var skill_id: String = entry.get("skill_id", "")
        var slot: String = entry.get("source_equip_slot", "")
        var skill_data: SkillData = SkillDatabase.get_skill(skill_id) if skill_id != "" else null

        if skill_data == null:
            continue

        available_skills.append({
            "skill_id": skill_id,
            "source_equip_slot": slot,
            "cooldown": skill_data.cooldown,
            "current_cooldown": 0.0,
            "stamina_cost": skill_data.stamina_cost,
            "input_action": SLOT_INPUT_MAP.get(slot, ""),
        })

    skills_changed.emit()


## Attempt to activate a skill by id
func try_activate_skill(skill_id: String) -> bool:
    for skill: Dictionary in available_skills:
        if skill.get("skill_id", "") != skill_id:
            continue

        # Check cooldown
        if skill.get("current_cooldown", 0.0) > 0.0:
            return false

        # Check stamina
        var cost: float = skill.get("stamina_cost", 0.0)
        if use_stamina_func != null and not use_stamina_func.call(cost):
            return false

        # Start cooldown
        skill["current_cooldown"] = skill.get("cooldown", 0.0)

        # Emit activation signal — owner handles state change + execution
        skill_activated.emit(skill_id)
        return true

    return false


## Check if a skill is off cooldown
func is_skill_ready(skill_id: String) -> bool:
    for skill: Dictionary in available_skills:
        if skill.get("skill_id", "") == skill_id:
            return skill.get("current_cooldown", 0.0) <= 0.0
    return false
```

---

## Phase 4 — Crafting UI (integrated into Blacksmith)

### Step 10. Integrate crafting into Blacksmith → modify `sense/entities/npcs/blacksmith/smith_shop_popup.gd` + `blacksmith.gd` (EXISTING FILES)

**Architecture**: Crafting is a **tab** within the existing Blacksmith shop UI (`SmithShopPopup`). No separate CraftingStation entity is needed — the blacksmith forge already serves as the crafting station. The `SmithShopPopup` has two main tabs: "Buy/Sell" and "Crafting". When the player selects the "Crafting" tab, the `CraftingPanel` is shown alongside an embedded inventory panel.

```
SmithShopPopup (Control)
├── Dim (ColorRect)                  # Click-to-close background
└── Panel
    └── VBox
        ├── TitleRow (HBox)          # Title + Close button
        ├── MainTabsRow (HBox)       # [Buy/Sell] [Crafting] tab buttons
        ├── ShopContent (VBox)       # Buy/Sell tab content (existing)
        │   ├── CategoryTabs
        │   └── ItemsScroll
        └── CraftingContent (HBox)   # Crafting tab content
            ├── CraftingPanel        # Recipe list + detail + craft button
            └── InventoryContainer   # Embedded inventory for ingredient reference
```

**Key behavior** (`smith_shop_popup.gd`):
- `_create_main_tabs()` — Creates "Buy/Sell" and "Crafting" tab buttons
- `_switch_main_tab(tab)` — Toggles between shop and crafting content
- `_setup_crafting_view()` — Injects player inventory into `CraftingPanel` and creates an `EmbeddedInventoryPanel` for reference
- `CraftingPanel` is a child node of the popup, built programmatically via `_build_ui()` in `_ready()`

**No separate scene needed**: The `CraftingPanel` class (`sense/ui/crafting/crafting_panel.gd`) is a `Panel` that constructs its entire UI in code. It is instantiated as a child of `CraftingContent` in the blacksmith popup scene (`smith_shop_popup.tscn`).

---

### Step 11. `CraftingPanel` UI → `sense/ui/crafting/crafting_panel.gd` (EXISTING FILE)

**Architecture**: `Panel` node embedded within `SmithShopPopup`. Builds its entire UI programmatically in `_ready()` via `_build_ui()`. Receives player inventory via `set_player_inventory()` or `initialize()` (for UIPopupComponent compatibility).

```
CraftingPanel (CanvasLayer)
├── PanelContainer                # Main frame
│   ├── VBoxContainer
│   │   ├── Label                 # "Crafting Station" title
│   │   ├── HBoxContainer         # Category tabs: [Augments] [Buffs] [All]
│   │   ├── HSeparator
│   │   └── HBoxContainer         # Main content
│   │       ├── ScrollContainer    # LEFT: Recipe list
│   │       │   └── VBoxContainer
│   │       │       └── [RecipeListItem] × N
│   │       └── VBoxContainer      # RIGHT: Recipe detail
│   │           ├── Label          # Recipe name
│   │           ├── Label          # Description
│   │           ├── HBoxContainer  # Tier selector buttons: [T1] [T2] [T3]
│   │           ├── HSeparator
│   │           ├── VBoxContainer  # Ingredient list (icon + name + owned/required)
│   │           ├── HSeparator
│   │           ├── HBoxContainer  # Output preview (icon + name + stat summary)
│   │           └── Button         # "Craft" button (disabled if insufficient)
└── ColorRect                      # Dim background (same as inventory)
```

**Key methods in `crafting_panel.gd`**:

```gdscript
extends CanvasLayer

signal crafting_closed

var inventory: InventoryData
var selected_recipe: CraftingRecipe = null
var selected_tier: int = 1

func initialize(data: Dictionary) -> void:
    inventory = data.get("inventory")
    _populate_recipe_list()
    _refresh_detail()

func show_popup() -> void:
    visible = true
    _refresh_all()

func hide_popup() -> void:
    visible = false
    crafting_closed.emit()
    queue_free()

func _on_recipe_selected(recipe: CraftingRecipe) -> void:
    selected_recipe = recipe
    selected_tier = 1
    _refresh_detail()

func _on_tier_selected(tier: int) -> void:
    selected_tier = tier
    _refresh_detail()

func _on_craft_pressed() -> void:
    if selected_recipe == null:
        return
    if not selected_recipe.can_craft(inventory, selected_tier):
        return
    _execute_craft()

func _execute_craft() -> void:
    # Consume ingredients
    var ingredients := selected_recipe.get_ingredients(selected_tier)
    for ingredient: Dictionary in ingredients:
        var item: ItemData = ItemDatabase.get_item(ingredient.get("item_id", ""))
        if item:
            inventory.remove_item(item, ingredient.get("quantity", 0))

    # Add result
    var result_id := selected_recipe.get_result_item_id(selected_tier)
    var result_qty := selected_recipe.get_result_quantity(selected_tier)
    var result_item: ItemData = ItemDatabase.get_item_copy(result_id)
    if result_item:
        inventory.add_item(result_item, result_qty)

    GameEvent.item_crafted.emit(selected_recipe.id, selected_tier)
    _refresh_all()

func _refresh_all() -> void:
    _populate_recipe_list()
    _refresh_detail()

func _refresh_detail() -> void:
    # Update ingredient list (green = have enough, red = insufficient)
    # Update output preview (icon + stats)
    # Update craft button enabled/disabled
    # Update tier button highlights
    pass  # Implementation draws UI elements from recipe data

func _populate_recipe_list() -> void:
    # Clear and rebuild recipe list from RecipeDatabase
    # Highlight recipes that can be crafted with current inventory
    pass
```

---

### Step 12. Create `AugmentPanel` UI → `sense/ui/augment/augment_panel.gd` + `AugmentPanel.tscn` (NEW FILES)

**Architecture**: Opened as a sub-panel from `InventoryPanel` when the player clicks "Augment" on an equipment slot. It receives a reference to the equipped `ItemData` and the `InventoryData`.

```
AugmentPanel (PanelContainer)
├── VBoxContainer
│   ├── Label                    # "Augment: [Equipment Name]"
│   ├── HBoxContainer            # Equipment stats summary
│   ├── HSeparator
│   ├── GridContainer            # Augment slots (0-4 based on rarity)
│   │   └── [AugmentSlotUI] × N # Each shows augment icon or empty outline
│   ├── HSeparator
│   ├── Label                    # "Drag an augment from inventory to apply"
│   └── Button                   # "Close"
```

**Key methods in `augment_panel.gd`**:

```gdscript
extends PanelContainer

signal augment_applied(equip_slot: String)
signal augment_removed(equip_slot: String, augment_index: int)
signal panel_closed

var inventory: InventoryData
var equip_slot: String = ""
var equipment_item: ItemData = null

func setup(inv: InventoryData, slot: String) -> void:
    inventory = inv
    equip_slot = slot
    equipment_item = inventory.get_equipped(slot)
    _refresh()

func _refresh() -> void:
    equipment_item = inventory.get_equipped(equip_slot)
    if equipment_item == null:
        hide()
        return
    _draw_augment_slots()
    _update_stats_display()

func _draw_augment_slots() -> void:
    var slot_count := equipment_item.get_augment_slot_count()
    var applied := equipment_item.applied_augments
    # Render slot_count slots: filled ones show augment icon+name, empty show outline
    # Enable drag-drop from inventory slots (filter for is_augment() items)

func _on_augment_slot_clicked(augment_index: int) -> void:
    # Show context menu: [Remove Augment]
    pass

func _on_augment_drop(augment_inventory_index: int) -> void:
    if inventory.apply_augment(equip_slot, augment_inventory_index):
        augment_applied.emit(equip_slot)
        _refresh()

func _on_remove_augment(augment_index: int) -> void:
    if inventory.remove_augment(equip_slot, augment_index):
        augment_removed.emit(equip_slot, augment_index)
        _refresh()
```

**Integration with `InventoryPanel`**:
- Add an "Augment" button to each equipment slot in `inventory_panel.gd`
- Button is visible only when `equipment_item.get_augment_slot_count() > 0`
- On click → instantiate `AugmentPanel` as child of the inventory CanvasLayer

---

## Phase 5 — Active Skill Implementation

### Step 13. Create `SkillData` resource → `sense/skills/skill_data.gd` (NEW FILE)

```gdscript
class_name SkillData
extends Resource

## ╔════════════════════════════════════════════════════════╗
## ║  Skill Data — defines one activatable skill            ║
## ║  Referenced by SkillComponent via skill_id             ║
## ╚════════════════════════════════════════════════════════╝

@export var id: String = ""
@export var skill_name: String = ""
@export var description: String = ""
@export var cooldown: float = 5.0
@export var stamina_cost: float = 30.0
@export var damage_multiplier: float = 1.5
@export var range_radius: float = 40.0            # Hitbox radius
@export var knockback_force: float = 150.0
@export var effect_scene: PackedScene = null       # Optional VFX scene
```

### Step 14. Create `SkillDatabase` → `sense/skills/skill_database.gd` (NEW FILE, autoload)

```gdscript
extends Node

var skills: Dictionary = {}  # skill_id → SkillData

func _ready() -> void:
    _create_skills()

func get_skill(skill_id: String) -> SkillData:
    return skills.get(skill_id)

func _create_skills() -> void:
    _add_skill("whirlwind", "Whirlwind", "Spin attack hitting all nearby enemies.", 6.0, 35.0, 1.8, 50.0, 200.0)
    _add_skill("shield_bash", "Shield Bash", "Bash forward, knocking back and stunning.", 8.0, 25.0, 1.2, 30.0, 300.0)
    _add_skill("fire_burst", "Fire Burst", "Launch a burst of fire in facing direction.", 10.0, 40.0, 2.0, 60.0, 100.0)

func _add_skill(id: String, sname: String, desc: String, cd: float, stam: float, dmg_mult: float, range_r: float, kb: float) -> void:
    var skill := SkillData.new()
    skill.id = id
    skill.skill_name = sname
    skill.description = desc
    skill.cooldown = cd
    skill.stamina_cost = stam
    skill.damage_multiplier = dmg_mult
    skill.range_radius = range_r
    skill.knockback_force = kb
    skills[id] = skill
```

### Step 15. Create `SkillExecutor` → `sense/skills/skill_executor.gd` (NEW FILE)

**Architecture**: Pure `Node` component. Creates temporary `HitboxComponent`-compatible `Area2D` nodes for skill effects. Does not reference Player directly — receives position, direction, damage as parameters.

```gdscript
class_name SkillExecutor
extends Node

## ╔═══════════════════════════════════════════════════════════════════════╗
## ║  Skill Executor — spawns skill hitboxes/effects in the world          ║
## ║  Decoupled: receives (skill_data, position, direction, base_damage)   ║
## ║  Does NOT reference Player, SkillComponent, or any other component    ║
## ╚═══════════════════════════════════════════════════════════════════════╝

signal skill_effect_finished(skill_id: String)


## Execute a skill at a position in a direction
func execute_skill(skill: SkillData, origin: Vector2, direction: Vector2, base_damage: int, parent_node: Node2D) -> void:
    match skill.id:
        "whirlwind":
            _execute_whirlwind(skill, origin, base_damage, parent_node)
        "shield_bash":
            _execute_shield_bash(skill, origin, direction, base_damage, parent_node)
        "fire_burst":
            _execute_fire_burst(skill, origin, direction, base_damage, parent_node)
        _:
            push_warning("SkillExecutor: Unknown skill '%s'" % skill.id)


func _execute_whirlwind(skill: SkillData, origin: Vector2, base_damage: int, parent_node: Node2D) -> void:
    # AoE circle around player
    var damage := int(float(base_damage) * skill.damage_multiplier)
    var hitbox := _create_skill_hitbox(origin, skill.range_radius, damage, skill.knockback_force, parent_node)

    # Active for 0.3s then cleanup
    await get_tree().create_timer(0.3).timeout
    if is_instance_valid(hitbox):
        hitbox.queue_free()
    skill_effect_finished.emit(skill.id)


func _execute_shield_bash(skill: SkillData, origin: Vector2, direction: Vector2, base_damage: int, parent_node: Node2D) -> void:
    # Forward cone
    var damage := int(float(base_damage) * skill.damage_multiplier)
    var offset := direction.normalized() * skill.range_radius * 0.5
    var hitbox := _create_skill_hitbox(origin + offset, skill.range_radius * 0.6, damage, skill.knockback_force, parent_node)

    await get_tree().create_timer(0.2).timeout
    if is_instance_valid(hitbox):
        hitbox.queue_free()
    skill_effect_finished.emit(skill.id)


func _execute_fire_burst(skill: SkillData, origin: Vector2, direction: Vector2, base_damage: int, parent_node: Node2D) -> void:
    # Ranged projectile-like AoE at distance
    var damage := int(float(base_damage) * skill.damage_multiplier)
    var target_pos := origin + direction.normalized() * skill.range_radius
    var hitbox := _create_skill_hitbox(target_pos, 25.0, damage, skill.knockback_force, parent_node)

    await get_tree().create_timer(0.4).timeout
    if is_instance_valid(hitbox):
        hitbox.queue_free()
    skill_effect_finished.emit(skill.id)


## Create a temporary HitboxComponent-compatible Area2D
func _create_skill_hitbox(pos: Vector2, radius: float, damage: int, knockback: float, parent_node: Node2D) -> Area2D:
    var area := Area2D.new()
    area.global_position = pos
    area.collision_layer = CollisionLayers.Layer.PLAYER_HITBOX   # Layer 7
    area.collision_mask = CollisionLayers.Layer.ENEMY_HURTBOX    # Layer 6
    area.monitoring = true
    area.monitorable = false

    var shape := CollisionShape2D.new()
    var circle := CircleShape2D.new()
    circle.radius = radius
    shape.shape = circle
    area.add_child(shape)

    # Connect to detect hurtboxes
    area.area_entered.connect(func(other: Area2D):
        if other.has_method("take_damage"):
            other.take_damage(damage, knockback, pos)
    )

    parent_node.get_parent().add_child(area)
    return area
```

### Step 16. Add `SKILL` state to Player → modify `sense/entities/player/player.gd`

**Current state**: `enum State { IDLE, MOVE, ATTACK, DEATH }`, state machine in `_physics_process`.

**Changes**:

#### 16a. Add state

```gdscript
enum State { IDLE, MOVE, ATTACK, DEATH, SKILL }
```

#### 16b. Add component references in `_ready()`

```gdscript
# In _ready() — create and wire new components
var buff_component := BuffComponent.new()
buff_component.name = "BuffComponent"
add_child(buff_component)
buff_component.buffs_changed.connect(_on_buffs_changed)

var passive_processor := PassiveEffectProcessor.new()
passive_processor.name = "PassiveEffectProcessor"
add_child(passive_processor)
passive_processor.get_passive_effects_func = _get_all_passive_effects
passive_processor.get_owner_stats_func = func(): return stats
passive_processor.get_owner_node_func = func(): return self

var skill_component := SkillComponent.new()
skill_component.name = "SkillComponent"
add_child(skill_component)
skill_component.get_active_skills_func = func(): return inventory.get_all_augment_active_skills()
skill_component.use_stamina_func = func(cost: float): return stats.use_stamina(cost)
skill_component.skill_activated.connect(_on_skill_activated)

var skill_executor := SkillExecutor.new()
skill_executor.name = "SkillExecutor"
add_child(skill_executor)
skill_executor.skill_effect_finished.connect(_on_skill_effect_finished)

# Wire existing hitbox/hurtbox to passive processor
attack_hitbox.hit_landed.connect(func(hurtbox):
    passive_processor.on_hit_landed(hurtbox, stats.attack_damage)
)
hurtbox.damage_received.connect(func(amount, knockback, from_pos):
    passive_processor.on_damage_received(amount, knockback, from_pos)
)
```

#### 16c. Add signal handlers

```gdscript
func _on_buffs_changed() -> void:
    stats.apply_buff_bonuses(buff_component)

func _on_skill_activated(skill_id: String) -> void:
    if current_state == State.DEATH:
        return
    _change_state(State.SKILL)
    var skill_data := SkillDatabase.get_skill(skill_id)
    if skill_data:
        skill_executor.execute_skill(skill_data, global_position, last_direction, stats.attack_damage, self)
    # TODO: Play skill animation based on skill_id

func _on_skill_effect_finished(_skill_id: String) -> void:
    if current_state == State.SKILL:
        _change_state(State.IDLE)

func _get_all_passive_effects() -> Array[Dictionary]:
    # Aggregate from augments + active buffs
    var effects: Array[Dictionary] = []
    if inventory:
        effects.append_array(inventory.get_all_augment_passive_effects())
    if buff_component:
        effects.append_array(buff_component.get_active_passive_effects())
    return effects
```

#### 16d. Wire `equipment_changed` / `augments_changed` to rebuild skills

```gdscript
# In _setup_inventory() or _ready()
inventory.augments_changed.connect(func(_slot): skill_component.rebuild_skills())
inventory.equipment_changed.connect(func(_slot): skill_component.rebuild_skills())
```

#### 16e. Update `_on_item_used()` to handle timed buffs

```gdscript
func _on_item_used(result: Dictionary) -> void:
    if not result.get("success", false):
        return

    if result.get("is_timed_buff", false):
        var buff_item: ItemData = result.get("buff_item")
        if buff_item and buff_component:
            buff_component.apply_buff(buff_item)
        return

    # Existing consumable logic
    var heal_amount: int = result.get("heal_amount", 0)
    if heal_amount > 0:
        stats.heal(heal_amount)
    var stamina_restore: float = result.get("stamina_restore", 0.0)
    if stamina_restore > 0.0:
        stats.restore_stamina(stamina_restore)
```

#### 16f. Add SKILL state processing in state machine

```gdscript
func _state_skill(_delta: float) -> void:
    velocity = Vector2.ZERO  # Player stands still during skill
    move_and_slide()
    # State transition handled by _on_skill_effect_finished()
```

---

## Phase 6 — Enemy Loot & HUD Integration

### Step 17. Add segment drops to enemies → modify `sense/entities/enemies/skeleton/skeleton.gd`

**Current state**: `_spawn_drops()` uses `LootTable` with entries for `bone`, `monster_bone`, `iron_ore`, `gold_coin`.

**Changes**: Add segment entries to the loot table in `_setup_loot_table()` or wherever the loot table is configured:

```gdscript
# Existing entries...
loot_table.add_entry("fire_shard", 15)       # 15 weight — common drop
loot_table.add_entry("frost_shard", 15)
loot_table.add_entry("power_fragment", 12)
loot_table.add_entry("spirit_essence", 6)    # Lower weight — uncommon
loot_table.add_entry("venom_gland", 6)
loot_table.add_entry("herb_segment", 18)     # Most common segment
# Rare segments (only from stronger enemies or bosses — future)
# loot_table.add_entry("inferno_shard", 3)
# loot_table.add_entry("blizzard_shard", 3)
```

For rare/epic segments (`inferno_shard`, `hellfire_shard`, etc.), add to future stronger enemy loot tables or dungeon chest loot tables. The `LootTable` resource system already supports this via weighted entries.

---

### Step 18. Update HUD → modify `sense/ui/hud/hud.gd`

**Current state**: Has 6 status icon slots (`show_speed_icon()`, `show_heal_icon()`, etc.) that are purely visual toggles. Has `_process()` for camera follow.

**Changes**:

#### 18a. Wire BuffComponent signals to status icons

```gdscript
## Called by Player after creating BuffComponent
func connect_buff_component(buff_comp: BuffComponent) -> void:
    buff_comp.buff_applied.connect(_on_buff_applied)
    buff_comp.buff_expired.connect(_on_buff_expired)

func _on_buff_applied(buff_data: Dictionary) -> void:
    var source_id: String = buff_data.get("source_item_id", "")
    # Map known buff IDs to existing icon slots
    if "speed" in source_id:
        show_speed_icon()
    elif "vitality" in source_id or "health" in source_id:
        show_heal_icon()
    elif "defense" in source_id:
        show_shield_icon()
    # TODO: Add duration overlay (Label with countdown) on each icon

func _on_buff_expired(buff_id: String) -> void:
    if "speed" in buff_id:
        hide_speed_icon()
    elif "vitality" in buff_id or "health" in buff_id:
        hide_heal_icon()
    elif "defense" in buff_id:
        hide_shield_icon()
```

#### 18b. Add skill cooldown indicators

```gdscript
## Called by Player after creating SkillComponent
func connect_skill_component(skill_comp: SkillComponent) -> void:
    skill_comp.skills_changed.connect(_on_skills_changed)
    skill_comp.skill_cooldown_updated.connect(_on_skill_cooldown_updated)

func _on_skills_changed() -> void:
    # Rebuild skill icon display (small icons in bottom-right HUD area)
    pass

func _on_skill_cooldown_updated(skill_id: String, remaining: float) -> void:
    # Update cooldown sweep overlay on the skill icon
    pass
```

---

### Step 19. Extend tooltip system → modify `sense/ui/inventory/inventory_panel.gd`

**Current state**: `_show_tooltip()` builds tooltip text from item name, type, description, stat bonuses, and rarity color. `_get_item_stats_string()` returns stat lines.

**Changes**:

#### 19a. Extend `_get_item_stats_string()` for augment items

```gdscript
# In _get_item_stats_string(), add handling for AUGMENT items:
if item.item_type == ItemData.ItemType.AUGMENT:
    match item.augment_type:
        ItemData.AugmentType.PASSIVE_EFFECT:
            stats_text += _get_passive_effect_description(item.passive_effect, item.passive_value)
        ItemData.AugmentType.ACTIVE_SKILL:
            stats_text += "Grants Skill: %s\n" % item.active_skill_id
        ItemData.AugmentType.TIMED_BUFF:
            stats_text += "Duration: %.0fs\n" % item.buff_duration

func _get_passive_effect_description(effect: ItemData.PassiveEffect, value: float) -> String:
    match effect:
        ItemData.PassiveEffect.LIFE_STEAL:    return "Life Steal: %.0f%%\n" % value
        ItemData.PassiveEffect.CRIT_CHANCE:   return "Crit Chance: +%.0f%%\n" % value
        ItemData.PassiveEffect.THORNS:        return "Thorns: Reflect %.0f%% damage\n" % value
        ItemData.PassiveEffect.BURN_ON_HIT:   return "Burn: %.0f damage/s for 3s\n" % value
        ItemData.PassiveEffect.FREEZE_ON_HIT: return "Freeze: Slow %.0f%% for 2s\n" % value
        ItemData.PassiveEffect.POISON_ON_HIT: return "Poison: %.0f damage/s for 3s\n" % value
        _: return ""
```

#### 19b. Show augment slots in equipment tooltip

```gdscript
# In _show_tooltip(), after stats section, add augment slot info for equipped items:
if item.is_equippable() and item.get_augment_slot_count() > 0:
    tooltip_text += "\n--- Augment Slots ---\n"
    var slot_count := item.get_augment_slot_count()
    for i: int in range(slot_count):
        if i < item.applied_augments.size():
            var aug_id: String = item.applied_augments[i]
            var aug_item: ItemData = ItemDatabase.get_item(aug_id)
            if aug_item:
                tooltip_text += "  [%s] %s\n" % [aug_item.get_rarity_color().to_html(), aug_item.name]
        else:
            tooltip_text += "  [ Empty Slot ]\n"
```

#### 19c. Add "Augment" button to equipment slots

In `_on_equipment_slot_right_clicked()` or as a dedicated button:

```gdscript
func _on_augment_button_pressed(equip_slot: String) -> void:
    var equipment: ItemData = inventory.get_equipped(equip_slot)
    if equipment == null or equipment.get_augment_slot_count() == 0:
        return
    _open_augment_panel(equip_slot)

func _open_augment_panel(equip_slot: String) -> void:
    # Instantiate AugmentPanel scene, setup with inventory + slot
    var panel_scene := preload("res://sense/ui/augment/AugmentPanel.tscn")
    var panel := panel_scene.instantiate()
    add_child(panel)
    panel.setup(inventory, equip_slot)
```

---

## Phase 7 — Wiring & Signals

### Step 20. Extend `GameEvent` → modify `sense/globals/game_event.gd`

**Current state**: Single signal `request_ui_pause(is_open: bool)`.

**Add**:
```gdscript
signal item_crafted(recipe_id: String, tier: int)
signal augment_applied(equip_slot: String, augment_id: String)
signal augment_removed(equip_slot: String, augment_id: String)
signal buff_applied(buff_id: String)
signal buff_expired(buff_id: String)
signal skill_used(skill_id: String)
```

### Step 21. Register new autoloads → modify `project.godot`

Add after existing autoloads:
```ini
RecipeDatabase="*res://sense/ui/crafting/recipe_database.gd"
SkillDatabase="*res://sense/skills/skill_database.gd"
```

---

## Component Dependency Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                        COMPONENT COUPLING MAP                                    │
│                                                                                  │
│  ✅ = communicates via signal    ❌ = no direct reference                         │
│  📎 = injected Callable          📦 = data resource (no behavior)                │
│                                                                                  │
│  ┌────────────────────┐                                                          │
│  │   BuffComponent     │ ── (signals) ──▶ Player._on_buffs_changed()             │
│  │   extends Node      │                   └─▶ CharacterStats.apply_buff_bonuses │
│  │                     │ ── (signals) ──▶ HUD._on_buff_applied/expired()         │
│  │   ❌ No imports     │                                                          │
│  └────────────────────┘                                                          │
│                                                                                  │
│  ┌────────────────────────────┐                                                  │
│  │  PassiveEffectProcessor     │ ── 📎 get_passive_effects_func (injected)       │
│  │  extends Node               │ ── 📎 get_owner_stats_func (injected)           │
│  │                             │ ── 📎 get_owner_node_func (injected)            │
│  │  ❌ No imports except        │                                                  │
│  │     ItemData (for enums)    │                                                  │
│  │     CollisionLayers         │                                                  │
│  └────────────────────────────┘                                                  │
│                                                                                  │
│  ┌────────────────────┐                                                          │
│  │  SkillComponent     │ ── 📎 get_active_skills_func (injected)                 │
│  │  extends Node       │ ── 📎 use_stamina_func (injected)                       │
│  │                     │ ── (signals) ──▶ Player._on_skill_activated()            │
│  │  ❌ No imports       │                  └─▶ SkillExecutor.execute_skill()       │
│  │     except SkillData │                                                         │
│  └────────────────────┘                                                          │
│                                                                                  │
│  ┌────────────────────┐                                                          │
│  │  SkillExecutor      │ ── receives (SkillData, pos, dir, damage) as params     │
│  │  extends Node       │ ── (signals) ──▶ Player._on_skill_effect_finished()     │
│  │                     │                                                          │
│  │  ❌ No component     │                                                          │
│  │     references      │                                                          │
│  └────────────────────┘                                                          │
│                                                                                  │
│  ┌────────────────────┐                                                          │
│  │  InventoryData      │ ── augments_changed signal ──▶ SkillComponent.rebuild() │
│  │  extends Resource   │ ── equipment_changed signal ──▶ CharacterStats.apply()  │
│  │                     │                                                          │
│  │  References:        │                                                          │
│  │  - ItemDatabase     │ (for augment item lookups)                               │
│  └────────────────────┘                                                          │
│                                                                                  │
│  ┌────────────────────┐   ┌────────────────────┐   ┌──────────────────────┐      │
│  │  CraftingRecipe 📦  │   │  SkillData 📦      │   │  ItemData 📦         │      │
│  │  Pure data resource │   │  Pure data resource │   │  Pure data resource  │      │
│  │  No behavior deps   │   │  No behavior deps   │   │  No behavior deps    │      │
│  └────────────────────┘   └────────────────────┘   └──────────────────────┘      │
│                                                                                  │
│  ┌────────────────────┐   ┌────────────────────┐                                 │
│  │  RecipeDatabase     │   │  SkillDatabase     │   (Autoloads — lookup only)     │
│  │  Dict of recipes    │   │  Dict of skills    │                                 │
│  └────────────────────┘   └────────────────────┘                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

## New Files Summary

| File | Type | Purpose |
|---|---|---|
| `sense/ui/crafting/crafting_recipe.gd` | Resource | Recipe data: tiers, ingredients, results |
| `sense/ui/crafting/recipe_database.gd` | Autoload | All recipe definitions, lookup methods |
| `sense/ui/crafting/crafting_panel.gd` | Script | Crafting UI logic (recipe list, tier selection, craft button), `_refresh_all()` guards null UI refs for headless/test usage |
| `sense/ui/crafting/embedded_inventory_panel.gd` | Script | Embedded inventory for crafting tab reference |
| `sense/ui/augment/augment_panel.gd` | Script | Augment slot UI (drag/drop augments into equipment) |
| `sense/ui/augment/AugmentPanel.tscn` | Scene | Augment panel layout |
| `sense/components/buff_component.gd` | Component | Timed buff manager (decoupled Node), emits `GameEvent.buff_applied`/`GameEvent.buff_expired` in all paths (`apply_buff`, `remove_buff`, `clear_all_buffs`, `_process` expiry) |
| `sense/components/passive_effect_processor.gd` | Component | On-hit/on-damage passive effects (decoupled Node) |
| `sense/components/skill_component.gd` | Component | Equipment-bound skill manager (decoupled Node) |
| `sense/skills/skill_data.gd` | Resource | Skill definition (cooldown, damage, range) |
| `sense/skills/skill_database.gd` | Autoload | All skill definitions, lookup methods |
| `sense/skills/skill_executor.gd` | Component | Skill activation & temporary hitbox spawning |

## Modified Files Summary

| File | Changes |
|---|---|
| `sense/items/item_data.gd` | +`SEGMENT`/`AUGMENT` ItemTypes, +`AugmentType`/`PassiveEffect` enums, +augment export vars, +`applied_augments`, +computed methods (`get_augment_slot_count`, `is_augmentable`, `is_augment`, `is_timed_buff`, `is_crafting_material`), updated `is_consumable()` |
| `sense/items/item_database.gd` | +10 segment items, +13 augment items, +6 timed buff items in `_create_sample_items()` |
| `sense/items/item_icon_atlas.gd` | +29 new icon mappings in `ICONS` dictionary |
| `sense/ui/inventory/inventory_data.gd` | +`augments_changed` signal, +`apply_augment()`, +`remove_augment()`, +`_get_augment_stat_sum()`, +`get_all_augment_passive_effects()`, +`get_all_augment_active_skills()`, updated `get_total_*_bonus()` to include augment stats, updated `use_item()` for timed buffs |
| `sense/entities/npcs/blacksmith/smith_shop_popup.gd` | +"Crafting" main tab, +`CraftingPanel` integration, +`EmbeddedInventoryPanel` for crafting view, +tab switching logic |
| `sense/entities/npcs/blacksmith/smith_shop_popup.tscn` | +CraftingContent HBox with CraftingPanel + InventoryContainer child nodes |
| `sense/ui/inventory/inventory_panel.gd` | +`character_stats: CharacterStats` var, +Augment button on equipment slots, +augment slot section in tooltips, +passive effect descriptions, +`_open_augment_panel()`, updated `setup()` to accept optional `CharacterStats` param, updated `_refresh_stats()` to show total stats (base + equipment + buff) instead of equipment-only bonuses, auto-refreshes stats on buff apply/expire via `health_changed` |
| `sense/entities/player/character_stats.gd` | +`buff_*_bonus` vars, +`apply_buff_bonuses()`, +`clear_buff_bonuses()`, updated computed properties to include buff bonuses |
| `sense/entities/player/player.gd` | +`SKILL` state, +BuffComponent/PassiveEffectProcessor/SkillComponent/SkillExecutor creation & wiring in `_ready()`, +`_on_buffs_changed()`, +`_on_skill_activated()`, +`_on_skill_effect_finished()`, +`_get_all_passive_effects()`, +`_state_skill()`, updated `_on_item_used()` for timed buffs with debug stat prints, passes `stats` to `inventory_panel.setup(inventory, stats)` |
| `sense/ui/hud/hud.gd` | +`connect_buff_component()`, +`connect_skill_component()`, +buff icon lifecycle, +skill cooldown display |
| `sense/globals/game_event.gd` | +6 new signals (item_crafted, augment_applied/removed, buff_applied/expired, skill_used) |
| `sense/entities/enemies/skeleton/skeleton.gd` | +segment items in loot table weights |
| `project.godot` | +`RecipeDatabase` and `SkillDatabase` autoloads |
| `sense/main.gd` | +`_test_phase7()` — comprehensive tests for GameEvent signal emissions (buff_applied/expired, item_crafted, augment_applied/removed, skill_used), autoload validation, cross-referencing recipe ingredients/results against ItemDatabase, and skill augments against SkillDatabase |

---

## Verification Checklist

| # | Test | Steps | Expected |
|---|---|---|---|
| 1 | **Crafting flow** | Walk to blacksmith → interact → click "Crafting" tab → select Flame Augment → pick T1 → verify 3× fire_shard + 2× iron_ore highlighted green → click Craft | `flame_augment_t1` appears in inventory, ingredients consumed |
| 2 | **Tier upgrade** | Same recipe → pick T2 → verify needs inferno_shard + gold_ore | `flame_augment_t2` produced with stronger stats |
| 3 | **Insufficient ingredients** | Select recipe with missing ingredients | Craft button disabled, missing ingredients shown in red |
| 4 | **Augment application** | Open inventory → click equipped Rare sword (2 slots) → "Augment" → drag `flame_augment_t1` into slot 1 | Augment consumed from inventory, tooltip shows augment in slot, ATK stat updated |
| 5 | **Augment removal** | Right-click filled augment slot → "Remove" | Augment returned to inventory, stats revert |
| 6 | **Rarity gating** | Attempt to open augment panel on Common equipment (0 slots) | "Augment" button hidden or panel shows "No augment slots" |
| 7 | **Augment persistence** | Unequip augmented weapon, re-equip it | Augments still present on the item |
| 8 | **Timed buff** | Use Vitality Tonic T1 from inventory | HUD shows buff icon with 60s countdown, max HP +20, after 60s stats revert |
| 9 | **Buff refresh** | Use another Vitality Tonic T1 while first is active | Timer resets to 60s, HP bonus stays +20 (no stack to +40) |
| 10 | **Passive: Life Steal** | Equip weapon with Lifesteal Augment T1 → attack enemy | Player heals 5% of damage dealt |
| 11 | **Passive: Burn on Hit** | Equip weapon with Flame Augment → attack enemy | Enemy takes DoT damage (3 ticks, 1s apart) |
| 12 | **Passive: Crit** | Equip weapon with Crit Augment T2 (15%) → attack 50 times | ~7-8 hits deal 2× damage (statistical check) |
| 13 | **Passive: Thorns** | Equip armor with Thorns augment → get hit by enemy | Enemy takes reflected damage |
| 14 | **Active skill: Whirlwind** | Equip weapon augmented with Whirlwind Rune → press Q | Player enters SKILL state, AoE hitbox spawns, nearby enemies take 1.8× damage, 6s cooldown starts |
| 15 | **Skill cooldown** | Press Q again immediately | Nothing happens (on cooldown), HUD shows remaining time |
| 16 | **Equipment-bound skill removal** | Unequip the augmented weapon | Skill disappears from available skills, Q key does nothing |
| 17 | **Segment drops** | Kill Skeleton enemies | fire_shard, frost_shard, power_fragment, herb_segment etc. drop per loot table weights |
| 18 | **Death buff clear** | Activate buff → die | All buffs cleared, stats return to base + equipment |
| 19 | **Multiple augments** | Equip Epic weapon (3 slots), add Flame + Lifesteal + Crit augments | All three effects active simultaneously |
| 20 | **Stat stacking** | Apply Power Augment T2 (+15 ATK) to weapon + activate Vitality Tonic (+20 HP) | ATK = base + weapon + augment, HP = base + equipment + buff — all additive |

---

## Implementation Order

```
Phase 1 (Foundation)   ──▶  Phase 2 (Buffs)  ──▶  Phase 3 (Augments)
     Steps 1-4                 Steps 5-7              Steps 8-9
         │                         │                      │
         └─────────────────────────┴──────────────────────┘
                                   │
                    Phase 4 (Crafting UI)  ──▶  Phase 5 (Skills)
                         Steps 10-12              Steps 13-16
                    (Blacksmith integration)
                              │                      │
                              └──────────────────────┘
                                        │
                          Phase 6 (Integration)  ──▶  Phase 7 (Wiring)
                              Steps 17-19               Steps 20-21
```

Build data model first → combat integration → UI → skills → polish. Each phase is independently testable.