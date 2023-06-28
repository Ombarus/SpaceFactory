extends Node

var distributor_objects := {}

func _ready() -> void:
	Events.connect("OnObjectCreated",Callable(self,"OnObjectCreated_Callback"))
	Events.connect("OnObjectDestroyed",Callable(self,"OnObjectDestroyed_Callback"))
	
func OnObjectDestroyed_Callback(data : Dictionary) -> void:
	distributor_objects.erase(data["id"])
	
func OnObjectCreated_Callback(data : Dictionary) -> void:
	if Globals.get_attrib(data, "distributor", null) != null:
		distributor_objects[data["id"]] = data

func _process(delta: float) -> void:
	for id in distributor_objects:
		var data = distributor_objects[id]
			
		var connections = Globals.get_attrib(data, "connections", [])
		if connections.is_empty():
			continue
		
		var item_to_share : String = Globals.get_attrib(data, "distributor.item_to_share")
		var min_share_per : float = Globals.get_attrib(data, "distributor.min_share_percent")
		var inventory := InventoryUtil.new(data)
		var in_stock : float = inventory.total(item_to_share)
		var item_data : Dictionary = Globals.LevelLoaderRef.load_json(item_to_share)
		var min_share : float = Globals.get_attrib(item_data, "inventory.max_stack") * min_share_per
		if in_stock > min_share:
			var to_share : float = min_share
			for connected_id in connections:
				var connected_data : Dictionary = Globals.LevelLoaderRef.get_object_data(connected_id)
				var connected_inv := InventoryUtil.new(connected_data)
				to_share = connected_inv.add(item_to_share, to_share)
				if to_share <= 0.0:
					break
			inventory.substract(item_to_share, min_share - to_share)
