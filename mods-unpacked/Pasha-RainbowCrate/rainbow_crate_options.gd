extends Node

var rainbow_crates_enabled = true
const RAINBOW_CRATES_ENABLED_OPTION_NAME = "PASHA_RAINBOW_CRATE_RAINBOW_CRATES_ENABLED"

var rainbow_crates_drop_chance = .2
const RAINBOW_CRATES_DROP_CHANCE_OPTION_NAME = "PASHA_RAINBOW_CRATE_DROP_CHANCE"

var unlocked_items_only = false
const UNLOCKED_ITEMS_ONLY_OPTION_NAME = "PASHA_RAINBOW_CRATE_UNLOCKED_ITEMS_ONLY"

const MOD_NAME = "Pasha-RainbowCrate"
const CONFIG_FILENAME = "user://pasha-rainbowcrate-options.cfg"
const CONFIG_SECTION = "options"
# Writes wait until the settings stop changing for this long, so dragging the drop
# chance slider writes the file once instead of on every step.
const SAVE_DELAY = 0.5

var _save_timer: Timer
var _loading := false   # load_configs is pushing the saved values into Mod Options
var _dirty := false

func _ready():
	if not get_node("/root/ModLoader").has_node("dami-ModOptions"):
		return
	
	var mod_configs_interface = get_node("/root/ModLoader/dami-ModOptions/ModsConfigInterface")
	
	if mod_configs_interface:
		mod_configs_interface.connect("setting_changed", self, "setting_changed")

func setting_changed(key:String, value, mod) -> void:
	# While the saved config is loading the values are already in place.
	if mod != MOD_NAME or _loading:
		return
	
	if key == RAINBOW_CRATES_ENABLED_OPTION_NAME:
		if rainbow_crates_enabled == value:
			return
		rainbow_crates_enabled = value
	elif key == RAINBOW_CRATES_DROP_CHANCE_OPTION_NAME:
		if rainbow_crates_drop_chance == value:
			return
		rainbow_crates_drop_chance = value
	elif key == UNLOCKED_ITEMS_ONLY_OPTION_NAME:
		if unlocked_items_only == value:
			return
		unlocked_items_only = value
	else:
		print_debug("WARNING, UNKNOWN CHANGE ", key)
		return
	
	_schedule_save()

func load_configs() -> void:
	if not get_node("/root/ModLoader").has_node("dami-ModOptions"):
		return
	
	var mod_configs_interface = get_node("/root/ModLoader/dami-ModOptions/ModsConfigInterface")
	
	var config = ConfigFile.new()
	var err = config.load(CONFIG_FILENAME)
	
	if err != OK:
		return
	
	_loading = true
	
	rainbow_crates_enabled = config.get_value(CONFIG_SECTION, RAINBOW_CRATES_ENABLED_OPTION_NAME, true)
	mod_configs_interface.on_setting_changed(RAINBOW_CRATES_ENABLED_OPTION_NAME, rainbow_crates_enabled, MOD_NAME)
	
	rainbow_crates_drop_chance = config.get_value(CONFIG_SECTION, RAINBOW_CRATES_DROP_CHANCE_OPTION_NAME, .2)
	mod_configs_interface.on_setting_changed(RAINBOW_CRATES_DROP_CHANCE_OPTION_NAME, rainbow_crates_drop_chance, MOD_NAME)
	
	unlocked_items_only = config.get_value(CONFIG_SECTION, UNLOCKED_ITEMS_ONLY_OPTION_NAME, false)
	mod_configs_interface.on_setting_changed(UNLOCKED_ITEMS_ONLY_OPTION_NAME, unlocked_items_only, MOD_NAME)
	
	_loading = false
	
func save_configs() -> void:
	_dirty = false
	var config = ConfigFile.new()
	
	config.set_value(CONFIG_SECTION, RAINBOW_CRATES_ENABLED_OPTION_NAME, rainbow_crates_enabled)
	config.set_value(CONFIG_SECTION, RAINBOW_CRATES_DROP_CHANCE_OPTION_NAME, rainbow_crates_drop_chance)
	config.set_value(CONFIG_SECTION, UNLOCKED_ITEMS_ONLY_OPTION_NAME, unlocked_items_only)
	
	config.save(CONFIG_FILENAME)

func _schedule_save() -> void:
	_dirty = true
	if _save_timer == null:
		_save_timer = Timer.new()
		_save_timer.one_shot = true
		_save_timer.wait_time = SAVE_DELAY
		var _error = _save_timer.connect("timeout", self, "_flush")
		add_child(_save_timer)
	_save_timer.start()

# A change still waiting to be written is not lost when the game closes.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_QUIT_REQUEST:
		_flush()

func _exit_tree() -> void:
	_flush()

func _flush() -> void:
	if _dirty:
		save_configs()
