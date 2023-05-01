extends Node2D
# Lord forgive me for the boolean setting in this file

var endScreen = preload("res://UI/EndScreen.tscn")
onready var tutorials = $Tutorials

var levels = [ preload("res://Levels/Level1.tscn"),
			   preload("res://Levels/LevelCaveEnter.tscn"),
			   preload("res://Levels/LevelCave1.tscn"),
			   preload("res://Levels/LevelCaveFireJump.tscn"),
			   preload("res://Levels/LevelIntoHole.tscn") ]
var level_index = 0
var current_level = null

func end_game():
	var end_screen = endScreen.instance()
	add_child(end_screen)
	State.should_tick = false

func handle_won_game():
	print("Game won!")
	end_game()

func handle_out_of_ice():
	print("Out of ice!")
	end_game()

func handle_completed_level() -> void:
	if State.disable_tutorials == false:
		if tutorials.state == tutorials.S.FINISH:
			State.disable_tutorials = true
			tutorials.finished = true
			tutorials.call_deferred("queue_free")
		else:
			# Jesus this code is bad
			var can_launch = current_level.can_launch
			var can_restart = current_level.can_restart
			var can_build = current_level.can_build
			var can_delete = current_level.can_delete
			load_level(0)
			current_level.can_launch = can_launch
			current_level.can_restart = can_restart
			current_level.can_build = can_build
			current_level.can_delete = can_delete
			return
	else:
		level_index += 1

	if level_index >= levels.size():
		# Wrong, but useful for now
		level_index = 0
		handle_won_game()
	load_level(level_index)

func load_level(index) -> void:
	if current_level != null:
		current_level.call_deferred("queue_free")
	current_level = levels[index].instance()
	current_level.connect("level_completed", self, "handle_completed_level")

	if State.disable_tutorials == false:
		current_level.connect("launched", self, "handle_bucket_launched")
		current_level.connect("restart", self, "handle_restart")
		current_level.connect("tower_built", self, "handle_built_tower")
		current_level.connect("tower_built_at_same_spot", self, "handle_built_tower_at_same_spot")
		current_level.connect("tower_deleted", self, "handle_tower_deleted")
	else:
		current_level.can_launch = true
		current_level.can_restart = true
		current_level.can_build = true
		current_level.can_delete = true

	self.call_deferred("add_child", current_level)

func handle_bucket_launched():
	if State.disable_tutorials or tutorials.state != tutorials.S.LAUNCH: return
	tutorials.launched = true
	yield(get_tree().create_timer(2), "timeout")
	current_level.can_restart = true

func handle_restart():
	if State.disable_tutorials or tutorials.state != tutorials.S.RESTART: return
	tutorials.restarted = true
	yield(get_tree().create_timer(0.5), "timeout")
	current_level.can_build = true
	current_level.can_launch = false

func handle_built_tower():
	if State.disable_tutorials or tutorials.state != tutorials.S.BUILD_TOWER: return
	tutorials.built_tower = true

func handle_built_tower_at_same_spot():
	if State.disable_tutorials or tutorials.state != tutorials.S.CHANGE_TOWER: return
	tutorials.built_tower_at_same_spot = true
	current_level.can_delete = true

func handle_tower_deleted():
	if State.disable_tutorials or tutorials.state != tutorials.S.DELETE_TOWER: return
	tutorials.deleted_tower = true
	current_level.can_launch = true
	current_level.can_restart = true

func handle_tutorial_finished():
	State.disable_tutorials = true
	load_level(0)

func _ready() -> void:
	load_level(level_index)
	State.should_tick = true
	VisualServer.set_default_clear_color(Color("1b1b17"))

	if State.disable_tutorials:
		tutorials.call_deferred("queue_free")
	else:
		current_level.can_restart = false
		current_level.can_build = false
		current_level.can_delete = false
		tutorials.show()
	
	State.connect("out_of_ice", self, "handle_out_of_ice")

	
