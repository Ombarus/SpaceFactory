extends Node

var harvester_objects := []

func _ready() -> void:
	Events.connect("OnObjectCreated", self, "OnObjectCreated_Callback")
	
func OnObjectCreated_Callback(data : Dictionary) -> void:
	if Globals.get_attrib(data, "harvester", null) != null:
		harvester_objects.push_back(Globals.LevelLoaderRef.get_visual_from_data(data["id"]))
		
func _process(delta: float) -> void:
	for obj in harvester_objects:
		var connections = obj.get_attrib("connections", [])
		if connections.empty():
			obj.set_attrib("harvester.harvest_time", 0)
			continue
		var cur_inv = obj.get_attrib("inventory", {})
		#NOTE: This will bork if there is more than one connection that's harvestable
		for connected_id in connections:
			var connected_obj : Attributes = Globals.LevelLoaderRef.get_visual_from_data(connected_id)
			var harvestable_data = connected_obj.get_attrib("harvestable", [])
			if harvestable_data.empty():
				continue
			var harvest_time : float = obj.get_attrib("harvester.harvest_time", 0)
			var seconds_per_item : float = 1.0 / obj.get_attrib("harvester.item_per_second")
			harvest_time += delta
			while harvest_time > seconds_per_item:
				harvest_time -= seconds_per_item
				var result : String = MersenneTwister.rand_weight(harvestable_data, "item", "weight")
				var data : Dictionary = Globals.LevelLoaderRef.load_json(result)
				var max_stack = Globals.get_attrib(data, "inventory.max_stack")
				cur_inv[result] = min(cur_inv.get(result,0) + 1, max_stack)
			obj.set_attrib("harvester.harvest_time", harvest_time)
			break
		obj.set_attrib("inventory", cur_inv)
