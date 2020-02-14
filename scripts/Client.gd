extends Node

const server_addr = '127.0.0.1'
const server_port = 5000

var players = []
var player = load('res://scenes/Player.tscn')

func _ready():
	# create and connect client to server
	var client = NetworkedMultiplayerENet.new()
	client.create_client(self.server_addr, self.server_port)
	get_tree().set_network_peer(client)

remote func register_player(id):
	players.append(id)
	# set player name to its unique ID
	var new_player = player.instance()
	new_player.set_name(str(id))
	new_player.set_network_master(1)
	# add node to root
	get_tree().get_root().add_child(new_player)

remote func unregister_player(id):
	# search and remove disconnected player node
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