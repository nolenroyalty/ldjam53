extends Node2D
# LORD FORGIVE ME FOR THE BOOLEAN SETTING IN THIS FILE
# IT WAS 4:30 IN THE MORNING AND I WANTED TO SLEEP

var endScreen = preload("res://UI/EndScreen.tscn")
onready var tutorials = $Tutorials
onready var transition_anim = $Transition/TransitionAnimator

var levels = [ preload("res://Levels/Level1.tscn"),
			   preload("res://Levels/LevelCaveEnter.tscn"),
			   preload("res://Levels/LevelCave1.tscn"),
			   preload("res://Levels/LevelCave2.tscn"),
			   preload("res://Levels/LevelCaveFireJump.tscn"),
			   preload("res://Levels/LevelIntoHole.tscn"),
			   preload("res://Levels/LevelMomentum.tscn") ]
var level_index = 0
var current_level = null
var level_completed = false

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

func handle_completed_tutorial() -> void:
	if tutorials.state == tutorials.S.FINISH:
		State.disable_tutorials = true
		tutorials.finished = true
		tutorials.call_deferred("queue_free")
		# We can actually complete the level
		State.reset_start_time()
		handle_completed_level(true)
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

func handle_completed_level(increment_level=true) -> void:
	if level_completed: return
	if State.disable_tutorials == false:
		handle_completed_tutorial()
	else:
		if increment_level: level_index += 1
		level_completed = true
		if level_index >= levels.size():
			# level_index = 0
			handle_won_game()
		else:
			State.should_tick = false
			load_level(level_index)
			level_completed = false

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
	VisualServer.set_default_clear_color(Color("1b1b17"))
	transition_anim.play("fade_in_from_black")
	if State.disable_tutorials: level_index = 1

	load_level(level_index)
	State.should_tick = true
	State.reset_start_time()

	if State.disable_tutorials:
		tutorials.call_deferred("queue_free")
	else:
		current_level.can_restart = false
		current_level.can_build = false
		current_level.can_delete = false
		tutorials.show()
	
	State.connect("out_of_ice", self, "handle_out_of_ice")

	
