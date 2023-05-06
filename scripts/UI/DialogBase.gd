extends Control

@export var Transition : bool = false
@export var VFXRoot: NodePath = "."
@export var LockControls : bool = false

@onready var _vfx_root = get_node(VFXRoot)

var VFXCopy : Node = null

func GetVFXRoot():
	return _vfx_root

func _ready():
	Events.emit_signal("OnGUILoaded", self.name, self)
	self.set_process_input(false)
	self.set_process_unhandled_input(false)
	self.mouse_filter = Control.MOUSE_FILTER_IGNORE

# overridable function for loading dialog content
func Init(init_param):
	pass
	
# UIManager will call this when something else is pushed on top of this UI
func OnFocusLost():
	if LockControls:
		Events.emit_signal("OnLockControl", LockControls)
	
# UIManager will call this when whatever was on top of this UI is poped
func OnFocusGained():
	if LockControls:
		Events.emit_signal("OnLockControl", not LockControls)
