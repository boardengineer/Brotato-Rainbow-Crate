extends "res://singletons/item_service.gd"

onready var rainbow_crate_resource = load("res://mods-unpacked/Pasha-RainbowCrate/rainbow_crate_data.tres")

func process_item_box(wave:int, consumable_data:ConsumableData, fixed_tier:int = - 1)->ItemParentData:
	if consumable_data.my_id == rainbow_crate_resource.my_id:
		print_debug("rainbow crate picked up")
		var result = .process_item_box(wave, consumable_data, fixed_tier).duplicate()
		result.my_id = consumable_data.my_id
		return result
	return .process_item_box(wave, consumable_data, fixed_tier)
