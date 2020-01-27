extends KinematicBody2D

# animation state machine
var state_machine
var speed = 200
var velocity = Vector2()

# Attack variables
var attack_cooldown_time = 500
var next_attack_time = 0
var attack_damage = 10

func check_flip_sprite():
	if velocity.x < 0:
		$Sprite.flip_h = true
	else:
		$Sprite.flip_h = false

func do_attack(target):
	# Check if player can attack
	var now = OS.get_ticks_msec()
	if now >= next_attack_time:
		state_machine.travel('attack')
		target.take_damage(self.attack_damage)
		# Add cooldown time to current time
		next_attack_time = now + attack_cooldown_time

# warning-ignore:unused_argument
func _input(event):
	var mouse_pos = get_global_mouse_position()
	
	if Input.is_mouse_button_pressed(BUTTON_LEFT):
		velocity = (mouse_pos - transform.get_origin())
	else:
		velocity = Vector2.ZERO

	velocity = velocity.normalized() * speed
	
	check_flip_sprite()
	
	if velocity == Vector2.ZERO:
		state_machine.travel('idle')
	else:
		state_machine.travel('walk')

func _ready():
	state_machine = $AnimationTree.get('parameters/playback')
	pass
	
func _physics_process(delta):
	var collision = move_and_collide(velocity * delta)
	if collision:
		var collider_name = collision.collider.name.to_lower()
		if not 'player' in collider_name:
			self.do_attack(collision.collider)
