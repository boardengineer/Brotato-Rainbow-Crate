extends VBoxContainer

# The rainbow crate picker: a searchable grid of everything the crate can give this player.
# Cards are created a page at a time, so opening it costs the same however many items the
# game and its DLCs add.

signal item_chosen(item_data)
signal random_chosen

enum Mode {NONE, CURSED, MUTANT, MECA}

const PAGE_SIZE = 24
const CARD_MIN_WIDTH = 340.0
const TITLE_MIN_WIDTH = 1000.0
const SOLO_MIN_WIDTH = 1500.0
const SEARCH_DELAY = 0.2		 # the search is applied this long after the last key press
const SEARCH_CLICK_MARGIN = 6.0  # a click this close to the search box focuses it
const ITEM_TIER_KEYS = ["TIER_COMMON", "TIER_UNCOMMON", "TIER_RARE", "TIER_LEGENDARY"]
const WEAPON_TIER_KEYS = ["TIER_I", "TIER_II", "TIER_III", "TIER_IV"]
const TIER_BUTTON_WIDTH = 120.0
const NARROW_TIER_BUTTON_WIDTH = 56.0

onready var item_card_scene = load("res://mods-unpacked/Pasha-RainbowCrate/rainbow_crate_ui/rainbow_crate_item.tscn")

onready var title_bar = $Header/TitleBar
onready var search_text_box = $Header/SearchText
onready var random_button = $Header/RandomButton
onready var toggles = $Toggles
onready var cursed_button = $Toggles/CursedButton
onready var mutant_button = $Toggles/MutantButton
onready var meca_button = $Toggles/MecaButton
onready var tiers = $Tiers
onready var tier_buttons = [$Tiers/AllButton, $Tiers/Tier0Button, $Tiers/Tier1Button, $Tiers/Tier2Button, $Tiers/Tier3Button]
onready var scroll_container = $ScrollContainer
onready var item_container = $ScrollContainer/VBoxContainer/ItemContainer
onready var more_button = $ScrollContainer/VBoxContainer/MoreButton

var player_index := 0
var weapons_mode := false

var _entries := []
var _names := {}				 # entry instance id -> translated name in lower case
var _tier_filter := -1		   # -1 = every tier
var _search_timer: Timer
var _variants := {}
var _cards := []
var _shown_limit: int = PAGE_SIZE
var _mode: int = Mode.NONE
var _updating_toggles := false


func _ready() -> void:
	var _error_cursed = cursed_button.connect("toggled", self, "_on_mode_button_toggled", [Mode.CURSED])
	var _error_mutant = mutant_button.connect("toggled", self, "_on_mode_button_toggled", [Mode.MUTANT])
	var _error_meca = meca_button.connect("toggled", self, "_on_mode_button_toggled", [Mode.MECA])
	var _error_resized = scroll_container.connect("resized", self, "_update_layout")

	var tier_group := ButtonGroup.new()
	for i in tier_buttons.size():
		tier_buttons[i].group = tier_group
		var _error_tier = tier_buttons[i].connect("pressed", self, "_on_tier_button_pressed", [i - 1])

	_search_timer = Timer.new()
	_search_timer.one_shot = true
	_search_timer.wait_time = SEARCH_DELAY
	var _error_timer = _search_timer.connect("timeout", self, "_apply_search")
	add_child(_search_timer)
	var _error_entered = search_text_box.connect("text_entered", self, "_on_SearchText_text_entered")


