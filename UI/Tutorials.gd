extends CanvasLayer

signal finished

enum S { LAUNCH, RESTART, BUILD_TOWER, CHANGE_TOWER, DELETE_TOWER, FINISH }
var update_text = true
var state = S.LAUNCH
var launched = false
var restarted = false
var built_tower = false
var built_tower_at_same_spot = false
var deleted_tower = false
var finished = false

onready var label = $NinePatchRect/Label

func _process(_delta):
	if update_text == true:
		update_text = false
		match state:
			S.LAUNCH:
				label.text = "Your goal: deliver the ice bucket to the bottom of the mountain while it's still cold.\n\nPress Space to launch the bucket."
			S.RESTART:
				label.text = "Obstacles will stop the bucket.\n\nPress Space to move the bucket back to the start of the level."
			S.BUILD_TOWER:
				label.text = "Left click over flat ground to build a tower. Towers change the path of the bucket.\n\n(Build a tower to continue)"
			S.CHANGE_TOWER:
				label.text = "Left click above or below a tower to change its height.\n\n(Change your tower's height to continue)"
			S.DELETE_TOWER:
				label.text = "Right click to delete a tower.\n\n(Delete a tower to continue)"
			S.FINISH:
				pass
				# label.text = "Get the bucket to the bottom right of the screen to complete the level."
	
	if launched and state == S.LAUNCH:
		yield(get_tree().create_timer(2), "timeout")
		update_text = true
		state = S.RESTART
	
	if restarted and state == S.RESTART:
		yield(get_tree().create_timer(1), "timeout")
		update_text = true
		state = S.BUILD_TOWER
	
	if built_tower and state == S.BUILD_TOWER:
		# label.text = "Nice job! Now get the ice to the bottom right of the screen."
		update_text = true
		yield(get_tree().create_timer(1.0), "timeout")
		state = S.CHANGE_TOWER
	
	if built_tower_at_same_spot and state == S.CHANGE_TOWER:
		update_text = true
		yield(get_tree().create_timer(1.0), "timeout")
		state = S.DELETE_TOWER
	
	if deleted_tower and state == S.DELETE_TOWER:
		yield(get_tree().create_timer(1.0), "timeout")
		label.text = "Nice job! Now build towers, launch the ice bucket, and get the bucket to the bottom right of the screen.\n\nGood luck!"
		state = S.FINISH
	


