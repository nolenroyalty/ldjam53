extends CanvasLayer

onready var ice_bar = $IceBar 
onready var ice_bar_label = $IceBar/Label

var starting_bar_width = 0

func update_for_current_ice(ice):
	var ice_percent = ice / float(State.STARTING_ICE)
	var new_bar_width = int(starting_bar_width * ice_percent)
	ice_bar.rect_size.x = new_bar_width
	ice_bar_label.text = "%s%% ice remaining" % int(ice_percent * 100)

func _ready():
	starting_bar_width = ice_bar.rect_size.x
	update_for_current_ice(State.ice_remaining)
	var _ignore = State.connect("ice_updated", self, "update_for_current_ice")
