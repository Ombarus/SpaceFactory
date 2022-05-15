extends Node


export(NodePath) onready var PlayerCamera
export(Resource) var CameraState
onready var player_camera : Camera = get_node(PlayerCamera)
var player_node : Attributes = null


func _ready() -> void:
	Events.connect("OnObjectCreated", self, "OnObjectCreated_Callback")
	CameraState.pitch_limit.x = deg2rad(CameraState.pitch_limit.x)
	CameraState.pitch_limit.y = deg2rad(CameraState.pitch_limit.y)
	

func OnObjectCreated_Callback(data):
	if Globals.get_attrib(data, "player", null) != null:
		player_node = Globals.LevelLoaderRef.get_visual_from_data(data["id"])


func _process(delta: float) -> void:
	player_camera.transform.origin = player_node.global_transform.xform(CameraState.anchor_offset + CameraState.target_offset)
	var look_at = player_node.global_transform.xform(CameraState.anchor_offset + CameraState.look_target)

	player_camera.look_at(look_at, player_node.global_transform.basis.y)
	
	#TODO: Make it smooth!
	
	collide()


func collide():
	var start = player_node.transform.origin + CameraState.anchor_offset
	var end = player_camera.transform.origin
	var space_state = player_node.get_world().direct_space_state
	var col = space_state.intersect_ray(start, end)
	if not col.empty():
		player_camera.transform.origin = col.position
	
	
	
