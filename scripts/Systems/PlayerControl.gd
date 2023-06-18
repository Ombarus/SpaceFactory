extends Node

var last_mouse_pos := Vector2.ZERO
var player_node : Attributes = null
var placing_name := ""
var cur_placing_distance := 15.0
var placing_obj : Node3D = null
var locked_controls : bool = false
@export var PlacingRoot : NodePath
@export var HarvestBeam : NodePath
@export var InventoryLine : NodePath
@onready var placing_root : Node = get_node(PlacingRoot)
@onready var harvest_beam : Attributes = get_node(HarvestBeam)
@onready var inventory_line : Control = get_node(InventoryLine)

func _ready() -> void:
	Events.connect("OnObjectCreated",Callable(self,"OnObjectCreated_Callback"))
	Events.connect("OnPlaceToggle",Callable(self,"OnPlaceToggle_Callback"))
	Events.connect("OnDoPlacement",Callable(self,"OnDoPlacement_Callback"))
	Events.connect("OnLockControl",Callable(self,"OnLockControl_Callback"))
	Events.connect("OnRegionEntered",Callable(self,"OnRegionEntered_Callback"))
	Events.connect("OnRegionLeft",Callable(self,"OnRegionLeft_Callback"))
	
func OnRegionEntered_Callback(data : Dictionary) -> void:
	player_node.set_attrib("current_context", data["id"])
	
# TODO: handle some sort of priority (in case multiple region overlap)
func OnRegionLeft_Callback(data : Dictionary) -> void:
	var current_context = player_node.get_attrib("current_context", -1)
	if current_context == data["id"]:
		player_node.set_attrib("current_context", -1)
	
func OnLockControl_Callback(locked : bool) -> void:
	locked_controls = locked
	
func OnObjectCreated_Callback(data : Dictionary) -> void:
	if Globals.get_attrib(data, "player", null) != null:
		player_node = Globals.LevelLoaderRef.get_visual_from_data(data["id"])
	if Globals.get_attrib(data, "beam", null) != null:
		var beam_obj = Globals.LevelLoaderRef.get_visual_from_data(data["id"])
		if beam_obj == harvest_beam:
			Globals.set_attrib(data, "beam.origin", player_node.get_attrib("id"))
		
func OnDoPlacement_Callback() -> void:
	if placing_obj != null and validate_cost(placing_obj, true):
		toggle_collider(placing_obj, false)
		var land_anim : String = placing_obj.get_attrib("animation.spawn", "")
		if not land_anim.is_empty():
			var anim_player : AnimationPlayer = placing_obj.find_child("AnimationPlayer", true, false)
			anim_player.play(land_anim)
		
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
	if placing_obj != null or locked_controls:
		return
		
	if event.is_action_pressed("ui_accept"):
		harvest_beam_enable(true)
	elif event.is_action_released("ui_accept"):
		harvest_beam_enable(false)
	elif event.is_action_released("context_menu"):
		var current_context = player_node.get_attrib("current_context", -1)
		var menu_name = "CraftDialog"
		var data = null
		if current_context >= 0:
			data = Globals.LevelLoaderRef.get_object_data(current_context)
			menu_name = Globals.get_attrib(data, "dialog_name", "CraftDialog")
		Events.emit_signal("OnPushGUI", menu_name, {"player_data": player_node.get_data(), "building_data":data})

func OnPlaceToggle_Callback(name : String) -> void:
	placing_name = name
	if placing_obj != null:
		Globals.LevelLoaderRef.destroy_object(placing_obj.attribute_ref)
		placing_obj = null
		
