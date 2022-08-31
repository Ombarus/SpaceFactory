class_name InventoryUtil

var _attributes : Dictionary

func _init(attrib_ref : Dictionary) -> void:
	_attributes = attrib_ref
	
func total(item_path : String) -> int:
	var total := 0
	var keys : Array = Globals.get_keys(_attributes, "inventory_slots")
	for key in keys:
		var count : int = Globals.get_attrib(_attributes, "inventory_slots.%s.count" % str(key))
		var name : String = Globals.get_attrib(_attributes, "inventory_slots.%s.content" % str(key))
		if name == item_path:
			total += count
	return total

# return remainder if we don't have enough in the inventory
func substract(item_path : String, number : int) -> int:
	var left_to_substract = number
	var keys : Array = Globals.get_keys(_attributes, "inventory_slots")
	for key in keys:
		var count : int = Globals.get_attrib(_attributes, "inventory_slots.%s.count" % str(key))
		var name : String = Globals.get_attrib(_attributes, "inventory_slots.%s.content" % str(key))
		if name == item_path:
			var substracted = min(left_to_substract, count)
			Globals.set_attrib(_attributes, "inventory_slots.%s.count" % str(key), count - substracted)
			if substracted == count:
				Globals.set_attrib(_attributes, "inventory_slots.%s.content" % str(key), "")
			
			left_to_substract -= substracted
			if left_to_substract == 0:
				break
	Events.emit_signal("OnInventoryChanged", _attributes)
	return left_to_substract

# return remainder if we don't have space in the inventory
func add(item_path: String, number : int) -> int:
	var left_to_add = number
	var keys : Array = Globals.get_keys(_attributes, "inventory_slots")
	var item_data = Globals.LevelLoaderRef.load_json(item_path)
	var max_stack : int = Globals.get_attrib(item_data, "inventory.max_stack")
	var empty_keys = []
	for key in keys:
		var count : int = Globals.get_attrib(_attributes, "inventory_slots.%s.count" % str(key))
		var name : String = Globals.get_attrib(_attributes, "inventory_slots.%s.content" % str(key))
		if name == item_path and count < max_stack:
			var to_add : int = min(max_stack - count, left_to_add)
			Globals.set_attrib(_attributes, "inventory_slots.%s.count" % str(key), count + to_add)
			left_to_add -= to_add
			if left_to_add == 0:
				break
		if name.empty():
			empty_keys.push_back(key)
	if left_to_add > 0:
		for key in empty_keys:
			var to_add : int = min(max_stack, left_to_add)
			Globals.set_attrib(_attributes, "inventory_slots.%s.count" % str(key), to_add)
			Globals.set_attrib(_attributes, "inventory_slots.%s.content" % str(key), item_path)
			left_to_add -= to_add
			if left_to_add == 0:
				break
	Events.emit_signal("OnInventoryChanged", _attributes)
	return left_to_add
