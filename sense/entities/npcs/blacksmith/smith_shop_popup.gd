extends Control
class_name SmithShopPopup

signal buy_requested(item: Dictionary)

@onready var dim: ColorRect = $Dim
@onready var items_list: VBoxContainer = $Panel/VBox/ItemsScroll/ItemsList
@onready var close_btn: Button = $Panel/VBox/TitleRow/Close

var items: Array[Dictionary] = []
var owner_npc: Node = null  # Reference to the NPC that opened this shop

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	if dim and dim.has_signal("dim_clicked"):
		dim.dim_clicked.connect(_on_dim_clicked)
	close_btn.pressed.connect(hide_popup)

## Initialize the shop with data from the NPC
func initialize(data: Dictionary) -> void:
	if data.has("items"):
		set_items(data["items"])
	if data.has("owner"):
		owner_npc = data["owner"]
		# Connect buy signal to owner if it has a purchase handler
		if owner_npc and owner_npc.has_method("_on_purchase_requested"):
			buy_requested.connect(owner_npc._on_purchase_requested)

func set_items(new_items: Array[Dictionary]) -> void:
	items = new_items
	_refresh()

func show_popup() -> void:
	visible = true

func hide_popup() -> void:
	visible = false
	queue_free()  # Remove from scene tree when closed

func _on_dim_clicked(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		hide_popup()

func _refresh() -> void:
	# clear list
	for c in items_list.get_children():
		c.queue_free()

	for it in items:
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var name_lbl := Label.new()
		name_lbl.text = str(it.get("name", "Unknown"))
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var price_lbl := Label.new()
		price_lbl.text = "%s G" % str(it.get("price", 0))
		price_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		price_lbl.custom_minimum_size.x = 80

		var buy_btn := Button.new()
		buy_btn.text = "Buy"
		buy_btn.pressed.connect(func():
			emit_signal("buy_requested", it)
		)

		row.add_child(name_lbl)
		row.add_child(price_lbl)
		row.add_child(buy_btn)

		items_list.add_child(row)
