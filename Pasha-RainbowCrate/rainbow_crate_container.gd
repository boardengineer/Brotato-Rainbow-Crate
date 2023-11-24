extends VBoxContainer


onready var item_container = $Container/VBoxContainer/ScrollContainer/VBoxContainer/ItemContainer

func add_item_ui(item_ui):
	item_container.add_child(item_ui)
