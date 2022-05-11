extends Node
class_name Attributes

export(String, FILE, "*.json") var PreloadData = ""
#TODO: hack to be able to modify modified_attributes in the editor. Apparently we can edit dictionnary in 3.1 so
# this shouldn't be needed in 3.1
export(String, MULTILINE) var PreloadJSON = ""

var attribute_ref = -1

# helper function to get modified_attributes
func get_attrib(path : String, default=null):
	return Globals.get_attrib(Globals.LevelLoaderRef.get_object_data(attribute_ref), path, default)
	
func set_attrib(modified_attributes : Dictionary, path : String, val) -> void:
	Globals.set_attrib(Globals.LevelLoaderRef.get_object_data(attribute_ref), path, val)

func _ready():
	if PreloadData == null or PreloadData.empty():
		return
	
	var modified_attributes : Dictionary = {}
	if not PreloadJSON.empty():
		modified_attributes = JSON.parse(PreloadJSON).result
	Globals.LevelLoaderRef.create_object_data(PreloadData, modified_attributes)
	self.visible = false
