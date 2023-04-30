extends RigidBody2D

onready var carriage = $Carriage
onready var string_detector = $StringDetector
var in_string = false

# onready var slider = $Slider

func stop_moving():
	carriage.mode = RigidBody2D.MODE_STATIC
	mode = RigidBody2D.MODE_STATIC

func start_moving():
	carriage.mode = RigidBody2D.MODE_RIGID
	mode = RigidBody2D.MODE_RIGID

func bump_up():
	print("Bucket may be intersecting string - bumping up")
	# carriage.mode = RigidBody2D.MODE_STATIC
	# mode = RigidBody2D.MODE_STATIC
	# carriage.position.y -= 1
	position.y -= 1
	# carriage.mode = RigidBody2D.MODE_RIGID
	# mode = RigidBody2D.MODE_RIGID

func string_entered(_body): in_string = true
func string_exited(_body): in_string = false

func _physics_process(_delta):
	if mode == RigidBody2D.MODE_RIGID and in_string: bump_up()

func _ready():
	stop_moving()
	var _ignore = string_detector.connect("body_entered", self, "string_entered")
	_ignore = string_detector.connect("body_exited", self, "string_exited")
