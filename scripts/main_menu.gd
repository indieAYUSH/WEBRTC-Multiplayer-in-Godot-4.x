extends Control

@onready var main_menu: Control = $"."
@onready var host_lobby: Panel = $"../Lobby/HostLobby"
@onready var client_lobby: Panel = $"../Lobby/ClientLobby"
@onready var lobby: Control = $"../Lobby"
@onready var room_code_display: Label = $"../Lobby/HostLobby/RoomCodeDisplay"
@onready var wait_timer: Timer = $"../WaitTimer"
@onready var name_edit: Panel = $player_profile/name_edit
@onready var entered_name: LineEdit = $player_profile/name_edit/name
@onready var button: Button = $player_profile/name_edit/Button

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_host_button_pressed() -> void:
	Network.create_room()
	Network.my_roll = "host"
	main_menu.visible = false
	lobby.visible = true
	host_lobby.visible = true
	lobby.is_host = true
	room_code_display.text = Network.room_code
	wait_timer.start()

func _on_join_button_pressed() -> void:
	main_menu.visible = false
	lobby.visible = true
	client_lobby.visible = true
	lobby.is_host = false


func _on_exit_button_pressed() -> void:
	get_tree().quit()


func _on_name_change_button_pressed() -> void:
	name_edit.visible = true



func _on_close_button_pressed() -> void:
	name_edit.visible  = false
