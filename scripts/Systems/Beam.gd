extends Node

var beam_objects := []

func _ready() -> void:
	Events.connect("OnObjectCreated",Callable(self,"OnObjectCreated_Callback"))
	
func OnObjectCreated_Callback(data : Dictionary) -> void:
	if Globals.get_attrib(data, "beam", null) != null:
		beam_objects.push_back(Globals.LevelLoaderRef.get_visual_from_data(data["id"]))

func _physics_process(delta: float) -> void:
	for obj in beam_objects:
		if obj.visible == false:
			obj.set_attrib("connections", [])
			continue
			
		var cooldown : float = obj.get_attrib("beam.cooldown", 0.0)
		cooldown = min(0.0, cooldown - delta)
		if cooldown > 0.0:
			obj.set_attrib("beam.cooldown", cooldown)
			obj.visible = false
			continue
		
		var originator_id = obj.get_attrib("beam.origin", null)
		if originator_id == null:
			continue
			
		var originator : Attributes = Globals.LevelLoaderRef.get_visual_from_data(originator_id)
		var last_frame_lost : float = obj.get_attrib("beam.fractional_energy_used", 0.0)
		var energy_lost : float = obj.get_attrib("beam.energy_per_sec", 0.0) * delta + last_frame_lost
		var inventory := InventoryUtil.new(originator.get_data())
		while energy_lost > 1.0:
			energy_lost -= 1
			var left_over : int = inventory.substract("data/json/items/energy.json", 1)
			if left_over > 0:
				# TODO: "disable" the connection so we remember 
				# how much we had harvested so we don't reset when we run out of energy?
				obj.set_attrib("connections", [])
				obj.visible = false
				obj.set_attrib("beam.cooldown", obj.get_attrib("fail_cooldown_sec", 0.0))
				continue
			
		var max_dist : float = obj.get_attrib("beam.max_range")
		
		obj.set_attrib("beam.fractional_energy_used", energy_lost)
		
		var space_state : PhysicsDirectSpaceState3D = originator.get_world_3d().direct_space_state
		var start_point : Vector3 = originator.global_transform.origin
		if originator.has_node("FrontAnchor"):
			start_point = originator.get_node("FrontAnchor").global_transform.origin
		var end_point : Vector3 = start_point - (originator.global_transform.basis.z.normalized() * max_dist)
		var query = PhysicsRayQueryParameters3D.create(start_point, end_point, Globals.COLLISION_LAYERS.WORLD)
		query.collide_with_areas = true
		var result : Dictionary = space_state.intersect_ray(query)
		var end_fx = obj.get_node("End")
		var connections := []
		if not result.is_empty():
			end_point = result.position
			end_fx.global_transform.origin = end_point
			var collided : Attributes = result["collider"]
			var placing_on_id = collided.get_attrib("id")
			connections = [placing_on_id]
		obj.set_attrib("connections", connections)
		end_fx.visible = not result.is_empty()
		var mid_point : Vector3 = ((end_point - start_point) / 2.0) + start_point
		obj.global_transform.origin = mid_point
		obj.global_transform.basis = originator.global_transform.basis
		obj.get_node("Beam").scale.y = (end_point - start_point).length()
		obj.get_node("Start").global_transform.origin = start_point
