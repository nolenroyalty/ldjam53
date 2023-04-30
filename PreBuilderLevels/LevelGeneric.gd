extends Node2D

signal level_completed

func get_fixed_points():
	var fixed_points = []
	for point in $Points.get_children():
		fixed_points.append(point.position)
	return fixed_points

func get_and_hide_bucket_position():
	var bucket_position = $Bucket.position
	$Bucket.queue_free()
	return bucket_position

func handle_body_entered(_body):
	emit_signal("level_completed")

func get_hazards():
	var hazards = []
	for node in get_children():
		if node.is_in_group("hazards"):
			hazards.append(node)
	return hazards

func _ready():
	var _ignore = $WinArea.connect("body_entered", self, "handle_body_entered")
