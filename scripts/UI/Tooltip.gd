extends Control
class_name Tooltip

var ItemData : Dictionary
var description_node : RichTextLabel

func _ready():
	description_node = get_node("ColorRect/VBoxContainer/HBoxContainer/Description")

# can be an already loaded dict or a string pointing to a json resource
func Init(item):
	if item is String:
		item = Globals.LevelLoaderRef.load_json(item)
		
	ItemData = item
	description_node.text = Globals.get_attrib(ItemData, "tooltip.description", "")
