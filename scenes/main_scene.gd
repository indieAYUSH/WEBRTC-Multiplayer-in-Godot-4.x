extends Node3D
@onready var wait_timer: Timer = $WaitTimer

@onready var main_menu: Control = $MainMenu
@onready var lobby: Control = $Lobby
@onready var spawn_point_1: Node3D = $SpawnPoints/SpawnPoint1
@onready var spawn_point_2: Node3D = $SpawnPoints/SpawnPoint2
@onready var red_team_score_label: Label = $UI/score_board/red_team/red_team_score
@onready var blue_team_score_label: Label = $UI/score_board/blue_team/blue_team_score
@onready var score_board: CanvasGroup = $UI/score_board

@export var player_scene : PackedScene
var spawn_count : int = 0     # u can use more scalable way like sending role direct from netwrok manager i am using this just for speed

var current_spawn_node : Node3D

var red_team_score : int = 0
var blue_team_score : int = 0 
var max_score : int = 2

@onready var menu_camera: Camera3D = $menu_camera

#----============Player profile ----------============#
@onready var name_field: LineEdit = $MainMenu/player_profile/name_edit/name_field
@onready var button: Button = $MainMenu/player_profile/name_edit/Button
var my_name : String
@onready var looser_prompt: Label = $UI/winning_Screen/looser_prompt
@onready var winner_prompt: Label = $UI/winning_Screen/winner_prompt
@onready var returning_label: Label = $UI/winning_Screen/returning_label
@onready var winning_screen: Panel = $UI/winning_Screen
@onready var rain_sound_effect: AudioStreamPlayer = $rain_sound_effect

var host_name : String
var gues_name : String



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
	score_board.visible = true


func start_game(peer_id):
	set_spawn_point()
	spawn_count += 1
	main_menu.visible = false
	lobby.visible = false
	score_board.visible = true
	spawn_player(peer_id)
	menu_camera.queue_free()

func spawn_player(mp_peer_id):
	if player_scene == null:
		return
	
	rain_sound_effect.play()
	var p = player_scene.instantiate()
	p.name = (str(mp_peer_id))
	p.global_position = current_spawn_node.global_position
	add_child(p) 

func set_spawn_point():
	if spawn_count == 0:
		current_spawn_node = spawn_point_1
	elif spawn_count == 1:
		current_spawn_node = spawn_point_2

@rpc("any_peer" , "call_local")
func check_player_death(peer_id : int) -> void:
	inc_score_count.rpc(peer_id)

@rpc("call_local")
func inc_score_count(_peer_id : int) -> void:
	if _peer_id  == 1:
		blue_team_score += 1
	elif _peer_id == 2:
		red_team_score += 1
	red_team_score_label.text = str(red_team_score)
	blue_team_score_label.text = str(blue_team_score)
	check_winner.rpc_id(1)


func _on_close_button_pressed() -> void:
	pass # Replace with function body.



@rpc("any_peer" , "call_local")
func check_winner():
	if red_team_score >= max_score or blue_team_score >= max_score:
		if red_team_score > blue_team_score:
			declare_host_winner.rpc()
		else:
			declare_guest_winner.rpc()

@rpc("any_peer" , "call_local")
func declare_host_winner():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$lobby_return_timer.start()
	winning_screen.visible = true
	if Network.is_host:
		winner_prompt.visible = true
	else:
		looser_prompt.visible = true


@rpc("any_peer" , "call_local")
func declare_guest_winner():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$lobby_return_timer.start()
	winning_screen.visible = true
	if Network.is_host:
		looser_prompt.visible = true
	else:
		winner_prompt.visible = true


func _on_lobby_return_timer_timeout() -> void:
	get_tree().reload_current_scene()
