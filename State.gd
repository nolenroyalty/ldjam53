extends Node

signal ice_updated(ice_remaining)
signal towers_used_updated(towers_used)
signal out_of_ice()

const STARTING_ICE = 100
const MELT_RATE = 1
const MELT_EVERY_N_SECONDS = 120.0 / 100.0

var ice_remaining = STARTING_ICE setget set_ice_remaining
var start_time = null
var should_tick = false
var towers_used = 0 setget set_towers_used
var disable_tutorials = true

func set_ice_remaining(value):
	var was_already_zero = ice_remaining == 0
	ice_remaining = value
	if ice_remaining < 0:
		ice_remaining = 0

	var percent_ice_remaining = int((float(ice_remaining) / STARTING_ICE) * 100)
	emit_signal("ice_updated", percent_ice_remaining)
	if ice_remaining == 0 and not was_already_zero:
		emit_signal("out_of_ice")
	
func deduct_ice(amount):
	set_ice_remaining(ice_remaining - amount)

func set_towers_used(amount):
	towers_used = amount
	emit_signal("towers_used_updated", towers_used)

func add_towers_used(amount):
	set_towers_used(towers_used + amount)

func _ready():
	start_time = OS.get_unix_time()
	tick_forever()

func tick_forever():
	while true:
		yield(get_tree().create_timer(MELT_EVERY_N_SECONDS), "timeout")
		if should_tick and disable_tutorials == true: deduct_ice(MELT_RATE)

func time_elapsed():
	return OS.get_unix_time() - start_time