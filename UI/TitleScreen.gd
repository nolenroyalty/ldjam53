extends Node2D
onready var disable_tutorials = $CenterContainer2/Control/DisableTutorials
onready var transition_rect = $SceneTransitionRect
var mouse_in_disable_tutorials_area = false
var dropletInstance = preload("res://Effects/Droplet.tscn")

func _ready():
	if State.disable_tutorials:
		disable_tutorials.frame = 1
	spawn_droplets_forever()

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		if mouse_in_disable_tutorials_area:
			State.disable_tutorials = not State.disable_tutorials
			if State.disable_tutorials:
				disable_tutorials.frame = 1
			else:
				disable_tutorials.frame = 0

func _on_Area2D_mouse_entered():
	mouse_in_disable_tutorials_area = true

func _on_Area2D_mouse_exited():
	mouse_in_disable_tutorials_area = false

func _on_TextureButton_pressed():
	print("start game")
	transition_rect.transition_to("res://LevelRunner.tscn")
	# get_tree().change_scene("res://LevelRunner.tscn")

func spawn_droplets_forever():
	while true:
		var droplet = dropletInstance.instance()
		droplet.position = $DropletSpawnLocation.position
		droplet.z_index = 1
		add_child(droplet)
		yield(get_tree().create_timer(4.5), "timeout")
