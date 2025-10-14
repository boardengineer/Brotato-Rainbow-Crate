extends VBoxContainer

onready var item_container = $Container/VBoxContainer/ScrollContainer/VBoxContainer/ItemContainer
onready var search_text_box = $Container/VBoxContainer/HBoxContainer/SearchText
onready var cursed_button = $Container/VBoxContainer/HBoxContainer/CursedButton

onready var title_canvas = $Container/VBoxContainer/HBoxContainer/

onready var items_to_iterate := []


func add_item_ui(item_ui):
	item_container.add_child(item_ui)
	items_to_iterate.push_back(item_ui)


func show() -> void:
	.show()
	var dlc = ProgressData.get_dlc_data("abyssal_terrors")
	if not dlc:
		cursed_button.hide()
	_update_visible_elements()
	title_canvas.show()

func hide() -> void:
	.hide()
	title_canvas.hide()


func _on_SearchText_focus_entered():
	if search_text_box.text == "Search Name":
		search_text_box.text = ""


func _on_CheckButton_toggled(button_pressed):
	_update_visible_elements()


func _on_search_text_changed():
	_update_visible_elements()


func _update_visible_elements() -> void:
	var search_text = search_text_box.text.to_lower()
	var search_cursed = cursed_button.pressed
	for item in items_to_iterate:
		var name = tr(item.item_data.name).to_lower()
		var match_search_string = (name.find(search_text) != -1) or search_text == "" or search_text == "search name"
		var match_curse = item.item_data.is_cursed == search_cursed
		
		if match_search_string and match_curse:
			item.show()
		else:
			item.hide()
