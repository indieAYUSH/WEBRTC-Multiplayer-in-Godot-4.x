extends Control

@onready var lobby: Control = $"."
@onready var main_menu: Control = $"../MainMenu"
@onready var host_lobby: Panel = $HostLobby
@onready var client_lobby: Panel = $ClientLobby
@onready var client_room_code: LineEdit = $ClientLobby/ClientRoomCode
@onready var wait_timer: Timer = $"../WaitTimer"


var is_host : bool = false





func _on_back_to_menu_pressed() -> void:
	get_tree().reload_current_scene()


func _on_client_joinbutton_pressed() -> void:
	FirebaseManager.get_room(client_room_code.text)
	Network.room_code = client_room_code.text
	Network.my_roll = "guest"
	wait_timer.start()
