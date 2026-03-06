extends Node
signal request_ui_pause(is_open: bool)
signal item_crafted(recipe_id: String, tier: int)
signal augment_applied(equip_slot: String, augment_id: String)
signal augment_removed(equip_slot: String, augment_id: String)
signal buff_applied(buff_id: String)
signal buff_expired(buff_id: String)
signal skill_used(skill_id: String)



