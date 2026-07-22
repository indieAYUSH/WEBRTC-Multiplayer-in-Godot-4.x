class_name NetworkManager
extends Node

const STUN_SERVER = {
	"urls" : ["stun:stun.l.google.com:19302"]
}

var room_code : String = ""
var max_player : int = 4
var is_host : bool 
var peers : Dictionary = {}
var room_ready : bool = false
var connected_players : Array[int]

var my_roll : String = ""
var recieved_candidate = []
var host_answer_recieved : bool = false
var last_state = -1

#PLACE HOLDER FOR MY PROJECT TO STOP POLLING TIMER
signal stop_polling 
var host_guest_connected : bool = false

signal start_game(_peer_id)




func _ready() -> void:
	FirebaseManager.room_recieved.connect(on_room_recieved)
	FirebaseManager.offer_answered.connect(on_offer_recieved)
	FirebaseManager.ice_candidate_recieved.connect(_on_ice_candidate_recieved)


func _process(_delta):
	for peer in peers.values():
		peer.poll()
	
	if host_guest_connected:
		return
	
	if peers.size() < 1:
		return
	var state = peers[1].get_connection_state()
	if state != last_state:
		last_state = state
		print("State:", state)
	
	if state == 2:
		print("starting game")
		host_guest_connected = true
		stop_polling.emit()



func genrate_room_code(length : = 6)->String:
	var code : = ""
	var ChracterPool : = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	
	for i in length:
		code += ChracterPool[randi()%ChracterPool.length()]
	
	return code

func create_room():
	is_host = true
	room_code = genrate_room_code()
	connected_players.clear()
	connected_players.append(1)
	create_host_peer()

func create_host_peer():
	var peer = create_new_peer_connection(1)
	peer.create_offer()

func create_new_peer_connection(peer_id:int) -> WebRTCPeerConnection:
	var peer : WebRTCPeerConnection = WebRTCPeerConnection.new()
	
	var error = peer.initialize({
		"iceServers":[STUN_SERVER]
	})
	
	if error != OK:
		push_error("Couldn't initialize WebRTC")
		
	
	
	peer.session_description_created.connect(_on_session_description_created.bind(peer_id))
	peer.ice_candidate_created.connect(_on_ice_candidate_created.bind(peer_id))
	
	peers[peer_id] = peer
	
	if is_host:
			create_host_multiplayer_peer()
	else:
			create_client_multiplayer_peer()
	return peer

func _on_session_description_created(type:String , sdp:String , _peer_id ):
	var peer : WebRTCPeerConnection = peers[_peer_id]
	peer.set_local_description(type , sdp)
	if type == "answer":
		FirebaseManager.upload_answer(room_code , type , sdp)
	elif type == "offer":
		FirebaseManager.upload_offer(room_code , type , sdp)
	

func _on_ice_candidate_created(media: String, index: int, name: String, _peer_id):
	FirebaseManager.upload_ice_candidates(room_code , media , name , index , my_roll)
 
func on_room_recieved(_type:String , _sdp:String):
	create_new_peer_connection(1)
	var peer : WebRTCPeerConnection = peers[1]
	peer.set_remote_description(_type , _sdp)

func on_offer_recieved(_type : String , _sdp : String):
	var peer : WebRTCPeerConnection = peers[1]
	peer.set_remote_description(_type , _sdp)
	host_answer_recieved = true


func _on_ice_candidate_recieved(sender, media, index, candidate):
	var peer : WebRTCPeerConnection= peers[1]
	
	if sender == my_roll:
		return
	
	if recieved_candidate.has(candidate):
		return
	
	recieved_candidate.push_back(candidate)
	peer.add_ice_candidate(media , index , candidate)




func create_host_multiplayer_peer():
	var mp = WebRTCMultiplayerPeer.new()
	mp.create_server()
	var err = mp.add_peer(peers[1], 2)
	print("add_peer:", err)
	multiplayer.multiplayer_peer = mp
	_start_game(multiplayer.get_unique_id())
	mp.peer_connected.connect(_start_game , multiplayer.get_unique_id())

func create_client_multiplayer_peer():
	var mp = WebRTCMultiplayerPeer.new()
	mp.create_client(2)
	var err = mp.add_peer(peers[1], 1)
	print("add_peer:", err)
	multiplayer.multiplayer_peer = mp

func _start_game(_peer_id):
	print(_peer_id)
	start_game.emit(_peer_id)
