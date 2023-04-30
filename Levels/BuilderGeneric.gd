extends Node2D

signal level_completed

const GRAVITY = 9.8
const MAX_GRAVITY = 100
const GRID_SIZE = 16

var terrainRay = preload("res://Terrain/TerrainRay.tscn")
var dynamicPole = preload("res://Terrain/DynamicPole.tscn")

onready var static_body = $StaticBody2D
onready var line = $StaticBody2D/Line2D
onready var bucket = $Bucket

enum M { BUILDING, RUNNING, EXITING }

var mode = M.BUILDING
var fixed_latch_points = []
var bucket_velocity = Vector2.ZERO
var placed_towers = {}

func _ready():
	init_fixed_latchpoints()
	render_line_for_current_points()
	var _ignore = $Finish.connect("body_entered", self, "emit_level_completed")

func _physics_process(_delta):
	match mode:
		M.BUILDING: return
		M.RUNNING:
			bucket_velocity.y += GRAVITY
			bucket_velocity.y = min(bucket_velocity.y, MAX_GRAVITY)
			bucket_velocity = bucket.move_and_slide(bucket_velocity)
		M.EXITING: return

func render_line_for_current_points():
	var points = []
	for latchpoint in fixed_latch_points:
		points.append(latchpoint)
	for tower in placed_towers.values():
		points.append(tower.get_latchpoint())
	
	render_line(points)
	var bucket_position = determine_position_for_bucket(points)
	bucket.position = bucket_position

func enter_running_mode():
	mode = M.RUNNING

func process_building():
	if Input.is_action_just_pressed("ui_accept"):
		enter_running_mode()
		return

func snap_x_position_to_grid(pos):
	pos.x = int(pos.x / GRID_SIZE) * GRID_SIZE
	return pos

func snap_int_to_grid(i):
	return int(i / GRID_SIZE) * GRID_SIZE

func snap_to_grid(pos):
	return Vector2(snap_int_to_grid(pos.x), snap_int_to_grid(pos.y))

func can_build_tower(pos) -> bool:
	var latchpoint_location = apply_latchpoint_x_offset(pos)
	# Check that we're on solid ground
	if not we_are_over_solid_ground(latchpoint_location):
		return false
	
	# Check that we're not overlapping another fixed latch point
	for latchpoint in fixed_latch_points:
		# Shouldn't matter but you never know
		var snapped = apply_latchpoint_x_offset(snap_x_position_to_grid(latchpoint))
		if snapped.x == latchpoint_location.x:
			print("Can't build a tower if there's already a latchpoint present")
			return false
		
	return true
 
# We'll want to track the total number of tower blocks remaining
func try_to_remove_tower(pos):
	pos = snap_to_grid(pos)
	if pos.x in placed_towers:
		placed_towers[pos.x].queue_free()
		placed_towers.erase(pos.x)
		render_line_for_current_points()

func try_to_build_tower(pos):
	pos = snap_to_grid(pos)
	if can_build_tower(pos):
		if pos.x in placed_towers:
			placed_towers[pos.x].queue_free()
			placed_towers.erase(pos.x)
		if build_tower(pos):
			render_line_for_current_points()

func build_tower(pos):
	var pole = dynamicPole.instance()
	pole.position.x = pos.x
	
	var height = determine_pole_height(pos)
	if height == null:
		print("Received null height??")
		return false
	# Not clear to me why we need this -1 but I'm not debugging it at
	# 2 AM
	height -= 1

	pole.position.y = pos.y + height * GRID_SIZE
	pole.init(height)
	add_child(pole)
	print("build tower pos %s | height %s" % [pos, height])
	placed_towers[pos.x] = pole
	return true


func handle_building_event(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == BUTTON_LEFT:
			try_to_build_tower(event.position)
		elif event.button_index == BUTTON_RIGHT:
			try_to_remove_tower(event.position)

func _process(_delta):
	match mode:
		M.RUNNING: pass
		M.BUILDING: process_building()
		M.EXITING: pass

func _input(event):
	match mode:
		M.BUILDING: handle_building_event(event)
		M.RUNNING: pass
		M.EXITING: pass

func init_fixed_latchpoints():
	for child in get_children():
		if child.is_in_group("fixed_latchpoint"):
			fixed_latch_points.append(child.position)

func determine_position_for_bucket(points) -> Vector2:
	var closest_before = closest_point_before(points, bucket.position)
	var closest_after = closest_point_after(points, bucket.position)
	var slope = float(closest_after.y - closest_before.y) / (closest_after.x - closest_before.x)
	var y_position = closest_before.y + slope * (bucket.position.x - closest_before.x)
	return Vector2(bucket.position.x, y_position)
	
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

func we_are_over_solid_ground(position):
	var ray = terrainRay.instance()
	add_child(ray)
	ray.position = position
	ray.force_raycast_update()
	var collision = ray.get_collider()
	ray.queue_free()

	if collision == null:
		print("no collision? Probable bug")
		# Should never happen?
		return false

	var collision_point = ray.get_collision_point()
	if snap_int_to_grid(collision_point.y) != int(collision_point.y):
		# We're over a slant
		print("Can't build - over slant - start pos %s | collision point %s" % [position, collision_point])
		return false

	if int(collision_point.y / GRID_SIZE) * GRID_SIZE != int(collision_point.y):
		# We're over a slant
		print("Can't build - over slant - start pos %s | collision point %s" % [position, collision_point])
		return false
	return true

# Definite copy-pasted code here :/
func determine_pole_height(position):
	var ray = terrainRay.instance()
	add_child(ray)
	ray.position = position
	ray.force_raycast_update()
	var collision = ray.get_collider()
	ray.queue_free()

	if collision == null:
		print("Asked to determine pole height but there's no terrain to build on - this should never happen")
		return null
	
	var collision_point = ray.get_collision_point()
	var collision_y = snap_int_to_grid(collision_point.y)
	if int(collision_point.y) != collision_y:
		print("Asked to determine pole height but we aren't on solid ground - this should never happen")
		return null
	
	return (int(collision_y) - int(position.y)) / GRID_SIZE

func apply_latchpoint_x_offset(pos):
	return pos + Vector2(GRID_SIZE / 2, 0)

func emit_level_completed(_body):
	mode = M.EXITING
	print("level completed")
	emit_signal("level_completed")

class SortByX:
	static func sort(a, b):
		return a.x < b.x
