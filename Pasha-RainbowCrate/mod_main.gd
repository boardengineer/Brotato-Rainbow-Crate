extends Node

const MOD_DIR = "Pasha-RainbowCrate/"

func _init(_modLoader = ModLoader):
	var dir = ModLoaderMod.get_unpacked_dir() + MOD_DIR
	var ext_dir = dir + "extensions/"
	
	ModLoaderMod.install_script_extension(ext_dir + "main.gd")
	ModLoaderMod.install_script_extension(ext_dir + "singletons/item_service.gd")
	ModLoaderMod.install_script_extension(ext_dir + "ui/menus/upgrades/item_box_ui.gd")
