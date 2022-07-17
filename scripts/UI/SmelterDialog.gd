extends "res://scripts/UI/DialogBase.gd"

var player_data := {}
var building_data := {}

func Init(init_param):
	player_data = init_param["player_data"]
	building_data = init_param["buildling_data"]

func redraw():
	pass

func _on_Button_pressed() -> void:
	Events.emit_signal("OnPopGUI")
