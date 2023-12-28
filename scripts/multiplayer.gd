extends Node

const PLAYER  = preload("res://players/player.tscn")
const PORT    = 6969
var enet_peer = ENetMultiplayerPeer.new()
var add = "studioentropy.ddns.net"#"localhost"#

func _input(event):
	if Input.is_action_just_pressed("host"):
		enet_peer.create_server(PORT)
		multiplayer.multiplayer_peer = enet_peer
		multiplayer.peer_connected.connect(add_player)
		
		add_player(multiplayer.get_unique_id())
		
	if Input.is_action_just_pressed("join"):
		enet_peer.create_client(add, PORT)
		multiplayer.multiplayer_peer = enet_peer
		
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()

func add_player(peer_id):
	var player = PLAYER.instantiate()
	player.name = str(peer_id)
	add_child(player)
