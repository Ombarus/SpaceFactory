extends "res://scripts/UI/DialogBase.gd"

var attributes = null
@onready var inventory_list : ItemList = get_node("VBoxContainer/HBoxContainer/ThisShouldBeStandardDialogScene/HBoxContainer/Inventory/InventoryList")
@onready var crafting_list : ItemList = get_node("VBoxContainer/HBoxContainer/ThisShouldBeStandardDialogScene/HBoxContainer/Crafting/CraftingList")

func _ready() -> void:
	super._ready()
	self.set_process(false)

func Init(init_param):
	attributes = init_param["player_data"]
	update_inventory()
	update_crafting_list()
	self.set_process(true)
	
func _process(delta: float) -> void:
	if Globals.get_attrib(attributes, "inventory_dirty", false) == true:
		update_inventory()
	
func update_inventory():
	inventory_list.clear()
	var keys : Array = Globals.get_keys(attributes, "inventory_slots")
	for key in keys:
		var item_path : String = Globals.get_attrib(attributes, "inventory_slots.%s.content" % str(key))
		if item_path.is_empty():
			continue
		var count : int = Globals.get_attrib(attributes, "inventory_slots.%s.count" % str(key))
		var inventory_data = Globals.LevelLoaderRef.load_json(item_path)
		inventory_list.add_item(Globals.get_attrib(inventory_data, "name") + " : " + str(count))
	
func update_crafting_list():
	crafting_list.clear()
	var recipes : Array = Globals.get_attrib(attributes, "recipes", {})
	var count := -1
	for recipe_data in recipes:
		count += 1
		if recipe_data.get("hidden", false) == true:
			continue
		var output_array : Array = recipe_data.get("output", [])
		var recipe_name := ""
		for output_info in output_array:
			var item_data = Globals.LevelLoaderRef.load_json(output_info.get("name"))
			recipe_name += str(output_info.get("count", 0)) + "x " + item_data.get("name") + " | "
		crafting_list.add_item(recipe_name)
		crafting_list.set_item_metadata(crafting_list.get_item_count()-1, count)
		
func _on_Button_pressed() -> void:
	self.set_process(false)
	Events.emit_signal("OnPopGUI")

func _on_CraftingList_item_selected(index: int) -> void:
	var recipe_index : int = crafting_list.get_item_metadata(index)
	var recipe_data = Globals.get_attrib(attributes, "recipes")[recipe_index]
	Events.emit_signal("OnQueueCrafting", attributes, recipe_data)
