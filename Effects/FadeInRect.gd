extends ColorRect
onready var anim = $AnimationPlayer
export var SET_SHOULD_TICK = true
signal faded_out

func fade_and_enable_ticking():
	anim.play("fadein")
	yield(anim, "animation_finished")
	if SET_SHOULD_TICK: State.should_tick = true

func fade_out():
	anim.play_backwards("fadein")
	if SET_SHOULD_TICK: State.should_tick = false
	yield(anim, "animation_finished")
	if SET_SHOULD_TICK: State.should_tick = true
	emit_signal("faded_out")

func _ready():
	if SET_SHOULD_TICK:	State.should_tick = false
	fade_and_enable_ticking()