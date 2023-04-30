extends KinematicBody2D

enum S { FROZEN, MOVING }

const GRAVITY = 9.8
const MAX_GRAVITY = 200
const X_SPEED_GAIN = 2
const BONK_CUTOFF = 5

# onready var bottom = $Bottom

var state = S.FROZEN
var velocity = Vector2.ZERO

func stop_moving():
	state = S.FROZEN
	velocity = Vector2.ZERO

func start_moving():
	state = S.MOVING

func _physics_process(_delta):
	match state:
		S.FROZEN: return
		S.MOVING:
			if velocity.y > 0:
				print("gaining")
				if velocity.x > 0: velocity.x += X_SPEED_GAIN
				else: velocity.x -= X_SPEED_GAIN
				
			velocity.y += GRAVITY
			if velocity.y > MAX_GRAVITY:
				print("maxxed")
				velocity.y = MAX_GRAVITY
			velocity = move_and_slide(velocity)

func bottom_bonked(_body):
	var proposed_new_velocity = velocity * -0.3
	if abs(proposed_new_velocity.y) < BONK_CUTOFF:
		proposed_new_velocity.y = 0
	if abs(proposed_new_velocity.x) < BONK_CUTOFF:
		proposed_new_velocity.x = 0
	if proposed_new_velocity == Vector2.ZERO:
		stop_moving()
	else:
		velocity = proposed_new_velocity

# Called when the node enters the scene tree for the first time.
func _ready():
	# var _ignore = $Bottom.connect("body_entered", self, "bottom_bonked")
	pass