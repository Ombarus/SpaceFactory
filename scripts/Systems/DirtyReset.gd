extends Node

var dirty_objs := {}

func _ready() -> void:
	Events.connect("OnInventoryChanged", self, "OnInventoryChanged_Callback")
	Events.connect("OnObjectCreated", self, "OnObjectCreated_Callback")


func OnObjectCreated_Callback(data : Dictionary) -> void:
	var dirty : bool = Globals.get_attrib(data, "inventory_dirty", false)
	if dirty:
		dirty_objs[data["id"]] = data
	

func OnInventoryChanged_Callback(data : Dictionary) -> void:
	Globals.set_attrib(data, "inventory_dirty", true)
	dirty_objs[data["id"]] = data

func _process(delta: float) -> void:
	# this will make sure it's always after everything else
	call_deferred("clear_dirty")

func clear_dirty():
	for key in dirty_objs:
		var obj : Dictionary = dirty_objs[key]
		Globals.set_attrib(obj, "inventory_dirty", false)
	dirty_objs.clear()
