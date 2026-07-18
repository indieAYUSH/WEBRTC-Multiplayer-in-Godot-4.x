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

var channels = {}


func _ready() -> void:
	FirebaseManager.room_recieved.connect(on_room_recieved)
	FirebaseManager.offer_answered.connect(on_offer_recieved)
	FirebaseManager.ice_candidate_recieved.connect(_on_ice_candidate_recieved)


func _process(_delta):
	for peer in peers.values():
		peer.poll()
	
	if my_roll == "guest" and channels.has(1):
		var channel: WebRTCDataChannel = channels[1]

		while channel.get_available_packet_count() > 0:
			var msg = channel.get_packet().get_string_from_utf8()
			print("Guest received:", msg)
	if my_roll == "host" and channels.has(1):
		var channel: WebRTCDataChannel = channels[1]

		while channel.get_available_packet_count() > 0:
			var msg = channel.get_packet().get_string_from_utf8()
			print("Host received:", msg)
	
	if host_guest_connected:
		return
	
	if peers.size() < 1:
		return
	var state = peers[1].get_connection_state()
	if state != last_state:
		last_state = state
		print("State:", state)
	
	if state == 2:
		host_guest_connected = true
		stop_polling.emit()
		var channel = channels[1]
		#=================--------testing and place holder only---===
		if is_host:
			send_hello_packet()

	

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
	peer.data_channel_received.connect(_on_data_channel_received.bind(peer_id))
	
	if is_host:
		var channel = peer.create_data_channel("game")
		channels[peer_id] = channel
	
	
	peers[peer_id] = peer
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

func _on_data_channel_received(channel: WebRTCDataChannel, peer_id):
	channels[peer_id] = channel
	print(channels)

#PLACE HOLDER U CAN USE THIS FOR TESTING WETHER DATA CHANNELS ARE OPENED OR NOT

func send_hello_packet():
	var channel: WebRTCDataChannel = channels[1]

	if channel.get_ready_state() == WebRTCDataChannel.STATE_OPEN:
		var err = channel.put_packet("Hello from Host".to_utf8_buffer())
		print("Send result:", err)
