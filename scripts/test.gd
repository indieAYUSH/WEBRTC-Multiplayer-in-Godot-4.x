extends Node
var peer: WebRTCPeerConnection

func _ready():
	peer = WebRTCPeerConnection.new()

	peer.initialize({
		"iceServers": [{
			"urls": ["stun:stun.l.google.com:19302"]
		}]
	})

	peer.session_description_created.connect(func(type, sdp):
		print("SESSION CREATED:", type)
	)

	peer.create_data_channel("game")
	peer.create_offer()


func _process(_delta):
	peer.poll()
