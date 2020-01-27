extends KinematicBody2D

var health

func _ready():
	self.health = 100
	pass

func take_damage(value):
	print(self.health)
	self.health -= value
	if self.health <= 0:
		queue_free()