extends KinematicBody2D

onready var string_location = $StringLocation

func get_string_location() -> Vector2:
	return string_location.global_position
