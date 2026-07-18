extends Node3D
@onready var wait_timer: Timer = $WaitTimer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#FirebaseManager.offer_answer_unavailable.connect(_on_offer_answer_unavailable)
	#FirebaseManager.offer_answered.connect(answ_recied)
	FirebaseManager.ice_candidate_recieved.connect(on_ice_candidate_recieved)
	Network.stop_polling.connect(stop_polling)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_wait_timer_timeout() -> void:
	if Network.my_roll == "guest":
		FirebaseManager.get_ice_candidates(Network.room_code)
	else:
		if !Network.host_answer_recieved:
			FirebaseManager.get_answer(Network.room_code)
		elif Network.host_answer_recieved:
			FirebaseManager.get_ice_candidates(Network.room_code)


func stop_polling():
	wait_timer.stop()


func on_ice_candidate_recieved(_sender, _media, _index, _candidate):
	return
	print("recieved_ice-candiate")
	wait_timer.stop()
