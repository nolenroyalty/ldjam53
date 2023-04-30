extends Node2D

onready var planning_site = $PlanningSite

func _ready():
	planning_site.hide()

func get_latchpoint():
	return global_position
