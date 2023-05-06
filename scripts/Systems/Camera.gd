extends Node


@export_node_path("Camera3D") var PlayerCamera : NodePath
@export var CameraState: Resource
@export var Smoothing: float = 10.0
@onready var player_camera : Camera3D = get_node(PlayerCamera)
var player_node : Attributes = null
var last_mouse_pos := Vector2.ZERO
var locked_controls : bool = false


func _ready() -> void:
	Events.connect("OnObjectCreated",Callable(self,"OnObjectCreated_Callback"))
	Events.connect("OnLockControl",Callable(self,"OnLockControl_Callback"))
	#CameraState.pitch_limit.x = deg_to_rad(CameraState.pitch_limit.x)
	#CameraState.pitch_limit.y = deg_to_rad(CameraState.pitch_limit.y)
	

func OnObjectCreated_Callback(data):
	if Globals.get_attrib(data, "player", null) != null:
		player_node = Globals.LevelLoaderRef.get_visual_from_data(data["id"])
		
		
func OnLockControl_Callback(locked : bool) -> void:
	locked_controls = locked


func _process(delta: float) -> void:
	if player_node == null or locked_controls:
		last_mouse_pos = get_viewport().get_mouse_position()
		return
		
	var cur_mouse_pos : Vector2 = get_viewport().get_mouse_position()
	var mouse_offset_x : float = last_mouse_pos.x - cur_mouse_pos.x
	var mouse_offset_y : float = last_mouse_pos.y - cur_mouse_pos.y
	last_mouse_pos = cur_mouse_pos
	
	CameraState.rotation.y += mouse_offset_x / 100.0
	CameraState.rotation.x += mouse_offset_y / 100.0
	#CameraState.rotation.x = min(max(CameraState.rotation.x, deg_to_rad(CameraState.pitch_limits.x)), deg_to_rad(CameraState.pitch_limits.y))
	
	var roll = Input.get_action_strength("roll_left") - Input.get_action_strength("roll_right")
	CameraState.rotation.z += roll / 50.0
		
	camera_follow_mouse()

	collide()

func camera_follow_mouse():
	var target_origin : Vector3 = player_node.global_transform.origin
	var anchor_abs_pos : Vector3 = target_origin + CameraState.anchor_offset
	var cur_rot_quat : Quaternion = Quaternion.from_euler(CameraState.rotation)
	var rotated_up : Vector3 = cur_rot_quat * Vector3.UP
	var rotated_target_offset : Vector3 = cur_rot_quat * CameraState.target_offset
	var rotated_look_offset : Vector3 = cur_rot_quat * CameraState.look_target
	var abs_target_pos : Vector3 = anchor_abs_pos + rotated_target_offset
	var abs_look_pos : Vector3 = anchor_abs_pos + rotated_look_offset
	player_camera.transform.origin = abs_target_pos
	player_camera.look_at(abs_look_pos, rotated_up)
	player_node.set_attrib("camera_look_at", abs_look_pos)
	player_node.set_attrib("camera_rotation", CameraState.rotation)

func collide():
	var start = player_node.transform.origin + CameraState.anchor_offset
	var end = player_camera.transform.origin
	var space_state = player_node.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(start, end)
	var col = space_state.intersect_ray(query)
	if not col.is_empty():
		player_camera.transform.origin = col.position
	
	
	
