extends Node

var last_mouse_pos := Vector2.ZERO
var player_node : Attributes = null
var placing_name := ""
var cur_placing_distance := 15.0
var placing_obj : Spatial = null
export(NodePath) var PlacingRoot : NodePath
export(NodePath) var HarvestBeam : NodePath
export(NodePath) var InventoryLine : NodePath
onready var placing_root : Node = get_node(PlacingRoot)
onready var harvest_beam : Attributes = get_node(HarvestBeam)
onready var inventory_line : Label = get_node(InventoryLine)

func _ready() -> void:
	Events.connect("OnObjectCreated", self, "OnObjectCreated_Callback")
	Events.connect("OnPlaceToggle", self, "OnPlaceToggle_Callback")
	Events.connect("OnDoPlacement", self, "OnDoPlacement_Callback")
	
func OnObjectCreated_Callback(data : Dictionary) -> void:
	if Globals.get_attrib(data, "player", null) != null:
		player_node = Globals.LevelLoaderRef.get_visual_from_data(data["id"])
	if Globals.get_attrib(data, "beam", null) != null:
		var beam_obj = Globals.LevelLoaderRef.get_visual_from_data(data["id"])
		if beam_obj == harvest_beam:
			Globals.set_attrib(data, "beam.origin", player_node.get_attrib("id"))
		
func OnDoPlacement_Callback() -> void:
	if placing_obj != null:
		toggle_collider(placing_obj, false)
		placing_obj = null
		placing_name = ""

func _input(event: InputEvent) -> void:
	if placing_obj == null:
		return
		
	if event.is_action_released("ui_accept"):
		Events.emit_signal("OnDoPlacement")
		Events.emit_signal("OnPlaceToggle", "")
	if event.is_action_released("ui_cancel"):
		Events.emit_signal("OnPlaceToggle", "")
		
func _unhandled_input(event: InputEvent) -> void:
	if placing_obj != null:
		return
		
	if event.is_action_pressed("ui_accept"):
		harvest_beam_enable(true)
	elif event.is_action_released("ui_accept"):
		harvest_beam_enable(false)
	elif event.is_action_released("context_menu"):
		Events.emit_signal("OnPushGUI", "CraftDialog", {})

func OnPlaceToggle_Callback(name : String) -> void:
	placing_name = name
	if placing_obj != null:
		placing_obj.visible = false
		placing_obj.queue_free()
		placing_obj = null
		
func _process(delta: float) -> void:
	if player_node == null and harvest_beam.is_valid():
		return
		
	var beam_inv : Dictionary = harvest_beam.get_attrib("inventory", {})
	var player_inv : Dictionary = player_node.get_attrib("inventory", {})
	var changed := false
	for item_path in beam_inv:
		if beam_inv[item_path] <= 0:
			continue
		var data : Dictionary = Globals.LevelLoaderRef.load_json(item_path)
		var max_stack = Globals.get_attrib(data, "inventory.max_stack")
		var take = min(beam_inv[item_path], max_stack - player_inv.get(item_path, 0))
		if take > 0:
			changed = true
		player_inv[item_path] = player_inv.get(item_path, 0) + take
		beam_inv[item_path] -= take
	if changed == true:
		player_node.set_attrib("inventory", player_inv)
		harvest_beam.set_attrib("inventory", beam_inv)
		update_inventory_display()
		
func update_inventory_display():
	for n in get_tree().get_nodes_in_group("inventory"):
		n.queue_free()
	var player_inv : Dictionary = player_node.get_attrib("inventory", {})
	for key in player_inv:
		var line = inventory_line.duplicate()
		inventory_line.get_parent().add_child(line)
		line.visible = true
		var data : Dictionary = Globals.LevelLoaderRef.load_json(key)
		line.text = Globals.get_attrib(data, "name") + " : " + str(player_inv[key])
		line.add_to_group("inventory")

