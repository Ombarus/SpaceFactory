extends Node


var _gui_list := {}
var _stack := []

func _ready():
	Events.connect("OnGUILoaded",Callable(self,"OnGUILoaded_Callback"))
	Events.connect("OnPushGUI",Callable(self,"OnPushGUI_Callback"))
	Events.connect("OnPopGUI",Callable(self,"OnPopGUI_Callback"))
	Events.connect("OnShowGUI",Callable(self,"OnShowGUI_Callback"))
	Events.connect("OnHideGUI",Callable(self,"OnHideGUI_Callback"))
	

func OnShowGUI_Callback(name, init_param, transition=""):
	_gui_list[name].visible = true
	_gui_list[name].Init(init_param)
	
	
func OnHideGUI_Callback(name):
	if name in _gui_list:
		_gui_list[name].visible = false
		

func OnGUILoaded_Callback(name, obj):
	# prevent adding duplicate that we create temporary for vfx
	if name in _gui_list:
		return
		
	_gui_list[name] = obj
	obj.visible = false
	
	# Default
	if name == "HUD":
		Events.emit_signal("OnPushGUI", name, {})
	
	
func OnPushGUI_Callback(name, init_param, transition_name=""):
	#TODO: make sure Layout is not already in stack
	#print("Push " + name)
		
	_gui_list[name].Init(init_param)
	if _stack.size() > 0:
		_gui_list[_stack[-1]].call_deferred("OnFocusLost")
	_stack.push_back(name)
		
	#print("visible true " + name)
	_gui_list[name].visible = true
	
func OnPopGUI_Callback():
	#print("Pop " + _stack[-1])
	var gui_name = _stack[-1]
	_stack.pop_back()
	if _stack.size() > 0:
		_gui_list[_stack[-1]].call_deferred("OnFocusGained")
	
	#print ("visible false " + gui_name)
	_gui_list[gui_name].visible = false
		
