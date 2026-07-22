extends Node3D
@onready var wait_timer: Timer = $WaitTimer

@onready var main_menu: Control = $MainMenu
@onready var lobby: Control = $Lobby
@onready var spawn_point_1: Node3D = $SpawnPoints/SpawnPoint1
@onready var spawn_point_2: Node3D = $SpawnPoints/SpawnPoint2

@export var player_scene : PackedScene
var spawn_count : int = 0     # u can use more scalable way like sending role direct from netwrok manager i am using this just for speed

var current_spawn_node : Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Network.stop_polling.connect(stop_polling)
	Network.start_game.connect(start_game)
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
	main_menu.visible = false
	lobby.visible = false	


@rpc("any_peer" , "call_remote")
func print_hello():
	print("Hello its ur host speaking")



func start_game(peer_id):
	set_spawn_point()
	spawn_count += 1
	main_menu.visible = false
	lobby.visible = false
	spawn_player(peer_id)


func spawn_player(mp_peer_id):
	if player_scene == null:
		return
	
	var p = player_scene.instantiate()
	p.name = (str(mp_peer_id))
	p.global_position = current_spawn_node.global_position
	add_child(p)
	print(Network.my_roll , "spawning player:" , p.get_multiplayer_authority() , p.global_position)
func set_spawn_point():
	if spawn_count == 0:
		current_spawn_node = spawn_point_1
	elif spawn_count == 1:
		current_spawn_node = spawn_point_2
