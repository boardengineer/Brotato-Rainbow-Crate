extends "res://ui/menus/ingame/upgrades_ui_player_container.gd"

onready var rainbow_crate_resource = load("res://mods-unpacked/Pasha-RainbowCrate/rainbow_crate_data.tres")

onready var rainbow_crate_ui_scene = load("res://mods-unpacked/Pasha-RainbowCrate/rainbow_crate_ui/rainbow_crate_container.tscn")
onready var rainbow_crate_item_ui = load("res://mods-unpacked/Pasha-RainbowCrate/rainbow_crate_ui/rainbow_crate_item.tscn")

var rainbow_crate_ui


func prep_rainbow_crate_options() -> void:
	var rainbow_crate_options = $"/root/PashaRainbowCrateOptions"
	
	rainbow_crate_ui = rainbow_crate_ui_scene.instance()
	add_child(rainbow_crate_ui)
	move_child(rainbow_crate_ui,0)
	
	for item_data in ItemService.items:
		if rainbow_crate_options.unlocked_items_only and not ProgressData.items_unlocked.has(item_data.my_id):
			continue
		
		_add_item_to_container(item_data)
		var dlc = ProgressData.get_dlc_data("abyssal_terrors")
		if dlc:
			var cursed_item_data = item_data.duplicate()
			cursed_item_data = dlc.curse_item(cursed_item_data, player_index, true)
			_add_item_to_container(cursed_item_data)
		
	rainbow_crate_ui.call_deferred("hide")


func show_upgrades_for_level(level:int) -> void:
	rainbow_crate_ui.hide()
	.show_upgrades_for_level(level)


func show_item(item_data:ItemParentData) -> void:
	if item_data.my_id != "consumable_pasha_rainbow_crate":
		rainbow_crate_ui.hide()
		.show_item(item_data)
		return
	
	_update_gold_label()
	_items_container.hide()
	_upgrades_container.hide()
	rainbow_crate_ui.show()


func _add_item_to_container(item_data) -> void:
	var item_ui = rainbow_crate_item_ui.instance()
	rainbow_crate_ui.call_deferred("add_item_ui", item_ui)
	item_ui.parent_box_ui = self
	item_ui.call_deferred("set_item_data", item_data)
