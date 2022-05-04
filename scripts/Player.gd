extends KinematicBody

export(NodePath) onready var inv_line = get_node(inv_line)
export(NodePath) onready var fps_player = get_node(fps_player)

onready var place_ray : MeshInstance = $PlaceRay
var last_mouse_pos := Vector2.ZERO
var placing_name := ""
var placing_obj : Spatial = null
var cur_placing_distance := 15.0
var inventory := {}

const placing_instance := {
	"miner":preload("res://scenes/Miner.tscn"),
	"smelter":preload("res://scenes/Smelter.tscn"),
	"floor":preload("res://scenes/Floor.tscn"),
	"wall":preload("res://scenes/Wall.tscn")
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
		toggle_collider(placing_obj, false)
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

func toggle_collider(obj : Node, disabled : bool) -> void:
	for c in obj.get_children():
		if c is CollisionShape:
			c.disabled = disabled
		toggle_collider(c, disabled)

func _unhandled_input(event: InputEvent) -> void:
	if $Camera.current == true and Input.is_action_just_released("boarding"):
		$Camera.current = false
		(fps_player.get_node("Camera") as Camera).current = true
		return

func _physics_process(delta: float) -> void:
	if $Camera.current == false:
		return
	if Input.is_mouse_button_pressed(1):
		var cur_mouse_pos : Vector2 = get_viewport().get_mouse_position()
		var mouse_offset_x : float = last_mouse_pos.x - cur_mouse_pos.x
		var mouse_offset_y : float = last_mouse_pos.y - cur_mouse_pos.y
		self.rotate(self.global_transform.basis.y.normalized(), mouse_offset_x / 100.0)
		self.rotate(self.global_transform.basis.x.normalized(), mouse_offset_y / 100.0)
	last_mouse_pos = get_viewport().get_mouse_position()
	
	var roll = Input.get_action_strength("roll_left") - Input.get_action_strength("roll_right")
	self.rotate(self.global_transform.basis.z.normalized(), roll / 50.0)
	
	var dir := Vector3.ZERO
	dir = self.global_transform.basis.z * (Input.get_action_strength("backward") - Input.get_action_strength("forward"))
	dir += self.global_transform.basis.y * (Input.get_action_strength("strafe_up") - Input.get_action_strength("strafe_down"))
	dir += self.global_transform.basis.x * (Input.get_action_strength("strafe_right") - Input.get_action_strength("strafe_left"))
	var vel = self.move_and_slide(dir * 10.0, self.transform.basis.y)
	
	if not placing_name.empty():
		if placing_name in ["floor", "wall"]:
			var target_pos = self.global_transform.origin - (self.global_transform.basis.z.normalized() * cur_placing_distance)
			if placing_obj == null:
				placing_obj = placing_instance[placing_name].instance()
				$"..".add_child(placing_obj)
				toggle_collider(placing_obj, true)
			placing_obj.visible = true
			
			var space_state : PhysicsDirectSpaceState = get_world().direct_space_state
			var start_point : Vector3 = self.translation - (self.global_transform.basis.z.normalized() * 2.0)
			var end_point : Vector3 = start_point - (self.global_transform.basis.z.normalized() * 1000.0)
			var result : Dictionary = space_state.intersect_ray(start_point, end_point, [], 4, true, true)
			$"../s".translation = start_point
			$"../e".translation = end_point
			if not result.empty():
				handle_piece_snapping(result)
#				dir = result["collider"].transform.origin
#				placing_obj.global_transform = result["collider"].global_transform
#				if placing_name == "floor":
#					placing_obj.translation += dir
				return
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
					toggle_collider(placing_obj, true)
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

func handle_piece_snapping(col_res):
	var fixed_snap := col_res["collider"] as Snapping
	var fixed_piece := fixed_snap.get_parent() as Piece
	var placing_snap_point : Snapping = null
	for combo in fixed_piece.snap_association:
		if fixed_snap.snap_name == combo[0]:
			for c in placing_obj.get_children():
				if c is Snapping and (c as Snapping).snap_name == combo[1]:
					placing_snap_point = c
					break
		if placing_snap_point != null:
			break
	
	if placing_snap_point == null:
		return
	
	var fixed_pos : Vector3 = fixed_snap.global_transform.origin
	var placing_pos : Vector3 = placing_snap_point.global_transform.origin
	
	var offset = placing_pos - placing_obj.global_transform.origin
	placing_obj.global_transform.basis = fixed_snap.global_transform.basis
	placing_obj.global_transform.origin = fixed_pos + offset
	
