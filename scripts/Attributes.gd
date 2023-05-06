extends Node3D
class_name Attributes

@export_file("*.json") var PreloadData = "" # (String, FILE, "*.json")
#TODO: hack to be able to modify modified_attributes in the editor. Apparently we can edit dictionnary in 3.1 so
# this shouldn't be needed in 3.1
@export_multiline var PreloadJSON = "" # (String, MULTILINE)

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
	if PreloadData == null or PreloadData.is_empty():
		return
	
	self.call_deferred("_deferred_init")
	

func _deferred_init():
	var modified_attributes : Dictionary = {}
	if not PreloadJSON.is_empty():
		var test_json_conv = JSON.new()
		if test_json_conv.parse(PreloadJSON) != OK:
			printerr("Error loading inline JSON for object %s" % self.name)
		modified_attributes = test_json_conv.data
	modified_attributes["visual"] = {
		"node_id":self.get_path(),
		"transform":self.global_transform
	}
	self.attribute_ref = Globals.LevelLoaderRef.create_object_data(PreloadData, modified_attributes)


func _on_UIInteraction_body_entered(body: Node) -> void:
	Events.emit_signal("OnRegionEntered", get_data())


func _on_UIInteraction_body_exited(body: Node) -> void:
	Events.emit_signal("OnRegionLeft", get_data())
