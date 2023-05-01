extends Node2D

var endScreen = preload("res://UI/EndScreen.tscn")

var levels = [ preload("res://Levels/Level1.tscn"),
			   preload("res://Levels/LevelCaveEnter.tscn"),
			   preload("res://Levels/LevelCave1.tscn") ]
var level_index = 2
var current_level = null

func handle_won_game():
	print("Game won!")
	var end_screen = endScreen.instance()
	add_child(end_screen)
	State.should_tick = false

func handle_completed_level() -> void:
	level_index += 1
	if level_index >= levels.size():
		# Wrong, but useful for now
		level_index = 0
		# handle_won_game()
	load_level(level_index)

func load_level(index) -> void:
	if current_level != null:
		current_level.call_deferred("queue_free")
	current_level = levels[index].instance()
	current_level.connect("level_completed", self, "handle_completed_level")
	self.call_deferred("add_child", current_level)

func _ready() -> void:
	load_level(level_index)
	State.should_tick = true
	VisualServer.set_default_clear_color(Color("1b1b17"))
