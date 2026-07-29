extends Control
class_name PlayerUiComponent


@onready var player = owner as PlayerController
@onready var health_bar: ProgressBar = $health_bar
@onready var pause_menu: Panel = $pause_menu

@onready var spawn_timer_label: Label = $death_menu/spawn_timer

signal game_pause 
signal game_resumed

@onready var respawn_timer: Timer = $"../respawn_timer"

var paused : bool = true

var ui_state_died : bool = false

func _ready():
	await owner.ready 
	if !is_multiplayer_authority():
		visible = false
		return
	await get_tree().create_timer(1.5).timeout



func _on_player_update_health(amount: float) -> void:
	health_bar.value = amount


func _on_resume_button_pressed() -> void:
	pause_menu.visible = false
	resume_game()


func _on_quit_button_pressed() -> void:
	get_tree().reload_current_scene()

func _unhandled_input(event: InputEvent) -> void:
	if !is_multiplayer_authority(): return
	if event.is_action_pressed("menu"):
		if paused:
			resume_game()
			paused = false
		else:
			pause_game()
			paused = true

func pause_game():
	pause_menu.visible = true
	game_pause.emit()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func resume_game():
	pause_menu.visible = false
	game_resumed.emit()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_player_died() -> void:
	$death_menu.visible = true
	spawn_timer_label.text = str(round(respawn_timer.time_left))
	ui_state_died = true


func _on_player_respawned() -> void:
	$death_menu.visible = false
	ui_state_died = false


func  _process(delta: float) -> void:
	if !is_multiplayer_authority(): return
	spawn_timer_label.text = str(round(respawn_timer.time_left))
	$fps_label.text = str(Engine.get_frames_per_second())
