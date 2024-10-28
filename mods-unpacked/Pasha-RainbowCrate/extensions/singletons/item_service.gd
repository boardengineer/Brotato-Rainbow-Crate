extends "res://singletons/item_service.gd"

onready var rainbow_crate_resource = load("res://mods-unpacked/Pasha-RainbowCrate/rainbow_crate_data.tres")


func process_item_box(consumable_data:ConsumableData, wave:int, player_index:int)->ItemParentData:
	if consumable_data.my_id == rainbow_crate_resource.my_id:
		var result = .process_item_box(consumable_data, wave, player_index).duplicate()
		result.my_id = consumable_data.my_id
		return result
	return .process_item_box(consumable_data, wave, player_index)
