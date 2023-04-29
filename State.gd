extends Node

signal ice_updated(ice_remaining)
signal out_of_ice()

const STARTING_ICE = 100
var ice_remaining = STARTING_ICE setget set_ice_remaining

func set_ice_remaining(value):
	ice_remaining = value
	if ice_remaining < 0:
		ice_remaining = 0

	emit_signal("ice_updated", ice_remaining)
	if ice_remaining == 0:
		emit_signal("out_of_ice")
	
func deduct_ice(amount):
	set_ice_remaining(ice_remaining - amount)