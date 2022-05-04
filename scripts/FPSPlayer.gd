extends KinematicBody

var last_mouse_pos := Vector2.ZERO
export(NodePath) onready var player_ship = get_node(player_ship)

func _ready() -> void:
	last_mouse_pos = get_viewport().get_mouse_position()

func _unhandled_input(event: InputEvent) -> void:
	if $Camera.current == true and Input.is_action_just_released("boarding"):
		$Camera.current = false
		(player_ship.get_node("Camera") as Camera).current = true
		return

func _physics_process(delta: float) -> void:
	if $Camera.current == false:
		return
		
	var cur_mouse_pos : Vector2 = get_viewport().get_mouse_position()
	var mouse_offset_x : float = last_mouse_pos.x - cur_mouse_pos.x
	var mouse_offset_y : float = last_mouse_pos.y - cur_mouse_pos.y
	self.rotate(self.global_transform.basis.y.normalized(), mouse_offset_x / 100.0)
	self.rotate(self.global_transform.basis.x.normalized(), mouse_offset_y / 100.0)
	last_mouse_pos = get_viewport().get_mouse_position()
	
	#var roll = Input.get_action_strength("roll_left") - Input.get_action_strength("roll_right")
	#self.rotate(self.global_transform.basis.z.normalized(), roll / 50.0)
	
	var dir := Vector3.ZERO
	dir = self.global_transform.basis.z * (Input.get_action_strength("backward") - Input.get_action_strength("forward"))
	#dir += self.global_transform.basis.y * (Input.get_action_strength("strafe_up") - Input.get_action_strength("strafe_down"))
	dir += self.global_transform.basis.x * (Input.get_action_strength("strafe_right") - Input.get_action_strength("strafe_left"))
	var vel = self.move_and_slide(dir * 10.0, self.transform.basis.y)
