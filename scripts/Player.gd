extends KinematicBody2D

# animation state machine
var state_machine
var speed = 200
var velocity = Vector2()

var health = 100;
var type = ''

# Attack variables
var attack_cooldown_time = 500
var next_attack_time = 0
var min_damage = 7
var max_damage = 10
var crit_chance = 0.05
var rng = RandomNumberGenerator.new()


func _ready():
	rng.randomize()
	state_machine = $AnimationTree.get('parameters/playback')


# SETTERS

func set_damage(value):
	self.health -= value
	print('Damage!')
	if self.health <= 0:
		get_tree().get_root().get_node('Network').broadcast_death(self.name)
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
			var dmg = 0
			# Check if player can attack
			var now = OS.get_ticks_msec()

			if now >= next_attack_time:
				dmg = rng.randi_range(min_damage, max_damage)

				var crit = randf()
				if crit < crit_chance:
					print('CRITICAL')
				dmg *= 2

				if collision.position.x < self.position.x:
					$Sprite.flip_h = true

				state_machine.travel('attack')

				dmg = 45
				get_tree().get_root().get_node('Network')\
					.broadcast_attack(self.name, collision.collider.name, dmg)
				self.next_attack_time = now + attack_cooldown_time