func _process(delta: float) -> void:
	if player_node == null and harvest_beam.is_valid():
		return
		
	var beam_inv := InventoryUtil.new(harvest_beam.get_data())
	var player_inv := InventoryUtil.new(player_node.get_data())
	var changed := false
	var keys : Array = Globals.get_keys(harvest_beam.get_data(), "inventory_slots")
	for key in keys:
		var take_name : String = harvest_beam.get_attrib("inventory_slots.%s.content" % str(key))
		var take_count : int = harvest_beam.get_attrib("inventory_slots.%s.count" % str(key))
		if take_name.is_empty() or take_count <= 0:
			continue
		player_inv.add(take_name, take_count)
		beam_inv.substract(take_name, take_count)
		changed = true
	if changed or player_node.get_attrib("inventory_dirty", false) == true:
		update_inventory_display()
		
func update_inventory_display():
	#TODO: update display when crafting finishes
	for n in get_tree().get_nodes_in_group("inventory"):
		n.queue_free()
	var keys : Array = Globals.get_keys(player_node.get_data(), "inventory_slots")
	for key in keys:
		var item_path : String = player_node.get_attrib("inventory_slots.%s.content" % str(key))
		if item_path.is_empty():
			continue
		var line = inventory_line.duplicate()
		inventory_line.get_parent().add_child(line)
		line.visible = true
		var item_count : int = player_node.get_attrib("inventory_slots.%s.count" % str(key))
		var data : Dictionary = Globals.LevelLoaderRef.load_json(item_path)
		line.get_node("Name").text = Globals.get_attrib(data, "name") + " : " + str(item_count)
		var icon_name : String = Globals.get_attrib(data, "icon", "")
		if not icon_name.is_empty():
			(line.get_node("Icon") as TextureRect).texture = load(icon_name)
		line.add_to_group("inventory")

func _physics_process(delta: float) -> void:
	if player_node == null or locked_controls:
		return
	
	var cur_mouse_pos : Vector2 = get_viewport().get_mouse_position()
	var mouse_offset_x : float = last_mouse_pos.x - cur_mouse_pos.x
	var mouse_offset_y : float = last_mouse_pos.y - cur_mouse_pos.y
	last_mouse_pos = cur_mouse_pos
	
	# pitch
	player_node.rotate(player_node.global_transform.basis.x.normalized(), mouse_offset_y / 100.0)
	
	# yaw
	player_node.rotate(player_node.global_transform.basis.y.normalized(), mouse_offset_x / 100.0)
	
	var roll = Input.get_action_strength("roll_left") - Input.get_action_strength("roll_right")
	player_node.rotate(player_node.global_transform.basis.z.normalized(), roll / 50.0)

	var dir := Vector3.ZERO
	dir = player_node.global_transform.basis.z * (Input.get_action_strength("backward") - Input.get_action_strength("forward"))
	dir += player_node.global_transform.basis.y * (Input.get_action_strength("strafe_up") - Input.get_action_strength("strafe_down"))
	dir += player_node.global_transform.basis.x * (Input.get_action_strength("strafe_right") - Input.get_action_strength("strafe_left"))
	player_node.set_velocity(dir * 10.0)
	player_node.set_up_direction(player_node.transform.basis.y)
	player_node.move_and_slide()
	var vel = player_node.velocity
	
	do_placement()
	
	
