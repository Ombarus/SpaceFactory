extends Button

func _ready() -> void:
	Events.connect("OnPlaceToggle", self, "OnPlaceToggle_Callback")

func OnPlaceToggle_Callback(name):
	if name != "smelter":
		self.pressed = false
	if name.empty():
		$"..".visible = true

func _on_PlaceSmelterBtn_toggled(button_pressed: bool) -> void:
	if button_pressed:
		Events.emit_signal("OnPlaceToggle", "smelter")
		$"..".visible = false
