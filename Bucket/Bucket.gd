extends RigidBody2D

var dropletInstance = preload("res://Effects/Droplet.tscn")

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
	yield(get_tree().create_timer(0.9), "timeout")
	can_play_sound = true

func collided(body):
	if body.collision_layer == 2 and can_play_sound and not body.is_in_group("droplet"):
		print(body)
		can_play_sound = false
		audio.stream = sound
		# audio.volume_db = -10.0
		audio.play()
		reset_play_sound_state()

func maybe_spawn_droplet(percent_ice_remaining):
	if percent_ice_remaining % 5 == 0:
		var droplet = dropletInstance.instance()
		droplet.global_position = $DropletSpawnPoint.global_position
		get_parent().add_child(droplet)

func _ready():
	stop_moving()
	var _ignore = string_detector.connect("body_entered", self, "string_entered")
	_ignore = string_detector.connect("body_exited", self, "string_exited")
	_ignore = carriage.connect("body_entered", self, "collided")
	_ignore = self.connect("body_entered", self, "collided")
	_ignore = State.connect("ice_updated", self, "maybe_spawn_droplet")
