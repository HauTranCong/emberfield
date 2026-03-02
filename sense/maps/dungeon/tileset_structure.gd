class_name TilesetStructure
extends RefCounted
## A placeable structure made of tiles from FloorLayer and/or WallLayer
##
## How it works:
## - You define a rectangle region from your tileset atlas
## - When placed, each tile maps to the correct atlas coordinate
## - Collision is automatic (from TileSet config in dungeon_map.tscn)

enum Layer { FLOOR, WALL }

## Which layer this structure belongs to
var layer: Layer

## Atlas coordinates: top-left and bottom-right in your tileset PNG
var atlas_start: Vector2i
var atlas_end: Vector2i

## Size in tiles (calculated automatically)
var size: Vector2i


func _init(p_layer: Layer, p_start: Vector2i, p_end: Vector2i) -> void:
	layer = p_layer
	atlas_start = p_start
	atlas_end = p_end
	size = p_end - p_start + Vector2i.ONE


## Get the atlas coordinate for a local position within the structure
## Example: local (0,0) → atlas_start, local (1,0) → atlas_start + (1,0)
func get_atlas_at(local_pos: Vector2i) -> Vector2i:
	return atlas_start + local_pos
