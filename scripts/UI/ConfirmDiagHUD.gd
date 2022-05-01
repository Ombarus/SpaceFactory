extends Control


func _ready() -> void:
	Events.connect("OnPlaceToggle", self, "OnPlaceToggle_Callback")
	self.visible = false

func OnPlaceToggle_Callback(name: String) -> void:
	self.visible = not name.empty()


func _on_Ok_pressed() -> void:
	Events.emit_signal("OnDoPlacement")
	Events.emit_signal("OnPlaceToggle", "")
	self.visible = false


func _on_Cancel_pressed() -> void:
	Events.emit_signal("OnPlaceToggle", "")
	self.visible = false
