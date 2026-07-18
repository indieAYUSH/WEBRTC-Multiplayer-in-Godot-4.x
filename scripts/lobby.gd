extends Control

@onready var lobby: Control = $"."
@onready var main_menu: Control = $"../MainMenu"
@onready var host_lobby: Panel = $HostLobby
@onready var client_lobby: Panel = $ClientLobby
@onready var client_room_code: LineEdit = $ClientLobby/ClientRoomCode
@onready var wait_timer: Timer = $"../WaitTimer"


var is_host : bool = false


func _on_room_code_copy_pressed() -> void:
	DisplayServer.clipboard_set(Network.room_code)


func _on_join_button_pressed() -> void:
	pass


func _on_back_to_menu_pressed() -> void:
	main_menu.visible = true
	lobby.visible = false
	if is_host:
		host_lobby.visible = false
	else:
		client_lobby.visible = false


func _on_client_joinbutton_pressed() -> void:
	FirebaseManager.get_room(client_room_code.text)
	Network.room_code = client_room_code.text
	Network.my_roll = "guest"
	wait_timer.start()
