extends "res://main.gd"

onready var rainbow_crate = load("res://mods-unpacked/Pasha-RainbowCrate/rainbow_crate_data.tres")

func spawn_consumables(unit:Unit) -> void:
	var luck = (Utils.get_stat("stat_luck") / 100.0) / 2
	var drop_chance = min(1.0, unit.stats.base_drop_chance * (1 + luck))
	
	if RunData.current_wave > RunData.nb_of_waves:
		drop_chance /= (1.0 + RunData.get_endless_factor())
	
	if randf() <= drop_chance or unit.stats.always_drop_consumables:
		var pos = unit.global_position
		var consumable_to_spawn:Resource
		var item_chance = (unit.stats.item_drop_chance * (1 + luck)) / (1 + _items_spawned_this_wave)
		
		if unit.stats.always_drop_consumables and unit.stats.item_drop_chance >= 1.0 and RunData.current_wave <= RunData.nb_of_waves:
			item_chance = 1.0
		
		if randf() <= item_chance:
			consumable_to_spawn = rainbow_crate
		
			var dist = rand_range(50, 100 + unit.stats.gold_spread)
			var consumable = consumable_scene.instance()
			consumable.consumable_data = consumable_to_spawn
			consumable.global_position = pos
			_consumables_container.call_deferred("add_child", consumable)
			consumable.call_deferred("set_texture", consumable_to_spawn.icon)
			var _error = consumable.connect("picked_up", self, "on_consumable_picked_up")
			consumable.push_back_destination = Vector2(rand_range(pos.x - dist, pos.x + dist), rand_range(pos.y - dist, pos.y + dist))
			_consumables.push_back(consumable)
		
			return
	
	
	print_debug("spawn consumables?")
	.spawn_consumables(unit)
