extends TooltipTrigger

@export_file("*.json") var ItemSrc: String
#@export var ItemSrc : FilePath

# Called when the node enters the scene tree for the first time.
func _ready():
	super._ready()
	TooltipObj = ItemSrc
	if ItemSrc.is_empty():
		return
	var item : Dictionary = Globals.LevelLoaderRef.load_json(ItemSrc)
	var icon : String = Globals.get_attrib(item, "icon", "")
	if not icon.is_empty():
		self.icon = load(icon)
	
