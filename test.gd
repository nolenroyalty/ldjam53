extends Node2D

# oroginal for static body mapping to line from
#  https://github.com/theshaggydev/the-shaggy-dev-projects/blob/main/projects/godot-3/line2d-physics/physics_line/rigid_physics_line.gd

onready var line = $Body/TestLine
onready var body = $Body
onready var flinger = $Flinger
onready var bucket = $Bucket

const FLING_BOUNCES = 20

# Add snapping
enum S { STATIC, SNAPPING, DRAGGING }
var mouse_within_line = false
var state = S.STATIC
var original_length = 0
var strech_allowed = 1.4
var fling_speed = 1000
var turn_around_when_this_close_to_fling_target = 0.1
var initial_position_of_bouncing_point = null
var position_of_bouncing_point = null
var original_points = []
var fling_target = Vector2()
var mouse_click_position = Vector2()
var number_of_fling_bounces = 0
	
func add_bucket_to_points(points_without_bucket) -> Array:
	var idx = 0
	var points = []
	for i in range(len(points_without_bucket)):
		if points_without_bucket[i].x < bucket.global_position.x:
			points.append(points_without_bucket[i])
			idx += 1
		else: break

	var closest_before = points[-1]
	var closest_after = points_without_bucket[idx]
	var slope = (closest_after.y - closest_before.y) / (closest_after.x - closest_before.x)
	var default_y = closest_before.y + (bucket.global_position.x - closest_before.x) * slope
	
	# Revisit this
	match state:
		S.STATIC:
			bucket.global_position.y = default_y + 50
		S.DRAGGING:
			bucket.global_position.y = default_y + 25
		S.SNAPPING:
			bucket.global_position.y = default_y + 35
	points.append(bucket.global_position)

	while idx < len(points_without_bucket):
		points.append(points_without_bucket[idx])
		idx += 1
	return points

func _physics_process(delta):
	if Input.is_action_just_pressed("click") and mouse_within_line:
		print("begin dragging")
		state = S.DRAGGING
		mouse_click_position = get_mouse_position()
		number_of_fling_bounces = 0
	if Input.is_action_just_released("click") and state == S.DRAGGING:
		print("begin snapping")
		state = S.SNAPPING
		number_of_fling_bounces = 0
		
	# This doesn't go here.
	bucket.move_and_slide(Vector2(0, 200))

	match state:
		S.STATIC:
			var points = add_bucket_to_points(original_points)
			render_line(points)
		S.DRAGGING:
			var mouse_position = get_mouse_position()
			var points_before_after = determine_points_before_and_after(original_points, mouse_position)
			var points_before = points_before_after[0]
			var points_after = points_before_after[1]
			var maximum_allowed_distance = original_length * strech_allowed
			var attempted_points = points_before + [mouse_position] + points_after
			var attempted_length = line_length(attempted_points)
			if attempted_length <= maximum_allowed_distance:
				var points = add_bucket_to_points(attempted_points)
				fling_target = determine_fling_target(mouse_position, points)
				flinger.position = fling_target
				initial_position_of_bouncing_point = mouse_position
				position_of_bouncing_point = initial_position_of_bouncing_point
				render_line(points)
		S.SNAPPING:
			position_of_bouncing_point = position_of_bouncing_point.move_toward(fling_target, fling_speed * delta)
			var points_before_after = determine_points_before_and_after(original_points, position_of_bouncing_point)
			var points_before = points_before_after[0]
			var points_after = points_before_after[1]
			var points = add_bucket_to_points(points_before + [position_of_bouncing_point] + points_after)
			render_line(points)

			var distance_until_fling_target = (position_of_bouncing_point - fling_target).length()
			var original_distance = (initial_position_of_bouncing_point - fling_target).length()								

			if distance_until_fling_target < turn_around_when_this_close_to_fling_target * original_distance:
				print("turning around %s %s %s %s" % [distance_until_fling_target, turn_around_when_this_close_to_fling_target, original_distance, fling_target])
				fling_target = determine_fling_target(position_of_bouncing_point, add_bucket_to_points(original_points))
				initial_position_of_bouncing_point = position_of_bouncing_point
				number_of_fling_bounces += 1
				if number_of_fling_bounces >= FLING_BOUNCES:
					state = S.STATIC
					print("done flinging")

func determine_fling_target(position, points) -> Vector2:
	var closest_before = closest_point_before(points, position)
	var closest_after = closest_point_after(points, position)
	var vector_to_point_after = closest_after - position
	var reduce_by = float(FLING_BOUNCES - number_of_fling_bounces) / FLING_BOUNCES
	return closest_before + vector_to_point_after * reduce_by

func clear_current_polygons():
	# Maybe this could be smart about keeping most of the polygons?
	for child in body.get_children():
		if child is CollisionPolygon2D:
			child.queue_free()

func render_line(points):
	clear_current_polygons()
	line.points = points
	# Store the line's global position so we can reset its position after moving its parent
	var line_global_position = line.global_position
	# Generate collision polygons from the Line2D node
	var line_poly = Geometry.offset_polyline_2d(line.points, line.width / 2, Geometry.JOIN_ROUND, Geometry.END_ROUND)
	# Move the rigidbody to the center of the line, taking into account
	# any offset the Polygon2D node may have relative to the rigidbody
	var line_center = get_line_center()
	body.global_position += line_center + line.position
	# Move the line node to its original position
	line.global_position = line_global_position

	# line_poly may contain multiple polygons, so iterate over it
	for poly in line_poly:
		var collision_shape = CollisionPolygon2D.new()
		collision_shape.polygon = offset_line_points(line_center, poly)
		body.add_child(collision_shape)
		

func _ready():
	# Connect the mouse enter and exit signals to the appropriate functions
	body.connect("mouse_entered", self, "handle_mouse_entered")
	body.connect("mouse_exited", self, "handle_mouse_exited")

	original_points = line.points
	original_length = line_length(line.points)
	render_line(original_points)

func handle_mouse_entered():
	print("mouse within line")
	mouse_within_line = true

func handle_mouse_exited():
	mouse_within_line = false

func get_mouse_position() -> Vector2:
	return get_viewport().get_mouse_position()

func closest_point_before(points, point):
	var closest = points[0]
	for p in points:
		if p.x < point.x:
			closest = p
		else:
			return closest

func closest_point_after(points, point):
	for p in points:
		if p.x > point.x:
			return p

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

# A simple weighted average of all points of the Line2D to find the center
func get_line_center() -> Vector2:
	var center_weight = line.points.size()
	var center = Vector2(0, 0)
	
	for point in line.points:
		center.x += point.x / center_weight
		center.y += point.y / center_weight
	
	return center

func determine_points_before_and_after(points, pos) -> Array:
	var points_before = []
	var points_after = []
	for point in points:
		if point.x < pos.x:
			points_before.append(point)
		else:
			points_after.append(point)
	return [points_before, points_after]

func line_length(points) -> int:
	var initial_point = points[0]
	var length = 0
	for idx in range(1, points.size()):
		var point = points[idx]
		length += initial_point.distance_to(point)
		initial_point = point
	return length
