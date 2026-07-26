class_name PlayerController  extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 6

const gravity : float = 11.5

@onready var head = %head
@onready var crouched_collsion_shape = $crouched_collsion_shape
@onready var uncrouched_collision_shape = $uncrouched_collision_shape
@onready var obstacle_checker = %ShapeCast3D
@onready var player_animation = $PlayerAnimation

@export_category("Component Refrences")
@export var player_statemachine : StateMachine
@export var CameraJuice_Component : CameraJuiceComponent
@export var UiComponent : PlayerUiComponent
@onready var camera : Camera3D = %Camera3D
@onready var respawn_timer: Timer = $respawn_timer
@onready var death_particle: GPUParticles3D = $death_particle

var spawn_point  : Vector3

@export_category("Movement Bools")
@export var can_dash : bool = true

@export var current_character : PlayerChracterStats

@export_category("Lean_Vars")
@export var lean_speed : float = 0.20
enum {LEFT = -1 , CENTER = 0 , RIGHT = 1}
@export var left_lean_collision : ShapeCast3D
@export var right_lean_collision : ShapeCast3D
var lean_tween  

signal  UpdateWeaponHud

@export var health : float = 200
signal update_health(amount : float)

var input_dir
@onready var camera_3d = %Camera3D
var can_lean : bool = true
#Signals
signal recieved_damage
signal died
signal respawned

var player_died: bool = false

var parent 

func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())
	

func _ready():
	position.y+= 4.0
	var local = is_multiplayer_authority()
	set_process(local)
	set_physics_process(local)
	set_process_input(local)
	set_process_unhandled_input(local)
	set_process_shortcut_input(local)
	if !is_multiplayer_authority(): return
	spawn_point = position
	camera.current= true
	parent = get_parent()
	obstacle_checker.add_exception(self)
	left_lean_collision.add_exception(self)
	right_lean_collision.add_exception(self)
	Global.Player = self
	$head/Player_model.visible = false
	

func _physics_process(delta):
	move_and_slide()





func _update_rotation(rot_value : Vector3) -> void :
	transform.basis = Basis.from_euler(rot_value)




func update_movement(_speed : float , _acceleration : float , Deacceleration :float ):
	if !is_multiplayer_authority(): return
	input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = lerp(velocity.x , direction.x * _speed , _acceleration)
		velocity.z = lerp(velocity.z , direction.z * _speed , _acceleration)
	else:
		velocity.x = move_toward(velocity.x, 0,  Deacceleration)
		velocity.z = move_toward(velocity.z, 0,  Deacceleration)



func update_gravity(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta


func crouch():
	#head.position.y =  lerp(head.position.y ,  crouch_depth , lerp_speed *delta)
	crouched_collsion_shape.disabled = false
	uncrouched_collision_shape.disabled = true
	player_animation.play("crouch")

func uncrouch():
	#head.position.y =  lerp(head.position.y , 0.6 + crouch_depth , lerp_speed *delta)
	crouched_collsion_shape.disabled = true
	uncrouched_collision_shape.disabled = false
	player_animation.play("uncrouch")

func dash(direction: Vector3, speed: float) -> void:
	if direction.length() == 0:
		return
	var _direction = direction.normalized()
	_direction.y = 0  
	velocity = _direction * speed  

@rpc("any_peer")
func damage(amount):
	if player_died: return
	health -= min(health , amount)
	update_health.emit(health)
	player_animation.play("damage")
	if health <= 0:
		parent.check_player_death.rpc_id(1, multiplayer.get_unique_id())
		death()

func _on_ui_game_pause() -> void:
	player_statemachine.current_state.change_state.emit("PausedState")


func _on_ui_game_resumed() -> void:
	player_statemachine.current_state.change_state.emit("IdleState")

func death():
	player_died = true
	player_statemachine.current_state.change_state.emit("PausedState")
	death_fx.rpc()
	head.visible = false
	respawn_timer.start()
	died.emit()

@rpc("call_local")
func death_fx():
	death_particle.restart()


func respawn_player():
	health = 200.0
	player_died = false
	head.visible = true
	position = spawn_point
	update_health.emit(health)
	respawned.emit()
	player_statemachine.current_state.change_state.emit("IdleState")


func _on_respawn_timer_timeout() -> void:
	respawn_player()
