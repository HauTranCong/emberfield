# Item & Shop Implementation Best Practices

> Use this prompt when creating new items, integrating shop systems, or spawning item drops.

---

## Creating a New Item

### Step 1: Add icon to atlas (if needed)

Edit `sense/items/item_icon_atlas.gd` and add to `ICONS` dictionary:
```gdscript
const ICONS := {
    # ... existing icons
    "my_new_icon": Vector2i(row, col),  # row/col from sprite sheet
}
```

Use `debug_icon_atlas.tscn` scene to find correct row/col in sprite sheet.

### Step 2: Define item in ItemDatabase

Edit `sense/items/item_database.gd` in `_create_sample_items()`:
```gdscript
var my_item := ItemData.new()
my_item.id = "my_item"              # Unique ID (snake_case)
my_item.name = "My Item"            # Display name
my_item.description = "Item description here."
my_item.item_type = ItemData.ItemType.WEAPON  # or ARMOR, CONSUMABLE, MATERIAL, etc.
my_item.rarity = ItemData.ItemRarity.COMMON   # COMMON, UNCOMMON, RARE, EPIC, LEGENDARY

# Stacking
my_item.stackable = true            # false for equipment
my_item.max_stack = 99              # 1 for equipment

# Pricing
my_item.buy_price = 100             # Cost to buy from shop
my_item.sell_price = 50             # Player sells at this price

# Stats (for equipment)
my_item.attack_bonus = 15
my_item.defense_bonus = 10
my_item.health_bonus = 20
my_item.speed_bonus = 5.0

# Consumable effects
my_item.heal_amount = 50
my_item.stamina_restore = 30.0

# Icon (choose ONE method)
# Method A: Named icon
my_item.use_atlas_icon = true
my_item.atlas_icon_name = "my_new_icon"

# Method B: Direct row/col
my_item.use_atlas_icon = true
my_item.atlas_row = 5
my_item.atlas_col = 3

items["my_item"] = my_item
```

---

## Item Type Reference

| ItemType | Equip Slot | Stackable | Notes |
|----------|------------|-----------|-------|
| `WEAPON` | weapon | No | attack_bonus |
| `ARMOR` | armor | No | defense_bonus |
| `HELMET` | helmet | No | defense_bonus |
| `BOOTS` | boots | No | defense_bonus, speed_bonus |
| `SHIELD` | shield | No | defense_bonus |
| `ACCESSORY` | accessory_1/2 | No | Any stat bonus |
| `CONSUMABLE` | - | Yes | heal_amount, stamina_restore |
| `MATERIAL` | - | Yes | Crafting materials |
| `QUEST` | - | No | Cannot drop/sell |

---

## Item Rarity Colors

| Rarity | Color | Use Case |
|--------|-------|----------|
| COMMON | Gray `#B3B3B3` | Basic items, common drops |
| UNCOMMON | Green `#4DCC4D` | Upgraded items |
| RARE | Blue `#4D80FF` | Special items |
| EPIC | Purple `#B34DE6` | Boss drops |
| LEGENDARY | Orange `#FF9919` | Endgame items |

---

## Shop Integration

### Shop Component Architecture

```
ShopNPC (CharacterBody2D or Area2D)
├── Sprite2D
├── CollisionShape2D
├── ShopComponent (Node)          # Handles transactions
└── UIPopupComponent (Node)       # Manages shop UI
```

### Adding Shop to NPC

**Step 1: Add ShopComponent**
```gdscript
@onready var shop_component: ShopComponent = $ShopComponent
```

**Step 2: Define shop inventory**
```gdscript
var shop_items: Array[Dictionary] = [
    {"item_id": "iron_sword", "price": 100},
    {"item_id": "health_potion", "price": 25},
    {"item_id": "leather_armor", "price": 80},
]
```

**Step 3: Connect purchase signals**
```gdscript
func _ready():
    shop_component.purchase_successful.connect(_on_purchase_successful)
    shop_component.purchase_failed.connect(_on_purchase_failed)

func _on_purchase_successful(item: Dictionary, remaining_gold: int):
    var item_data = ItemDatabase.get_item(item.item_id)
    if item_data:
        player.inventory.add_item(item_data, 1)

func _on_purchase_failed(reason: String, item: Dictionary):
    print("Purchase failed: %s" % reason)
```

---

## Processing Buy/Sell Transactions

