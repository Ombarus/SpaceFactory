extends Node2D
class_name Attributes

export(String, FILE, "*.json") var PreloadData = ""
#TODO: hack to be able to modify modified_attributes in the editor. Apparently we can edit dictionnary in 3.1 so
# this shouldn't be needed in 3.1
export(String, MULTILINE) var PreloadJSON = ""

export var base_attributes = {} # can be kept by reference, no need to serialize
export var modified_attributes = {} # locally modified attribute (like current position). Should be saved !


func get_attrib(path, default=null):
	var splices = path.split(".", false)
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
	
func set_attrib(path, val):
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
	elif not typeof(val) in [TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_REAL, TYPE_STRING, TYPE_DICTIONARY, TYPE_ARRAY]:
		print("warning: (", path,  " = ", val, ") trying to serialize an unknown type to JSON")
	
	sub[splices[-1]] = val


func init_cargo():
	if modified_attributes.has("cargo") or not base_attributes.has("cargo"):
		return
	
	modified_attributes["cargo"] = {}
	modified_attributes.cargo["content"] = str2var(var2str(base_attributes.cargo.content))
	modified_attributes.cargo["volume_used"] = 0
	for item in modified_attributes.cargo.content:
		var item_data = Globals.LevelLoaderRef.LoadJSON(item.src)
		var volume_mult = Globals.EffectRef.GetMultiplierValue(self, item.src, item.get("modified_attributes", {}), "volume_multiplier")
		var vol = item_data.equipment.volume * volume_mult
		modified_attributes.cargo["volume_used"] += vol * item.count

func init_mounts():
	if base_attributes.has("mounts") and not modified_attributes.has("mount_attributes"):
		if base_attributes.has("mount_attributes"):
			modified_attributes["mount_attributes"] = str2var(var2str(base_attributes.mount_attributes))
		else:
			var mounts = get_attrib("mounts")
			var mount_variations = {}
			for key in mounts:
				for item in mounts[key]:
					if not mount_variations.has(key):
						mount_variations[key] = []
					mount_variations[key].push_back({})
					
			set_attrib("mount_attributes", mount_variations)
		
	if modified_attributes.has("mounts") or not base_attributes.has("mounts"):
		return
		
	modified_attributes["mounts"] = str2var(var2str(base_attributes.mounts))

func _ready():
	if PreloadData == null or PreloadData.empty():
		return
		
	if not PreloadJSON.empty():
		modified_attributes = JSON.parse(PreloadJSON).result
	Globals.LevelLoaderRef.RequestObject(PreloadData, Globals.LevelLoaderRef.World_to_Tile(self.global_position), modified_attributes)
	self.visible = false
	

func _sort_by_hp_regen(a, b):
	var rate_a = a.shield.shielding.hp_regen_per_ap * Globals.EffectRef.GetMultiplierValue(self, a.shield.src, a.attribute, "hp_regen_per_ap_multiplier")
	var rate_b = b.shield.shielding.hp_regen_per_ap * Globals.EffectRef.GetMultiplierValue(self, b.shield.src, b.attribute, "hp_regen_per_ap_multiplier")
	# reversed sort
	if rate_a > rate_b:
		return true
	return false

func _sort_by_shield_size(a, b):
	var rate_a = a.shield.shielding.max_hp * Globals.EffectRef.GetMultiplierValue(self, a.shield.src, a.attribute, "shield_multiplier")
	var rate_b = b.shield.shielding.max_hp * Globals.EffectRef.GetMultiplierValue(self, b.shield.src, b.attribute, "shield_multiplier")
	# reversed sort
	if rate_a > rate_b:
		return true
	return false
	
# Can't find a better place to put this. I'm now using it in 3 different places so I have to put it somewhere
# Systems shouldn't return values and communicate through events so how do I do this ?
func get_max_shield():
	var shields = get_attrib("mounts.shield")
	var attributes = get_attrib("mount_attributes.shield")
	var shields_data = Globals.LevelLoaderRef.LoadJSONArray(shields)
	
	if shields_data.size() <= 0:
		return 0
	
	var packaged_shield = []
	for i in range(shields_data.size()):
		var data = shields_data[i]
		var attribute = attributes[i]
		packaged_shield.push_back({"shield":data, "attribute":attribute})
		
	packaged_shield.sort_custom(self, "_sort_by_shield_size")
	var max_shield = 0
	var count = 0
	for data in packaged_shield:
		# 1, 0.5, 0.25, 0.125, etc.
		max_shield += (data.shield.shielding.max_hp) / pow(2, count) * Globals.EffectRef.GetMultiplierValue(self, data.shield.src, data.attribute, "shield_multiplier")
		count += 1
		
	return max_shield
	
