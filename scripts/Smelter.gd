extends StaticBody3D

@export var prod_per_sec: float := 0.1
@export var max_hold: int := 100
var cur_time := 0.0
var cur_in := 0
var cur_out := 0
@onready var ui : Label = $PickupLabel

func _ready() -> void:
	ui.visible = false
	

func _process(delta: float) -> void:
	if collision_layer & 1 == 0:
		return
		
	if ui.visible == true:
		var parent_pos : Vector2 = get_viewport().get_camera_3d().unproject_position(self.transform.origin)
		ui.position = parent_pos
		
	if cur_in <= 0:
		return
		
	cur_time += delta
	var sec_per_prod = 1.0 / prod_per_sec
	while cur_time > sec_per_prod and cur_in > 0 and cur_out != max_hold:
		cur_out = cur_out + 1
		cur_in = cur_in - 1
		cur_time -= sec_per_prod


func _unhandled_key_input(event: InputEvent) -> void:
	if event.keycode == KEY_R and not event.is_pressed() and ui.visible == true:
		if cur_out > 0:
			Events.emit_signal("OnPickup", "iron ingot", cur_out)
			cur_out = 0
		else:
			Events.emit_signal("OnInsertItems", "iron ore", self, "Insert_Callback")
	
func Insert_Callback(name : String, count : int) -> int:
	var prev = cur_in
	cur_in = min(max_hold, cur_in + count)
	return cur_in - prev

func _on_UIInteraction_body_entered(body: Node) -> void:
	ui.visible = true
	var parent_pos : Vector2 = get_viewport().get_camera_3d().unproject_position(self.transform.origin)
	ui.position = parent_pos


func _on_UIInteraction_body_exited(body: Node) -> void:
	ui.visible = false
