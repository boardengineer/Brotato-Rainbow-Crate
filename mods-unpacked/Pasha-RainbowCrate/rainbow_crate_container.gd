extends VBoxContainer

onready var item_container = $Container/VBoxContainer/ScrollContainer/VBoxContainer/ItemContainer
onready var search_text_box = $Container/VBoxContainer/HBoxContainer/TitleCanvas/SearchText

onready var title_canvas = $Container/VBoxContainer/HBoxContainer/TitleCanvas

onready var items_to_iterate := []

func add_item_ui(item_ui):
	item_container.add_child(item_ui)
	items_to_iterate.push_back(item_ui)

func _on_search_text_changed():
	var search_text = search_text_box.text.to_lower()
	for item in items_to_iterate:
		var name = tr(item.item_data.name).to_lower()
		if name.find(search_text) == -1 and search_text != "":
			item.hide()
		else:
			item.show()

func show() -> void:
	.show()
	title_canvas.show()

func hide() -> void:
	.hide()
	title_canvas.hide()
