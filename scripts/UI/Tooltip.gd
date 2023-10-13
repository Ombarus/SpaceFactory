extends Control
class_name Tooltip

@export var InputExample : NodePath
@export var OutputExample : NodePath
var ItemData : Dictionary
var description_node : RichTextLabel
var _input_example : Control
var _output_example : Control

func _ready():
	description_node = get_node("ColorRect/VBoxContainer/HBoxContainer/VBoxContainer/Description")
	_input_example = get_node(InputExample)
	_output_example = get_node(OutputExample)

# can be an already loaded dict or a string pointing to a json resource
func Init(item):
	Clear()
	if item is String:
		item = Globals.LevelLoaderRef.load_json(item)
		
	ItemData = item
	description_node.text = Globals.get_attrib(ItemData, "tooltip.description", "")
	var root_name : String = ItemData["src"].get_file()
	if FileAccess.file_exists("res://data/json/refs/recipes/" + root_name):
		var recipe_data = Globals.LevelLoaderRef.load_json("res://data/json/refs/recipes/" + root_name)
		var input_list = Globals.get_attrib(recipe_data, "input")
		var output_list = Globals.get_attrib(recipe_data, "output")
		var processing_time = Globals.get_attrib(recipe_data, "processing_time_sec")
		var energy_use = Globals.get_attrib(recipe_data, "energy_use")
		for input_data in input_list:
			var n = _input_example.duplicate()
			_input_example.get_parent().add_child(n)
			n.visible = true
			n.get_node("Name").text = input_data["name"]
			n.get_node("Count").text = str(input_data["count"])
			n.add_to_group("tooltip_input")
		for output_data in output_list:
			var n = _output_example.duplicate()
			_output_example.get_parent().add_child(n)
			n.visible = true
			n.get_node("Name").text = output_data["name"]
			n.get_node("Count").text = str(output_data["count"])
			n.add_to_group("tooltip_input")
	var placeable_cost : Array = Globals.get_attrib(ItemData, "placeable.cost", [])
	if not placeable_cost.is_empty():
		for input_data in placeable_cost:
			var n = _input_example.duplicate()
			_input_example.get_parent().add_child(n)
			n.visible = true
			n.get_node("Name").text = input_data["name"]
			n.get_node("Count").text = str(input_data["count"])
			n.add_to_group("tooltip_input")
		
func Clear():
	for n in get_tree().get_nodes_in_group("tooltip_input"):
		n.queue_free()
	for n in get_tree().get_nodes_in_group("tooltip_output"):
		n.queue_free()
