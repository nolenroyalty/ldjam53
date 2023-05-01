extends RigidBody2D

onready var carriage = $Carriage
onready var string_detector = $StringDetector
onready var audio = $AudioStreamPlayer2D
var in_string = false
var sound = preload("res://Sounds/hit2.wav")
var can_play_sound = true

# onready var slider = $Slider

func stop_moving():
	carriage.mode = RigidBody2D.MODE_STATIC
	mode = RigidBody2D.MODE_STATIC

func start_moving():
	carriage.mode = RigidBody2D.MODE_RIGID
	mode = RigidBody2D.MODE_RIGID

func bump_up():
	print("Bucket may be intersecting string - bumping up")
	position.y -= 1


func string_entered(_body): in_string = true
func string_exited(_body): in_string = false

func _physics_process(_delta):
	if mode == RigidBody2D.MODE_RIGID and in_string: bump_up()

func reset_play_sound_state():
	yield(get_tree().create_timer(0.5), "timeout")
	can_play_sound = true

func collided(body):
	if body.collision_layer == 2 and can_play_sound:
		can_play_sound = false
		audio.stream = sound
		audio.volume_db = -10.0
		audio.play()
		reset_play_sound_state()

func _ready():
	stop_moving()
	var _ignore = string_detector.connect("body_entered", self, "string_entered")
	_ignore = string_detector.connect("body_exited", self, "string_exited")
	_ignore = carriage.connect("body_entered", self, "collided")
	_ignore = self.connect("body_entered", self, "collided")