func open(p_player_index: int, p_weapons_mode: bool) -> void:
	player_index = p_player_index
	weapons_mode = p_weapons_mode
	_entries = _get_entries()
	_names = {}
	for entry in _entries:
		_names[entry.get_instance_id()] = tr(entry.name).to_lower()
	_entries.sort_custom(self, "_sort_entries")
	_variants = {}
	_shown_limit = PAGE_SIZE

	search_text_box.text = ""
	_search_timer.stop()
	_tier_filter = -1
	tier_buttons[0].pressed = true

	var primal_dread_active: bool = get_active_dlc("primal_dread") != null
	cursed_button.visible = get_active_dlc("abyssal_terrors") != null
	# The mutation helpers arrived in game 1.2.0.2.
	mutant_button.visible = primal_dread_active and not weapons_mode and get_active_dlc("primal_dread").has_method("_get_removable_negative_effect_indexes")
	meca_button.visible = primal_dread_active and weapons_mode
	toggles.visible = cursed_button.visible or mutant_button.visible or meca_button.visible
	_set_mode(Mode.NONE)

	# Solo, the panel shrinks to its content, so ask for room. In co-op every player has a fixed
	# share of the screen and the picker has to fit inside it.
	var player_count: int = RunData.get_player_count()
	rect_min_size.x = SOLO_MIN_WIDTH if player_count == 1 else 0.0
	toggles.columns = 1 if player_count > 2 else 3

	# With 3 or 4 players a full rarity name does not fit a quarter of the screen: the
	# buttons show the tier numerals instead, in the tier colour.
	var narrow: bool = player_count > 2
	var tier_keys: Array = WEAPON_TIER_KEYS if weapons_mode or narrow else ITEM_TIER_KEYS
	for i in tier_buttons.size():
		tier_buttons[i].rect_min_size.x = NARROW_TIER_BUTTON_WIDTH if narrow else TIER_BUTTON_WIDTH
		if i > 0:
			tier_buttons[i].text = tr(tier_keys[i - 1])
			tier_buttons[i].add_color_override("font_color", ItemService.get_color_from_tier(i - 1))

	scroll_container.scroll_vertical = 0
	show()
	_update_layout()
	_refresh()


# A click on the search box edge or just outside it lands on the cards or the toggles
# around it: catch it before the GUI does and focus the box.
func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not (event is InputEventMouseButton) or not event.pressed or event.button_index != BUTTON_LEFT:
		return
	if search_text_box.has_focus():
		return
	if search_text_box.get_global_rect().grow(SEARCH_CLICK_MARGIN).has_point(search_text_box.get_global_mouse_position()):
		search_text_box.grab_focus()


func get_default_focus() -> Control:
	return random_button


# The DLC's data when the DLC is owned and switched on for this run, else null.
func get_active_dlc(dlc_id: String):
	if not ProgressData.has_item_set(dlc_id):
		return null

	return ItemService.get_dlc_data_by_id(dlc_id)


func _get_entries() -> Array:
	var rainbow_crate_options = get_node_or_null("/root/PashaRainbowCrateOptions")
	var unlocked_only: bool = rainbow_crate_options != null and rainbow_crate_options.unlocked_items_only
	var entries := []

	if weapons_mode:
		for item_set in _active_item_sets():
			for weapon in item_set.weapons:
				if unlocked_only and not ProgressData.weapons_unlocked.has(weapon.weapon_id_hash):
					continue
				entries.push_back(weapon)
		return entries

	for item in _active_items():
		# max_nb 0 marks items the game never hands out (Tumor, Broken Hourglass).
		if item.max_nb == 0:
			continue
		if item.max_nb > 0 and RunData.get_nb_item(item.my_id_hash, player_index) >= item.max_nb:
			continue
		if unlocked_only and not ProgressData.items_unlocked.has(item.my_id_hash):
			continue
		entries.push_back(item)

	return entries


# Tier first, then name: the list reads like the shop tiers, common to legendary.
func _sort_entries(a: ItemParentData, b: ItemParentData) -> bool:
	if a.tier != b.tier:
		return a.tier < b.tier
	return _names[a.get_instance_id()] < _names[b.get_instance_id()]


# The item sets this run uses: the base game plus every update or DLC that is owned AND
# ticked on the DLC screen, the same list the shop pools are built from
# (ItemService.init_unlocked_pool). ItemService.items and .weapons follow ownership only,
# so they still hold a DLC that was unticked for this run.
func _active_item_sets() -> Array:
	var item_sets := [ItemService.base_game_item_set]
	for update_data in ItemService.update_data_list:
		if update_data != null and update_data.item_set != null and ProgressData.has_item_set(update_data.id):
			item_sets.push_back(update_data.item_set)
	return item_sets


func _active_items() -> Array:
	var items := []
	for item_set in _active_item_sets():
		items.append_array(item_set.items)
		# Primal Dread keeps its mecha, mutant and evolution items outside the main list.
		for extra in ["meca_items", "mutant_items", "evolution_items"]:
			if extra in item_set:
				items.append_array(item_set.get(extra))
	return items


func _mode_allows(entry: ItemParentData) -> bool:
	if _mode == Mode.CURSED:
		return ItemService.can_item_be_cursed(entry)
	if _mode == Mode.MUTANT:
		return ItemService.can_item_be_mutated(entry) and not get_active_dlc("primal_dread")._get_removable_negative_effect_indexes(entry).empty()
	if _mode == Mode.MECA:
		return ItemService.can_weapon_be_mechanized(entry)
	return true


