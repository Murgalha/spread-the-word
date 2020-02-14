extends Node

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
	rpc("register_player", id)
	
func _client_disconnected(id):
	# send RPC to tell a player disconnected
	print('Client ' + str(id) + ' disconnected from server')
	rpc("unregister_player", id)

remotesync func register_player(id):
	players.append(id)
	var new_player = player.instance()
	# set player name to its unique ID
	new_player.set_name(str(id))
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
func signal_movement(id, pos):
	rpc_unreliable('move_player', id, pos)

# set player position
remote func move_player(id, pos):
	var player = get_tree().get_root().get_node(str(id))
	player.set_position(pos)