extends Sprite

export var PENALTY = 35
var MAX_HAZARD_COUNTER = 60
var hazard_counter = 0
var is_hazarding = false

signal hazard_contact(penalty)

func handle_body_entered(_body):
	is_hazarding = true

func handle_body_exited(_body):
	is_hazarding = false
	hazard_counter = 0

func _physics_process(_delta):
	if is_hazarding:
		if hazard_counter == 0:
			emit_signal("hazard_contact", PENALTY)
		
		hazard_counter += 1
		
		if hazard_counter >= MAX_HAZARD_COUNTER:
			hazard_counter = 0

func _ready():
	var _ignore = $Area2D.connect("body_entered", self, "handle_body_entered")
	_ignore = $Area2D.connect("body_exited", self, "handle_body_exited")
