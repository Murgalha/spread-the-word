extends Node2D

var PORT = 5000
var MAX_PEERS = 20
var players = []
var player = load('res://scenes/Player.tscn')
var rng = RandomNumberGenerator.new()

func _ready():
	rng.randomize()

	get_tree().connect("network_peer_connected", self, "_client_connected")
	get_tree().connect("network_peer_disconnected", self, "_client_disconnected")

	# create server peer
	var server = NetworkedMultiplayerENet.new()
	var err = server.create_server(PORT, MAX_PEERS)

	if(err):
		print('ERROR ', err,' : Could not create server')
	else:
		print('Server created successfully')

	get_tree().set_network_peer(server)


func _client_connected(id):
	# send RPC to tell a player connected
	print('Client ' + str(id) + ' connected to server')
	var rand_x = rng.randi() % int(get_viewport().size.x) + 1
	var rand_y = rng.randi() % int(get_viewport().size.y) + 1

	# register every player on new player's client
	for player_id in players:
		var player_node = get_tree().get_root().get_node(str(player_id))
		var pos = player_node.position
		rpc_id(id, 'register_player', player_id, pos.x, pos.y)

	# register new player on every other player's client
	rpc("register_player", id, rand_x, rand_y)


func _client_disconnected(id):
	# send RPC to tell a player disconnected
	print('Client ' + str(id) + ' disconnected from server')
	rpc("unregister_player", id)


remotesync func register_player(id, x, y):
	players.append(id)
	var new_player = player.instance()
	# set player name to its unique ID
	new_player.set_name(str(id))
	new_player.position = Vector2(x, y)
	new_player.set_network_master(1)
	# Add to root node
	get_tree().get_root().add_child(new_player)


remotesync func unregister_player(id):
	# find and remove disconnected player
	var index = players.find(id)
	if index > -1:
		players.remove(index)
	var node = get_tree().get_root().get_node(str(id))
	if node:
		node.queue_free()


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
