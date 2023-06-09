extends Node


@export_node_path("Camera3D") var PlayerCamera : NodePath
@export var CameraState: CameraData
@export var Smoothing: float = 10.0
@export var SmoothingBase: float = 0.1
@onready var player_camera : Camera3D = get_node(PlayerCamera)
var player_node : Attributes = null
var last_player_transform := Transform3D.IDENTITY
var locked_controls : bool = false


func _ready() -> void:
	Events.connect("OnObjectCreated",Callable(self,"OnObjectCreated_Callback"))
	Events.connect("OnLockControl",Callable(self,"OnLockControl_Callback"))
	#CameraState.pitch_limit.x = deg_to_rad(CameraState.pitch_limit.x)
	#CameraState.pitch_limit.y = deg_to_rad(CameraState.pitch_limit.y)
	

func OnObjectCreated_Callback(data):
	if Globals.get_attrib(data, "player", null) != null:
		player_node = Globals.LevelLoaderRef.get_visual_from_data(data["id"])
		last_player_transform = player_node.transform
		
		
func OnLockControl_Callback(locked : bool) -> void:
	locked_controls = locked


func _process(delta: float) -> void:
	if player_node == null or locked_controls:
		return
		
	var cur_player_transform := player_node.transform
	
	var rest_global_offset = player_node.to_global(CameraState.target_offset + CameraState.anchor_offset)
	var rest_global_look_at = player_node.to_global(CameraState.look_target)
	
	var cur_global_pos : Vector3 = player_camera.position
	var offset : Vector3 = rest_global_offset - cur_global_pos
	offset = offset * pow(SmoothingBase, Smoothing * delta)
	
	player_camera.position += offset
	player_camera.look_at(rest_global_look_at, player_node.transform.basis.y)

	collide()
	
	last_player_transform = cur_player_transform


func collide():
	var start = player_node.transform.origin + CameraState.anchor_offset
	var end = player_camera.transform.origin
	var space_state = player_node.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(start, end)
	var col = space_state.intersect_ray(query)
	if not col.is_empty():
		player_camera.transform.origin = col.position
	
	
	
