extends Node2D

var fixed_latch_points = []
onready var static_body = $StaticBody2D
onready var line = $StaticBody2D/Line2D

func _ready():
	init_fixed_latchpoints()

func init_fixed_latchpoints():
	for child in get_children():
		if child.is_in_group("fixed_latchpoint"):
			fixed_latch_points.append(child.position)

	render_line(fixed_latch_points)

func render_line(points):
	points.sort_custom(SortByX, "sort")

	# Maybe this could be smart about keeping most of the polygons?
	for child in static_body.get_children():
		if child is CollisionPolygon2D:
			child.call_deferred("queue_free")
			# child.queue_free()

	line.points = points
	# Store the line's global position so we can reset its position after moving its parent
	var line_global_position = line.global_position
	# Generate collision polygons from the Line2D node
	var line_poly = Geometry.offset_polyline_2d(line.points, line.width / 2, Geometry.JOIN_ROUND, Geometry.END_ROUND)
	# Move the rigidbody to the center of the line, taking into account
	# any offset the Polygon2D node may have relative to the rigidbody
	var line_center = get_line_center()
	# static_line.set_deferred("global_position", static_line.global_position + line_center + line_points.position)
	static_body.global_position += line_center + line.position
	# Move the line node to its original position
	# line_points.set_deferred("global_position", line_global_position)
	line.global_position = line_global_position

	# line_poly may contain multiple polygons, so iterate over it
	for poly in line_poly:
		var collision_shape = CollisionPolygon2D.new()
		collision_shape.polygon = offset_line_points(line_center, poly)
		# static_line.call_deferred("add_child", collision_shape)
		static_body.add_child(collision_shape)

# A simple weighted average of all points of the Line2D to find the center
func get_line_center() -> Vector2:
	var center_weight = line.points.size()
	var center = Vector2(0, 0)
	
	for point in line.points:
		center.x += point.x / center_weight
		center.y += point.y / center_weight
	
	return center

# Offset the points of the polygon by the center of the line
func offset_line_points(center: Vector2, poly: Array) -> Array:
	var adjusted_points = []
	for point in poly:
		# Moving the collision shape itself doesn't seem to work as well as offsetting the polygon points
		# for putting the collision shape in the right position after moving the rigidbody.
		# Therefore, to have the collision shape appear where drawn, subtract the polygon center from each point
		# to move the point by the amount the rigidbody was moved relative to the original Line2D's position.
		adjusted_points.append(point - center)
	return adjusted_points

func line_length(points) -> int:
	var initial_point = points[0]
	var length = 0
	for idx in range(1, points.size()):
		var point = points[idx]
		length += initial_point.distance_to(point)
		initial_point = point
	return length

class SortByX:
	static func sort(a, b):
		return a.x < b.x
