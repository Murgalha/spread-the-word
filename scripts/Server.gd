extends Node2D

var PORT = 5000
var MAX_PEERS = 20
var players = []
var player = load('res://scenes/Player.tscn')


func _ready():
	get_tree().connect("network_peer_connected",    self, "_client_connected"   )
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
	var rand_x = randi() % int(get_viewport().size.x) + 1
	var rand_y = randi() % int(get_viewport().size.y) + 1
	
	for player_id in players:
		var player_node = get_tree().get_root().get_node(str(player_id))
		var pos = player_node.position
		rpc_id(id, 'register_player', player_id, pos.x, pos.y)
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
	get_tree().get_root().get_node(str(id)).queue_free()


# send RPC to tell player has moved and set its position
func signal_movement(id, vel):
	if id != 1:
		rpc('move_player', id, vel)


# set player position
remote func move_player(id, vel):
	var player_node = get_tree().get_root().get_node(str(id))
	player_node.set_velocity(vel)