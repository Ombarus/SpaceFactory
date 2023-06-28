extends Node

var harvester_objects := {}

func _ready() -> void:
	Events.connect("OnObjectCreated",Callable(self,"OnObjectCreated_Callback"))
	Events.connect("OnObjectDestroyed",Callable(self,"OnObjectDestroyed_Callback"))
	
func OnObjectDestroyed_Callback(data : Dictionary) -> void:
	#TODO: drop or pickup inventory if any?
	harvester_objects.erase(data["id"])
	
func OnObjectCreated_Callback(data : Dictionary) -> void:
	if Globals.get_attrib(data, "harvester", null) != null:
		harvester_objects[data["id"]] = data
		
func Stop(data):
	#TODO: when out of energy, don't reset harvest time so when we resume we continue from where we left off
	Globals.set_attrib(data, "harvester.harvest_time", 0)
	var stopped_anim : String = Globals.get_attrib(data, "animation.idle", "")
	if not stopped_anim.is_empty():
		var visual : Attributes = Globals.LevelLoaderRef.get_visual_from_data(data["id"])
		var anim_player : AnimationPlayer = visual.find_child("AnimationPlayer", true, false)
		anim_player.play(stopped_anim)
		
func _process(delta: float) -> void:
	for id in harvester_objects:
		var data = harvester_objects[id]
		var is_offline : bool = Globals.get_attrib(data, "harvester.offline", false)
		# is_offline is used while playing other animations so don't use Stop() that sets the stopped anim
		if is_offline:
			Globals.set_attrib(data, "harvester.harvest_time", 0)
			continue
			
		var connections = Globals.get_attrib(data, "connections", [])
		if connections.is_empty():
			Stop(data)
			continue
			
		var inventory := InventoryUtil.new(data)
		var energy : float = inventory.total(Globals.item_energy)
		var energy_per_second : float = Globals.get_attrib(data, "harvester.energy_per_second", 0)
		if energy <= 0 and energy_per_second > 0:
			Stop(data)
			continue
		
		var seconds_per_item : float = 1.0 / Globals.get_attrib(data, "harvester.item_per_second")
		
		var working_anim : String = Globals.get_attrib(data, "animation.working", "")
		if not working_anim.is_empty():
			var visual : Attributes = Globals.LevelLoaderRef.get_visual_from_data(data["id"])
			var anim_player : AnimationPlayer = visual.find_child("AnimationPlayer", true, false)
			anim_player.play(working_anim)
		
		#NOTE: This will bork if there is more than one connection that's harvestable
		for connected_id in connections:
			var connected_obj : Dictionary = Globals.LevelLoaderRef.get_object_data(connected_id)
			var harvestable_data = Globals.get_attrib(connected_obj, "harvestable", [])
			if harvestable_data.is_empty():
				continue
			var harvest_time : float = Globals.get_attrib(data, "harvester.harvest_time", 0)
			harvest_time += delta
			while harvest_time > seconds_per_item:
				harvest_time -= seconds_per_item
				var energy_used = seconds_per_item * energy_per_second
				var result : String = MersenneTwister.rand_weight(harvestable_data, "item", "weight")
				inventory.add(result, 1)
				inventory.substract(Globals.item_energy, energy_used)
			Globals.set_attrib(data, "harvester.harvest_time", harvest_time)
			break
