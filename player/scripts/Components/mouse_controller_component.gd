class_name MouseControllerComponent extends Node


@export_category("Mouse settings")
@export var mouse_capture_mode : Input.MouseMode = Input.MOUSE_MODE_CAPTURED
@export var mouse_senstivity : float  = 0.005

@export_category("refrences")
@export var camera_controller : CameraControllerComponent

@onready var akm: Node3D = %AKM

var capture_mouse : bool
var mouse_input : Vector2

var game_paused : bool = false

@onready var player: PlayerController = $"../.."

func _unhandled_input(event):
	if !is_multiplayer_authority(): return
	if game_paused: return
	if player.player_died : return
	capture_mouse = event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	if capture_mouse:
		mouse_input.x += -event.relative.x * mouse_senstivity
		mouse_input.y += -event.relative.y * mouse_senstivity
		camera_controller._update_rotation(mouse_input)
		akm._sway(mouse_input)

func _ready():
	Input.mouse_mode = mouse_capture_mode


func _process(delta):
	if !is_multiplayer_authority(): return
	mouse_input = Vector2.ZERO




func _on_ui_game_pause() -> void:
	game_paused = true


func _on_ui_game_resumed() -> void:
	game_paused = false