### Buy Item (Shop → Player)
```gdscript
func buy_item(item_id: String) -> bool:
    var item_data = ItemDatabase.get_item(item_id)
    if not item_data:
        return false
    
    var player = get_tree().get_first_node_in_group("player")
    if not player or not player.inventory:
        return false
    
    var inventory: InventoryData = player.inventory
    
    # Check gold
    if inventory.gold < item_data.buy_price:
        return false
    
    # Process transaction
    inventory.gold -= item_data.buy_price
    inventory.add_item(item_data, 1)
    return true
```

### Sell Item (Player → Shop)
```gdscript
func sell_item(slot_index: int) -> bool:
    var player = get_tree().get_first_node_in_group("player")
    if not player or not player.inventory:
        return false
    
    var inventory: InventoryData = player.inventory
    var slot = inventory.inventory_slots[slot_index]
    
    if slot.item == null:
        return false
    
    # Quest items cannot be sold
    if slot.item.item_type == ItemData.ItemType.QUEST:
        return false
    
    # Process transaction
    inventory.gold += slot.item.sell_price * slot.quantity
    inventory.remove_item_at(slot_index, slot.quantity)
    return true
```

---

## Shop UI Integration Pattern

```gdscript
## Shop popup should:
## 1. Display shop inventory with buy_price
## 2. Show player's gold
## 3. Enable/disable buy button based on gold
## 4. Call ShopComponent.process_purchase() on buy

func _on_buy_button_pressed(item_id: String):
    var item_data = ItemDatabase.get_item(item_id)
    var purchase_info = {
        "item_id": item_id,
        "name": item_data.name,
        "price": item_data.buy_price
    }
    shop_component.process_purchase(purchase_info)
```

---

## Common Shop Patterns

### Blacksmith Shop (Equipment)
```gdscript
var blacksmith_inventory = [
    {"item_id": "iron_sword", "price": 100},
    {"item_id": "steel_sword", "price": 300},
    {"item_id": "iron_armor", "price": 400},
    {"item_id": "iron_helmet", "price": 60},
]
```

### General Store (Consumables + Materials)
```gdscript
var general_store_inventory = [
    {"item_id": "health_potion", "price": 25},
    {"item_id": "stamina_potion", "price": 20},
    {"item_id": "iron_ore", "price": 10},
]
```

### Shop Collision Layer

Shops use **Layer 9 (Interactable)**:
```gdscript
collision_layer = CollisionLayers.Layer.INTERACTABLE  # 9
collision_mask = CollisionLayers.Layer.PLAYER         # 2
```

---

## Item Spawning (Enemy Drops)

### Using ItemSpawner
```gdscript
# In enemy death handler:
func _on_death():
    # Spawn single item
    ItemSpawner.spawn_item(get_tree(), global_position, "bone", 1, global_position)
    
    # Spawn gold
    ItemSpawner.spawn_gold(get_tree(), global_position, 50, global_position)
    
    # Spawn from loot table
    var loot = LootTable.roll_drops(enemy_loot_table)
    for drop in loot:
        ItemSpawner.spawn_item(get_tree(), global_position, drop.item_id, drop.quantity, global_position)
```

### Loot Table Definition
```gdscript
var skeleton_loot := LootTable.new()
skeleton_loot.add_drop("bone", 1, 3, 0.8)        # 80% chance, 1-3 bones
skeleton_loot.add_drop("iron_ore", 1, 1, 0.2)   # 20% chance, 1 ore
skeleton_loot.add_gold(10, 25, 1.0)              # 100% chance, 10-25 gold
```

---

## Common Pitfalls

1. **Forgetting to register item in ItemDatabase**
   ```gdscript
   # ❌ Missing this line
   items["my_item"] = my_item
   ```

2. **Wrong stackable setting for equipment**
   ```gdscript
   # ❌ Equipment should NOT be stackable
   iron_sword.stackable = true
   
   # ✅ Correct
   iron_sword.stackable = false
   ```

3. **Missing get_tree() parameter in ItemSpawner**
   ```gdscript
   # ❌ Wrong
   ItemSpawner.spawn_item(position, "sword", 1)
   
   # ✅ Correct
   ItemSpawner.spawn_item(get_tree(), position, "sword", 1)
   ```

4. **Forgetting scatter_origin for nice visual**
   ```gdscript
   # Items spawn in place (boring)
   ItemSpawner.spawn_item(get_tree(), pos, "item", 1)
   
   # Items scatter outward from enemy (better!)
   ItemSpawner.spawn_item(get_tree(), pos, "item", 1, enemy_pos)
   ```
