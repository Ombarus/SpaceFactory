extends Node

signal OnObjectCreated(data)
signal OnQueueCrafting(crafter_data, recipe_data)

signal OnPlaceToggle(name)
signal OnDoPlacement()

signal OnLockControl(locked)

### UI STUFF ###
signal OnGUILoaded(name, obj)
signal OnPushGUI(name, init_param, transition_name)
signal OnPopGUI()
signal OnShowGUI(name, init_param, transition) # will not add the menu on the stack
signal OnHideGUI(name)
