extends Node

var example_loaded_object = {
	0: { # unique id handle
		"src":"data/json/items/glass.json", # base_attributes, also serve as key in global cache
		"inventory": { # override value in "src" (base_attribute)
			"max_stack":200
		}
	}
}
var loaded_objects := {}
var loaded_visuals := {}

func _ready():
	Globals.LevelLoaderRef = self
	
	# Seems to be working fine. Distribution is pretty flat over huge number of throws.
	# Average is good
	# Saving and restoring state seems to work
	#MersenneTwister.set_seed(2)
	MersenneTwister.randomize_seed()

func _exit_tree():
	Globals.LevelLoaderRef = null
	
func load_json(filepath):
	if not "res://" in filepath and not "user://" in filepath:
		filepath = "res://" + filepath
	
	if filepath in Preloader.JsonCache:
		return Preloader.JsonCache[filepath]
	
	var file = FileAccess.open(filepath, FileAccess.READ)
	var text = file.get_as_text()
	var test_json_conv = JSON.new()
	if test_json_conv.parse(text) != OK:
		print("Error in ", filepath)
		print("Error: ", test_json_conv.error)
		print("Error Line: ", test_json_conv.error_line)
		print("Error String: ", test_json_conv.error_string)
		
	var data = test_json_conv.data
	file.close()
	
	if data != null:
		data["src"] = filepath
		load_references(data)
		Preloader.JsonCache[filepath] = data
	return data
	
func load_json_array(filepaths):
	var res = []
	if filepaths == null:
		return res
	for filepath in filepaths:
		if not filepath.is_empty():
			res.push_back(load_json(filepath))
	return res
	
func load_references(json_data):
	if typeof(json_data) == TYPE_DICTIONARY:
		var key_to_delete = []
		for key in json_data:
			if "__ref__" in key:
				var ref_data : Dictionary = load_json(json_data[key])
				for ref_key in ref_data:
					json_data[ref_key] = ref_data[ref_key]
				key_to_delete.append(key)
			elif typeof(json_data[key]) == TYPE_DICTIONARY or typeof(json_data[key]) == TYPE_ARRAY:
				load_references(json_data[key])
		for key in key_to_delete:
			json_data.erase(key)
	if typeof(json_data) == TYPE_ARRAY:
		for val in json_data:
			if typeof(val) == TYPE_DICTIONARY or typeof(val) == TYPE_ARRAY:
				load_references(val)
				
	
#######################################################
# EVERY OBJECT SHOULD BE CREATED THROUGH HERE
#######################################################
func get_object_data(id : int) -> Dictionary:
	return loaded_objects[id]
	
func get_visual_from_data(data_id : int) -> Attributes:
	var data = get_object_data(data_id)
	var visual = loaded_visuals.get(Globals.get_attrib(data, "visual.node_id"), null)
	return visual

func create_object_data(src_path : String, modified_attributes : Dictionary) -> int:
	var new_id = Globals.get_unique_id()
	
	var modified_copy = str_to_var(var_to_str(modified_attributes))
	modified_copy["src"] = src_path
	modified_copy["id"] = new_id
	loaded_objects[new_id] = modified_copy
	var node_id = Globals.get_attrib(modified_copy, "visual.node_id", "")
	if not node_id.is_empty():
		loaded_visuals[node_id] = get_node(node_id)
	Events.emit_signal("OnObjectCreated", loaded_objects[new_id])
	return new_id
	
func destroy_object(id):
	var data = get_object_data(id)
	var visual = get_visual_from_data(id)
	
	Events.emit_signal("OnObjectDestroyed", data)
	
	if visual:
		visual.visible = false
		var node_id = Globals.get_attrib(data, "visual.node_id")
		loaded_visuals[node_id].queue_free()
		loaded_visuals.erase(node_id)
		
	loaded_objects.erase(id)
#func CreateAndInitNode(data, pos, modified_data = null):
#	var r = get_node("/root/Root/GameTiles")
#	var scene = Preloader.BaseObject
#	var n = scene.instantiate()
#	if data.has("name_id"):
#		var last = data["name_id"].split("/")
#		n.set_name(last[-1])
#	n.position = Tile_to_World(pos)
#	n.base_attributes = data
#	n.modified_attributes = {}
#	if modified_data != null:
#		# If I init objects with modified data in a loop and pass the same dictionnary
#		# it'll be shared between multiple objects. To avoid this, make sure I save a copy
#		# (see dropping food in ProcessHarvest())
#		n.modified_attributes = str_to_var(var_to_str(modified_data))
#	r.call_deferred("add_child", n)
#	levelTiles[ pos.x ][ pos.y ].push_back(n)
#	var obj_type = n.get_attrib("type")
#	if obj_type != null:
#		if not objByType.has(obj_type):
#			objByType[ obj_type ] = []
#		objByType[ obj_type ].push_back(n)
#		if obj_type == "wormhole" and not n.modified_attributes.has("depth"):
#			n.modified_attributes["depth"] = current_depth + 1
#	if not n.modified_attributes.has("unique_id"):
#		n.modified_attributes["unique_id"] = _sequence_id
#		_sequence_id += 1
#	objById[n.modified_attributes["unique_id"]] = n
#	if n.get_attrib("animation.waiting_moving") == true:
#		n.set_attrib("animation.waiting_moving", false)
#	if n.get_attrib("animation.in_movement") == true:
#		n.set_attrib("animation.in_movement", false)
#	BehaviorEvents.emit_signal("OnObjectLoaded", n)
#	if modified_data == null: # only count new stuff
#		var clean_path = Globals.clean_path(data["src"])
#		if not clean_path in _global_spawns:
#			_global_spawns[clean_path] = 0
#		_global_spawns[clean_path] += 1
#	return n
	
#######################################################
#######################################################
