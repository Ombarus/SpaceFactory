extends Node

export var startLevel = "data/json/levels/start.json"

func _ready():
	Globals.LevelLoaderRef = self
	
	# Seems to be working fine. Distribution is pretty flat over huge number of throws.
	# Average is good
	# Saving and restoring state seems to work
	#MersenneTwister.set_seed(2)
	MersenneTwister.randomize_seed()

func _exit_tree():
	Globals.LevelLoaderRef = null
	
func LoadJSON(filepath):
	var file = File.new()
	if not "res://" in filepath and not "user://" in filepath:
		filepath = "res://" + filepath
	
	if filepath in Preloader.JsonCache:
		return Preloader.JsonCache[filepath]
	
	file.open(filepath, file.READ)
	var text = file.get_as_text()
	var result_json = JSON.parse(text)
	file.close()
	
	var data = null
	if result_json.error == OK:  # If parse OK
		data = result_json.result
	else:  # If parse has errors
		print("Error in ", filepath)
		print("Error: ", result_json.error)
		print("Error Line: ", result_json.error_line)
		print("Error String: ", result_json.error_string)
	
	if data != null:
		data["src"] = filepath
		Preloader.JsonCache[filepath] = data
	return data
	
func LoadJSONArray(filepaths):
	var res = []
	if filepaths == null:
		return res
	for filepath in filepaths:
		if not filepath.empty():
			res.push_back(LoadJSON(filepath))
	return res
	
#######################################################
# EVERY OBJECT SHOULD BE CREATED THROUGH HERE
#######################################################

func CreateAndInitNode(data, pos, modified_data = null):
	var r = get_node("/root/Root/GameTiles")
	var scene = Preloader.BaseObject
	var n = scene.instance()
	if data.has("name_id"):
		var last = data["name_id"].split("/")
		n.set_name(last[-1])
	n.position = Tile_to_World(pos)
	n.base_attributes = data
	n.modified_attributes = {}
	if modified_data != null:
		# If I init objects with modified data in a loop and pass the same dictionnary
		# it'll be shared between multiple objects. To avoid this, make sure I save a copy
		# (see dropping food in ProcessHarvest())
		n.modified_attributes = str2var(var2str(modified_data))
	r.call_deferred("add_child", n)
	levelTiles[ pos.x ][ pos.y ].push_back(n)
	var obj_type = n.get_attrib("type")
	if obj_type != null:
		if not objByType.has(obj_type):
			objByType[ obj_type ] = []
		objByType[ obj_type ].push_back(n)
		if obj_type == "wormhole" and not n.modified_attributes.has("depth"):
			n.modified_attributes["depth"] = current_depth + 1
	if not n.modified_attributes.has("unique_id"):
		n.modified_attributes["unique_id"] = _sequence_id
		_sequence_id += 1
	objById[n.modified_attributes["unique_id"]] = n
	if n.get_attrib("animation.waiting_moving") == true:
		n.set_attrib("animation.waiting_moving", false)
	if n.get_attrib("animation.in_movement") == true:
		n.set_attrib("animation.in_movement", false)
	BehaviorEvents.emit_signal("OnObjectLoaded", n)
	if modified_data == null: # only count new stuff
		var clean_path = Globals.clean_path(data["src"])
		if not clean_path in _global_spawns:
			_global_spawns[clean_path] = 0
		_global_spawns[clean_path] += 1
	return n
	
#######################################################
#######################################################
