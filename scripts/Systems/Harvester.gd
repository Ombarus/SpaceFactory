extends Node

var harvester_objects := {}

func _ready() -> void:
	Events.connect("OnObjectCreated", self, "OnObjectCreated_Callback")
	Events.connect("OnObjectDestroyed", self, "OnObjectDestroyed_Callback")
	
func OnObjectDestroyed_Callback(data : Dictionary) -> void:
	#TODO: drop or pickup inventory if any?
	harvester_objects.erase(data["id"])
	
func OnObjectCreated_Callback(data : Dictionary) -> void:
	if Globals.get_attrib(data, "harvester", null) != null:
		harvester_objects[data["id"]] = data
		
func _process(delta: float) -> void:
	for id in harvester_objects:
		var data = harvester_objects[id]
		var connections = Globals.get_attrib(data, "connections", [])
		if connections.empty():
			Globals.set_attrib(data, "harvester.harvest_time", 0)
			continue
		var cur_inv = Globals.get_attrib(data, "inventory", {})
		#NOTE: This will bork if there is more than one connection that's harvestable
		for connected_id in connections:
			var connected_obj : Dictionary = Globals.LevelLoaderRef.get_object_data(connected_id)
			var harvestable_data = Globals.get_attrib(connected_obj, "harvestable", [])
			if harvestable_data.empty():
				continue
			var harvest_time : float = Globals.get_attrib(data, "harvester.harvest_time", 0)
			var seconds_per_item : float = 1.0 / Globals.get_attrib(data, "harvester.item_per_second")
			harvest_time += delta
			while harvest_time > seconds_per_item:
				harvest_time -= seconds_per_item
				var result : String = MersenneTwister.rand_weight(harvestable_data, "item", "weight")
				var output_data : Dictionary = Globals.LevelLoaderRef.load_json(result)
				var max_stack = Globals.get_attrib(output_data, "inventory.max_stack")
				cur_inv[result] = min(cur_inv.get(result,0) + 1, max_stack)
			Globals.set_attrib(data, "harvester.harvest_time", harvest_time)
			break
		Globals.set_attrib(data, "inventory", cur_inv)