func _physics_process(delta: float) -> void:
	if player_node == null:
		return
		
	#if Input.is_mouse_button_pressed(1):
	var cur_mouse_pos : Vector2 = get_viewport().get_mouse_position()
	var mouse_offset_x : float = last_mouse_pos.x - cur_mouse_pos.x
	var mouse_offset_y : float = last_mouse_pos.y - cur_mouse_pos.y
	player_node.rotate(player_node.global_transform.basis.y.normalized(), mouse_offset_x / 100.0)
	player_node.rotate(player_node.global_transform.basis.x.normalized(), mouse_offset_y / 100.0)
	last_mouse_pos = get_viewport().get_mouse_position()
	
	var roll = Input.get_action_strength("roll_left") - Input.get_action_strength("roll_right")
	player_node.rotate(player_node.global_transform.basis.z.normalized(), roll / 50.0)
	
	var dir := Vector3.ZERO
	dir = player_node.global_transform.basis.z * (Input.get_action_strength("backward") - Input.get_action_strength("forward"))
	dir += player_node.global_transform.basis.y * (Input.get_action_strength("strafe_up") - Input.get_action_strength("strafe_down"))
	dir += player_node.global_transform.basis.x * (Input.get_action_strength("strafe_right") - Input.get_action_strength("strafe_left"))
	var vel = player_node.move_and_slide(dir * 10.0, player_node.transform.basis.y)
	
	player_node.set_attrib("visual.transform", player_node.global_transform)
	
	do_placement()
	
func do_placement():
	if placing_name.empty():
		return
		
	if placing_name in ["floor", "wall"]:
		var target_pos = player_node.global_transform.origin - (player_node.global_transform.basis.z.normalized() * cur_placing_distance)
		if placing_obj == null:
			placing_obj = Preloader.BuildingList[placing_name].instance()
			placing_root.add_child(placing_obj)
			toggle_collider(placing_obj, true)
		placing_obj.visible = true
		
		var space_state : PhysicsDirectSpaceState = player_node.get_world().direct_space_state
		var start_point : Vector3 = player_node.translation - (player_node.global_transform.basis.z.normalized() * 2.0)
		var end_point : Vector3 = start_point - (player_node.global_transform.basis.z.normalized() * 1000.0)
		var result : Dictionary = space_state.intersect_ray(start_point, end_point, [], Globals.COLLISION_LAYERS.SNAP_POINTS, true, true)
		if not result.empty():
			handle_piece_snapping(result)
			return
		placing_obj.global_transform = player_node.global_transform
		placing_obj.translation = target_pos
	else:
		var space_state : PhysicsDirectSpaceState = player_node.get_world().direct_space_state
		var start_point : Vector3 = player_node.translation - (player_node.global_transform.basis.z.normalized() * 2.0)
		var end_point : Vector3 = start_point - (player_node.global_transform.basis.z.normalized() * 1000.0)
		var result : Dictionary = space_state.intersect_ray(start_point, end_point, [self])
		if not result.empty():
			end_point = result.position
			var norm : Vector3 = result.normal
			#norm.y = 0.0
			if placing_obj == null:
				placing_obj = Preloader.BuildingList[placing_name].instance()
				placing_root.add_child(placing_obj)
				toggle_collider(placing_obj, true)
				return
			
			var placing_on : Attributes = result["collider"]
			if not validate_surface(placing_on, placing_obj):
				placing_obj.visible = false
				return
			
			var connections = placing_obj.get_attrib("connections", [])
			var placing_on_id = placing_on.get_attrib("id")
			if not placing_on_id in connections:
				connections.push_back(placing_on_id)
				placing_obj.set_attrib("connections", connections)
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
		#place_ray.scale.y = l
		#place_ray.translation.z = -2.0 -l/2.0


func toggle_collider(obj : Node, disabled : bool) -> void:
	for c in obj.get_children():
		if c is CollisionShape:
			c.disabled = disabled
		toggle_collider(c, disabled)


func handle_piece_snapping(col_res):
	var fixed_snap := col_res["collider"] as Snapping
	var fixed_piece := fixed_snap.get_parent() as Attributes
	var placing_snap_point : Snapping = null
	for combo in fixed_piece.get_attrib("snap_association"):
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

func validate_surface(placing_on : Attributes, placing_obj : Attributes) -> bool:
	var placing_on_surface_name : String = placing_on.get_attrib("surface", "")
	var placing_valid_surfaces : Array = placing_obj.get_attrib("placeable.surfaces", [])
	return placing_valid_surfaces.empty() or placing_on_surface_name in placing_valid_surfaces

func harvest_beam_enable(is_enabled : bool) -> void:
	harvest_beam.visible = is_enabled
	
