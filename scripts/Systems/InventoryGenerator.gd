extends Node

var data_to_watch := {}

func _ready() -> void:
	Events.connect("OnObjectCreated",Callable(self,"OnObjectCreated_Callback"))
	Events.connect("OnObjectDestroyed",Callable(self,"OnObjectDestroyed_Callback"))
	# If we ever need to "create" an inventory slot that generate stuff on the fly
	# I would add an OnGeneratePerSecondChanged event to avoid hooking to the spammy
	# "OnInventoryChanged" event


func OnObjectDestroyed_Callback(data : Dictionary) -> void:
	#TODO: drop or pickup inventory if any?
	data_to_watch.erase(data["id"])


func OnObjectCreated_Callback(data : Dictionary) -> void:
	var keys : Array = Globals.get_keys(data, "inventory_slots")
	for key in keys:
		var generate_rate : float = Globals.get_attrib(data, "inventory_slots.%s.generate_per_second" % str(key), 0.0)
		if generate_rate > 0:
			data_to_watch[data["id"]] = data
			var next_in : float = Globals.get_attrib(data, "inventory_slots.%s.next_in_second" % str(key), 1.0 / generate_rate)
			Globals.set_attrib(data, "inventory_slots.%s.next_in_second" % str(key), next_in)
			
			
func _process(delta: float) -> void:
	for id in data_to_watch:
		var data = data_to_watch[id]
		var inventory_util = InventoryUtil.new(data)
		var inventory_keys : Array = Globals.get_keys(data, "inventory_slots")
		for key in inventory_keys:
			var generate_rate : float = Globals.get_attrib(data, "inventory_slots.%s.generate_per_second" % str(key), 0.0)
			var item_name : String = Globals.get_attrib(data, "inventory_slots.%s.content" % str(key))
			if generate_rate > 0:
				data_to_watch[data["id"]] = data
				var next_in : float = Globals.get_attrib(data, "inventory_slots.%s.next_in_second" % str(key), 1.0 / generate_rate)
				next_in -= delta
				var total_to_add := 0
				while next_in <= 0.0:
					next_in += 1.0 / generate_rate
					total_to_add += 1
				if total_to_add > 0:
					inventory_util.add(item_name, total_to_add)
					
				Globals.set_attrib(data, "inventory_slots.%s.next_in_second" % str(key), next_in)
