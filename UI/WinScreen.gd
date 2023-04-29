extends CanvasLayer

onready var ice_remaining = $IceRemaining
onready var total_time = $TotalTime
onready var title = $Title

func _ready():
	# This should have grades so that folks feel a desire to replay
	if State.ice_remaining > 0:
		title.text = "You Win!"
	else:
		title.text = "You Lose :("
		
	ice_remaining.text = "Ice Remaining: %d%%" % int( 100 * float(State.ice_remaining) / State.STARTING_ICE)
	total_time.text = "Total Time: %d seconds" % int(State.time_elapsed())
