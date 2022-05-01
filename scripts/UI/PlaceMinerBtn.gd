extends Button

func _ready() -> void:
	Events.connect("OnPlaceToggle", self, "OnPlaceToggle_Callback")

func OnPlaceToggle_Callback(name):
	if name != "miner":
		self.pressed = false
	if name.empty():
		$"..".visible = true

func _on_PlaceMinerBtn_toggled(button_pressed: bool) -> void:
	if button_pressed:
		Events.emit_signal("OnPlaceToggle", "miner")
		$"..".visible = false
