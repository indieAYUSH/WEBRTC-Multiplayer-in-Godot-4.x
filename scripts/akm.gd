extends Node3D



@export var weapon_damage : float = 18.0


@export var current_ammo : int = 30
@export var mag_size : int = 30
@export var animation_player : AnimationPlayer
@export var weapon_ray_cast : RayCast3D
@export var autofire : bool = true

@onready var muzzle_flash: Node3D = $Barrel_node/MuzzleFlash

@export var envo_hit_particles : PackedScene
@export var blood_splatter_particle : PackedScene
@export var bullet_tracer : PackedScene


@export_category("animation_name")
@export var shootin_anim : String
@export var reloading_anim : String

@onready var barrel_node: Node3D = $Barrel_node

@export var ads_pos : Vector3 
@export var default_pos : Vector3

var can_ads : bool = true

@export var player_controller : PlayerController

enum GUN_ANIMATION_STATE{
	NONE,
	SHOOTING,
	RELOADING
}

var current_gun_animation_state : GUN_ANIMATION_STATE = GUN_ANIMATION_STATE.NONE

@export_group("WEAPON JUICE THINGS")
@export_category("refrences")
@export var weapon_holder : Node3D

@export_category("effects")
@export var weapon_tilt : bool
@export  var weapon_bob : bool

@export_category("weapon_tilt")
@export var roll_pitch : float 
@export var roll_side_rot  : float

@export_category("weapon_bob")
@export var frequency  : float
@export var amplitude : float
var bob_phase : float
var bob_intensity : float

@export_category("others")
@export var lerp_speed : float = 15.0

func _unhandled_input(event: InputEvent) -> void:
	if !is_multiplayer_authority(): return
	if event.is_action_pressed("shoot"):
		shoot()
	if event.is_action_pressed("reload"):
		reload()

func _ready() -> void:
	if !is_multiplayer_authority(): return
	animation_player.animation_finished.connect(on_animation_player_finished_playing)

func on_animation_player_finished_playing(anim_name : String)->void:
	
	if anim_name == shootin_anim and Input.is_action_pressed("shoot") and autofire:
		shoot()




func reload()->void:
	if current_ammo >= mag_size:
		return
	if animation_player.is_playing(): return
	var amt = min(mag_size , mag_size-current_ammo)
	current_ammo += amt
	animation_player.play(reloading_anim)

func shoot()->void:
	if animation_player.is_playing(): return
	
	if current_ammo <= 0:
		reload()
		return
	current_gun_animation_state = GUN_ANIMATION_STATE.SHOOTING
	show_fx.rpc()
	current_ammo -= 1
	if weapon_ray_cast.is_colliding():
		var collider = weapon_ray_cast.get_collider()
		var pos = weapon_ray_cast.get_collision_point()
		show_bullet_traces.rpc(barrel_node.global_position , pos)
		if collider.has_method("damage"):
			collider.damage.rpc_id(collider.get_multiplayer_authority()  , weapon_damage)
			show_player_hit_particle.rpc(pos)
		else:
			show_eno_hit_particle.rpc(pos)
	else:
		show_bullet_traces.rpc(barrel_node.global_position , weapon_ray_cast.target_position)

@rpc("call_local")
func show_fx()->void:
	muzzle_flash._show_muzzle_flash()
	match current_gun_animation_state:
		GUN_ANIMATION_STATE.NONE:
			pass
		GUN_ANIMATION_STATE.SHOOTING:
			animation_player.play(shootin_anim)
		GUN_ANIMATION_STATE.RELOADING:
			animation_player.play(reloading_anim)

@rpc("call_local")
func show_eno_hit_particle(position , _normal : Vector3):
	var h_p :GPUParticles3D   = envo_hit_particles.instantiate()
	add_child(h_p)
	h_p.global_position = position
	h_p.emitting = true
	await get_tree().create_timer(0.09).timeout
	h_p.queue_free()


@rpc("call_local")
func show_player_hit_particle(position):
	var h_p   =  blood_splatter_particle.instantiate()
	add_child(h_p)
	h_p.global_position = position
	h_p.emitting = true
	await get_tree().create_timer(0.09).timeout
	h_p.queue_free()


@rpc("call_local")
func show_bullet_traces(_start_point : Vector3 , _end_point : Vector3):
	var b_t : = bullet_tracer.instantiate()
	add_child(b_t)
	b_t.global_position = _start_point
	
	var tween = get_tree().create_tween()
	tween.tween_property(b_t , "global_position" , _end_point , 0.08)
	tween.tween_callback(b_t.queue_free)

func _process(delta: float) -> void:
	if !is_multiplayer_authority() : return
	if Input.is_action_pressed("ADS") and can_ads:
		position = ads_pos
	else:
		position = default_pos



func _sway(amount: Vector2) -> void :
	position.x += amount.x * 0.09
	position.y += amount.y * 0.09 
	
	rotation.x += deg_to_rad(amount.x * 0.08)  
	rotation.y += deg_to_rad (amount.y * 0.05) 


func weapon_juice(delta : float ) -> void:
	var angles  : Vector3
	var offset  : Vector3
	
	var velocity = player_controller.velocity.length()
	
	if velocity > 0.01 and weapon_tilt:
		rotation.x = lerp(rotation.x , (roll_pitch*Input.get_axis("forward","backward"))  , delta*lerp_speed)
		rotation.z = lerp(rotation.z , -(roll_side_rot*Input.get_axis("left","right"))  , delta*lerp_speed)

	if velocity > 0.01 and player_controller.is_on_floor() and weapon_bob and _can_headbob():
		var speed_factor = clamp(velocity/9.5 , 0.0 , 1.0)
		bob_phase += frequency*speed_factor*delta*velocity
		bob_intensity = amplitude
		var p = position
		p.x =  sin(bob_phase*0.5) * amplitude
		p.y = sin(bob_phase)*amplitude
		offset = p
	else :
		offset = lerp(offset , Vector3.ZERO , delta*8.0)
		
	
	weapon_holder.rotation = angles
	position = offset

func _can_headbob() -> bool:
	var state_name = player_controller.player_statemachine.current_state.name
	# Headbob is allowed if the player is NOT sliding or dashing
	return state_name != "SlideState" and state_name != "DashState"
