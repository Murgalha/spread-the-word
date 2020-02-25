extends KinematicBody2D

# animation state machine
var state_machine
var speed = 200
var velocity = Vector2()

var health = 100;
var type = ''


func _ready():
	state_machine = $AnimationTree.get('parameters/playback')


# SETTERS

func set_damage(value):
	self.health -= value
	print('Damage!')
	if self.health <= 0:
		get_tree().get_root().get_node('Network').signal_death(self.name)
		queue_free()


func set_velocity(vel):
	self.velocity = vel * speed


func set_type(type):
	self.type = type


func check_and_flip_sprite():
	if velocity.x < 0:
		$Sprite.flip_h = true
	elif velocity.x > 0:
		$Sprite.flip_h = false


func _physics_process(delta):
	check_and_flip_sprite()
	
	if self.velocity == Vector2.ZERO:
		state_machine.travel('idle')
	else:
		state_machine.travel('walk')
	
	var collision = move_and_collide(velocity * delta)

	if collision:
		var collider = collision.collider
		if collider.get('type') and\
		'enemy' in collider.get('type'):
			if collision.position.x < self.position.x:
				$Sprite.flip_h = true
			state_machine.travel('attack')
			print('attacking ', collider.name)
			get_tree().get_root().get_node('Network')\
			.signal_attack(self.name, collision.collider.name)