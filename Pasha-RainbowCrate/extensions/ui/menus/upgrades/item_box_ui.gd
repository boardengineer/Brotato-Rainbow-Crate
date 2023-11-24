extends "res://ui/menus/upgrades/item_box_ui.gd"

onready var rainbow_crate_resource = load("res://mods-unpacked/Pasha-RainbowCrate/rainbow_crate_data.tres")
onready var rainbow_crate_ui_scene = load("res://mods-unpacked/Pasha-RainbowCrate/rainbow_crate_container.tscn")
onready var rainbow_crate_item_ui = load("res://mods-unpacked/Pasha-RainbowCrate/rainbow_crate_item.tscn")

onready var item_ui_container = $MarginContainer/HBoxContainer
onready var original_item_ui  = $MarginContainer/HBoxContainer/VBoxContainer

var rainbow_crate_ui

func _ready() -> void:
	rainbow_crate_ui = rainbow_crate_ui_scene.instance()
	rainbow_crate_ui.hide()
	item_ui_container.add_child(rainbow_crate_ui)
	item_ui_container.move_child(rainbow_crate_ui,0)
	
	for item_data in ItemService.items:
		var item_ui = rainbow_crate_item_ui.instance()
		rainbow_crate_ui.call_deferred("add_item_ui", item_ui)
		item_ui.parent_box_ui = self
		
		item_ui.call_deferred("set_item_data", item_data)

func set_item_data(p_item_data:ItemParentData)->void :
	if p_item_data.my_id == rainbow_crate_resource.my_id:
		rainbow_crate_ui.show()
		original_item_ui.hide()
	.set_item_data(p_item_data)
