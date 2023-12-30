extends Node

@onready var status_label = $CanvasLayer/main_menu/VBoxContainer/status
@onready var name_entry = $CanvasLayer/main_menu/VBoxContainer/HBoxContainer/name_entry
const PLAYER  = preload("res://players/player.tscn")
var addr = "studioentropy.ddns.net"
var port = 6969
var peer
var player
var member_index
var member_list = []

func _ready():
	multiplayer.peer_connected.connect(player_connected)
	multiplayer.peer_disconnected.connect(player_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)

func player_connected(id):
	print(str(multiplayer.get_unique_id()) + " ---> " + str(id))
	rpc_id(id, "add_list_local", get_meta("Name"), get_meta("Is_Host"))

func player_disconnected(id):
	print(str(multiplayer.get_unique_id()) + ": Player disconnected - " + str(id))
	
func connected_to_server():
	status_label.text = "Connection established!"
	set_member_name(name_entry.text)
	add_list_local(get_meta("Name"))
	$CanvasLayer/main_menu/VBoxContainer/play_button.disabled = false


func connection_failed(id):
	print("Failed to connect - " + str(id))
	
func _on_join_button_pressed(): # JOIN_BUTTON
	if name_entry.text == "": return
	$CanvasLayer/main_menu/VBoxContainer/HBoxContainer/join_button.disabled = true
	$CanvasLayer/main_menu/VBoxContainer/host_button.disabled = true
	name_entry.editable = false
	peer = ENetMultiplayerPeer.new()
	peer.create_client(addr, port)
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)

func _on_host_button_pressed(): # HOST_BUTTON
	if name_entry.text == "": return
	$CanvasLayer/main_menu/VBoxContainer/HBoxContainer/join_button.disabled = true
	$CanvasLayer/main_menu/VBoxContainer/host_button.disabled = true
	name_entry.editable = false
	peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(port)
	if err != OK:
		print("Error connecting: " + str(err))
		return
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	status_label.text = "Server established!"
	set_meta("Is_Host", true)
	set_member_name(name_entry.text)
	add_list_local(get_meta("Name"), get_meta("Is_Host"))
	$CanvasLayer/main_menu/VBoxContainer/play_button.disabled = false

func _on_play_button_pressed():
	spawn_player(multiplayer.get_unique_id())
	$CanvasLayer.visible = false

@rpc("any_peer", "call_local")
func add_list_local(member_name, host = false): 
	print(str(multiplayer.get_unique_id()) + ": new label (%s)" % member_name)
	var member_label = Label.new()
	member_label.add_theme_font_size_override("font_size", 30)
	if host:
		member_label.text = "👑"
	member_label.text += member_name
	member_label.name = member_name
	$CanvasLayer/main_menu/VBoxContainer/member_list.add_child(member_label)
	if multiplayer.get_unique_id() == 1:
		member_list.push_back(member_name)
		#print("Pushed index")
		#print("Post Pushed Index: " + str(member_list.size()))
	if host:
		$CanvasLayer/main_menu/VBoxContainer/member_list.move_child(member_label, 0)
	else:
		#if multiplayer.get_unique_id() == 1: return
		print("pre-id: " + str(multiplayer.get_unique_id()))
		rpc_id(1, "set_member_index", member_list)
		#$CanvasLayer/main_menu/VBoxContainer/member_list.move_child(member_label, member_index)

@rpc("any_peer", "call_local")
func set_member_index(list):
	#member_index = list.size()
	print("post-id: " + str(multiplayer.get_unique_id()))
	#print("INDEX: " + str(list.size()))
	#print("INDEX0: " + str(list[0]))

#@rpc("call_local")
func spawn_player(id):
	player = PLAYER.instantiate()
	player.name = str(id)
	add_child(player)

func set_member_name(member_name):
	set_meta("Name", member_name)

func _process(_delta):
	pass
