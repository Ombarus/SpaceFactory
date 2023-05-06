extends Node

const CURRENT_VERSION := 0

#TODO: Might want to add more info about the player (cargo inventory, # of turn spent, etc.
var _perm_save = {
	"version" : CURRENT_VERSION,
	"settings": {
		"default_name":null,
		"full_screen":true,
		"vsync":true,
		"master_volume":4.0,
		"sfx_volume":4.0,
		"music_volume":4.0,
		"display_fps":false,
		"lang":null
	}
}

var _savefile_name = "user://perm_config.save"

func _ready():
	var tmp = _perm_save
	if FileAccess.file_exists(_savefile_name):
		var file = FileAccess.open(_savefile_name, FileAccess.READ)
		var text = file.get_as_text()
		var test_json_conv = JSON.new()
		if test_json_conv.parse(text) != OK:
			printerr("Error parsing JSON for %s" % _savefile_name)
		tmp = test_json_conv.data
		file.close()
		
		if "version" in tmp and tmp.version == CURRENT_VERSION:
			_perm_save = tmp
		else:
			var msg : String = str(tmp.version) if 'version' in tmp else 'missing'
			print("WARNING : Savefile version does not match (" + msg + " != " + str(CURRENT_VERSION) + "). Perm save update")
			var valid := true
			if valid:
				tmp.version = CURRENT_VERSION
				_perm_save = tmp
				save()
				

func get_attrib(path, default=null):
	return Globals.get_data(_perm_save, path, default)

func set_attrib(path, val, save=true):
	Globals.set_data(_perm_save, path, val)
	if save == true:
		save()
	
func save():
	var save_game = FileAccess.open(_savefile_name, FileAccess.WRITE)
	save_game.store_line(JSON.stringify(_perm_save))
	save_game.close()
