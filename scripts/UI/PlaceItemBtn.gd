extends Button

func _ready() -> void:
	Events.connect("OnPlaceToggle",Callable(self,"OnPlaceToggle_Callback"))

func OnPlaceToggle_Callback(name):
	if name != self.name:
		self.button_pressed = false
	if name.is_empty():
		$"..".visible = true

func _on_PlaceSmelterBtn_toggled(button_pressed: bool) -> void:
	if button_pressed:
		Events.emit_signal("OnPlaceToggle", self.name)
		$"..".visible = false
