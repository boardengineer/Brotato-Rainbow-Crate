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

func _ready():
	if not get_node("/root/ModLoader").has_node("dami-ModOptions"):
		return
	
	var mod_configs_interface = get_node("/root/ModLoader/dami-ModOptions/ModsConfigInterface")
	
	if mod_configs_interface:
		mod_configs_interface.connect("setting_changed", self, "setting_changed")

func setting_changed(key:String, value, mod) -> void:
	if mod != MOD_NAME:
		return
	
	if key == RAINBOW_CRATES_ENABLED_OPTION_NAME:
		rainbow_crates_enabled = value
	elif key == RAINBOW_CRATES_DROP_CHANCE_OPTION_NAME:
		rainbow_crates_drop_chance = value
	elif key == UNLOCKED_ITEMS_ONLY_OPTION_NAME:
		unlocked_items_only = value
	else:
		print_debug("WARNING, UNKNOWN CHANGE ", key)
	
	save_configs()

func load_configs() -> void:
	if not get_node("/root/ModLoader").has_node("dami-ModOptions"):
		return
	
	var mod_configs_interface = get_node("/root/ModLoader/dami-ModOptions/ModsConfigInterface")
	
	var config = ConfigFile.new()
	var err = config.load(CONFIG_FILENAME)
	
	if err != OK:
		return
	
	rainbow_crates_enabled = config.get_value(CONFIG_SECTION, RAINBOW_CRATES_ENABLED_OPTION_NAME, true)
	mod_configs_interface.on_setting_changed(RAINBOW_CRATES_ENABLED_OPTION_NAME, rainbow_crates_enabled, MOD_NAME)
	
	rainbow_crates_drop_chance = config.get_value(CONFIG_SECTION, RAINBOW_CRATES_DROP_CHANCE_OPTION_NAME, .2)
	mod_configs_interface.on_setting_changed(RAINBOW_CRATES_DROP_CHANCE_OPTION_NAME, rainbow_crates_drop_chance, MOD_NAME)
	
	unlocked_items_only = config.get_value(CONFIG_SECTION, UNLOCKED_ITEMS_ONLY_OPTION_NAME, false)
	mod_configs_interface.on_setting_changed(UNLOCKED_ITEMS_ONLY_OPTION_NAME, unlocked_items_only, MOD_NAME)
	
func save_configs() -> void:
	var config = ConfigFile.new()
	
	config.set_value(CONFIG_SECTION, RAINBOW_CRATES_ENABLED_OPTION_NAME, rainbow_crates_enabled)
	config.set_value(CONFIG_SECTION, RAINBOW_CRATES_DROP_CHANCE_OPTION_NAME, rainbow_crates_drop_chance)
	config.set_value(CONFIG_SECTION, UNLOCKED_ITEMS_ONLY_OPTION_NAME, unlocked_items_only)
	
	config.save(CONFIG_FILENAME)
