extends "res://scripts/UI/DialogBase.gd"

func Init(init_param):
	pass
	


func _on_Button_pressed() -> void:
	Events.emit_signal("OnPopGUI")
