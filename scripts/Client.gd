extends Node2D

const server_addr = '127.0.0.1'
const server_port = 5000

var players = []
var player = load('res://scenes/Player.tscn')

# Attack variables
var attack_cooldown_time = 500
var next_attack_time = 0
var min_damage = 7
var max_damage = 10
var crit_chance = 0.05
var rng = RandomNumberGenerator.new()

func _input(event):
	var mouse_pos = get_global_mouse_position()
	var velocity = Vector2.ZERO
	var uid = get_tree().get_network_unique_id()
	var player_node = get_tree().get_root().get_node(str(uid))

	if Input.is_mouse_button_pressed(BUTTON_LEFT):
		velocity = (mouse_pos - player_node.transform.get_origin())

	velocity = velocity.normalized()
	
	player_node.set_velocity(velocity)
	signal_movement(uid, velocity)


func _ready():
	rng.randomize()
	self.set_process_input(true)
	# create and connect client to server
	var client = NetworkedMultiplayerENet.new()
	client.create_client(self.server_addr, self.server_port)
	get_tree().set_network_peer(client)


remote func register_player(id, x, y):
	print('registering player ', str(id))

	players.append(id)
	# set player name to its unique ID
	var new_player = player.instance()
	new_player.set_name(str(id))
	new_player.position = Vector2(x, y)
	new_player.set_network_master(1)
	
	if id == get_tree().get_network_unique_id():
		new_player.set_type('player')
	else:
		new_player.set_type('enemy')

	# add node to root
	get_tree().get_root().add_child(new_player)


remote func unregister_player(id):
	# search and remove disconnected player node
	var index = players.find(id)
	if index > -1:
		players.remove(index)
	get_tree().get_root().get_node(str(id)).queue_free()

# SIGNALS AND RPC CALLS

# send RPC to tell player has moved and set its position
func signal_movement(id, vel):
	if id != 1:
		rpc('move_player', id, vel)


# set player position
remote func move_player(id, vel):
	var player_node = get_tree().get_root().get_node(str(id))
	player_node.set_velocity(vel)


func signal_death(player):
	rpc('kill_player', player)


remote func kill_player(player):
	get_tree().get_root().get_node(str(player)).queue_free()


func signal_attack(attacker_id, target_id):
	# Check if player can attack
	var now = OS.get_ticks_msec()
	
	if now >= next_attack_time:
		rpc('attack_player', attacker_id, target_id)
		# Add cooldown time to current time
		next_attack_time = now + attack_cooldown_time


remote func attack_player(attacker_id, target_id):
	var target_node = get_tree().get_root().get_node(str(target_id))
	var attacker_node = get_tree().get_root().get_node(str(attacker_id))
	attacker_node.state_machine.travel('attack')
	var dmg_range = max_damage - min_damage
	var dmg = rng.randi_range(min_damage, max_damage)
	
	var crit = randf()
	if crit < crit_chance:
		print('CRITICAL')
		dmg *= 2
	
	target_node.set_damage(dmg)