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
		$ColorRect.color = Color("#575647")


	ice_remaining.text = "Ice Remaining: %d%%" % int( 100 * float(State.ice_remaining) / State.STARTING_ICE)
	total_time.text = "Total Time: %d seconds" % int(State.time_elapsed())
	$TowersUsed.text = "Towers Used: %d" % State.towers_used

func _on_TextureButton_pressed():
	print("resetting")
	State.should_tick = false
	State.disable_tutorials = true
	State.ice_remaining = State.STARTING_ICE
	State.towers_used = 0
	get_tree().change_scene("res://UI/TitleScreen.tscn")