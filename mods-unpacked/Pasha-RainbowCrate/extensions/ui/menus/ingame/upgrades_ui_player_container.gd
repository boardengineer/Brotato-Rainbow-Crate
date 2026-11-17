extends "res://ui/menus/ingame/upgrades_ui_player_container.gd"

const RAINBOW_CRATE_ID = "consumable_pasha_rainbow_crate"

# Built the first time this player opens a rainbow crate. It sits next to the stock item
# and upgrade panels, so it works for the solo container and the co-op one alike.
var rainbow_crate_ui = null
var _rainbow_fallback_item: ItemParentData = null


func show_consumable_data(consumable_data: ConsumableData):
	if consumable_data.my_id != RAINBOW_CRATE_ID:
		_hide_rainbow_picker()
		.show_consumable_data(consumable_data)
		return

	_consumable_data = consumable_data
	# What a normal crate would have given; the picker's "Random" button shows it.
	_rainbow_fallback_item = ItemService.process_item_box(consumable_data, RunData.current_wave, player_index)
	_show_rainbow_picker()


func show_upgrades_for_level(level: int) -> void:
	_hide_rainbow_picker()
	.show_upgrades_for_level(level)


func show_item(item_data: ItemParentData) -> void:
	_hide_rainbow_picker()
	.show_item(item_data)


# True while the picker is open as well, so crate-weapon characters (Survivor) keep their
# weapons inventory next to it.
func is_showing_item() -> bool:
	return is_rainbow_picker_open() or .is_showing_item()


func get_focus_control() -> Control:
	if is_rainbow_picker_open():
		return rainbow_crate_ui.get_default_focus()

	return .get_focus_control()


func is_rainbow_picker_open() -> bool:
	return rainbow_crate_ui != null and is_instance_valid(rainbow_crate_ui) and rainbow_crate_ui.visible


func _show_rainbow_picker() -> void:
	if rainbow_crate_ui == null or not is_instance_valid(rainbow_crate_ui):
		rainbow_crate_ui = load("res://mods-unpacked/Pasha-RainbowCrate/rainbow_crate_ui/rainbow_crate_container.tscn").instance()
		_items_container.get_parent().add_child(rainbow_crate_ui)
		var _error_item = rainbow_crate_ui.connect("item_chosen", self, "_on_rainbow_item_chosen")
		var _error_random = rainbow_crate_ui.connect("random_chosen", self, "_on_rainbow_random_chosen")

	_update_gold_label()
	_items_container.hide()
	_upgrades_container.hide()

	var weapons_mode: bool = RunData.get_player_effect(Keys.effect_crate_give_weapon_hash, player_index) > 0
	rainbow_crate_ui.open(player_index, weapons_mode)
	call_deferred("_focus_rainbow_picker")


func _hide_rainbow_picker() -> void:
	if rainbow_crate_ui != null and is_instance_valid(rainbow_crate_ui):
		rainbow_crate_ui.hide()


# The co-op container's own focus() only knows the stock panels, so the picker asks for
# focus itself (emulated focus in co-op, real focus in solo).
func _focus_rainbow_picker() -> void:
	if is_rainbow_picker_open():
		Utils.focus_player_control(rainbow_crate_ui.get_default_focus(), player_index, get("focus_emulator"))


func _on_rainbow_item_chosen(item_data: ItemParentData) -> void:
	if _button_pressed:
		return

	# Weapons and mecha picks go through the stock panel: it owns the weapon-slot and
	# combine rules and the mecha stat choice.
	if item_data is WeaponData or item_data.is_meca:
		show_item(item_data)
		focus()
		return

	_button_pressed = true
	_button_delay_timer.start()
	_hide_rainbow_picker()

	if _things_to_process_container:
		_things_to_process_container.consumables.remove_element(_consumable_data)

	emit_signal("item_take_button_pressed", item_data)


func _on_rainbow_random_chosen() -> void:
	if _button_pressed or _rainbow_fallback_item == null:
		return

	show_item(_rainbow_fallback_item)
	focus()
