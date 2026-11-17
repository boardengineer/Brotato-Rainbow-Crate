extends VBoxContainer

signal take_pressed(item_data)

var item_data: ItemParentData = null

onready var _panel_container = $PanelContainer
onready var _description_node = $PanelContainer/MarginContainer/ItemDescription


func set_item_data(p_item_data: ItemParentData, player_index: int) -> void:
	item_data = p_item_data
	_description_node.set_item(p_item_data, player_index)

	var stylebox_color = _panel_container.get_stylebox("panel").duplicate()
	ItemService.change_panel_stylebox_from_tier(stylebox_color, p_item_data.tier)
	_panel_container.add_stylebox_override("panel", stylebox_color)


func _on_TakeButton_pressed() -> void:
	emit_signal("take_pressed", item_data)
