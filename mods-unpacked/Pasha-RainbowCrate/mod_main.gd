extends Node

const MOD_DIR = "Pasha-RainbowCrate/"

var options_node_script = load("res://mods-unpacked/Pasha-RainbowCrate/rainbow_crate_options.gd")

func _init():
	var dir = ModLoaderMod.get_unpacked_dir() + MOD_DIR
	var ext_dir = dir + "extensions/"
	var trans_dir = dir + "translations/"
	
	ModLoaderMod.install_script_extension(ext_dir + "main.gd")
	ModLoaderMod.install_script_extension(ext_dir + "singletons/item_service.gd")
	ModLoaderMod.install_script_extension(ext_dir + "ui/menus/ingame/upgrades_ui_player_container.gd")
	
	ModLoaderMod.add_translation(trans_dir + "pasha_rainbow_crate_options.en.translation")

func _ready():
	var options_node = options_node_script.new()
	options_node.set_name("PashaRainbowCrateOptions")
	$"/root".call_deferred("add_child", options_node)
	options_node.call_deferred("load_configs")
