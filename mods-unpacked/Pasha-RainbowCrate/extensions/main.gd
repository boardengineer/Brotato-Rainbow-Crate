extends "res://main.gd"

onready var rainbow_crate = load("res://mods-unpacked/Pasha-RainbowCrate/rainbow_crate_data.tres")


func spawn_consumables(unit: Unit) -> void:
	if should_spawn_rainbow_crate(unit):
		spawn_rainbow_crate(unit)
	else:
		.spawn_consumables(unit)


# Same roll the game makes for a normal crate (ItemService.get_consumable_to_drop and
# main.spawn_consumables), with the item chance scaled by the mod's drop-chance option.
func should_spawn_rainbow_crate(unit: Unit) -> bool:
	var rainbow_crate_options = get_node_or_null("/root/PashaRainbowCrateOptions")

	if rainbow_crate_options == null or not rainbow_crate_options.rainbow_crates_enabled:
		return false

	var luck: = 0.0

	for player_index in RunData.get_player_count():
		luck += Utils.get_stat(Keys.stat_luck_hash, player_index) / 100.0

	var drop_chance = min(1.0, unit.stats.base_drop_chance * (1.0 + luck))

	if RunData.current_wave > RunData.nb_of_waves:
		drop_chance /= (1.0 + RunData.get_endless_factor())

	if not (unit.stats.always_drop_consumables or randf() <= drop_chance):
		return false

	var item_chance: float = (unit.stats.item_drop_chance * (1.0 + luck)) / (1.0 + _items_spawned_this_wave)
	item_chance += item_chance * RunData.sum_all_player_effects(Keys.crate_chance_hash) / 100.0
	item_chance *= rainbow_crate_options.rainbow_crates_drop_chance

	if unit.stats.always_drop_consumables and unit.stats.item_drop_chance >= 1.0 and RunData.current_wave <= RunData.nb_of_waves:
		item_chance = rainbow_crate_options.rainbow_crates_drop_chance / (rainbow_crate_options.rainbow_crates_drop_chance + 1.0)

	return randf() <= item_chance


func spawn_rainbow_crate(unit: Unit) -> void:
	var pos: = unit.global_position
	var dist: = rand_range(50, 100 + unit.stats.gold_spread)

	var consumable: Consumable = get_node_from_pool(_consumable_pool_id, _consumables_container)
	if consumable == null:
		consumable = consumable_scene.instance()
		_consumables_container.call_deferred("add_child", consumable)
		var _error = consumable.connect("picked_up", self, "on_consumable_picked_up")
		yield(consumable, "ready")

	consumable.already_picked_up = false
	consumable.consumable_data = rainbow_crate
	consumable.set_texture(rainbow_crate.icon)
	var push_back_destination: Vector2 = ZoneService.get_rand_pos_in_area(pos, dist, 0)
	consumable.drop(pos, 0, push_back_destination)
	_consumables.push_back(consumable)

