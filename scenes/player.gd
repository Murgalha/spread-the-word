extends KinematicBody2D

var speed = 200
var velocity = Vector2()
var is_moving = false

func _input(event):
	is_moving = false
	var mouse_pos = get_global_mouse_position()

	if Input.is_mouse_button_pressed(BUTTON_LEFT):
		velocity = (mouse_pos - transform.get_origin())
		is_moving = true
	else:
		velocity = Vector2()
		is_moving = false
		
	velocity = velocity.normalized() * speed

func _ready():
	pass
	
func _physics_process(delta):
	#var collision = move_and_collide(velocity * delta)
	velocity = move_and_slide(velocity)
	
	if is_moving:
		$Sprite/AnimationPlayer.play("walk")
	else:
		$Sprite/AnimationPlayer.play("idle")
