extends StaticBody

export(float) var prod_per_sec := 0.5
export(int) var max_hold := 100
var cur_time := 0.0
var cur_hold := 0
onready var ui : Label = $PickupLabel

func _ready() -> void:
	ui.visible = false
	

func _process(delta: float) -> void:
	if collision_layer & 1 == 0:
		return
		
	cur_time += delta
	var sec_per_prod = 1.0 / prod_per_sec
	while cur_time > sec_per_prod:
		cur_hold = min(max_hold, cur_hold + 1)
		cur_time -= sec_per_prod

	if ui.visible == true:
		var parent_pos : Vector2 = get_viewport().get_camera().unproject_position(self.transform.origin)
		ui.rect_position = parent_pos

func _unhandled_key_input(event: InputEventKey) -> void:
	if event.scancode == KEY_R and not event.is_pressed() and ui.visible == true:
		Events.emit_signal("OnPickup", "iron ore", cur_hold)
		cur_hold = 0
		

func _on_UIInteraction_body_entered(body: Node) -> void:
	ui.visible = true
	var parent_pos : Vector2 = get_viewport().get_camera().unproject_position(self.transform.origin)
	ui.rect_position = parent_pos


func _on_UIInteraction_body_exited(body: Node) -> void:
	ui.visible = false
