extends KinematicBody2D


# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"


# Called when the node enters the scene tree for the first time.
func _physics_process(delta: float) -> void:
	var dir = Vector2.ZERO
	dir.y = Input.get_action_strength("forward") - Input.get_action_strength("backward")
	dir.x = Input.get_action_strength("strafe_right") - Input.get_action_strength("strafe_left")
	move_and_slide(dir * 100.0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass
