extends Node

@onready var status_label = $CanvasLayer/main_menu/VBoxContainer/status
@onready var name_entry = $CanvasLayer/main_menu/VBoxContainer/HBoxContainer/name_entry
@onready var logs = $CanvasLayer/LogMenu/Logs
@onready var member_list = $CanvasLayer/main_menu/VBoxContainer/member_list
const PLAYER  = preload("res://players/player.tscn")
var addr = "studioentropy.ddns.net"#"localhost"#
var port = 6969
var peer
var members = []
var local_id

func _ready():
	multiplayer.peer_connected.connect(player_connected)
	multiplayer.peer_disconnected.connect(player_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)

func player_connected(_id):
	pass

func player_disconnected(id):
	for member in members:
		if member["user_id"] == id: member["connected"] = false
	update_members_list(members)

func connected_to_server():
	#$CanvasLayer/main_menu/VBoxContainer/play_button.disabled = false
	status_label.text = "Connection established!\nID: %s" % local_id
	rpc_id(1, "append_members_list", local_id, name_entry.text)

func _on_join_button_pressed(): # JOIN_BUTTON
	#Lock UI
	if name_entry.text == "": return
	$CanvasLayer/main_menu/VBoxContainer/HBoxContainer/join_button.disabled = true
	$CanvasLayer/main_menu/VBoxContainer/host_button.disabled = true
	name_entry.editable = false
	#Network Logic
	peer = ENetMultiplayerPeer.new()
	peer.create_client(addr, port)
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	#Post Network Setup
	local_id = multiplayer.get_unique_id()

func _on_host_button_pressed(): # HOST_BUTTON
	#Lock UI
	if name_entry.text == "": return
	$CanvasLayer/main_menu/VBoxContainer/HBoxContainer/join_button.disabled = true
	$CanvasLayer/main_menu/VBoxContainer/host_button.disabled = true
	name_entry.editable = false
	#Network Logic
	peer = ENetMultiplayerPeer.new()
	peer.create_server(port)
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	#Post Network Setup
	set_meta("Is_Host", true)
	local_id = multiplayer.get_unique_id()
	status_label.text = "Server established!\nID: %s" % local_id
	$CanvasLayer/main_menu/VBoxContainer/play_button.disabled = false
	rpc("append_members_list", local_id, name_entry.text)

@rpc ("any_peer", "call_local")
func append_members_list(user_id, user_name):
	members.append({
		"user_id"   : user_id,
		"user_name" : user_name,
		"connected" : true,
		"removed"   : false,
	})
	rpc("update_members_list", members)

@rpc ("any_peer", "call_local")
func update_members_list(members_table):
	var old_list = member_list.get_children()
	members = members_table
	var hit
	
	for member in members:
		for label in old_list:
			if label.name == str(member["user_id"]):
				hit = true
				break
			else: hit = false
		if member["connected"] and not hit:
			var label = Label.new()
			label.add_theme_font_size_override("font_size", 30)
			if member["user_id"] == 1:
				label.text += "👑"
			label.text += member["user_name"]
			label.name = str(member["user_id"])
			member_list.add_child(label)
		if not member["connected"] and not member["removed"]:
			member["removed"] = true
			print("removing %s" % member["user_name"])
			print(member_list.get_children())
			member_list.get_node(str(member["user_id"])).queue_free()

func _on_play_button_pressed():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	$CanvasLayer/main_menu.visible = false
	$CanvasLayer/LogMenu.visible = false
	rpc("spawn_player", local_id)
	$env/music.play()

@rpc("any_peer", "call_local")
func spawn_player(id):
	$CanvasLayer/main_menu/VBoxContainer/play_button.disabled = false
	var player = PLAYER.instantiate()
	player.name = str(id)
	add_child(player)
