extends ColorRect

onready var anim : AnimationPlayer = $AnimationPlayer

func _ready():
	anim.play_backwards("fade")

func transition_to(next_scene : String):
	anim.play("fade")
	yield(anim, "animation_finished")
	var _ignore = get_tree().change_scene(next_scene)	
