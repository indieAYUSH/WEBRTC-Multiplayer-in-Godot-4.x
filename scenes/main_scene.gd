extends Node3D
@onready var wait_timer: Timer = $WaitTimer

@onready var main_menu: Control = $MainMenu
@onready var lobby: Control = $Lobby

@export var player_scene : PackedScene

var current_spawn_node : Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
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


func stop_polling(_peer_id):
	print(_peer_id)
	wait_timer.stop()
	main_menu.visible = false
	lobby.visible = false
	start_game(_peer_id)

@rpc("any_peer" , "call_remote")
func print_hello():
	print("Hello its ur host speaking")



func start_game(peer_id):
	print(peer_id)
	return
	
	spawn_player(peer_id)


func spawn_player(mp_peer_id):
	if player_scene == null:
		return
	
	var p = player_scene.instantiate()
	add_child(p)
	p.global_position = current_spawn_node.global_position
	p.name = (str(mp_peer_id).to_int())
