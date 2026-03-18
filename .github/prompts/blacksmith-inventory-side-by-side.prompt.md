# Blacksmith + Inventory Side-by-Side Layout

> Documents the implemented feature where opening the Blacksmith shop shows both the shop and inventory panels side-by-side using Godot's container system.

---

## Summary

When the player interacts with the Blacksmith:
- A **combined UI** opens with both panels side-by-side, centered on screen
- **SmithShopPopup** on the **left**, **InventoryPanel** on the **right**
- Closing via X button, ESC, dim-click, or walking away closes everything
- The `B` key standalone inventory toggle is unaffected (centered, with overlay)

---

## Architecture

### Approach: Combined UI Scene with HBoxContainer

Instead of opening two separate panels and docking them, we use a **single combined scene** (`blacksmith_combined_ui.tscn`) that embeds both panels inside an `HBoxContainer`. Godot's container system handles all alignment and sizing — no script-based positioning needed.

### Flow
```
Player interacts → blacksmith.gd._on_interact()
  → UIPopupComponent.open_ui()
    → BlacksmithCombinedUI added to HUD (contains both panels)
    → blacksmith_combined_ui.gd.initialize({items, owner})
      → SmithShopPopup.initialize(data)
      → InventoryPanel.setup(player.inventory)
    → show_popup() makes everything visible
  → On close (X / ESC / dim-click / walk away): queue_free()

Player presses B → unchanged (standalone InventoryPanel, centered with overlay)
```

### Scene Tree
```
BlacksmithCombinedUI (Control, Full Rect) ← blacksmith_combined_ui.gd
├── Dim (ColorRect, Full Rect)            ← dim_background.gd, click to close
└── CenterContainer (Full Rect)           ← centers the HBox on screen
    └── HBoxContainer (separation=20)     ← horizontal side-by-side
        ├── SmithShopPopup (left)         ← 400×450 min size, container-friendly
        └── InventoryPanel (right)        ← embedded_mode=true, no overlay
```

---

## Implementation Details

### Key Design Decisions

1. **InventoryPanel changed from CanvasLayer to Control** — so it can be a child of HBoxContainer. Standalone use now requires a CanvasLayer parent (HUD).
2. **InventoryPanel has `embedded_mode` export** — when true, hides its own overlay and disables ESC handling (parent manages that).
3. **SmithShopPopup is container-friendly** — no Dim overlay (parent provides it), no `queue_free()` on close, emits `close_requested` signal instead.
4. **UIPopupComponent unchanged** — still uses `open_ui()` → `initialize()` → `show_popup()` pattern. The combined UI scene handles all internal wiring.

---

### File: `sense/entities/npcs/blacksmith/blacksmith_combined_ui.tscn`

The combined scene. Uses `CenterContainer` → `HBoxContainer` to center both panels horizontally.

```
ext_resources:
  - blacksmith_combined_ui.gd (script)
  - smith_shop_popup.tscn (left panel)
  - dim_background.gd (overlay)
  - inventory_panel.tscn (right panel)

BlacksmithCombinedUI (Control, Full Rect, script)
  Dim (ColorRect, Full Rect, dim_background.gd)
  CenterContainer (Full Rect)
    HBoxContainer (separation=20)
      SmithShopPopup (instance, layout_mode=2)
      InventoryPanel (instance, layout_mode=2, embedded_mode=true)
```

### File: `sense/entities/npcs/blacksmith/blacksmith_combined_ui.gd`

**NEW file.** Orchestrates the combined UI:

```gdscript
extends Control
class_name BlacksmithCombinedUI

@onready var dim: DimBackground = $Dim
@onready var smith_popup: SmithShopPopup = $CenterContainer/HBoxContainer/SmithShopPopup
@onready var inventory_panel: InventoryPanel = $CenterContainer/HBoxContainer/InventoryPanel

func _ready() -> void:
    visible = false
    smith_popup.close_requested.connect(hide_popup)
    dim.dim_clicked.connect(_on_dim_clicked)

func _input(event: InputEvent) -> void:
    if visible and event.is_action_pressed("ui_cancel"):
        hide_popup()
        get_viewport().set_input_as_handled()

func initialize(data: Dictionary) -> void:
    smith_popup.initialize(data)
    # Connect to player's shared inventory data
    var player = get_tree().get_first_node_in_group("player")
    if player and player.get("inventory"):
        inventory_panel.setup(player.inventory)

func show_popup() -> void:
    visible = true
    smith_popup.show_popup()
    inventory_panel.open_inventory()

func hide_popup() -> void:
    visible = false
    queue_free()
```

### File: `sense/entities/npcs/blacksmith/smith_shop_popup.tscn` / `.gd`

**Changed:** Made container-friendly for embedding.

- **Scene:** Removed `Dim` overlay. Root Control has `custom_minimum_size = Vector2(400, 450)`. Inner `Panel` fills parent via anchors.
- **Script:** Removed dim references. `hide_popup()` no longer calls `queue_free()`. Added `close_requested` signal emitted by X button. Close button calls `close_requested.emit()` instead of directly hiding.

