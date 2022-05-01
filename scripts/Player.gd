extends KinematicBody

export(NodePath) onready var inv_line = get_node(inv_line)

onready var place_ray : MeshInstance = $PlaceRay
var last_mouse_pos := Vector2.ZERO
var placing_name := ""
var placing_obj : Spatial = null
var cur_placing_distance := 15.0
var inventory := {}

const placing_instance := {
	"miner":preload("res://scenes/Miner.tscn"),
	"smelter":preload("res://scenes/Smelter.tscn"),
	"floor":preload("res://scenes/Floor.tscn")
}

func _ready() -> void:
	Events.connect("OnPlaceToggle", self, "OnPlaceToggle_Callback")
	Events.connect("OnDoPlacement", self, "OnDoPlacement_Callback")
	Events.connect("OnPickup", self, "OnPickup_Callback")
	Events.connect("OnInsertItems", self, "OnInsertItems_Callback")
	
func OnInsertItems_Callback(accept : String, callback_obj : Node, callback_method : String) -> void:
	for key in inventory:
		if key == accept:
			var consumed = callback_obj.call(callback_method, key, inventory[key])
			inventory[key] -= consumed
	update_inventory_display()
	
func OnPlaceToggle_Callback(name : String) -> void:
	place_ray.visible = !name.empty()
	placing_name = name
	if placing_obj != null:
		placing_obj.visible = false
		placing_obj.queue_free()
		placing_obj = null

func OnDoPlacement_Callback() -> void:
	if placing_obj != null:
		placing_obj.collision_layer = 1
		placing_obj = null
		placing_name = ""
		
func OnPickup_Callback(name, count) -> void:
	var c = inventory.get(name, 0)
	c += count
	inventory[name] = c
	update_inventory_display()
		
func update_inventory_display():
	for n in get_tree().get_nodes_in_group("inventory"):
		n.queue_free()
	for key in inventory:
		var line = inv_line.duplicate()
		inv_line.get_parent().add_child(line)
		line.visible = true
		line.text = key + " : " + str(inventory[key])
		line.add_to_group("inventory")

func _physics_process(delta: float) -> void:
	if Input.is_mouse_button_pressed(1):
		var cur_mouse_pos : Vector2 = get_viewport().get_mouse_position()
		var mouse_offset_x : float = last_mouse_pos.x - cur_mouse_pos.x
		var mouse_offset_y : float = last_mouse_pos.y - cur_mouse_pos.y
		self.rotate(self.global_transform.basis.y, mouse_offset_x / 100.0)
		self.rotate(self.global_transform.basis.x, mouse_offset_y / 100.0)
	last_mouse_pos = get_viewport().get_mouse_position()
	
	var dir := Vector3.ZERO
	dir = self.global_transform.basis.z * (Input.get_action_strength("backward") - Input.get_action_strength("forward"))
	dir += self.global_transform.basis.y * (Input.get_action_strength("strafe_up") - Input.get_action_strength("strafe_down"))
	dir += self.global_transform.basis.x * (Input.get_action_strength("strafe_right") - Input.get_action_strength("strafe_left"))
	var vel = self.move_and_slide(dir * 10.0, self.transform.basis.y)
	
	if not placing_name.empty():
		if placing_name == "floor":
			var target_pos = self.global_transform.origin - (self.global_transform.basis.z.normalized() * cur_placing_distance)
			if placing_obj == null:
				placing_obj = placing_instance[placing_name].instance()
				$"..".add_child(placing_obj)
			placing_obj.visible = true
			
			var space_state : PhysicsDirectSpaceState = get_world().direct_space_state
			var start_point : Vector3 = self.translation - (self.global_transform.basis.z.normalized() * 2.0)
			var end_point : Vector3 = start_point - (self.global_transform.basis.z.normalized() * 1000.0)
			var result : Dictionary = space_state.intersect_ray(start_point, end_point, [self], 4)
			$"../s".translation = start_point
			$"../e".translation = end_point
			if not result.empty():
				print(result["collider"].name)
			placing_obj.transform = self.transform
			placing_obj.translation = target_pos
		else:
			var space_state : PhysicsDirectSpaceState = get_world().direct_space_state
			var start_point : Vector3 = self.translation - (self.global_transform.basis.z.normalized() * 2.0)
			var end_point : Vector3 = start_point - (self.global_transform.basis.z.normalized() * 1000.0)
			var result : Dictionary = space_state.intersect_ray(start_point, end_point, [self])
			$"../s".translation = start_point
			$"../e".translation = end_point
			if not result.empty():
				end_point = result.position
				var norm : Vector3 = result.normal
				#norm.y = 0.0
				if placing_obj == null:
					placing_obj = placing_instance[placing_name].instance()
					$"..".add_child(placing_obj)
				placing_obj.visible = true
				placing_obj.translation = end_point
				var a : float = placing_obj.transform.basis.y.angle_to(norm)
				if a > 0.01:
					var axis : Vector3 = placing_obj.transform.basis.y.cross(norm).normalized()
					placing_obj.transform = placing_obj.transform.rotated(axis, a)
				placing_obj.translation = end_point
				
			elif placing_obj != null:
				placing_obj.visible = false
				
			var l = (end_point - start_point).length()
			place_ray.scale.y = l
			place_ray.translation.z = -2.0 -l/2.0
			
