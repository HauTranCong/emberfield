extends Node

# Collision Layer Constants
# Based on LAYER_AND_MASK_STANDARDS.md

enum Layer {
	WORLD = 1,           # Layer 1: Walls, obstacles, terrain
	PLAYER = 2,          # Layer 2: Player character
	ENEMY = 4,           # Layer 3: Enemy entities
	NPC = 8,             # Layer 4: Non-playable characters
	PLAYER_HURTBOX = 16, # Layer 5: Player hurtbox (receives damage)
	ENEMY_HURTBOX = 32,  # Layer 6: Enemy hurtbox (receives damage)
	PLAYER_HITBOX = 64,  # Layer 7: Player attack hitbox (deals damage)
	ENEMY_HITBOX = 128,  # Layer 8: Enemy attack hitbox (deals damage)
	INTERACTABLE = 256,  # Layer 9: Shop, chest, door, etc.
	PICKUP = 512         # Layer 10: Items to collect
}