```gdscript
signal buy_requested(item: Dictionary)
signal close_requested  # Parent handles actual close/cleanup

func hide_popup() -> void:
    visible = false  # No queue_free — parent manages lifecycle

func _on_close_pressed() -> void:
    close_requested.emit()
```

### File: `sense/ui/inventory/inventory_panel.tscn` / `.gd`

**Changed:** Root node type from `CanvasLayer` → `Control`. Added `embedded_mode` export.

- **Scene:** Root is `Control` with Full Rect anchors. `Overlay` and `CenterContainer` use `layout_mode = 1`.
- **Script:**
  - `extends Control` (was `extends CanvasLayer`)
  - `@export var embedded_mode: bool = false` — set `true` in combined UI scene instance
  - `set_embedded_mode()` hides overlay, disables ESC handling
  - ESC input is skipped when `_embedded` is true

```gdscript
@export var embedded_mode: bool = false
var _embedded := false

func _ready() -> void:
    visible = false
    _create_inventory_slots()
    _setup_equipment_slots()
    _setup_tabs()

func _input(event: InputEvent) -> void:
    if not visible or _embedded:
        return
    if event.is_action_pressed("ui_cancel"):
        close_inventory()

func set_embedded_mode(enabled: bool) -> void:
    _embedded = enabled
    var overlay = get_node_or_null("Overlay")
    if overlay:
        overlay.visible = not enabled
```

### File: `sense/entities/player/player.gd`

**Changed:** InventoryPanel (now a Control) must live under a CanvasLayer for screen-space rendering.

```gdscript
func _setup_inventory() -> void:
    inventory = InventoryData.new()
    inventory.gold = 500
    inventory.equipment_changed.connect(_on_equipment_changed)

    var inventory_scene := preload("res://sense/ui/inventory/inventory_panel.tscn")
    inventory_panel = inventory_scene.instantiate()
    # Defer to HUD (CanvasLayer) since it may not exist during _ready()
    _add_inventory_to_hud.call_deferred()

func _add_inventory_to_hud() -> void:
    var hud = get_tree().root.get_node_or_null("Main/HUD")
    if hud:
        hud.add_child(inventory_panel)
    else:
        add_child(inventory_panel)
    inventory_panel.setup(inventory)
    inventory_panel.item_used.connect(_on_item_used)
    _add_starter_items()
```

### Files NOT changed

- `sense/entities/npcs/blacksmith/blacksmith.gd` — unchanged, still passes `{items, owner}` via `UIPopupComponent.open_ui()`
- `sense/entities/npcs/blacksmith/blacksmith.tscn` — unchanged, `UIPopupComponent` references `blacksmith_combined_ui.tscn` as `ui_scene`
- `sense/components/ui_popup_component.gd` — unchanged, generic open/close flow works with the combined UI's `initialize()` / `show_popup()` / `hide_popup()` interface

---

## Key Files Reference

| File | Role |
|------|------|
| `sense/entities/npcs/blacksmith/blacksmith_combined_ui.tscn` | Combined scene: HBox layout with shop + inventory |
| `sense/entities/npcs/blacksmith/blacksmith_combined_ui.gd` | **NEW** — orchestrates init, show, close, ESC/dim handling |
| `sense/entities/npcs/blacksmith/smith_shop_popup.tscn` | Shop panel — container-friendly, no Dim overlay |
| `sense/entities/npcs/blacksmith/smith_shop_popup.gd` | Shop logic — emits `close_requested`, no `queue_free` |
| `sense/ui/inventory/inventory_panel.tscn` | Inventory panel — Control root (was CanvasLayer) |
| `sense/ui/inventory/inventory_panel.gd` | Inventory logic — `embedded_mode` export for side-by-side |
| `sense/entities/player/player.gd` | Player — adds inventory to HUD via `call_deferred` |
| `sense/components/ui_popup_component.gd` | Generic NPC UI opener — unchanged |
| `sense/entities/npcs/blacksmith/blacksmith.gd` | Blacksmith NPC — unchanged |

---

## Testing Checklist

- [ ] Interact with Blacksmith → combined UI opens: shop (left) + inventory (right), centered
- [ ] Click X on shop → entire combined UI closes
- [ ] Click dim background → entire combined UI closes
- [ ] Press Escape → entire combined UI closes
- [ ] Walk away from Blacksmith → auto-close via UIPopupComponent
- [ ] Press `B` key normally → standalone inventory opens centered with overlay
- [ ] Press `B` while Blacksmith is open → standalone inventory toggles independently
- [ ] Gold display updates in real-time when purchasing
- [ ] Equipment slots work (drag/right-click) inside combined UI
- [ ] No errors in Godot console during open/close cycles
- [ ] Inventory items visible and not clipped in side-by-side layout