func do_placement():
	if placing_name.is_empty():
		return
		
	if placing_name in ["floor", "wall", "solar"]:
		var target_pos = player_node.global_transform.origin - (player_node.global_transform.basis.z.normalized() * cur_placing_distance)
		if placing_obj == null:
			placing_obj = Preloader.BuildingList[placing_name].instantiate()
			placing_root.add_child(placing_obj)
			toggle_collider(placing_obj, true)
			return # give it a frame to init properly
		placing_obj.visible = true
		
		var space_state : PhysicsDirectSpaceState3D = player_node.get_world_3d().direct_space_state
		var start_point : Vector3 = player_node.position - (player_node.global_transform.basis.z.normalized() * 2.0)
		var end_point : Vector3 = start_point - (player_node.global_transform.basis.z.normalized() * 1000.0)
		var query = PhysicsRayQueryParameters3D.create(start_point, end_point, Globals.COLLISION_LAYERS.SNAP_POINTS)
		query.collide_with_areas = true
		var result : Dictionary = space_state.intersect_ray(query)
		if not result.is_empty():
			handle_piece_snapping(result)
			return
		placing_obj.global_transform = player_node.global_transform
		placing_obj.position = target_pos
	else:
		var space_state : PhysicsDirectSpaceState3D = player_node.get_world_3d().direct_space_state
		var start_point : Vector3 = player_node.position - (player_node.global_transform.basis.z.normalized() * 2.0)
		var end_point : Vector3 = start_point - (player_node.global_transform.basis.z.normalized() * 1000.0)
		var query = PhysicsRayQueryParameters3D.create(start_point, end_point)
		query.exclude.append(player_node.get_rid())
		var result : Dictionary = space_state.intersect_ray(query)
		if not result.is_empty():
			end_point = result.position
			var norm : Vector3 = result.normal
			print(result["collider"].name)
			#norm.y = 0.0
			if placing_obj == null:
				placing_obj = Preloader.BuildingList[placing_name].instantiate()
				placing_root.add_child(placing_obj)
				toggle_collider(placing_obj, true)
				return
			
			var placing_on : Attributes = result["collider"]
			if not validate_surface(placing_on, placing_obj):
				placing_obj.visible = false
				return
			
			update_connections(placing_on)
			
			placing_obj.visible = true
			placing_obj.position = end_point
			var a : float = placing_obj.transform.basis.y.angle_to(norm)
			if a > 0.01:
				var axis : Vector3 = placing_obj.transform.basis.y.cross(norm).normalized()
				placing_obj.transform = placing_obj.transform.rotated(axis, a)
			placing_obj.position = end_point
			
		elif placing_obj != null:
			placing_obj.visible = false
			
		var l = (end_point - start_point).length()
		
	if placing_obj != null:
		var invalid_visual : Node3D = placing_obj.find_child("Invalid")
		if invalid_visual != null:
			if validate_cost(placing_obj):
				invalid_visual.visible = false
			else:
				invalid_visual.visible = true
		
func update_connections(placing_on : Attributes):
	var connections = placing_obj.get_attrib("connections", [])
	var placing_on_id = placing_on.get_attrib("id")
	if not placing_on_id in connections:
		connections.push_back(placing_on_id)
		placing_obj.set_attrib("connections", connections)

func toggle_collider(obj : Node, disabled : bool) -> void:
	for c in obj.get_children():
		if c is CollisionShape3D:
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
	
	update_connections(fixed_piece)
	
	var fixed_pos : Vector3 = fixed_snap.global_transform.origin
	var placing_pos : Vector3 = placing_snap_point.global_transform.origin
	
	var offset = placing_pos - placing_obj.global_transform.origin
	placing_obj.global_transform.basis = fixed_snap.global_transform.basis
	placing_obj.global_transform.origin = fixed_pos + offset

func validate_surface(placing_on : Attributes, placing_obj : Attributes) -> bool:
	var placing_on_surface_name : String = placing_on.get_attrib("surface", "")
	var placing_valid_surfaces : Array = placing_obj.get_attrib("placeable.surfaces", [])
	return placing_valid_surfaces.is_empty() or placing_on_surface_name in placing_valid_surfaces
	
func validate_cost(placing_obj : Attributes, consume := false) -> bool:
	var player_inv := InventoryUtil.new(player_node.get_data())
	var cost_list : Array = placing_obj.get_attrib("placeable.cost", [])
	var has_mat := true
	for item_data in cost_list:
		var item_path : String = item_data.get("name")
		var item_count : int = item_data.get("count")
		if player_inv.total(item_path) < item_count:
			has_mat = false
			break
	if has_mat and consume:
		for item_data in cost_list:
			var item_path : String = item_data.get("name")
			var item_count : int = item_data.get("count")
			player_inv.substract(item_path, item_count)
		
	return has_mat


func harvest_beam_enable(is_enabled : bool) -> void:
	harvest_beam.visible = is_enabled
	
