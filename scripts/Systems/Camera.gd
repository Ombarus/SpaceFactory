extends Node


export(NodePath) onready var PlayerCamera
export(Resource) var CameraState
export(float) var Smoothing = 10.0
onready var player_camera : Camera = get_node(PlayerCamera)
var player_node : Attributes = null
var last_mouse_pos := Vector2.ZERO
var locked_controls : bool = false


func _ready() -> void:
	Events.connect("OnObjectCreated", self, "OnObjectCreated_Callback")
	Events.connect("OnLockControl", self, "OnLockControl_Callback")
	#CameraState.pitch_limit.x = deg2rad(CameraState.pitch_limit.x)
	#CameraState.pitch_limit.y = deg2rad(CameraState.pitch_limit.y)
	

func OnObjectCreated_Callback(data):
	if Globals.get_attrib(data, "player", null) != null:
		player_node = Globals.LevelLoaderRef.get_visual_from_data(data["id"])
		
		
func OnLockControl_Callback(locked : bool) -> void:
	locked_controls = locked


func _process(delta: float) -> void:
#	var desired_abs_anchor : Vector3 = player_node.global_transform.xform(CameraState.anchor_offset)
#	var desired_abs_target : Vector3 = player_node.global_transform.xform(CameraState.anchor_offset + CameraState.target_offset)
#	var current_abs_target : Vector3 = player_camera.transform.origin
#	var current_offset : Vector3 = desired_abs_target - current_abs_target
#
#	var dist = current_offset.length()
#	var dir = current_offset.normalized()
#	var smooth_offset : Vector3 = (dist * pow(0.1, (Smoothing * delta))) * dir
#	player_camera.transform.origin = current_abs_target + smooth_offset
	if locked_controls:
		last_mouse_pos = get_viewport().get_mouse_position()
		return

	var cur_mouse_pos : Vector2 = get_viewport().get_mouse_position()
	var mouse_offset_x : float = last_mouse_pos.x - cur_mouse_pos.x
	var mouse_offset_y : float = last_mouse_pos.y - cur_mouse_pos.y
	CameraState.rotation.y += mouse_offset_x / 100.0
	CameraState.rotation.x += mouse_offset_y / 100.0
	CameraState.rotation.x = min(max(CameraState.rotation.x, deg2rad(CameraState.pitch_limits.x)), deg2rad(CameraState.pitch_limits.y))
#	player_camera.rotate(player_camera.global_transform.basis.y.normalized(), mouse_offset_x / 100.0)
#	player_camera.rotate(player_camera.global_transform.basis.x.normalized(), mouse_offset_y / 100.0)
	last_mouse_pos = cur_mouse_pos

	#var desired_abs_lookat : Vector3 = player_node.global_transform.xform(CameraState.anchor_offset + CameraState.look_target)
	#player_camera.look_at(desired_abs_lookat, player_node.global_transform.basis.y)
	
	var target_pos : Vector3 = Quat(CameraState.rotation).xform(CameraState.anchor_offset + CameraState.target_offset)
	var target_lookat : Vector3 = Quat(CameraState.rotation).xform(CameraState.anchor_offset + CameraState.look_target)

	target_pos = player_node.global_transform.origin + target_pos #player_node.global_transform.xform(target_pos)
	var target_look_at : Vector3 = player_node.global_transform.origin + target_lookat #player_node.global_transform.xform(target_lookat)
	player_node.set_attrib("camera_look_at", target_look_at)

	player_camera.transform.origin = target_pos

	player_camera.look_at(target_look_at, player_node.global_transform.basis.y)
#
#	#TODO: Make it smooth!
#
	collide()


func collide():
	var start = player_node.transform.origin + CameraState.anchor_offset
	var end = player_camera.transform.origin
	var space_state = player_node.get_world().direct_space_state
	var col = space_state.intersect_ray(start, end)
	if not col.empty():
		player_camera.transform.origin = col.position
	
	
	
