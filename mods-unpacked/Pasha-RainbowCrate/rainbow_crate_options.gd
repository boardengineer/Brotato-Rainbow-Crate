extends Node

var rainbow_crates_enabled = false
var rainbow_crate_drop_chance = .2

const MOD_NAME = "Pasha-RainbowCrate"
const CONFIG_FILENAME = "user://pasha-rainbowcrate-options.cfg"
const CONFIG_SECTION = "options"

func _ready():
	var mod_configs_interface = get_node("/root/ModLoader/dami-ModOptions/ModsConfigInterface")
	
	mod_configs_interface.connect("setting_changed", self, "setting_changed")

func setting_changed(key:String, value, mod) -> void:
	print_debug(key, " ", value, " ", mod)
	if mod != MOD_NAME:
		return
		
	var lower_key = key.to_lower()
	if lower_key == "pasha_rainbow_crates_enabled":
		rainbow_crates_enabled = value
	elif lower_key == "pasha_rainbow_crate_drop_chance":
		rainbow_crate_drop_chance = value
	
	save_configs()

func load_configs() -> void:
	var mod_configs_interface = get_node("/root/ModLoader/dami-ModOptions/ModsConfigInterface")
	
	var config = ConfigFile.new()
	var err = config.load(CONFIG_FILENAME)
	
	if err != OK:
		return
	
	rainbow_crates_enabled = config.get_value(CONFIG_SECTION, "pasha_rainbow_crates_enabled", false)
	mod_configs_interface.on_setting_changed("pasha_rainbow_crates_enabled".to_upper(), rainbow_crates_enabled, MOD_NAME)
	
	rainbow_crate_drop_chance = config.get_value(CONFIG_SECTION, "pasha_rainbow_crate_drop_chance", .2)
	mod_configs_interface.on_setting_changed("pasha_rainbow_crate_drop_chance".to_upper(), rainbow_crate_drop_chance, MOD_NAME)
	
func save_configs() -> void:
	var config = ConfigFile.new()
	
	config.set_value(CONFIG_SECTION, "pasha_rainbow_crates_enabled", rainbow_crates_enabled)
	config.set_value(CONFIG_SECTION, "pasha_rainbow_crate_drop_chance", rainbow_crate_drop_chance)
	
	config.save(CONFIG_FILENAME)
