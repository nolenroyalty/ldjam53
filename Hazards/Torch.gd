extends AnimatedSprite
signal hazard_hit(ice_damage_percent)
onready var flame_area = $FlameArea
onready var audio = $AudioStreamPlayer2D
var sound = preload("res://Sounds/fire2.wav")
var ice_damage_percent = 5

func handle_bucket_hit_flame(body):
	if not body.is_in_group("can_be_hurt_by_hazard"):
		return

	emit_signal("hazard_hit", ice_damage_percent)
	audio.stream = sound
	audio.volume_db = -20.0
	audio.play() 

func _ready():
	flame_area.connect("body_entered", self, "handle_bucket_hit_flame")
