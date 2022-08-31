extends Node

var producer_data := {}

func _ready() -> void:
	Events.connect("OnObjectCreated", self, "OnObjectCreated_Callback")
	Events.connect("OnObjectDestroyed", self, "OnObjectDestroyed_Callback")
	
func OnObjectDestroyed_Callback(data : Dictionary) -> void:
	#TODO: drop or pickup inventory if any?
	producer_data.erase(data["id"])
	
func OnObjectCreated_Callback(data : Dictionary) -> void:
	var systems : Array = Globals.get_attrib(data, "system", [])
	if "ProductionBuilding" in systems:
		producer_data[data["id"]] = data

func _process(delta):
	for id in producer_data:
		var recipe_index : int = Globals.get_attrib(producer_data[id], "selected_recipe_index", -1)
		if recipe_index < 0:
			continue
		
		#TODO: Optimize
		#		- Don't set filter every frame
		#		- Handle mismatched items in input/output (when changing recipe)
		#TODO: Use Energy
		var recipe_data : Dictionary = Globals.get_attrib(producer_data[id], "recipes")[recipe_index]
		var input_filter : Array = []
		for input_data in recipe_data.get("input"):
			input_filter.push_back(input_data.get("name"))
		var output_filter : Array = []
		for output_data in recipe_data.get("output"):
			output_filter.push_back(output_data.get("name"))
		
		var keys : Array = Globals.get_keys(producer_data[id], "inventory_slots")
		for key in keys:
			if "input" in key:
				Globals.set_attrib(producer_data[id], "inventory_slots.%s.allowed.%s" % [key, "prod"], input_filter)
			elif "output" in key:
				Globals.set_attrib(producer_data[id], "inventory_slots.%s.allowed.%s" % [key, "prod"], output_filter)
				
		var crafting_queue : Array = Globals.get_attrib(producer_data[id], "crafting_queue", [])
		if crafting_queue.empty():
			Events.emit_signal("OnQueueCrafting", producer_data[id], recipe_data)
		
		
