extends Node

var last_mouse_pos := Vector2.ZERO
var player_node : Attributes = null

func _ready() -> void:
	Events.connect("OnObjectCreated", self, "OnObjectCreated_Callback")
	
func OnObjectCreated_Callback(data):
	if Globals.get_attrib(data, "player", null) != null:
		player_node = Globals.LevelLoaderRef.get_visual_from_data(data["id"])

func _physics_process(delta: float) -> void:
	if player_node == null:
		return
		
	if Input.is_mouse_button_pressed(1):
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
	
