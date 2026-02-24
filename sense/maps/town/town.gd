extends Node2D


func get_spawn_position() -> Vector2:
	var spawn: Node2D = get_node_or_null("Spawn") as Node2D
	if spawn != null:
		return spawn.global_position

	var town_rect: Rect2 = _get_town_world_rect(self )
	if town_rect.size != Vector2.ZERO:
		return town_rect.get_center()

	var portal: Node2D = get_node_or_null("Portal") as Node2D
	if portal != null:
		# Place player slightly away from portal to avoid immediate re-trigger.
		return portal.global_position + Vector2(-48.0, 50.0)

	return global_position


func _get_town_world_rect(root: Node) -> Rect2:
	var found: bool = false
	var union_world: Rect2 = Rect2()

	var layers: Array[TileMapLayer] = []
	_collect_tilemap_layers(root, layers)

	for layer: TileMapLayer in layers:
		var used: Rect2i = layer.get_used_rect()
		if used.size == Vector2i.ZERO:
			continue
		if layer.tile_set == null:
			continue

		var cell: Vector2i = layer.tile_set.tile_size

		var left: float = float(used.position.x * cell.x)
		var top: float = float(used.position.y * cell.y)
		var right: float = float((used.position.x + used.size.x) * cell.x)
		var bottom: float = float((used.position.y + used.size.y) * cell.y)

		var r_local: Rect2 = Rect2(Vector2(left, top), Vector2(right - left, bottom - top))

		var p1: Vector2 = layer.to_global(r_local.position)
		var p2: Vector2 = layer.to_global(r_local.position + Vector2(r_local.size.x, 0.0))
		var p3: Vector2 = layer.to_global(r_local.position + Vector2(0.0, r_local.size.y))
		var p4: Vector2 = layer.to_global(r_local.position + r_local.size)

		var min_x: float = min(p1.x, p2.x, p3.x, p4.x)
		var max_x: float = max(p1.x, p2.x, p3.x, p4.x)
		var min_y: float = min(p1.y, p2.y, p3.y, p4.y)
		var max_y: float = max(p1.y, p2.y, p3.y, p4.y)

		var r_world: Rect2 = Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))

		if not found:
			union_world = r_world
			found = true
		else:
			union_world = union_world.merge(r_world)

	return union_world if found else Rect2()


func _collect_tilemap_layers(node: Node, out_layers: Array[TileMapLayer]) -> void:
	for child: Node in node.get_children():
		var layer: TileMapLayer = child as TileMapLayer
		if layer != null:
			out_layers.append(layer)
		_collect_tilemap_layers(child, out_layers)
