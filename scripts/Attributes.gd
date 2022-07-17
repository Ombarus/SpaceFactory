extends Spatial
class_name Attributes

export(String, FILE, "*.json") var PreloadData = ""
#TODO: hack to be able to modify modified_attributes in the editor. Apparently we can edit dictionnary in 3.1 so
# this shouldn't be needed in 3.1
export(String, MULTILINE) var PreloadJSON = ""

var attribute_ref := -1

func is_valid() -> bool:
	return attribute_ref >= 0

# helper function to get modified_attributes
func get_attrib(path : String, default=null):
	return Globals.get_attrib(Globals.LevelLoaderRef.get_object_data(self.attribute_ref), path, default)

func set_attrib(path : String, val) -> void:
	Globals.set_attrib(Globals.LevelLoaderRef.get_object_data(self.attribute_ref), path, val)
	
func get_data() -> Dictionary:
	return Globals.LevelLoaderRef.get_object_data(self.attribute_ref)

func _ready():
	if PreloadData == null or PreloadData.empty():
		return
	
	self.call_deferred("_deferred_init")
	

func _deferred_init():
	var modified_attributes : Dictionary = {}
	if not PreloadJSON.empty():
		modified_attributes = JSON.parse(PreloadJSON).result
	modified_attributes["visual"] = {
		"node_id":self.get_path(),
		"transform":self.global_transform
	}
	self.attribute_ref = Globals.LevelLoaderRef.create_object_data(PreloadData, modified_attributes)


func _on_UIInteraction_body_entered(body: Node) -> void:
	Events.emit_signal("OnRegionEntered", get_data())


func _on_UIInteraction_body_exited(body: Node) -> void:
	Events.emit_signal("OnRegionLeft", get_data())
