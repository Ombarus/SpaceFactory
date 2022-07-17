extends Node

var queued_attributes := {}

func _ready() -> void:
	Events.connect("OnQueueCrafting", self, "OnQueueCrafting_Callback")
	#TODO: When an object load, check if it has a crafting queue already
	
# TODO: maybe add an optional callback with crafting results?
# QUEUED, FAILED, COMPLETED?
func OnQueueCrafting_Callback(crafter_data, recipe_data):
	# TODO: eventually check if we have enough resource to *make*
	# the missing resources then queue those before
	var inventory := InventoryUtil.new(crafter_data)
	if not HasEnoughResource(inventory, recipe_data):
		return
		
	var crafting_queue : Array = crafter_data.get("crafting_queue", [])
	var input_list : Array = recipe_data.get("input")
	var crafting_queue_data = {
		"recipe": recipe_data,
		"process_time": 0.0
	}
	for input_detail in input_list:
		var input_name : String = input_detail.get("name")
		var input_count : int = input_detail.get("count")
		inventory.substract(input_name, input_count)
	crafting_queue.push_back(crafting_queue_data)
	Globals.set_attrib(crafter_data, "crafting_queue", crafting_queue)
	queued_attributes[crafter_data.get("id")] = crafter_data
	
func HasEnoughResource(inventory, recipe_data):
	#TODO: add an option to check if we have enough *base(?)*
	# resources to craft the missing intermediate requirements
	var input_list : Array = recipe_data.get("input")
	if input_list.empty():
		return true
		
	for input_detail in input_list:
		var input_name : String = input_detail.get("name")
		var input_count : int = input_detail.get("count")
		var inventory_count : int = inventory.total(input_name)
		if input_count > inventory_count:
			return false
		
	return true

func _process(delta: float) -> void:
	var to_remove := []
	for id in queued_attributes:
		var time_to_consume = delta
		var crafter_data : Dictionary = queued_attributes[id]
		var crafting_queue : Array = crafter_data.get("crafting_queue", [])
		var inventory := InventoryUtil.new(crafter_data)
		while time_to_consume > 0:
			if crafting_queue.empty():
				to_remove.push_back(id)
				time_to_consume = 0
				continue
			var crafting_data : Dictionary = crafting_queue[0]
			var current_time : float = crafting_data.get("process_time", 0)
			var processing_time : float = Globals.get_attrib(crafting_data, "recipe.processing_time_sec")
			var time_remaining : float = min(processing_time - current_time, time_to_consume)
			current_time += time_remaining
			time_to_consume -= time_remaining
			if current_time < processing_time:
				Globals.set_attrib(crafting_data, "process_time", current_time)
			else:
				var output_list : Array = Globals.get_attrib(crafting_data, "recipe.output")
				for output_detail in output_list:
					var item_count = output_detail.get("count")
					var item_path = output_detail.get("name")
					print("added " + item_path)
					#TODO: check inventory limits
					inventory.add(item_path, item_count)
				crafting_queue.remove(0)
				
		
		#TODO: Implement energy
