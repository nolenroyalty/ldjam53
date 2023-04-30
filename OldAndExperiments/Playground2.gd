extends Node2D

onready var line = $StaticBody/TestLine
onready var static_body = $StaticBody
onready var bucket = $BucketNew

enum S { STATIC, DRAGGING }
const STRETCH_FACTOR = 1.3
const MAXIMUM_BUCKET_WEIGHT = 80
const MINIMUM_BUCKET_WEIGHT = 0
const GRAVITY_MAX = 50
const GRAVITY_DELTA = 4
const MAX_EXPECTED_DISTANCE = 400
const STICK_TO_MOUSE_WITHIN = 30
const MAXIMUM_SINGLE_FRAME_Y_MOVE = 1

var state = S.STATIC
var original_length = 0
var mouse_within_line = false
var original_points = []
var bucket_velocity = Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready():
	static_body.connect("mouse_entered", self, "handle_mouse_entered")
	static_body.connect("mouse_exited", self, "handle_mouse_exited")

	original_points = line.points
	original_length = line_length(line.points)

func add_bucket_to_points(points_without_bucket, mouse_position) -> Array:
	var points_before_and_after = partition_points_before_and_after(points_without_bucket, bucket.position)
	var points_before = points_before_and_after[0]
	var points_after = points_before_and_after[1]
	# TODO: handle the case that there are no points before or after
	var closest_before = points_before[-1]
	var closest_after = points_after[0]
	var slope = (closest_after.y - closest_before.y) / (closest_after.x - closest_before.x)
	var y_without_bucket_weight = closest_before.y + (bucket.position.x - closest_before.x) * slope

	if mouse_position and mouse_position.distance_to(bucket.position) < STICK_TO_MOUSE_WITHIN:
		pass
	else:
		var current_line_length = line_length(points_without_bucket)
		var maximum_line_length = line_length(original_points) * STRETCH_FACTOR
		var amount_of_stretch_allowed = maximum_line_length - current_line_length
		var max_bucket_weight = min(amount_of_stretch_allowed, MAXIMUM_BUCKET_WEIGHT)
		# bucket_weight = max(bucket_weight, MINIMUM_BUCKET_WEIGHT)

		var distance_to_before = bucket.position.distance_to(closest_before)
		var distance_to_after = bucket.position.distance_to(closest_after)
		var distance_total = min(distance_to_before + distance_to_after, MAX_EXPECTED_DISTANCE)
		var desired_bucket_weight = max_bucket_weight * float(distance_total) / MAX_EXPECTED_DISTANCE
		desired_bucket_weight = max(desired_bucket_weight, MINIMUM_BUCKET_WEIGHT)
		var desired_bucket_y = y_without_bucket_weight + desired_bucket_weight
		var desired_delta_y = desired_bucket_y - bucket.position.y

		if desired_delta_y > 0:
			var actual_delta_y = min(desired_delta_y, MAXIMUM_SINGLE_FRAME_Y_MOVE)
			bucket.position.y += actual_delta_y

	return points_before + [bucket.position] + points_after

func _physics_process(_delta):
	if Input.is_action_just_pressed("click") and mouse_within_line:
		state = S.DRAGGING
	
	bucket_velocity.y = min(bucket_velocity.y + GRAVITY_DELTA, GRAVITY_MAX)
	bucket_velocity = bucket.move_and_slide(bucket_velocity)

	match state:
		S.STATIC:
			var points = add_bucket_to_points(original_points, null)
			render_line(points)
		S.DRAGGING:
			var mouse_pos = get_viewport().get_mouse_position()
			var points_before_and_after = partition_points_before_and_after(original_points, mouse_pos)
			var points_before = points_before_and_after[0]
			var points_after = points_before_and_after[1]
			var proposed_points = points_before + [mouse_pos] + points_after
			var proposed_length = line_length(proposed_points)
			var allowed_length = original_length * STRETCH_FACTOR
			if proposed_length <= allowed_length:
				render_line(add_bucket_to_points(proposed_points, mouse_pos))
			else:
				pass
				# var distance_before = mouse_pos.distance_to(points_before[-1])
				# var distance_after = mouse_pos.distance_to(points_after[0])
				# var desired_distance = distance_before + distance_after
				# var allowed_distance = allowed_length - original_length

				# var allotted_length_before = float(distance_before) / desired_distance
				# var allotted_length_after = float(distance_after) / desired_distance
				# allotted_length_before *= float(allowed_distance) / desired_distance
				# allotted_length_after *= float(allowed_distance) / desired_distance

				# var inter = Geometry.line_intersects_line_2d(points_before[-1], 
				# allotted_length_before * (mouse_pos - points_before[-1]),
				#  points_after[0], 
				#  allotted_length_after * (mouse_pos - points_after[0]))

				# if inter:
				# 	var points = points_before + [inter] + points_after
				# 	render_line(add_bucket_to_points(points, mouse_pos))


func render_line(points):
	# Maybe this could be smart about keeping most of the polygons?
	for child in static_body.get_children():
		if child is CollisionPolygon2D:
			child.queue_free()

	line.points = points
	# Store the line's global position so we can reset its position after moving its parent
	var line_global_position = line.global_position
	# Generate collision polygons from the Line2D node
	var line_poly = Geometry.offset_polyline_2d(line.points, line.width / 2, Geometry.JOIN_ROUND, Geometry.END_ROUND)
	# Move the rigidbody to the center of the line, taking into account
	# any offset the Polygon2D node may have relative to the rigidbody
	var line_center = get_line_center()
	static_body.global_position += line_center + line.position
	# Move the line node to its original position
	line.global_position = line_global_position

	# line_poly may contain multiple polygons, so iterate over it
	for poly in line_poly:
		var collision_shape = CollisionPolygon2D.new()
		collision_shape.polygon = offset_line_points(line_center, poly)
		static_body.add_child(collision_shape)

func partition_points_before_and_after(points, pos) -> Array:
	var points_before = []
	var points_after = []
	for point in points:
		if point.x < pos.x:
			points_before.append(point)
		else:
			points_after.append(point)
	return [points_before, points_after]

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

# It'd be nice to get rid of these
func handle_mouse_entered():
	mouse_within_line = true

func handle_mouse_exited():
	mouse_within_line = false