# What the card shows and gives for an entry under the current toggle. A variant is made
# once per picker opening, so the card shows exactly what taking it gives.
func _get_variant(entry: ItemParentData) -> ItemParentData:
	if _mode == Mode.NONE:
		return entry

	var key := "%d:%d" % [_mode, entry.get_instance_id()]

	if not _variants.has(key):
		if _mode == Mode.CURSED:
			_variants[key] = get_active_dlc("abyssal_terrors").curse_item(entry.duplicate(), player_index, true)
		elif _mode == Mode.MUTANT:
			_variants[key] = _mutant_variant(entry)
		else:
			_variants[key] = get_active_dlc("primal_dread").meca_item(entry, player_index)

	return _variants[key]


# The item as a mutation fruit leaves it when it removes a negative effect
# (DLC2Data.mutant_item, first branch). That function picks the Tumor branch half the
# time instead, which grows a Tumor and leaves the item as it was, so it is not called.
func _mutant_variant(entry: ItemParentData) -> ItemParentData:
	var removable: Array = get_active_dlc("primal_dread")._get_removable_negative_effect_indexes(entry)
	var mutant = entry.duplicate()
	var effects := []

	for effect in entry.effects:
		effects.append(effect.duplicate())

	var removed_index: int = Utils.get_rand_element(removable)
	mutant.mutation_removed_effects = [effects[removed_index]]
	effects.remove(removed_index)
	mutant.effects = effects
	mutant.is_mutant = true

	return mutant


func _refresh() -> void:
	var search_text: String = search_text_box.text.strip_edges().to_lower()
	var matches := []

	for entry in _entries:
		if _tier_filter != -1 and entry.tier != _tier_filter:
			continue
		if search_text != "" and _names[entry.get_instance_id()].find(search_text) == -1:
			continue
		if not _mode_allows(entry):
			continue
		matches.push_back(entry)

	var shown: int = int(min(matches.size(), _shown_limit))

	while _cards.size() < shown:
		var card = item_card_scene.instance()
		item_container.add_child(card)
		var _error = card.connect("take_pressed", self, "_on_card_take_pressed")
		_cards.push_back(card)

	for i in _cards.size():
		var card = _cards[i]
		card.visible = i < shown
		if i < shown:
			card.set_item_data(_get_variant(matches[i]), player_index)

	more_button.visible = matches.size() > shown
	more_button.text = "Show more (%d)" % (matches.size() - shown)
	# The title is hidden on narrow (co-op) pickers, so the search box carries the count too.
	title_bar.text = "%s (%d)" % ["Select any Weapon!" if weapons_mode else "Select any Item!", matches.size()]
	search_text_box.placeholder_text = "Search %d" % matches.size()


func _update_layout() -> void:
	var separation: int = item_container.get_constant("hseparation")
	item_container.columns = int(max(1, floor((scroll_container.rect_size.x + separation) / (CARD_MIN_WIDTH + separation))))
	title_bar.visible = rect_size.x >= TITLE_MIN_WIDTH


func _set_mode(mode: int) -> void:
	_mode = mode
	_updating_toggles = true
	cursed_button.pressed = mode == Mode.CURSED
	mutant_button.pressed = mode == Mode.MUTANT
	meca_button.pressed = mode == Mode.MECA
	_updating_toggles = false


func _on_mode_button_toggled(button_pressed: bool, mode: int) -> void:
	if _updating_toggles:
		return

	_set_mode(mode if button_pressed else Mode.NONE)
	_shown_limit = PAGE_SIZE
	scroll_container.scroll_vertical = 0
	_refresh()


func _on_tier_button_pressed(tier: int) -> void:
	_tier_filter = tier
	_shown_limit = PAGE_SIZE
	scroll_container.scroll_vertical = 0
	_refresh()


func _on_SearchText_text_changed(_new_text: String) -> void:
	_search_timer.start()


func _on_SearchText_text_entered(_new_text: String) -> void:
	_apply_search()


func _apply_search() -> void:
	_search_timer.stop()
	_shown_limit = PAGE_SIZE
	scroll_container.scroll_vertical = 0
	_refresh()


func _on_MoreButton_pressed() -> void:
	_shown_limit += PAGE_SIZE
	_refresh()


func _on_RandomButton_pressed() -> void:
	emit_signal("random_chosen")


func _on_card_take_pressed(item_data: ItemParentData) -> void:
	emit_signal("item_chosen", item_data)
