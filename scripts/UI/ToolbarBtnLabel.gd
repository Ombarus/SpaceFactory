@tool
extends Label

func _on_hotbar_renamed():
	var parent_name : String = self.get_parent().name
	self.text = parent_name.substr(parent_name.length() - 1, 1) + " "

func _ready():
	_on_hotbar_renamed()
