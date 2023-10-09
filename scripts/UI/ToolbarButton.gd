extends TooltipTrigger

@export_file("*.json") var ItemSrc: String
#@export var ItemSrc : FilePath

# Called when the node enters the scene tree for the first time.
func _ready():
	super._ready()
	TooltipObj = ItemSrc
