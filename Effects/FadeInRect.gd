extends ColorRect
onready var anim = $AnimationPlayer
export var SET_SHOULD_TICK = true
export var FADE_OUT_NOT_IN = false
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
	if FADE_OUT_NOT_IN: fade_out()
	else: fade_and_enable_ticking()