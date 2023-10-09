extends Control
class_name TooltipTrigger

var TooltipObj
var TooltipScene : PackedScene = preload("res://scenes/UI/Tooltip.tscn")
var active_tooltip : Control = null
var root : Node = null

func _ready():
	self.mouse_entered.connect(_on_mouse_entered)
	self.mouse_exited.connect(_on_mouse_exited)
	
func _on_mouse_entered():
	if not active_tooltip:
		var mouse_pos : Vector2 = self.get_global_mouse_position()
		if root == null:
			root = self.get_tree().root.find_child("TooltipRoot", true, false ) 
		active_tooltip = TooltipScene.instantiate()
		active_tooltip.size = Vector2(100.0, 100.0)
		active_tooltip.position = mouse_pos - Vector2(0.0, 100.0)
		root.add_child(active_tooltip)
		(active_tooltip as Tooltip).Init(TooltipObj)
	
func _on_mouse_exited():
	if active_tooltip:
		active_tooltip.queue_free()
