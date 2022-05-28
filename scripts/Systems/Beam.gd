extends Node

var beam_objects := []

func _ready() -> void:
	Events.connect("OnObjectCreated", self, "OnObjectCreated_Callback")
	
func OnObjectCreated_Callback(data : Dictionary) -> void:
	if Globals.get_attrib(data, "beam", null) != null:
		beam_objects.push_back(Globals.LevelLoaderRef.get_visual_from_data(data["id"]))

func _physics_process(delta: float) -> void:
	for obj in beam_objects:
		if obj.visible == false:
			continue
		
		var originator_id = obj.get_attrib("beam.origin", null)
		if originator_id == null:
			continue
			
		var originator : Spatial = Globals.LevelLoaderRef.get_visual_from_data(originator_id)
		var max_dist : float = obj.get_attrib("beam.max_range")
		
		var space_state : PhysicsDirectSpaceState = originator.get_world().direct_space_state
		var start_point : Vector3 = originator.global_transform.origin
		if originator.has_node("FrontAnchor"):
			start_point = originator.get_node("FrontAnchor").global_transform.origin
		var end_point : Vector3 = start_point - (originator.global_transform.basis.z.normalized() * max_dist)
		var result : Dictionary = space_state.intersect_ray(start_point, end_point, [], Globals.COLLISION_LAYERS.WORLD, true, true)
		var end_fx = obj.get_node("End")
		var connections := []
		if not result.empty():
			end_point = result.position
			end_fx.global_transform.origin = end_point
			var collided : Attributes = result["collider"]
			var placing_on_id = collided.get_attrib("id")
			connections = [placing_on_id]
		obj.set_attrib("connections", connections)
		end_fx.visible = not result.empty()
		var mid_point : Vector3 = ((end_point - start_point) / 2.0) + start_point
		obj.global_transform.origin = mid_point
		obj.global_transform.basis = originator.global_transform.basis
		obj.get_node("Beam").scale.y = (end_point - start_point).length()
		obj.get_node("Start").global_transform.origin = start_point
