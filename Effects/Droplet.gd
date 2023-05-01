extends RigidBody2D
onready var anim = $AnimatedSprite


func disperse(_body):
	anim.play("disperse")
	yield(anim, "animation_finished")
	self.call_deferred("queue_free")

func _ready():
	var _ignore = self.connect("body_entered", self, "disperse")
