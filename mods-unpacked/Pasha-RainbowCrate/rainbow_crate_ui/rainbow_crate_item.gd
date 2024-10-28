extends VBoxContainer

var parent_box_ui
var item_data

func set_item_data(p_item_data:ItemParentData)->void :
	var _description_node = $PanelContainer/MarginContainer/ItemDescription
	_description_node.set_item(p_item_data, 0)
	item_data = p_item_data
	
#	var stylebox_color = parent_box_ui.get_stylebox("panel").duplicate()
#	ItemService.change_panel_stylebox_from_tier(stylebox_color, p_item_data.tier)
#	parent_box_ui._panel_container.add_stylebox_override("panel", stylebox_color)

func _on_TakeButton_pressed() -> void:
	parent_box_ui.emit_signal("item_take_button_pressed", item_data)
