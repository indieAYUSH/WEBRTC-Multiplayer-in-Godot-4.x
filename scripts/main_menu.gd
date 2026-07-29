extends Control

@onready var main_menu: Control = $"."
@onready var host_lobby: Panel = $"../Lobby/HostLobby"
@onready var client_lobby: Panel = $"../Lobby/ClientLobby"
@onready var lobby: Control = $"../Lobby"
@onready var room_code_display: Label = $"../Lobby/HostLobby/RoomCodeDisplay"
@onready var wait_timer: Timer = $"../WaitTimer"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_host_button_pressed() -> void:
	AudioServer.unlock()
	Network.create_room()
	Network.my_roll = "host"
	main_menu.visible = false
	lobby.visible = true
	host_lobby.visible = true
	lobby.is_host = true
	room_code_display.text = ("Room Code: " + Network.room_code)
	wait_timer.start()

func _on_join_button_pressed() -> void:
	main_menu.visible = false
	lobby.visible = true
	client_lobby.visible = true
	lobby.is_host = false


func _on_exit_button_pressed() -> void:
	get_tree().quit()
