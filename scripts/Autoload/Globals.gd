extends Node

var LevelLoaderRef = null
var unique_id = 0
const _CHEAT_MODE = true

enum COLLISION_LAYERS {
	WORLD = 1,
	PLAYER = 2,
	SNAP_POINTS = 4,
	ALL = 2147483647
}

func get_unique_id():
	var id = unique_id
	unique_id += 1
	return id

func get_attrib(modified_attributes : Dictionary, path : String, default=null):
	var splices = path.split(".", false)
	var base_attributes = Globals.LevelLoaderRef.load_json(modified_attributes["src"])
	var sub = modified_attributes
	for s in splices:
		if sub.has(s):
			sub = sub[s]
			if typeof(sub) == TYPE_DICTIONARY and sub.has("disabled") and sub["disabled"] == true:
				return default
		else:
			sub = null
			break
	if sub != null:
		return Check(sub, default)
	sub = base_attributes
	var sub_mod = modified_attributes # to check if there's a disabled override
	var disabled_override = null
	for s in splices:
		if sub_mod != null and sub_mod.has(s):
			sub_mod = sub_mod[s]
			if typeof(sub_mod) == TYPE_DICTIONARY and sub_mod.has("disabled"):
				disabled_override = sub_mod["disabled"]
			else:
				disabled_override = null
		if sub.has(s):
			sub = sub[s]
			if (disabled_override != null and disabled_override == true) or (typeof(sub) == TYPE_DICTIONARY and disabled_override == null and sub.has("disabled") and sub["disabled"] == true):
				return default
		else:
			sub = null
			break
	return Check(sub, default)
	
func Check(val, default):
	if typeof(val) == TYPE_DICTIONARY and val.has("__class"):
		return str2var(val.value)
	else:
		if val == null:
			return default
		else:
			return val
	
func set_attrib(modified_attributes : Dictionary, path : String, val) -> void:
	var splices = path.split(".", false)
	var sub = modified_attributes
	for i in range(splices.size()-1):
		var s = splices[i]
		if not sub.has(s):
			sub[s] = {}
		sub = sub[s]
	
	#TYPE_NIL = 0 — Variable is of type nil (only applied for null).
	#TYPE_BOOL = 1 — Variable is of type bool.
	#TYPE_INT = 2 — Variable is of type int.
	#TYPE_REAL = 3 — Variable is of type float/real.
	#TYPE_STRING = 4 — Variable is of type String.
	#TYPE_VECTOR2 = 5 — Variable is of type Vector2.
	#TYPE_RECT2 = 6 — Variable is of type Rect2.
	#TYPE_VECTOR3 = 7 — Variable is of type Vector3.
	#TYPE_TRANSFORM2D = 8 — Variable is of type Transform2D.
	#TYPE_PLANE = 9 — Variable is of type Plane.
	#TYPE_QUAT = 10 — Variable is of type Quat.
	#TYPE_AABB = 11 — Variable is of type AABB.
	#TYPE_BASIS = 12 — Variable is of type Basis.
	#TYPE_TRANSFORM = 13 — Variable is of type Transform.
	#TYPE_COLOR = 14 — Variable is of type Color.
	#TYPE_NODE_PATH = 15 — Variable is of type NodePath.
	#TYPE_RID = 16 — Variable is of type RID.
	#TYPE_OBJECT = 17 — Variable is of type Object.
	#TYPE_DICTIONARY = 18 — Variable is of type Dictionary.
	#TYPE_ARRAY = 19 — Variable is of type Array.
	#TYPE_RAW_ARRAY = 20 — Variable is of type PoolByteArray.
	#TYPE_INT_ARRAY = 21 — Variable is of type PoolIntArray.
	#TYPE_REAL_ARRAY = 22 — Variable is of type PoolRealArray.
	#TYPE_STRING_ARRAY = 23 — Variable is of type PoolStringArray.
	#TYPE_VECTOR2_ARRAY = 24 — Variable is of type PoolVector2Array.
	#TYPE_VECTOR3_ARRAY = 25 — Variable is of type PoolVector3Array.
	#TYPE_COLOR_ARRAY = 26 — Variable is of type PoolColorArray.
	#TYPE_MAX = 27 — Marker for end of type constants.
	
	if typeof(val) == TYPE_VECTOR2:
		val = {"__class":"Vector2", "value": var2str(val)}
	elif typeof(val) == TYPE_VECTOR3:
		val = {"__class":"Vector3", "value": var2str(val)}
	elif typeof(val) == TYPE_TRANSFORM:
		val = {"__class":"Transform", "value": var2str(val)}
	elif not typeof(val) in [TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_REAL, TYPE_STRING, TYPE_DICTIONARY, TYPE_ARRAY]:
		print("warning: (", path,  " = ", val, ") trying to serialize an unknown type to JSON")
	
	sub[splices[-1]] = val
			
func clean_path(path : String) -> String:
	if not "res://" in path and not "user://" in path:
		path = "res://" + path
	
	return path
	
func mytr2(text : String, fmt:={}) -> String:
	var result : String = tr(text)
	if OS.is_debug_build() and result == text and TranslationServer.get_locale() != "en":
		print("====> [TR] : No %s translation for %s" % [TranslationServer.get_locale(), text])
		
	if not fmt.empty():
		result = tr(text).format(fmt)
			
	return result

func mytr(text : String, fmt:=[]) -> String:
	var result : String = tr(text)
	if OS.is_debug_build() and result == text and TranslationServer.get_locale() != "en":
		print("====> [TR] : No %s translation for %s" % [TranslationServer.get_locale(), text])
		
	if not fmt.empty():
		result = tr(text) % fmt
			
	return result

func is_mobile() -> bool:
	#return true
	#"Android", "Haiku", "iOS", "HTML5", "OSX", "Server", "Windows", "UWP", "X11"
	var os_name := OS.get_name()
	if os_name == "Android" or os_name == "iOS" or os_name == "UWP":
		return true
	
	return false
	
func is_ios() -> bool:
	#return true
	var os_name := OS.get_name()
	if os_name == "iOS":
		return true
	
	return false
