extends "res://scripts/UI/DialogBase.gd"

onready var inventory_list : ItemList = get_node("VBoxContainer/HBoxContainer/ThisShouldBeStandardDialogScene/HBoxContainer/Inventory/InventoryList")
onready var crafting_list : ItemList = get_node("VBoxContainer/HBoxContainer/ThisShouldBeStandardDialogScene/HBoxContainer/Crafting/CraftingList")

#TODO: Already seeing how this will get annoying everytime I tweak a name or add a new item type
const name_to_json_path = {
	"Glass":"data/json/items/glass.json",
	"Iron Ingot":"data/json/items/iron_ingot.json",
	"Silicon Wafer":"data/json/items/silicon_wafer.json",
}

func Init(init_param):
	pass

func _on_Button_pressed() -> void:
	Events.emit_signal("OnPopGUI")

func _on_CraftingList_item_selected(index: int) -> void:
	var json_path : String = name_to_json_path[crafting_list.get_item_text(index)]
	print("CRAFT SOME " + json_path)
