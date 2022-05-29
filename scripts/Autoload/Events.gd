extends Node

signal OnObjectCreated(data)

signal OnPlaceToggle(name)
signal OnDoPlacement()


### UI STUFF ###
signal OnGUILoaded(name, obj)
signal OnPushGUI(name, init_param, transition_name)
signal OnPopGUI()
signal OnShowGUI(name, init_param, transition) # will not add the menu on the stack
signal OnHideGUI(name)
