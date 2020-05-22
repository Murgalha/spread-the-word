extends Node2D

const server_addr = '127.0.0.1'
const server_port = 5000

var players = []
var player = load('res://scenes/Player.tscn')


func _input(event):
	var mouse_pos = get_global_mouse_position()
	var velocity = Vector2.ZERO
	var uid = get_tree().get_network_unique_id()
	var player_node = get_tree().get_root().get_node(str(uid))

	if Input.is_mouse_button_pressed(BUTTON_LEFT):
		velocity = (mouse_pos - player_node.transform.get_origin())

	velocity = velocity.normalized()

	player_node.set_velocity(velocity)
	broadcast_movement(uid, velocity)


func _ready():
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


remotesync func unregister_player(id):
	# search and remove disconnected player node
	var index = players.find(id)
	if index > -1:
		players.remove(index)
	var node = get_tree().get_root().get_node(str(id))
	if node:
		node.queue_free()

	if int(id) == get_tree().get_network_unique_id():
		get_tree().network_peer = null
		for p_id in players:
			get_tree().get_root().get_node(str(p_id)).queue_free()
		get_tree().change_scene('res://scenes/GameOver.tscn')

# SIGNALS AND RPC CALLS

# send RPC to tell player has moved and set its position
func broadcast_movement(id, vel):
	if id == get_tree().get_network_unique_id():
		rpc('move_player', id, vel)


# set player position
remotesync func move_player(id, vel):
	var player_node = get_tree().get_root().get_node(str(id))
	if player_node:
		player_node.set_velocity(vel)


func broadcast_death(player):
	if int(player) == get_tree().get_network_unique_id():
		rpc('unregister_player', player)


func broadcast_attack(attacker_id, target_id, dmg):
	if int(attacker_id) == get_tree().get_network_unique_id():
		rpc('attack_player', attacker_id, target_id, dmg)


remotesync func attack_player(attacker_id, target_id, dmg):
	var target_node = get_tree().get_root().get_node(str(target_id))
	var attacker_node = get_tree().get_root().get_node(str(attacker_id))

	if attacker_node:
		attacker_node.state_machine.travel('attack')
	if target_node:
		target_node.set_damage(dmg)
