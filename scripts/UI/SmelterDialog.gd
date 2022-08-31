extends "res://scripts/UI/DialogBase.gd"

var player_data := {}
var building_data := {}

onready var input_inventory = get_node("VBoxContainer/HBoxContainer/VBoxContainer3/InputInventory")
onready var output_inventory = get_node("VBoxContainer/HBoxContainer/VBoxContainer/OutputInventory")
onready var recipe_list = get_node("VBoxContainer/HBoxContainer/VBoxContainer2/RecipeList")
onready var player_inventory = get_node("VBoxContainer/VBoxContainer4/PlayerInventory")

func Init(init_param):
	player_data = init_param["player_data"]
	building_data = init_param["building_data"]
	redraw()
	self.set_process(true)
	

func _process(delta: float) -> void:
	if Globals.get_attrib(player_data, "inventory_dirty", false) == true or \
		Globals.get_attrib(building_data, "inventory_dirty", false) == true:
		redraw()
		

func redraw():
	update_inventory_list()
	update_building_inventories()
	update_crafting_list()

func update_inventory_list():
	player_inventory.clear()
	var keys : Array = Globals.get_keys(player_data, "inventory_slots")
	for key in keys:
		var item_path : String = Globals.get_attrib(player_data, "inventory_slots.%s.content" % str(key))
		if item_path.empty():
			continue
		var count : int = Globals.get_attrib(player_data, "inventory_slots.%s.count" % str(key))
		var inventory_data = Globals.LevelLoaderRef.load_json(item_path)
		player_inventory.add_item(Globals.get_attrib(inventory_data, "name") + " : " + str(count))
		#TODO: make sure to update when inventory change is fired (there's a "inventory_dirty" flag but it gets reset by player system so it might be tricky to time right?)
		player_inventory.set_item_metadata(player_inventory.get_item_count()-1, key)
		
func update_building_inventories():
	input_inventory.clear()
	output_inventory.clear()
	var keys : Array = Globals.get_keys(building_data, "inventory_slots")
	for key in keys:
		var item_path : String = Globals.get_attrib(building_data, "inventory_slots.%s.content" % str(key))
		if item_path.empty():
			continue
		var count : int = Globals.get_attrib(building_data, "inventory_slots.%s.count" % str(key))
		var inventory_data = Globals.LevelLoaderRef.load_json(item_path)
		if "input" in key:
			input_inventory.add_item(Globals.get_attrib(inventory_data, "name") + " : " + str(count))
		else:
			output_inventory.add_item(Globals.get_attrib(inventory_data, "name") + " : " + str(count))
			
func update_crafting_list():
	recipe_list.clear()
	var recipes : Array = Globals.get_attrib(building_data, "recipes", [])
	var count := -1
	var selected_recipe_index = Globals.get_attrib(building_data, "selected_recipe_index", -1)
	for recipe_data in recipes:
		count += 1
		if recipe_data.get("hidden", false) == true:
			continue
		var output_array : Array = recipe_data.get("output", [])
		var recipe_name := ""
		for output_info in output_array:
			var item_data = Globals.LevelLoaderRef.load_json(output_info.get("name"))
			recipe_name += str(output_info.get("count", 0)) + "x " + item_data.get("name") + " | "
		recipe_list.add_item(recipe_name)
		recipe_list.set_item_metadata(recipe_list.get_item_count()-1, count)
		if selected_recipe_index == count:
			recipe_list.select(recipe_list.get_item_count()-1)
		
	
func _on_Button_pressed() -> void:
	self.set_process(false)
	Events.emit_signal("OnPopGUI")


func _on_RecipeList_item_selected(index):
	Globals.set_attrib(building_data, "selected_recipe_index", recipe_list.get_item_metadata(index))


func _on_PlayerInventory_item_selected(index):
	var player_inv := InventoryUtil.new(player_data)
	var item_path : String = Globals.get_attrib(building_data, "inventory_slots.input.content")
	if not item_path.empty():
		var item_count : int = Globals.get_attrib(building_data, "inventory_slots.input.count")
		var remainder : int = player_inv.add(item_path, item_count)
		if remainder > 0:
			Globals.set_attrib(building_data, "inventory_slots.input.count", remainder)
			return
	var slot_name : String = player_inventory.get_item_metadata(index)
	item_path = Globals.get_attrib(player_data, "inventory_slots.%s.content" % slot_name)
	var item_count = Globals.get_attrib(player_data, "inventory_slots.%s.count" % slot_name)
	Globals.set_attrib(building_data, "inventory_slots.input.content", item_path)
	Globals.set_attrib(building_data, "inventory_slots.input.count", item_count)
	player_inv.substract(item_path, item_count)
	redraw()

#TODO: handle multiple input/outpu slots
func _on_OutputInventory_item_selected(index):
	var player_inv := InventoryUtil.new(player_data)
	var content_path : String = Globals.get_attrib(building_data, "inventory_slots.output.content", "")
	var content_count : int = Globals.get_attrib(building_data, "inventory_slots.output.count", 0)
	player_inv.add(content_path, content_count)
	Globals.set_attrib(building_data, "inventory_slots.output.content", "")
	Globals.set_attrib(building_data, "inventory_slots.output.count", 0)
	redraw()


func _on_InputInventory_item_selected(index):
	var player_inv := InventoryUtil.new(player_data)
	var content_path : String = Globals.get_attrib(building_data, "inventory_slots.input.content", "")
	var content_count : int = Globals.get_attrib(building_data, "inventory_slots.input.count", 0)
	player_inv.add(content_path, content_count)
	Globals.set_attrib(building_data, "inventory_slots.input.content", "")
	Globals.set_attrib(building_data, "inventory_slots.input.count", 0)
	redraw()
