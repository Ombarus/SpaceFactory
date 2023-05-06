extends "res://scripts/UI/DialogBase.gd"

var player_data = null
var building_data = null
@onready var character_list : ItemList = get_node("VBoxContainer/HBoxContainer/ThisShouldBeStandardDialogScene/HBoxContainer/Character/InventoryList")
@onready var harvester_list : ItemList = get_node("VBoxContainer/HBoxContainer/ThisShouldBeStandardDialogScene/HBoxContainer/Harvester/InventoryList")

func _ready() -> void:
	super._ready()
	self.set_process(false)

func Init(init_param):
	player_data = init_param["player_data"]
	building_data = init_param["building_data"]
	update_character_list()
	update_harvester_list()
	self.set_process(true)
	
func _process(delta: float) -> void:
	if Globals.get_attrib(player_data, "inventory_dirty", false) == true:
		update_character_list()
	if Globals.get_attrib(building_data, "inventory_dirty", false) == true:
		update_harvester_list()
	
func update_character_list():
	character_list.clear()
	var keys : Array = Globals.get_keys(player_data, "inventory_slots")
	for key in keys:
		var item_path : String = Globals.get_attrib(player_data, "inventory_slots.%s.content" % str(key))
		if item_path.is_empty():
			continue
		var count : int = Globals.get_attrib(player_data, "inventory_slots.%s.count" % str(key))
		var inventory_data = Globals.LevelLoaderRef.load_json(item_path)
		character_list.add_item(Globals.get_attrib(inventory_data, "name") + " : " + str(count))
		character_list.set_item_metadata(character_list.get_item_count()-1, key)
	
func update_harvester_list():
	harvester_list.clear()
	var keys : Array = Globals.get_keys(building_data, "inventory_slots")
	for key in keys:
		var item_path : String = Globals.get_attrib(building_data, "inventory_slots.%s.content" % str(key))
		if item_path.is_empty():
			continue
		var count : int = Globals.get_attrib(building_data, "inventory_slots.%s.count" % str(key))
		var inventory_data = Globals.LevelLoaderRef.load_json(item_path)
		harvester_list.add_item(Globals.get_attrib(inventory_data, "name") + " : " + str(count))
		harvester_list.set_item_metadata(harvester_list.get_item_count()-1, key)
		
func _on_Button_pressed() -> void:
	self.set_process(false)
	Events.emit_signal("OnPopGUI")

func _on_CraftingList_item_selected(index: int) -> void:
	var player_inv := InventoryUtil.new(player_data)
	var building_inv := InventoryUtil.new(building_data)
	var slot_name : String = harvester_list.get_item_metadata(index)
	var item_path : String = Globals.get_attrib(building_data, "inventory_slots.%s.content" % slot_name)
	var item_count : int = Globals.get_attrib(building_data, "inventory_slots.%s.count" % slot_name)
	player_inv.add(item_path, item_count)
	building_inv.substract(item_path, item_count)
	update_character_list()
	update_harvester_list()
