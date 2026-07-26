class_name  CrouchState  extends PlayerMovementState

@export_category("Movement vars")
@export var speed : float = 4.5
@export var acceleration : float = 0.15
@export var deacceleration : float  = 0.3

@export var toggle_crouch : bool

var crouched : bool = false

@onready var crouch_shape_cast = %ShapeCast3D
@onready var crouch: AudioStreamPlayer3D = $"../../movment_sfx/crouch"
@onready var uncrouch: AudioStreamPlayer3D = $"../../movment_sfx/uncrouch"

var crouch_depth : float = -0.6
var lerp_speed : float = 10.0
@export var CameraController : CameraControllerComponent

func enter()->void:
	Player.crouch()
	play_sfx.rpc()



func _update(delta : float) -> void:
	if not Input.is_action_pressed("crouch") and not crouch_shape_cast.is_colliding():
		change_state.emit("IdleState")
	
	if Player.velocity.y < -3.0 :
		change_state.emit("FallingState")



func physics_update(delta : float)-> void:
	Player.update_gravity(delta)
	Player.update_movement(speed,acceleration , deacceleration)

func exit()-> void:
	Player.uncrouch()
	play_sfx.rpc()

@rpc("call_local")
func  play_sfx():
	if crouched:
		uncrouch.play()
		crouched = false
	else:
		crouch.play()
		crouched = true
